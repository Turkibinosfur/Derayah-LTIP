/*
  # Fix process_vesting_event Function
  
  This migration fixes the process_vesting_event function to:
  1. Update remaining_unvested_shares when vesting shares
  2. Add proper error handling with row count checks
  3. Ensure data consistency between vested_shares and remaining_unvested_shares
*/

-- Update process_vesting_event to also update remaining_unvested_shares and add error handling
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
  v_requires_performance boolean := false;
  v_result jsonb := '{}';
  v_rows_updated integer;
BEGIN
  -- Get vesting event
  SELECT * INTO v_event FROM vesting_events WHERE id = p_vesting_event_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Vesting event not found');
  END IF;

  -- Check if event is due
  IF v_event.status NOT IN ('due', 'pending') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Event is not due for processing');
  END IF;

  -- Get grant
  SELECT * INTO v_grant FROM grants WHERE id = v_event.grant_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Grant not found for vesting event');
  END IF;

  -- Determine if the grant has performance metrics that require confirmation
  SELECT EXISTS (
    SELECT 1
    FROM grant_performance_metrics gpm
    WHERE gpm.grant_id = v_grant.id
      AND gpm.company_id = v_event.company_id
  ) INTO v_requires_performance;

  -- Prevent vesting if performance conditions are not met for grants with linked metrics
  -- Only enforce this check if there are actually linked performance metrics
  IF v_event.event_type IN ('performance', 'performance_based', 'hybrid')
     AND v_requires_performance
     AND NOT COALESCE(v_event.performance_condition_met, false) THEN
    RETURN jsonb_build_object(
      'success', false, 
      'error', 'Performance condition not confirmed. Please confirm performance metrics before vesting this event.'
    );
  END IF;

  -- Get plan details for response payloads
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
  
  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Failed to update vesting event status');
  END IF;

  -- Update grant vested shares AND remaining_unvested_shares
  -- Use GREATEST to ensure remaining_unvested_shares never goes negative
  UPDATE grants 
  SET 
    vested_shares = COALESCE(vested_shares, 0) + v_event.shares_to_vest,
    remaining_unvested_shares = GREATEST(0, COALESCE(remaining_unvested_shares, total_shares) - v_event.shares_to_vest),
    updated_at = now()
  WHERE id = v_event.grant_id;
  
  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Failed to update grant shares');
  END IF;

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

COMMENT ON FUNCTION process_vesting_event(uuid, uuid, numeric) IS 
'Processes a vesting event, updates event status to vested, and updates grant vested_shares and remaining_unvested_shares';

