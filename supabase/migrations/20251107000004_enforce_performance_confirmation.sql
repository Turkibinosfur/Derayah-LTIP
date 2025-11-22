-- Ensure performance-based vesting events require explicit confirmation before processing
CREATE OR REPLACE FUNCTION process_vesting_event(
  p_vesting_event_id uuid,
  p_processed_by uuid DEFAULT auth.uid(),
  p_fair_market_value numeric DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_event vesting_events%ROWTYPE;
  v_grant grants%ROWTYPE;
  v_plan incentive_plans%ROWTYPE;
  v_result jsonb := '{}';
BEGIN
  -- Get vesting event
  SELECT * INTO v_event FROM vesting_events WHERE id = p_vesting_event_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Vesting event not found');
  END IF;

  -- Prevent vesting if performance conditions are not met
  IF v_event.event_type IN ('performance', 'performance_based', 'hybrid')
     AND NOT COALESCE(v_event.performance_condition_met, false) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Performance condition not confirmed');
  END IF;

  -- Check if event is due
  IF v_event.status NOT IN ('due', 'pending') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Event is not due for processing');
  END IF;

  -- Get grant and plan details
  SELECT * INTO v_grant FROM grants WHERE id = v_event.grant_id;
  SELECT * INTO v_plan FROM incentive_plans WHERE id = v_grant.plan_id;

  -- Update vesting event status
  UPDATE vesting_events 
  SET 
    status = 'vested',
    processed_at = now(),
    processed_by = p_processed_by,
    fair_market_value = p_fair_market_value,
    updated_at = now()
  WHERE id = p_vesting_event_id;

  -- Update grant vested shares
  UPDATE grants 
  SET 
    vested_shares = vested_shares + v_event.shares_to_vest,
    updated_at = now()
  WHERE id = v_event.grant_id;

  v_result := jsonb_build_object(
    'success', true,
    'event_id', v_event.id,
    'shares_vested', v_event.shares_to_vest,
    'plan_type', v_plan.plan_type,
    'requires_exercise', v_plan.plan_type = 'ESOP'
  );

  RETURN v_result;
END;
$$;

-- Normalize existing performance events to require confirmation
UPDATE vesting_events
SET performance_condition_met = false
WHERE event_type = 'performance'
  AND status IN ('pending', 'due');

-- Migration: populate employee_id on vesting_events and keep it in sync

-- Backfill employee_id for existing vesting events based on grants
UPDATE vesting_events ve
SET employee_id = g.employee_id
FROM grants g
WHERE ve.grant_id = g.id
  AND (ve.employee_id IS DISTINCT FROM g.employee_id);

-- Create or replace function to sync employee_id on vesting_events
CREATE OR REPLACE FUNCTION public.sync_vesting_event_employee()
RETURNS TRIGGER AS $$
BEGIN
  NEW.employee_id := (SELECT employee_id FROM grants WHERE id = NEW.grant_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to set employee_id before insert on vesting_events
DROP TRIGGER IF EXISTS set_employee_id_on_vesting_events ON public.vesting_events;
CREATE TRIGGER set_employee_id_on_vesting_events
BEFORE INSERT OR UPDATE ON public.vesting_events
FOR EACH ROW
EXECUTE FUNCTION public.sync_vesting_event_employee();

