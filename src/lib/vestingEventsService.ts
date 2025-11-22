// @ts-nocheck
import { supabase } from './supabase';

const PERFORMANCE_EVENT_TYPES = ['performance', 'performance_based', 'hybrid'];

export interface GrantPerformanceMetricSummary {
  id?: string;
  name?: string;
  description?: string | null;
  metric_type?: string | null;
  unit_of_measure?: string | null;
  target_value?: number | null;
  actual_value?: number | null;
  is_achieved?: boolean | null;
  achieved_at?: string | null;
}

export interface VestingEvent {
  id: string;
  grant_id: string;
  employee_id: string;
  company_id: string;
  event_type: 'cliff' | 'time_based' | 'performance' | 'acceleration';
  sequence_number: number;
  vesting_date: string;
  shares_to_vest: number;
  cumulative_shares_vested: number;
  status: 'pending' | 'due' | 'vested' | 'transferred' | 'exercised' | 'forfeited' | 'cancelled';
  processed_at?: string;
  processed_by?: string;
  exercise_price?: number;
  fair_market_value?: number;
  total_exercise_cost?: number;
  performance_condition_met: boolean;
  performance_notes?: string;
  portfolio_transaction_id?: string;
  created_at: string;
  updated_at: string;
  
  // Joined data
  employees?: {
    id: string;
    first_name_en?: string;
    first_name_ar?: string;
    last_name_en?: string;
    last_name_ar?: string;
  };
  grants?: {
    id: string;
    grant_number: string;
    total_shares: number;
    vested_shares: number;
    plan_id: string;
    vesting_schedule_id?: string | null;
    employee_acceptance_at?: string | null;
    incentive_plans?: {
      plan_name_en: string;
      plan_code: string;
      plan_type: 'LTIP_RSU' | 'LTIP_RSA' | 'ESOP';
    };
    grant_performance_metrics?: {
      performance_metric_id: string;
      performance_metrics?: {
        id: string;
        name: string;
        description: string | null;
        metric_type: string | null;
        unit_of_measure: string | null;
      };
    }[];
  };
}

export interface VestingEventWithDetails extends VestingEvent {
  employee_name: string;
  plan_name: string;
  plan_code: string;
  plan_type: 'LTIP_RSU' | 'LTIP_RSA' | 'ESOP';
  days_remaining: number;
  can_exercise: boolean;
  requires_exercise: boolean;
  grantHasLinkedPerformanceMetrics: boolean;
  requiresPerformanceConfirmation: boolean;
  grantPerformanceMetrics: GrantPerformanceMetricSummary[];
  performanceMetric?: {
    id?: string;
    name?: string;
    description?: string | null;
    metric_type?: string | null;
    unit_of_measure?: string | null;
    target_value?: number | null;
    actual_value?: number | null;
    is_achieved?: boolean | null;
    achieved_at?: string | null;
  };
  performanceMilestoneId?: string | null;
}

/**
 * Fetches all vesting events for a company (for the vesting events page)
 */
export const getAllVestingEvents = async (
  companyId: string,
  statusFilter?: string,
  eventTypeFilter?: string,
  limit: number = 100,
  grantIds?: string[]  // Add parameter to filter by specific grant IDs
): Promise<VestingEventWithDetails[]> => {
  try {
    console.log('🔍 getAllVestingEvents called with:', { companyId, statusFilter, eventTypeFilter, limit, grantIds });
    
    const baseSelect = `
      *,
      employees (
        id,
        first_name_en,
        first_name_ar,
        last_name_en,
        last_name_ar
      ),
      grants (
        id,
        grant_number,
        total_shares,
        vested_shares,
        plan_id,
        vesting_schedule_id,
        employee_acceptance_at,
        incentive_plans (
          plan_name_en,
          plan_code,
          plan_type
        ),
        grant_performance_metrics (
          performance_metric_id,
          performance_metrics (
            id,
            name,
            description,
            metric_type,
            unit_of_measure
          )
        )
      )
    `;

    let query = supabase
      .from('vesting_events')
      .select(baseSelect)
      .eq('company_id', companyId);
    
    // Apply grant filter in database query if provided (BEFORE limit)
    // This ensures we get all events for the specified grants, not just the first N events
    if (grantIds && grantIds.length > 0) {
      query = query.in('grant_id', grantIds);
      // Increase limit significantly when filtering by grants to ensure we get all events
      limit = 1000;
      console.log('📌 Filtering by grant IDs:', grantIds, 'with increased limit:', limit);
    }
    
    console.log('📊 Query built for company_id:', companyId);

    // Apply filters
    if (statusFilter && statusFilter !== 'all') {
      query = query.eq('status', statusFilter);
    }
    
    if (eventTypeFilter && eventTypeFilter !== 'all') {
      query = query.eq('event_type', eventTypeFilter);
    }

    let eventsResponse = await query
      .order('vesting_date', { ascending: true })
      .limit(limit);

    let events = (eventsResponse.data ?? []) as any[];
    let error = eventsResponse.error;
    let vestingScheduleSupported = true;

    // Check for 400 Bad Request or error related to vesting_schedule_id
    if (error && (
      error.code === 'PGRST301' || 
      error.message?.includes('vesting_schedule_id') ||
      error.message?.includes('column') ||
      (error as any).status === 400
    )) {
      console.warn('⚠️ vesting_schedule_id not available on grants, retrying without it');
      vestingScheduleSupported = false;

      // Remove vesting_schedule_id from the select string more carefully
      const fallbackSelect = baseSelect
        .replace(/\s*vesting_schedule_id,\s*/g, '')
        .replace(/\s*vesting_schedule_id\s*/g, '');
      
      let fallbackQuery = supabase
        .from('vesting_events')
        .select(fallbackSelect)
        .eq('company_id', companyId);

      // Apply grant filter in fallback query too if provided
      if (grantIds && grantIds.length > 0) {
        fallbackQuery = fallbackQuery.in('grant_id', grantIds);
        // Use the same increased limit
        limit = 1000;
      }

      // Apply filters again for fallback query
      if (statusFilter && statusFilter !== 'all') {
        fallbackQuery = fallbackQuery.eq('status', statusFilter);
      }
      
      if (eventTypeFilter && eventTypeFilter !== 'all') {
        fallbackQuery = fallbackQuery.eq('event_type', eventTypeFilter);
      }

      const fallbackResponse = await fallbackQuery
        .order('vesting_date', { ascending: true })
        .limit(limit);

      events = (fallbackResponse.data ?? []) as any[];
      error = fallbackResponse.error;
    }

    console.log('📥 Raw query result:', { events: events?.length || 0, error });
    if (error) {
      console.error('❌ Supabase query error:', error);
      throw error;
    }

    const today = new Date();
    
    console.log('🔄 Processing events:', events?.length || 0);
    const processedEvents = (events || []).map((event: any) => {
      const vestingDate = new Date(event.vesting_date);
      const daysRemaining = Math.ceil((vestingDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
      const planType = event.grants?.incentive_plans?.plan_type || 'LTIP_RSU';
      const linkedMetrics = event.grants?.grant_performance_metrics || [];
      const grantMetricMap = new Map<string, GrantPerformanceMetricSummary>();
      linkedMetrics.forEach((link: any) => {
        const metricId = link.performance_metric_id;
        if (!metricId || grantMetricMap.has(metricId)) return;
        grantMetricMap.set(metricId, {
          id: metricId,
          name: link.performance_metrics?.name,
          description: link.performance_metrics?.description,
          metric_type: link.performance_metrics?.metric_type,
          unit_of_measure: link.performance_metrics?.unit_of_measure,
          target_value: null,
          actual_value: null,
          is_achieved: null,
          achieved_at: null
        });
      });
      const grantPerformanceMetrics = Array.from(grantMetricMap.values());
      const grantHasLinkedPerformanceMetrics = grantPerformanceMetrics.length > 0;
      const requiresPerformanceConfirmation = grantHasLinkedPerformanceMetrics && PERFORMANCE_EVENT_TYPES.includes(event.event_type);
      
      return {
        ...event,
        employee_name: `${event.employees?.first_name_en || event.employees?.first_name_ar || 'Unknown'} ${event.employees?.last_name_en || event.employees?.last_name_ar || 'Employee'}`,
        plan_name: event.grants?.incentive_plans?.plan_name_en || 'Unknown Plan',
        plan_code: event.grants?.incentive_plans?.plan_code || 'N/A',
        plan_type: planType,
        days_remaining: daysRemaining, // Can be negative for past dates
        can_exercise: planType === 'ESOP' && event.status === 'vested',
        requires_exercise: planType === 'ESOP',
        grantHasLinkedPerformanceMetrics,
        requiresPerformanceConfirmation,
        grantPerformanceMetrics
      } as VestingEventWithDetails;
    });

    // Attach performance metric information when applicable
    const performanceEvents = processedEvents.filter((event: any) => event.requiresPerformanceConfirmation);

    if (vestingScheduleSupported && performanceEvents.length > 0) {
      const scheduleIds = Array.from(
        new Set(
          performanceEvents
            .map(event => event.grants?.vesting_schedule_id)
            .filter((id): id is string => Boolean(id))
        )
      );

      if (scheduleIds.length > 0) {
        const { data: milestones, error: milestoneError } = await supabase
          .from('vesting_milestones')
          .select(`
            id,
            vesting_schedule_id,
            sequence_order,
            target_value,
            actual_value,
            is_achieved,
            achieved_at,
            performance_metric_id,
            performance_metrics (
              id,
              name,
              description,
              metric_type,
              unit_of_measure
            )
          `)
          .in('vesting_schedule_id', scheduleIds);

        if (milestoneError) {
          console.error('❌ Error fetching performance milestones:', milestoneError);
        } else if (milestones && milestones.length > 0) {
          const milestoneMap = new Map<string, typeof milestones[number]>();
          milestones.forEach(milestone => {
            const key = `${milestone.vesting_schedule_id}:${milestone.sequence_order}`;
            milestoneMap.set(key, milestone);
          });

          performanceEvents.forEach(event => {
            const scheduleId = event.grants?.vesting_schedule_id;
            if (!scheduleId) return;

            const milestoneKey = `${scheduleId}:${event.sequence_number}`;
            const milestone = milestoneMap.get(milestoneKey);
            if (!milestone) return;

            event.performanceMilestoneId = milestone.id;
            event.performanceMetric = {
              id: milestone.performance_metrics?.id || milestone.performance_metric_id,
              name: milestone.performance_metrics?.name || 'Performance Metric',
              description: milestone.performance_metrics?.description,
              metric_type: milestone.performance_metrics?.metric_type,
              unit_of_measure: milestone.performance_metrics?.unit_of_measure,
              target_value: milestone.target_value,
              actual_value: milestone.actual_value,
              is_achieved: milestone.is_achieved,
              achieved_at: milestone.achieved_at
            };
            const metricId = event.performanceMetric.id;
            if (metricId) {
              const existingIndex = event.grantPerformanceMetrics?.findIndex(metric => metric.id === metricId) ?? -1;
              const mergedMetric: GrantPerformanceMetricSummary = {
                id: metricId,
                name: event.performanceMetric.name,
                description: event.performanceMetric.description,
                metric_type: event.performanceMetric.metric_type,
                unit_of_measure: event.performanceMetric.unit_of_measure,
                target_value: event.performanceMetric.target_value ?? null,
                actual_value: event.performanceMetric.actual_value ?? null,
                is_achieved: event.performanceMetric.is_achieved ?? null,
                achieved_at: event.performanceMetric.achieved_at ?? null
              };
              if (existingIndex >= 0 && event.grantPerformanceMetrics) {
                event.grantPerformanceMetrics[existingIndex] = {
                  ...event.grantPerformanceMetrics[existingIndex],
                  ...mergedMetric
                };
              } else if (event.grantPerformanceMetrics) {
                event.grantPerformanceMetrics.push(mergedMetric);
              } else {
                event.grantPerformanceMetrics = [mergedMetric];
              }
            }
          });
        }
      }
    }
    
    console.log('✅ Processed events:', processedEvents.length);
    return processedEvents;
  } catch (error) {
    console.error('❌ Error fetching all vesting events:', error);
    return [];
  }
};

/**
 * Fetches upcoming vesting events for a company
 */
export const getUpcomingVestingEvents = async (
  companyId: string,
  limit: number = 10
): Promise<VestingEventWithDetails[]> => {
  try {
    const { data: events, error } = await supabase
      .from('vesting_events')
      .select(`
        *,
        employees (
          id,
          first_name_en,
          first_name_ar,
          last_name_en,
          last_name_ar
        ),
        grants (
          id,
          grant_number,
          total_shares,
          vested_shares,
          plan_id,
          incentive_plans (
            plan_name_en,
            plan_code,
            plan_type
          ),
          grant_performance_metrics (
            performance_metric_id,
            performance_metrics (
              id,
              name,
              description,
              metric_type,
              unit_of_measure
            )
          )
        )
      `)
      .eq('company_id', companyId)
      .in('status', ['pending', 'due'])
      .gte('vesting_date', new Date().toISOString().split('T')[0])
      .order('vesting_date', { ascending: true })
      .limit(limit);

    if (error) throw error;

    const today = new Date();
    
    return (events || []).map(event => {
      const vestingDate = new Date(event.vesting_date);
      const daysRemaining = Math.ceil((vestingDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
      const planType = event.grants?.incentive_plans?.plan_type || 'LTIP_RSU';
      const linkedMetrics = event.grants?.grant_performance_metrics || [];
      const grantMetricMap = new Map<string, GrantPerformanceMetricSummary>();
      linkedMetrics.forEach((link: any) => {
        const metricId = link.performance_metric_id;
        if (!metricId || grantMetricMap.has(metricId)) return;
        grantMetricMap.set(metricId, {
          id: metricId,
          name: link.performance_metrics?.name,
          description: link.performance_metrics?.description,
          metric_type: link.performance_metrics?.metric_type,
          unit_of_measure: link.performance_metrics?.unit_of_measure,
          target_value: null,
          actual_value: null,
          is_achieved: null,
          achieved_at: null
        });
      });
      const grantPerformanceMetrics = Array.from(grantMetricMap.values());
      const grantHasLinkedPerformanceMetrics = grantPerformanceMetrics.length > 0;
      const requiresPerformanceConfirmation = grantHasLinkedPerformanceMetrics && PERFORMANCE_EVENT_TYPES.includes(event.event_type);
      
      return {
        ...event,
        employee_name: `${event.employees?.first_name_en || event.employees?.first_name_ar || 'Unknown'} ${event.employees?.last_name_en || event.employees?.last_name_ar || 'Employee'}`,
        plan_name: event.grants?.incentive_plans?.plan_name_en || 'Unknown Plan',
        plan_code: event.grants?.incentive_plans?.plan_code || 'N/A',
        plan_type: planType,
        days_remaining: Math.max(0, daysRemaining),
        can_exercise: planType === 'ESOP' && event.status === 'vested',
        requires_exercise: planType === 'ESOP',
        grantHasLinkedPerformanceMetrics,
        requiresPerformanceConfirmation,
        grantPerformanceMetrics
      } as VestingEventWithDetails;
    });
  } catch (error) {
    console.error('Error fetching upcoming vesting events:', error);
    return [];
  }
};

/**
 * Fetches all vesting events for a specific grant
 */
export const getGrantVestingEvents = async (grantId: string): Promise<VestingEvent[]> => {
  try {
    const { data: events, error } = await supabase
      .from('vesting_events')
      .select('*')
      .eq('grant_id', grantId)
      .order('sequence_number', { ascending: true });

    if (error) throw error;
    return events || [];
  } catch (error) {
    console.error('Error fetching grant vesting events:', error);
    return [];
  }
};

/**
 * Fetches vesting events for a specific employee
 */
export const getEmployeeVestingEvents = async (
  employeeId: string,
  status?: string[]
): Promise<VestingEventWithDetails[]> => {
  try {
    let query = supabase
      .from('vesting_events')
      .select(`
        *,
        grants (
          id,
          grant_number,
          total_shares,
          vested_shares,
          plan_id,
          employee_acceptance_at,
          incentive_plans (
            plan_name_en,
            plan_code,
            plan_type
          ),
          grant_performance_metrics (
            performance_metric_id,
            performance_metrics (
              id,
              name,
              description,
              metric_type,
              unit_of_measure
            )
          )
        )
      `)
      .eq('employee_id', employeeId)
      .order('vesting_date', { ascending: true });

    if (status && status.length > 0) {
      query = query.in('status', status);
    }

    const { data: events, error } = await query;
    if (error) throw error;

    const today = new Date();
    
    return (events || []).map(event => {
      const vestingDate = new Date(event.vesting_date);
      const daysRemaining = Math.ceil((vestingDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
      const planType = event.grants?.incentive_plans?.plan_type || 'LTIP_RSU';
      const linkedMetrics = event.grants?.grant_performance_metrics || [];
      const grantMetricMap = new Map<string, GrantPerformanceMetricSummary>();
      linkedMetrics.forEach((link: any) => {
        const metricId = link.performance_metric_id;
        if (!metricId || grantMetricMap.has(metricId)) return;
        grantMetricMap.set(metricId, {
          id: metricId,
          name: link.performance_metrics?.name,
          description: link.performance_metrics?.description,
          metric_type: link.performance_metrics?.metric_type,
          unit_of_measure: link.performance_metrics?.unit_of_measure,
          target_value: null,
          actual_value: null,
          is_achieved: null,
          achieved_at: null
        });
      });
      const grantPerformanceMetrics = Array.from(grantMetricMap.values());
      const grantHasLinkedPerformanceMetrics = grantPerformanceMetrics.length > 0;
      const requiresPerformanceConfirmation = grantHasLinkedPerformanceMetrics && PERFORMANCE_EVENT_TYPES.includes(event.event_type);
      
      return {
        ...event,
        employee_name: `${event.employees?.first_name_en || event.employees?.first_name_ar || 'Unknown'} ${event.employees?.last_name_en || event.employees?.last_name_ar || 'Employee'}`,
        plan_name: event.grants?.incentive_plans?.plan_name_en || 'Unknown Plan',
        plan_code: event.grants?.incentive_plans?.plan_code || 'N/A',
        plan_type: planType,
        days_remaining: Math.max(0, daysRemaining),
        can_exercise: planType === 'ESOP' && event.status === 'vested',
        requires_exercise: planType === 'ESOP',
        grantHasLinkedPerformanceMetrics,
        requiresPerformanceConfirmation,
        grantPerformanceMetrics
      } as VestingEventWithDetails;
    });
  } catch (error) {
    console.error('Error fetching employee vesting events:', error);
    return [];
  }
};

/**
 * Processes a vesting event (marks shares as vested)
 */
export const processVestingEvent = async (
  eventId: string,
  fairMarketValue?: number
): Promise<{ success: boolean; error?: string; data?: any }> => {
  try {
    const { data, error } = await supabase.rpc('process_vesting_event', {
      p_vesting_event_id: eventId,
      p_fair_market_value: fairMarketValue
    });

    if (error) {
      console.error('RPC error:', error);
      throw error;
    }
    
    // The RPC function returns a JSONB object with success and error fields
    // Check if the response indicates failure
    if (data && typeof data === 'object' && 'success' in data) {
      if (data.success === false) {
        return {
          success: false,
          error: data.error || 'Failed to process vesting event'
        };
      }
    }
    
    // Trigger sidebar count refresh
    window.dispatchEvent(new CustomEvent('refreshVestingEventsCount'));
    
    return { success: true, data };
  } catch (error) {
    console.error('Error processing vesting event:', error);
    return { 
      success: false, 
      error: error instanceof Error ? error.message : 'Unknown error' 
    };
  }
};

/**
 * Exercises vested ESOP options and transfers shares to portfolio
 */
export const exerciseVestingEvent = async (
  eventId: string,
  exerciseShares?: number // Optional: partial exercise
): Promise<{ success: boolean; error?: string; data?: any }> => {
  try {
    // First, get the vesting event details
    const { data: event, error: eventError } = await supabase
      .from('vesting_events')
      .select(`
        *,
        grants (
          incentive_plans (
            plan_type
          )
        )
      `)
      .eq('id', eventId)
      .single();

    if (eventError) throw eventError;
    if (!event) throw new Error('Vesting event not found');
    
    // Verify this is an ESOP plan
    if (event.grants?.incentive_plans?.plan_type !== 'ESOP') {
      throw new Error('Exercise is only available for ESOP plans');
    }

    // Verify event is vested
    if (event.status !== 'vested') {
      throw new Error('Event must be vested before exercise');
    }

    const sharesToExercise = exerciseShares || event.shares_to_vest;
    const totalCost = sharesToExercise * (event.exercise_price || 0);

    // Update vesting event status to exercised
    const { error: updateError } = await supabase
      .from('vesting_events')
      .update({
        status: 'exercised',
        processed_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('id', eventId);

    if (updateError) throw updateError;

    // TODO: Create portfolio transaction for exercised shares
    // This would integrate with the portfolio system to transfer shares

    // Trigger sidebar count refresh
    window.dispatchEvent(new CustomEvent('refreshVestingEventsCount'));

    return {
      success: true,
      data: {
        shares_exercised: sharesToExercise,
        exercise_cost: totalCost,
        event_id: eventId
      }
    };
  } catch (error) {
    console.error('Error exercising vesting event:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
};

/**
 * Transfers vested RSU/RSA shares to employee portfolio
 */
export const transferVestingEvent = async (
  eventId: string
): Promise<{ success: boolean; error?: string; data?: any }> => {
  try {
    // Get the vesting event details with grant and portfolio information
    const { data: event, error: eventError } = await supabase
      .from('vesting_events')
      .select(`
        *,
        grants (
          id,
          grant_number,
          company_id,
          incentive_plans (
            plan_type
          )
        ),
        employees (
          id
        )
      `)
      .eq('id', eventId)
      .single();

    if (eventError) throw eventError;
    if (!event) throw new Error('Vesting event not found');
    
    // Verify this is an RSU/RSA plan
    const planType = event.grants?.incentive_plans?.plan_type;
    if (!['LTIP_RSU', 'LTIP_RSA'].includes(planType || '')) {
      throw new Error('Transfer is only available for RSU/RSA plans');
    }

    // Verify event is vested
    if (event.status !== 'vested') {
      throw new Error('Event must be vested before transfer');
    }

    const companyId = event.company_id || event.grants?.company_id;
    if (!companyId) {
      throw new Error('Company ID not found');
    }

    // Get portfolios for the transfer
    const { data: portfolios, error: portfolioError } = await supabase
      .from('portfolios')
      .select('id, portfolio_type, company_id, employee_id, portfolio_number')
      .eq('company_id', companyId);

    if (portfolioError) {
      console.error('Error fetching portfolios:', portfolioError);
      throw new Error(`Failed to fetch portfolios: ${portfolioError.message}`);
    }

    console.log(`📊 Fetched ${portfolios?.length || 0} portfolios for company ${companyId}`);
    console.log('Portfolios:', portfolios?.map(p => ({
      id: p.id,
      type: p.portfolio_type,
      company_id: p.company_id,
      employee_id: p.employee_id,
      number: p.portfolio_number
    })));

    // Find company reserved portfolio (from_portfolio)
    const fromPortfolio = portfolios?.find(p => 
      p.portfolio_type === 'company_reserved' && 
      p.company_id === companyId &&
      p.employee_id === null
    );

    // Find employee vested portfolio (to_portfolio)
    let toPortfolio = portfolios?.find(p => 
      p.portfolio_type === 'employee_vested' && 
      p.employee_id === event.employee_id &&
      p.company_id === companyId
    );

    if (!fromPortfolio) {
      console.error('Company reserved portfolio not found. Available portfolios:', portfolios);
      console.error('Looking for: portfolio_type=company_reserved, company_id=' + companyId + ', employee_id=NULL');
      throw new Error(
        `Company reserved portfolio not found for company ${companyId}. ` +
        `Found ${portfolios?.length || 0} portfolio(s) but none match company_reserved type. ` +
        `Please ensure a company reserved portfolio exists for this company.`
      );
    }

    // If employee portfolio doesn't exist, create it (fallback in case trigger didn't run)
    if (!toPortfolio) {
      console.log('⚠️ Employee vested portfolio not found. Creating new portfolio for employee:', event.employee_id);
      
      // Get employee details for portfolio number
      const { data: employee } = await supabase
        .from('employees')
        .select('employee_number, first_name_en, last_name_en')
        .eq('id', event.employee_id)
        .single();

      const employeeNumber = employee?.employee_number || event.employee_id.substring(0, 8);
      const portfolioNumber = `PORT-EMPLOYEE-${employeeNumber}`;

      // Create employee vested portfolio
      const { data: newPortfolio, error: createError } = await supabase
        .from('portfolios')
        .insert({
          portfolio_type: 'employee_vested',
          company_id: companyId,
          employee_id: event.employee_id,
          total_shares: 0,
          available_shares: 0,
          locked_shares: 0,
          portfolio_number: portfolioNumber
        })
        .select()
        .single();

      if (createError) {
        console.error('Error creating employee portfolio:', createError);
        throw new Error(
          `Failed to create employee vested portfolio: ${createError.message}. ` +
          `Please ensure the employee exists and has proper permissions.`
        );
      }

      if (!newPortfolio) {
        throw new Error('Failed to create employee vested portfolio');
      }

      toPortfolio = newPortfolio;
      console.log('✅ Created employee portfolio:', toPortfolio.portfolio_number);
    }

    console.log('✅ Found portfolios - From:', fromPortfolio.portfolio_number, 'To:', toPortfolio.portfolio_number);

    // Generate transfer number
    const transferNumber = `TR-${new Date().toISOString().split('T')[0].replace(/-/g, '')}-${Math.random().toString(36).substr(2, 6).toUpperCase()}`;

    // Create transfer request in share_transfers table
    const { data: transfer, error: transferError } = await supabase
      .from('share_transfers')
      .insert({
        transfer_number: transferNumber,
        company_id: companyId,
        grant_id: event.grant_id,
        employee_id: event.employee_id,
        from_portfolio_id: fromPortfolio.id,
        to_portfolio_id: toPortfolio.id,
        shares_transferred: event.shares_to_vest,
        transfer_type: 'vesting',
        transfer_date: new Date().toISOString().split('T')[0],
        status: 'pending',
        processed_by_system: false,
        notes: `Transfer request for vesting event ${eventId}`
      })
      .select()
      .single();

    if (transferError) throw transferError;

    // Update vesting event status to 'transferred' immediately
    console.log('🔄 Updating vesting event status to "transferred" for event:', eventId);
    const { data: updatedEvent, error: updateEventError } = await supabase
      .from('vesting_events')
      .update({
        status: 'transferred',
        updated_at: new Date().toISOString()
      })
      .eq('id', eventId)
      .select()
      .single();

    if (updateEventError) {
      console.error('❌ Error updating vesting event status:', updateEventError);
      console.error('Error details:', {
        code: updateEventError.code,
        message: updateEventError.message,
        details: updateEventError.details,
        hint: updateEventError.hint
      });
      // Throw error so we can see it in the UI - this is important
      throw new Error(`Failed to update vesting event status: ${updateEventError.message}`);
    } else if (updatedEvent) {
      console.log('✅ Updated vesting event status to "transferred" for event:', eventId);
      console.log('Updated event:', { id: updatedEvent.id, status: updatedEvent.status });
    } else {
      console.warn('⚠️ Vesting event update returned no data for event:', eventId);
      throw new Error('Vesting event status update returned no data');
    }

    // Trigger sidebar count refresh
    window.dispatchEvent(new CustomEvent('refreshVestingEventsCount'));

    return {
      success: true,
      data: {
        transfer_id: transfer.id,
        transfer_number: transferNumber,
        shares_transferred: event.shares_to_vest,
        event_id: eventId,
        plan_type: planType
      }
    };
  } catch (error) {
    console.error('Error transferring vesting event:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
};

/**
 * Updates vesting event statuses (should be run periodically)
 */
export const updateVestingEventStatuses = async (): Promise<{ success: boolean; error?: string }> => {
  try {
    const { error } = await supabase.rpc('update_vesting_event_status');
    if (error) throw error;
    
    // Trigger sidebar count refresh
    window.dispatchEvent(new CustomEvent('refreshVestingEventsCount'));
    
    return { success: true };
  } catch (error) {
    console.error('Error updating vesting event statuses:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
};

/**
 * Manually generates vesting events for a grant (if not auto-generated)
 */
export const generateVestingEventsForGrant = async (
  grantId: string
): Promise<{ success: boolean; error?: string }> => {
  try {
    const { error } = await supabase.rpc('generate_vesting_events_for_grant', {
      p_grant_id: grantId
    });
    
    if (error) throw error;
    return { success: true };
  } catch (error) {
    console.error('Error generating vesting events:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
};

/**
 * Gets vesting event statistics for a company
 */
export const getVestingEventStats = async (companyId: string) => {
  try {
    const { data: stats, error } = await supabase
      .from('vesting_events')
      .select('status, shares_to_vest, event_type')
      .eq('company_id', companyId);

    if (error) throw error;

    const summary = {
      total_events: stats?.length || 0,
      total_total_shares: stats?.reduce((sum, s) => sum + (Number(s.shares_to_vest) || 0), 0) || 0,
      pending_events: stats?.filter(s => s.status === 'pending').length || 0,
      due_events: stats?.filter(s => s.status === 'due').length || 0,
      vested_events: stats?.filter(s => s.status === 'vested').length || 0,
      transferred_events: stats?.filter(s => s.status === 'transferred').length || 0,
      exercised_events: stats?.filter(s => s.status === 'exercised').length || 0,
      forfeited_events: stats?.filter(s => s.status === 'forfeited').length || 0,
      cancelled_events: stats?.filter(s => s.status === 'cancelled').length || 0,
      processed_events: stats?.filter(s => ['transferred', 'exercised'].includes(s.status)).length || 0,
      total_pending_shares: stats?.filter(s => s.status === 'pending').reduce((sum, s) => sum + (Number(s.shares_to_vest) || 0), 0) || 0,
      total_due_shares: stats?.filter(s => s.status === 'due').reduce((sum, s) => sum + (Number(s.shares_to_vest) || 0), 0) || 0,
      total_vested_shares: stats?.filter(s => s.status === 'vested').reduce((sum, s) => sum + (Number(s.shares_to_vest) || 0), 0) || 0,
      total_transferred_shares: stats?.filter(s => s.status === 'transferred').reduce((sum, s) => sum + (Number(s.shares_to_vest) || 0), 0) || 0,
      total_exercised_shares: stats?.filter(s => s.status === 'exercised').reduce((sum, s) => sum + (Number(s.shares_to_vest) || 0), 0) || 0,
      total_forfeited_shares: stats?.filter(s => s.status === 'forfeited').reduce((sum, s) => sum + (Number(s.shares_to_vest) || 0), 0) || 0,
      total_cancelled_shares: stats?.filter(s => s.status === 'cancelled').reduce((sum, s) => sum + (Number(s.shares_to_vest) || 0), 0) || 0,
      cliff_events: stats?.filter(s => s.event_type === 'cliff').length || 0,
      time_based_events: stats?.filter(s => s.event_type === 'time_based').length || 0
    };

    return { success: true, data: summary };
  } catch (error) {
    console.error('Error fetching vesting event stats:', error);
    return { success: false, error: error instanceof Error ? error.message : 'Unknown error' };
  }
};

/**
 * Generates vesting events for all existing grants that don't have events yet
 */
export const generateVestingEventsForExistingGrants = async (
  companyId: string,
  grantIds?: string[]
): Promise<{ success: boolean; error?: string; data?: any }> => {
  try {
    // Get all active grants without vesting events
    const { data: grants, error: grantsError } = await supabase
      .from('grants')
      .select(`
        id,
        employee_id,
        total_shares,
        vesting_start_date,
        employees (
          first_name_en,
          first_name_ar,
          last_name_en,
          last_name_ar
        ),
        incentive_plans (
          plan_name_en,
          plan_code
        )
      `)
      .eq('company_id', companyId)
      .eq('status', 'active');

    if (grantsError) throw grantsError;

    const grantsToProcess = (grants || []).filter(grant => {
      if (!grantIds || grantIds.length === 0) {
        return true;
      }
      return grantIds.includes(grant.id);
    });

    const results = {
      total_grants: grants?.length || 0,
      selected_grants: grantsToProcess.length,
      processed: 0,
      skipped: 0,
      errors: 0,
      error_details: [] as string[]
    };

    for (const grant of grants || []) {
      if (!grantsToProcess.find(selected => selected.id === grant.id)) {
        results.skipped++;
        continue;
      }

      try {
        // Check if vesting events already exist
        const { data: existingEvents, error: eventsError } = await supabase
          .from('vesting_events')
          .select('id')
          .eq('grant_id', grant.id)
          .limit(1);

        if (eventsError) throw eventsError;

        if (existingEvents && existingEvents.length > 0) {
          console.log(`Grant ${grant.id} already has vesting events - skipping`);
          results.skipped++;
          continue;
        }

        // Generate vesting events for this grant
        const generateResult = await generateVestingEventsForGrant(grant.id);
        
        if (generateResult.success) {
          const employeeName = `${grant.employees?.first_name_en || grant.employees?.first_name_ar || 'Unknown'} ${grant.employees?.last_name_en || grant.employees?.last_name_ar || 'Employee'}`;
          console.log(`Generated vesting events for grant ${grant.id} (${employeeName})`);
          results.processed++;
        } else {
          throw new Error(generateResult.error || 'Failed to generate vesting events');
        }

      } catch (error) {
        const errorMsg = `Grant ${grant.id}: ${error instanceof Error ? error.message : 'Unknown error'}`;
        console.error(errorMsg);
        results.errors++;
        results.error_details.push(errorMsg);
      }
    }

    // Update vesting event statuses
    await updateVestingEventStatuses();
    
    return { success: true, data: results };
  } catch (error) {
    console.error('Error generating vesting events for existing grants:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
};

/**
 * Gets grants that don't have vesting events yet
 */
export const getGrantsWithoutVestingEvents = async (
  companyId: string
): Promise<{ success: boolean; error?: string; data?: any[] }> => {
  try {
    // Get all active grants
    const { data: grants, error: grantsError } = await supabase
      .from('grants')
      .select(`
        id,
        employee_id,
        grant_number,
        total_shares,
        vesting_start_date,
        created_at,
        employees (
          first_name_en,
          first_name_ar,
          last_name_en,
          last_name_ar
        ),
        incentive_plans (
          plan_name_en,
          plan_code,
          plan_type
        )
      `)
      .eq('company_id', companyId)
      .eq('status', 'active')
      .order('created_at', { ascending: false });

    if (grantsError) throw grantsError;

    const grantsWithoutEvents = [];

    for (const grant of grants || []) {
      // Check if vesting events exist for this grant
      const { data: events, error: eventsError } = await supabase
        .from('vesting_events')
        .select('id')
        .eq('grant_id', grant.id)
        .limit(1);

      if (eventsError) throw eventsError;

      if (!events || events.length === 0) {
        grantsWithoutEvents.push({
          ...grant,
          grant_number: grant.grant_number,
          employee_name: `${grant.employees?.first_name_en || grant.employees?.first_name_ar || 'Unknown'} ${grant.employees?.last_name_en || grant.employees?.last_name_ar || 'Employee'}`,
          plan_name: grant.incentive_plans?.plan_name_en,
          plan_code: grant.incentive_plans?.plan_code,
          plan_type: grant.incentive_plans?.plan_type
        });
      }
    }

    return { success: true, data: grantsWithoutEvents };
  } catch (error) {
    console.error('Error fetching grants without vesting events:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
};
