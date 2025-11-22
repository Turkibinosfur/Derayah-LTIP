/*
  # Vesting Utilities
  
  This file contains utility functions for generating individual vesting records
  from vesting schedule templates.
*/

import { supabase } from './supabase';

export interface VestingMilestone {
  id?: string;
  vesting_schedule_id?: string;
  milestone_type: 'time' | 'performance' | 'hybrid';
  sequence_order: number;
  vesting_percentage: number;
  months_from_start: number | null;
  performance_metric_id?: string | null;
  target_value?: number | null;
  actual_value?: number | null;
  achieved_at?: string | null;
  is_achieved?: boolean;
}

export interface VestingScheduleTemplate {
  id: string;
  name: string;
  description: string | null;
  schedule_type: 'time_based' | 'performance_based' | 'hybrid';
  total_duration_months: number;
  cliff_months: number;
  vesting_frequency: 'monthly' | 'quarterly' | 'annually';
  is_template: boolean;
  milestones?: VestingMilestone[];
}

export interface Grant {
  id: string;
  grant_number: string;
  company_id: string;
  plan_id: string;
  employee_id: string;
  grant_date: string;
  total_shares: number;
  vesting_start_date: string;
  vesting_end_date: string;
  vesting_schedule_id?: string | null;
}

/**
 * Generates individual vesting records from a vesting schedule template
 * @param grantId - The ID of the grant to create vesting records for
 * @param templateId - The ID of the vesting schedule template to use
 * @returns Promise<void>
 */
export const generateIndividualVestingRecords = async (
  grantId: string, 
  templateId: string,
  useEvenDistribution: boolean = false
): Promise<void> => {
  try {
    // Get the template with its milestones
    const { data: template, error: templateError } = await supabase
      .from('vesting_schedules')
      .select(`
        *,
        vesting_milestones (
          id,
          milestone_type,
          sequence_order,
          vesting_percentage,
          months_from_start,
          performance_metric_id,
          target_value
        )
      `)
      .eq('id', templateId)
      .eq('is_template', true)
      .single();

    if (templateError) throw templateError;
    if (!template) throw new Error('Template not found');

    // Get the grant details with its plan to access vesting_schedule_type
    const { data: grant, error: grantError } = await supabase
      .from('grants')
      .select(`
        *,
        incentive_plans (
          vesting_schedule_type
        )
      `)
      .eq('id', grantId)
      .single();

    if (grantError) throw grantError;
    if (!grant) throw new Error('Grant not found');

    // Get the plan's vesting schedule type (this is the source of truth)
    const planVestingScheduleType = grant.incentive_plans?.vesting_schedule_type || 'time_based';

    // Calculate vesting dates and shares with rounding remainder allocated to the last milestone
    let milestones = (template.vesting_milestones || [])
      .slice()
      .sort((a, b) => (a.sequence_order || 0) - (b.sequence_order || 0));

    // Calculate expected number of milestones to validate against existing ones
    const totalMonths = template.total_duration_months || 48;
    const cliffMonths = template.cliff_months || 12;
    const frequency = template.vesting_frequency === 'monthly' ? 1 :
                     template.vesting_frequency === 'quarterly' ? 3 : 12;
    const remainingMonths = totalMonths - cliffMonths;
    
    // IMPORTANT: Match the preview calculation
    // Use Math.ceil for even distribution, Math.floor for percentage-based
    const expectedPeriods = useEvenDistribution
      ? Math.ceil(remainingMonths / frequency)
      : Math.floor(remainingMonths / frequency);
    const expectedMilestoneCount = (cliffMonths > 0 ? 1 : 0) + expectedPeriods;

    // Validate milestones - check if they have valid months_from_start values
    const hasInvalidData = milestones.length > 0 && (
      milestones.some(m => m.months_from_start === null || m.months_from_start === undefined || m.months_from_start === 0) ||
      // Also check if all milestones have the same months_from_start (invalid for multiple milestones)
      (milestones.length > 1 && new Set(milestones.map(m => m.months_from_start)).size === 1)
    );
    
    // CRITICAL: Check if milestone count matches expected count for THIS grant's distribution method
    const countMismatch = milestones.length > 0 && milestones.length !== expectedMilestoneCount;
    
    const hasInvalidMilestones = hasInvalidData || countMismatch;

    // If no milestones exist OR milestones are invalid OR count doesn't match, generate them now
    if (milestones.length === 0 || hasInvalidMilestones) {
      // Always delete existing milestones if we need to regenerate (due to count mismatch or invalid data)
      if (hasInvalidMilestones && milestones.length > 0) {
        if (countMismatch) {
          console.warn(`⚠️ Template has incorrect number of milestones (${milestones.length} found, ${expectedMilestoneCount} expected for ${useEvenDistribution ? 'even' : 'percentage-based'} distribution), regenerating them`);
        } else {
          console.warn('⚠️ Template has invalid milestones (missing, zero, or duplicate months_from_start), regenerating them from template settings');
        }
        
        // Delete existing milestones from database before regenerating
        try {
          const { error: deleteError } = await supabase
            .from('vesting_milestones')
            .delete()
            .eq('vesting_schedule_id', templateId);
          
          if (deleteError) {
            console.error('❌ Error deleting invalid milestones:', deleteError);
            throw deleteError; // Throw to prevent using old milestones
          }
          console.log('✅ Deleted invalid/incorrect milestones from database');
        } catch (deleteError) {
          console.error('❌ Could not delete invalid milestones:', deleteError);
          throw new Error(`Failed to delete existing milestones: ${deleteError}`);
        }
      } else if (milestones.length === 0) {
        console.log('ℹ️ Template has no milestones, generating them from template settings');
      }
      
      // Use the template's schedule_type to determine milestone_type
      // Note: totalMonths, cliffMonths, frequency, and remainingMonths are already calculated above
      const scheduleType = (template.schedule_type || 'time_based') as 'time_based' | 'performance_based' | 'hybrid';
      const milestoneType = scheduleType === 'time_based' ? 'time' :
                           scheduleType === 'performance_based' ? 'performance' :
                           'hybrid';

      let order = 0;
      const generatedMilestones: VestingMilestone[] = [];

      if (cliffMonths > 0) {
        generatedMilestones.push({
          milestone_type: milestoneType,
          sequence_order: order++,
          vesting_percentage: 25,
          months_from_start: cliffMonths,
          performance_metric_id: null,
          target_value: null,
        });
      }

      // Use expectedPeriods which was already calculated above
      // For 48 months with 12 month cliff and annual (12) frequency:
      // remainingMonths = 36, frequency = 12, expectedPeriods = 3
      // This creates milestones at: 12 (cliff), 24, 36, 48 months = 4 total events
      const percentagePerPeriod = 75 / expectedPeriods;

      for (let i = 1; i <= expectedPeriods; i++) {
        const monthsFromStart = cliffMonths + (i * frequency);
        // Ensure we don't exceed totalMonths and that we include the end date
        if (monthsFromStart <= totalMonths) {
          generatedMilestones.push({
            milestone_type: milestoneType,
            sequence_order: order++,
            vesting_percentage: percentagePerPeriod,
            months_from_start: monthsFromStart,
            performance_metric_id: null,
            target_value: null,
          });
        }
      }
      
      // Ensure we have a milestone at the exact end date if it's not already included
      // This handles edge cases where the calculation might miss the final period
      const lastMilestoneMonths = generatedMilestones.length > 0 
        ? generatedMilestones[generatedMilestones.length - 1].months_from_start 
        : cliffMonths;
      
      if (lastMilestoneMonths < totalMonths && expectedPeriods > 0) {
        // The last period should be at totalMonths, but if it's not, we need to adjust
        // This should not happen with the correct calculation, but adding as a safeguard
        const lastMilestone = generatedMilestones[generatedMilestones.length - 1];
        if (lastMilestone && lastMilestone.months_from_start !== totalMonths) {
          // Update the last milestone to be at the end date
          lastMilestone.months_from_start = totalMonths;
        }
      }

      milestones = generatedMilestones;
      console.log(`✅ Generated ${milestones.length} milestones for template (expected: ${expectedMilestoneCount})`);
      
      // Save these milestones to the database for future use
      // Since we deleted old ones above, we can safely insert new ones
      try {
        const milestonesToSave = milestones.map(m => ({
          vesting_schedule_id: templateId,
          milestone_type: m.milestone_type,
          sequence_order: m.sequence_order,
          vesting_percentage: m.vesting_percentage,
          months_from_start: m.months_from_start,
          performance_metric_id: m.performance_metric_id,
          target_value: m.target_value,
        }));
        
        const { error: insertError } = await supabase
          .from('vesting_milestones')
          .insert(milestonesToSave);
        
        if (insertError) {
          console.error('❌ Error saving milestones to database:', insertError);
          throw insertError; // Throw to prevent using incorrect milestones
        }
        
        console.log(`✅ Saved ${milestones.length} generated milestones to database`);
      } catch (saveError) {
        console.error('❌ Could not save milestones to database:', saveError);
        throw new Error(`Failed to save generated milestones: ${saveError}`);
      }
    }

    let allocatedSoFar = 0;
    const sharesByMilestone = milestones.map((m, idx) => {
      const isLast = idx === milestones.length - 1;
      if (isLast) {
        // Assign the remaining shares to ensure the sum equals total_shares (this accounts for any rounding differences)
        return Math.max(0, Number(grant.total_shares) - allocatedSoFar);
      }
      
      if (useEvenDistribution) {
        // Even distribution: divide remaining shares equally among all remaining periods
        const remainingShares = Number(grant.total_shares) - allocatedSoFar;
        const remainingPeriods = milestones.length - idx;
        const sharesPerPeriod = Math.floor(remainingShares / remainingPeriods);
        allocatedSoFar += sharesPerPeriod;
        return sharesPerPeriod;
      } else {
        // Percentage-based with floor (existing logic)
        const shares = calculateSharesToVest(Number(grant.total_shares), Number(m.vesting_percentage));
        allocatedSoFar += shares;
        return shares;
      }
    });

    // Validate that all milestones have valid months_from_start values before proceeding
    const invalidMilestones = milestones.filter(m => 
      m.months_from_start === null || m.months_from_start === undefined || m.months_from_start === 0
    );
    
    if (invalidMilestones.length > 0) {
      console.error('⚠️ Found invalid milestones with null/zero months_from_start:', invalidMilestones);
      throw new Error(`Invalid milestones found: ${invalidMilestones.length} milestone(s) have null, undefined, or zero months_from_start`);
    }

    // Check if all milestones have the same months_from_start (another form of invalidity)
    const uniqueMonths = new Set(milestones.map(m => m.months_from_start));
    if (uniqueMonths.size === 1 && milestones.length > 1) {
      console.warn('⚠️ All milestones have the same months_from_start value, this may indicate invalid data');
    }

    // Calculate cumulative shares as we go
    let cumulativeShares = 0;
    const vestingRecords = milestones.map((milestone, index) => {
      // Ensure months_from_start is a valid number (should not reach here if validation above passed)
      if (milestone.months_from_start === null || milestone.months_from_start === undefined) {
        throw new Error(`Invalid milestone at index ${index}: months_from_start is null or undefined for sequence ${milestone.sequence_order}`);
      }
      
      const vestingDate = calculateVestingDate(grant.vesting_start_date, milestone.months_from_start);
      const sharesToVest = sharesByMilestone[index];
      cumulativeShares += sharesToVest;

      // Determine event type based on plan's vesting_schedule_type (not template's schedule_type)
      // Map plan vesting_schedule_type to vesting_event_type enum values
      // Note: enum values are 'cliff', 'time_based', 'performance', 'acceleration'
      // Plan vesting_schedule_type can be 'time_based', 'performance_based', or 'hybrid'
      let eventType: 'cliff' | 'time_based' | 'performance' | 'acceleration';
      
      if (index === 0 && milestone.vesting_percentage === 25) {
        eventType = 'cliff';
      } else {
        // Map plan's vesting_schedule_type to event_type enum
        if (planVestingScheduleType === 'performance_based') {
          eventType = 'performance';
        } else if (planVestingScheduleType === 'hybrid') {
          // Hybrid not in enum, default to time_based
          eventType = 'time_based';
        } else {
          eventType = planVestingScheduleType as 'time_based';
        }
      }

      return {
        grant_id: grantId,
        employee_id: grant.employee_id,
        company_id: grant.company_id,
        event_type: eventType,
        sequence_number: milestone.sequence_order,
        vesting_date: vestingDate,
        shares_to_vest: sharesToVest,
        cumulative_shares_vested: cumulativeShares,
        performance_condition_met: true,
        status: 'pending' as const,
        created_at: new Date().toISOString()
      };
    });

    // Insert individual vesting records into vesting_events table
    const { error: insertError } = await supabase
      .from('vesting_events')
      .insert(vestingRecords);

    if (insertError) throw insertError;

    console.log(`Generated ${vestingRecords.length} vesting records for grant ${grantId}`);
  } catch (error) {
    console.error('Error generating individual vesting records:', error);
    throw error;
  }
};

/**
 * Generates vesting events directly using the same logic as the preview calculation
 * This ensures the generated events match exactly what's shown in the preview
 * @param grantId - The ID of the grant to create vesting events for
 * @param scheduleId - The ID of the vesting schedule to use (optional)
 * @param totalShares - Total shares to grant
 * @param vestingStartDate - Start date for vesting
 * @param useEvenDistribution - Whether to use even distribution
 * @returns Promise<void>
 */
export const generateVestingEventsFromPreview = async (
  grantId: string,
  scheduleId: string | null,
  totalShares: number,
  vestingStartDate: string,
  useEvenDistribution: boolean = false
): Promise<void> => {
  try {
    // Get grant details - also check if grant has vesting_schedule_id saved
    const { data: grant, error: grantError } = await supabase
      .from('grants')
      .select(`
        *,
        incentive_plans (
          vesting_schedule_template_id,
          vesting_config,
          vesting_schedule_type
        )
      `)
      .eq('id', grantId)
      .single();

    if (grantError) throw grantError;
    if (!grant) throw new Error('Grant not found');

    // PRIORITY 1: Use grant's saved vesting_schedule_id if available (most accurate)
    let finalScheduleId = scheduleId;
    if (grant.vesting_schedule_id) {
      finalScheduleId = grant.vesting_schedule_id;
      console.log('📌 Using grant\'s saved vesting_schedule_id:', finalScheduleId);
    } else if (scheduleId) {
      finalScheduleId = scheduleId;
      console.log('📌 Using provided scheduleId:', finalScheduleId);
    }

    // Get schedule details - same priority as preview
    let scheduleToUse: any = null;
    
    // PRIORITY 1: Use grant's saved or provided scheduleId
    if (finalScheduleId) {
      const { data: schedule, error: scheduleError } = await supabase
        .from('vesting_schedules')
        .select('*')
        .eq('id', finalScheduleId)
        .single();
      
      if (!scheduleError && schedule) {
        scheduleToUse = schedule;
        console.log('✅ Found schedule:', schedule.name, `(${schedule.total_duration_months} months, ${schedule.cliff_months} month cliff, ${schedule.vesting_frequency})`);
      }
    }
    
    // PRIORITY 2: Use plan's template if no schedule provided
    if (!scheduleToUse && grant.incentive_plans?.vesting_schedule_template_id) {
      const { data: template, error: templateError } = await supabase
        .from('vesting_schedules')
        .select('*')
        .eq('id', grant.incentive_plans.vesting_schedule_template_id)
        .eq('is_template', true)
        .single();
      
      if (!templateError && template) {
        scheduleToUse = template;
        console.log('✅ Using plan template:', template.name);
      }
    }

    // Determine schedule parameters - same logic as preview
    let totalMonths = 48;
    let cliffMonths = 12;
    let frequency = 12; // months

    if (scheduleToUse) {
      totalMonths = scheduleToUse.total_duration_months || 48;
      cliffMonths = scheduleToUse.cliff_months || 12;
      const vestingFreq = scheduleToUse.vesting_frequency || 'annually';
      frequency = vestingFreq === 'monthly' ? 1 : vestingFreq === 'quarterly' ? 3 : 12;
    } else if (grant.incentive_plans?.vesting_config) {
      const config = grant.incentive_plans.vesting_config;
      totalMonths = (config.years || 4) * 12;
      cliffMonths = config.cliff_months || 12;
      const vestingFreq = config.frequency || 'annually';
      frequency = vestingFreq === 'monthly' ? 1 : vestingFreq === 'quarterly' ? 3 : 12;
    }

    // Calculate vesting events - EXACT same logic as preview
    const startDate = new Date(vestingStartDate);
    let allocatedSoFar = 0;
    let cumulativeShares = 0;

    // Calculate frequency in months - same as preview
    const remainingMonths = totalMonths - cliffMonths;
    
    // Use Math.floor for percentage-based, Math.ceil for even distribution - same as preview
    const totalPeriods = useEvenDistribution 
      ? Math.ceil(remainingMonths / frequency)
      : Math.floor(remainingMonths / frequency);

    let cliffShares = 0;
    let sharesPerPeriod = 0;

    if (useEvenDistribution) {
      // Even distribution: divide shares equally among all periods (including cliff) - same as preview
      if (cliffMonths > 0) {
        cliffShares = Math.floor(totalShares / (totalPeriods + 1));
        sharesPerPeriod = Math.floor((totalShares - cliffShares) / totalPeriods);
      } else {
        sharesPerPeriod = Math.floor(totalShares / totalPeriods);
      }
    } else {
      // Percentage-based (25% cliff, 75% divided) - same as preview
      if (cliffMonths > 0) {
        cliffShares = Math.floor(totalShares * 0.25);
        sharesPerPeriod = Math.floor((totalShares - cliffShares) / totalPeriods);
      } else {
        sharesPerPeriod = Math.floor(totalShares / totalPeriods);
      }
    }

    const vestingRecords: any[] = [];
    let sequenceNumber = 1;

    // Add cliff event - same as preview
    if (cliffMonths > 0 && cliffShares > 0) {
      const cliffDate = new Date(startDate);
      cliffDate.setMonth(cliffDate.getMonth() + cliffMonths);
      cumulativeShares = cliffShares;
      allocatedSoFar = cliffShares;
      
      vestingRecords.push({
        grant_id: grantId,
        employee_id: grant.employee_id,
        company_id: grant.company_id,
        event_type: 'cliff',
        sequence_number: sequenceNumber++,
        vesting_date: cliffDate.toISOString().split('T')[0],
        shares_to_vest: cliffShares,
        cumulative_shares_vested: cumulativeShares,
        performance_condition_met: true,
        status: 'pending',
        created_at: new Date().toISOString()
      });
    }

    // Add regular vesting events - same as preview
    for (let i = 1; i <= totalPeriods; i++) {
      const eventDate = new Date(startDate);
      eventDate.setMonth(eventDate.getMonth() + cliffMonths + (i * frequency));
      
      let sharesThisPeriod: number;
      if (i === totalPeriods) {
        // Last period: assign remaining shares - same as preview
        sharesThisPeriod = totalShares - allocatedSoFar;
      } else {
        sharesThisPeriod = sharesPerPeriod;
      }
      
      allocatedSoFar += sharesThisPeriod;
      cumulativeShares = allocatedSoFar;

      // Determine event type based on plan's vesting_schedule_type
      const planVestingScheduleType = grant.incentive_plans?.vesting_schedule_type || 'time_based';
      let eventType: 'cliff' | 'time_based' | 'performance' | 'acceleration';
      
      if (planVestingScheduleType === 'performance_based') {
        eventType = 'performance';
      } else if (planVestingScheduleType === 'hybrid') {
        eventType = 'time_based';
      } else {
        eventType = 'time_based';
      }

      vestingRecords.push({
        grant_id: grantId,
        employee_id: grant.employee_id,
        company_id: grant.company_id,
        event_type: eventType,
        sequence_number: sequenceNumber++,
        vesting_date: eventDate.toISOString().split('T')[0],
        shares_to_vest: sharesThisPeriod,
        cumulative_shares_vested: cumulativeShares,
        performance_condition_met: true,
        status: 'pending',
        created_at: new Date().toISOString()
      });
    }

    // Delete any existing vesting events for this grant first
    console.log('🗑️ Deleting any existing vesting events for grant:', grantId);
    const { error: deleteError } = await supabase
      .from('vesting_events')
      .delete()
      .eq('grant_id', grantId);

    if (deleteError) {
      console.warn('⚠️ Could not delete existing vesting events (may not exist):', deleteError);
      // Don't throw - continue with insert
    } else {
      console.log('✅ Deleted existing vesting events');
    }

    // Insert vesting events into database
    console.log(`📝 Inserting ${vestingRecords.length} vesting events...`);
    const { error: insertError } = await supabase
      .from('vesting_events')
      .insert(vestingRecords);

    if (insertError) {
      console.error('❌ Error inserting vesting events:', insertError);
      // If RLS error, throw a specific error that can be caught
      if (insertError.code === '42501') {
        const rlsError = new Error('RLS policy violation: Cannot insert vesting events');
        (rlsError as any).code = '42501';
        throw rlsError;
      }
      throw insertError;
    }

    console.log(`✅ Generated ${vestingRecords.length} vesting events using preview logic (expected: ${cliffMonths > 0 ? 1 : 0} cliff + ${totalPeriods} periods = ${(cliffMonths > 0 ? 1 : 0) + totalPeriods} total)`);
    console.log('📊 Event breakdown:', {
      cliffEvents: cliffMonths > 0 && cliffShares > 0 ? 1 : 0,
      regularEvents: totalPeriods,
      totalEvents: vestingRecords.length,
      totalShares: totalShares,
      cliffShares: cliffShares,
      sharesPerPeriod: sharesPerPeriod,
      totalPeriods: totalPeriods
    });
  } catch (error) {
    console.error('❌ Error generating vesting events from preview logic:', error);
    throw error;
  }
};

/**
 * Calculates the vesting date based on start date and months from start
 * @param startDate - The vesting start date (YYYY-MM-DD)
 * @param monthsFromStart - Number of months from start date
 * @returns The calculated vesting date (YYYY-MM-DD)
 */
const calculateVestingDate = (startDate: string, monthsFromStart: number): string => {
  const start = new Date(startDate);
  const vestingDate = new Date(start);
  vestingDate.setMonth(vestingDate.getMonth() + monthsFromStart);
  return vestingDate.toISOString().split('T')[0];
};

/**
 * Calculates the number of shares to vest based on total shares and percentage
 * @param totalShares - Total number of shares in the grant
 * @param percentage - Percentage of shares to vest (0-100)
 * @returns Number of shares to vest
 */
const calculateSharesToVest = (totalShares: number, percentage: number): number => {
  return Math.floor((totalShares * percentage) / 100);
};

/**
 * Gets vesting details for a grant from its linked template
 * @param grantId - The ID of the grant
 * @returns Promise with vesting details or null if no template linked
 */
export const getGrantVestingDetails = async (grantId: string) => {
  try {
    // Get grant with its plan, template, and selected schedule
    const { data: grant, error: grantError } = await supabase
      .from('grants')
      .select(`
        *,
        incentive_plans (
          vesting_schedule_template_id,
          vesting_config,
          vesting_schedule_type
        )
      `)
      .eq('id', grantId)
      .single();

    if (grantError) throw grantError;
    if (!grant) return null;

    const plan = grant.incentive_plans;
    
    // Load existing vesting events to determine the actual event types being used
    const { data: vestingEvents, error: vestingEventsError } = await supabase
      .from('vesting_events')
      .select('event_type')
      .eq('grant_id', grantId);

    if (vestingEventsError) {
      console.error('Error loading vesting events for grant:', vestingEventsError);
    }

    const actualEventType =
      vestingEvents?.find(event => event.event_type && event.event_type !== 'cliff')?.event_type ||
      vestingEvents?.[0]?.event_type ||
      null;
    
    // PRIORITY 1: Check if grant has a selected vesting_schedule_id
    let scheduleToUse: any = null;
    if (grant.vesting_schedule_id) {
      const { data: selectedSchedule, error: scheduleError } = await supabase
        .from('vesting_schedules')
        .select('*')
        .eq('id', grant.vesting_schedule_id)
        .single();

      if (!scheduleError && selectedSchedule) {
        scheduleToUse = selectedSchedule;
      }
    }
    
    // PRIORITY 2: If plan has a template linked, get template details
    if (!scheduleToUse && plan?.vesting_schedule_template_id) {
      const { data: template, error: templateError } = await supabase
        .from('vesting_schedules')
        .select('*')
        .eq('id', plan.vesting_schedule_template_id)
        .eq('is_template', true)
        .single();

      if (!templateError && template) {
        scheduleToUse = template;
      }
    }

    // Use the schedule if found
    if (scheduleToUse) {
      return {
        cliffMonths: scheduleToUse.cliff_months || 12,
        vestingFrequency: scheduleToUse.vesting_frequency || 'annually',
        vestingYears: Math.floor((scheduleToUse.total_duration_months || 60) / 12),
        vestingType: actualEventType || scheduleToUse.schedule_type || 'time_based',
        cliffDate: calculateVestingDate(grant.vesting_start_date, scheduleToUse.cliff_months || 12)
      };
    }

    // PRIORITY 3: Fallback to plan's vesting_config
    const vestingConfig = plan?.vesting_config || {};
    const configYears = vestingConfig.years || 4;
    return {
      cliffMonths: vestingConfig.cliff_months || 12,
      vestingFrequency: vestingConfig.frequency || 'annually',
      vestingYears: configYears,
      vestingType: actualEventType || plan?.vesting_schedule_type || 'time_based',
      cliffDate: calculateVestingDate(grant.vesting_start_date, vestingConfig.cliff_months || 12)
    };
  } catch (error) {
    console.error('Error getting grant vesting details:', error);
    return null;
  }
};

/**
 * Batch version: Gets vesting details for multiple grants efficiently
 * @param grantIds - Array of grant IDs
 * @returns Promise with a map of grantId -> vesting details
 */
export const getBatchGrantVestingDetails = async (grantIds: string[]): Promise<Record<string, any>> => {
  if (!grantIds || grantIds.length === 0) return {};

  try {
    // Load all grants with their plans in one query
    const { data: grants, error: grantsError } = await supabase
      .from('grants')
      .select(`
        id,
        vesting_start_date,
        vesting_end_date,
        incentive_plans (
          vesting_schedule_template_id,
          vesting_config,
          vesting_schedule_type
        )
      `)
      .in('id', grantIds);

    if (grantsError) throw grantsError;
    if (!grants || grants.length === 0) return {};

    // Load all vesting events for these grants in one query with full details
    const { data: allVestingEvents, error: eventsError } = await supabase
      .from('vesting_events')
      .select('grant_id, event_type, vesting_date, sequence_number')
      .in('grant_id', grantIds)
      .order('vesting_date', { ascending: true });

    if (eventsError) {
      console.error('Error loading vesting events:', eventsError);
    }

    // Group vesting events by grant_id and sort by sequence
    const eventsByGrant = new Map<string, any[]>();
    (allVestingEvents || []).forEach(event => {
      if (!eventsByGrant.has(event.grant_id)) {
        eventsByGrant.set(event.grant_id, []);
      }
      eventsByGrant.get(event.grant_id)!.push(event);
    });
    
    // Sort events within each grant by sequence_number
    eventsByGrant.forEach((events, grantId) => {
      events.sort((a, b) => (a.sequence_number || 0) - (b.sequence_number || 0));
    });

    // Get unique template IDs
    const templateIds = Array.from(
      new Set(
        grants
          .map(g => g.incentive_plans?.vesting_schedule_template_id)
          .filter((id): id is string => Boolean(id))
      )
    );

    // Load all templates in one query
    const templatesMap = new Map<string, any>();
    if (templateIds.length > 0) {
      const { data: templates, error: templatesError } = await supabase
        .from('vesting_schedules')
        .select('*')
        .in('id', templateIds)
        .eq('is_template', true);

      if (templatesError) {
        console.error('Error loading templates:', templatesError);
      } else {
        (templates || []).forEach(template => {
          templatesMap.set(template.id, template);
        });
      }
    }

    // Build the result map
    const result: Record<string, any> = {};

    grants.forEach(grant => {
      const plan = grant.incentive_plans;
      const grantEvents = eventsByGrant.get(grant.id) || [];
      
      // Calculate from actual vesting events if available
      if (grantEvents.length > 0 && grant.vesting_start_date) {
        const startDate = new Date(grant.vesting_start_date);
        const sortedEvents = [...grantEvents].sort((a, b) => {
          const dateA = new Date(a.vesting_date);
          const dateB = new Date(b.vesting_date);
          return dateA.getTime() - dateB.getTime();
        });
        
        // Calculate cliff period from first event
        const firstEventDate = new Date(sortedEvents[0].vesting_date);
        const cliffMonths = Math.round(
          (firstEventDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24 * 30.44)
        );
        
        // Calculate frequency from spacing between events (skip cliff event)
        let vestingFrequency = 'monthly';
        if (sortedEvents.length > 1) {
          // Find first non-cliff event or use second event
          const postCliffEvents = sortedEvents.filter(e => e.event_type !== 'cliff' || e.sequence_number > 1);
          if (postCliffEvents.length > 1) {
            const firstPostCliff = new Date(postCliffEvents[0].vesting_date);
            const secondPostCliff = new Date(postCliffEvents[1].vesting_date);
            const monthsBetween = Math.round(
              (secondPostCliff.getTime() - firstPostCliff.getTime()) / (1000 * 60 * 60 * 24 * 30.44)
            );
            
            if (monthsBetween >= 12) {
              vestingFrequency = 'annually';
            } else if (monthsBetween >= 3) {
              vestingFrequency = 'quarterly';
            } else {
              vestingFrequency = 'monthly';
            }
          }
        }
        
        // Calculate duration from start to end date or last event
        let vestingYears = 4;
        if (grant.vesting_end_date) {
          const endDate = new Date(grant.vesting_end_date);
          const totalMonths = Math.round(
            (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24 * 30.44)
          );
          vestingYears = Math.round(totalMonths / 12);
        } else if (sortedEvents.length > 0) {
          const lastEventDate = new Date(sortedEvents[sortedEvents.length - 1].vesting_date);
          const totalMonths = Math.round(
            (lastEventDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24 * 30.44)
          );
          vestingYears = Math.round(totalMonths / 12);
        }
        
        // Get type from events
        const actualEventType =
          grantEvents.find(event => event.event_type && event.event_type !== 'cliff')?.event_type ||
          grantEvents[0]?.event_type ||
          'time_based';
        
        result[grant.id] = {
          cliffMonths: Math.max(0, cliffMonths),
          vestingFrequency: vestingFrequency,
          vestingYears: Math.max(1, vestingYears),
          vestingType: actualEventType === 'cliff' ? 'time_based' : actualEventType || 'time_based',
          cliffDate: calculateVestingDate(grant.vesting_start_date, Math.max(0, cliffMonths))
        };
        return;
      }

      // Fallback to template if no events
      if (plan?.vesting_schedule_template_id) {
        const template = templatesMap.get(plan.vesting_schedule_template_id);
        if (template) {
          const actualEventType =
            grantEvents.find(event => event.event_type && event.event_type !== 'cliff')?.event_type ||
            grantEvents[0]?.event_type ||
            null;
          
          result[grant.id] = {
            cliffMonths: template.cliff_months || 12,
            vestingFrequency: template.vesting_frequency || 'monthly',
            vestingYears: Math.floor((template.total_duration_months || 48) / 12),
            vestingType: actualEventType || template.schedule_type || 'time_based',
            cliffDate: calculateVestingDate(grant.vesting_start_date, template.cliff_months || 12)
          };
          return;
        }
      }

      // Final fallback to plan's vesting_config
      const vestingConfig = plan?.vesting_config || {};
      const actualEventType =
        grantEvents.find(event => event.event_type && event.event_type !== 'cliff')?.event_type ||
        grantEvents[0]?.event_type ||
        null;
      
      result[grant.id] = {
        cliffMonths: vestingConfig.cliff_months || 12,
        vestingFrequency: vestingConfig.frequency || 'monthly',
        vestingYears: vestingConfig.years || 4,
        vestingType: actualEventType || plan?.vesting_schedule_type || 'time_based',
        cliffDate: calculateVestingDate(grant.vesting_start_date, vestingConfig.cliff_months || 12)
      };
    });

    return result;
  } catch (error) {
    console.error('Error getting batch grant vesting details:', error);
    return {};
  }
};

/**
 * Regenerates vesting events for a grant by deleting old events and creating new ones from the template
 * @param grantId - The ID of the grant to regenerate events for
 * @returns Promise<void>
 */
export const regenerateVestingEventsForGrant = async (grantId: string): Promise<void> => {
  try {
    // Get the grant with its plan to find the template
    const { data: grant, error: grantError } = await supabase
      .from('grants')
      .select(`
        *,
        incentive_plans (
          vesting_schedule_template_id
        )
      `)
      .eq('id', grantId)
      .single();

    if (grantError) throw grantError;
    if (!grant) throw new Error('Grant not found');
    if (!grant.incentive_plans?.vesting_schedule_template_id) {
      throw new Error('Grant does not have a linked vesting schedule template');
    }

    // Delete existing vesting events for this grant
    const { error: deleteError } = await supabase
      .from('vesting_events')
      .delete()
      .eq('grant_id', grantId);

    if (deleteError) throw deleteError;

    // Generate new vesting events
    await generateIndividualVestingRecords(grantId, grant.incentive_plans.vesting_schedule_template_id);
    
    console.log(`Successfully regenerated vesting events for grant ${grantId}`);
  } catch (error) {
    console.error('Error regenerating vesting events:', error);
    throw error;
  }
};

/**
 * Regenerates vesting events for all grants that use templates
 * @param companyId - Optional company ID to limit regeneration to specific company
 * @returns Promise<void>
 */
export const regenerateAllVestingEvents = async (companyId?: string): Promise<void> => {
  try {
    // Get all grants with templates
    let query = supabase
      .from('grants')
      .select(`
        id,
        grant_number,
        incentive_plans!inner (
          vesting_schedule_template_id
        )
      `);

    if (companyId) {
      query = query.eq('company_id', companyId);
    }

    const { data: grants, error: grantsError } = await query;

    if (grantsError) throw grantsError;
    if (!grants || grants.length === 0) {
      console.log('No grants with templates found');
      return;
    }

    console.log(`Found ${grants.length} grants with templates to regenerate`);

    // Regenerate events for each grant
    for (const grant of grants) {
      try {
        await regenerateVestingEventsForGrant(grant.id);
        console.log(`✓ Regenerated events for grant ${grant.grant_number}`);
      } catch (error) {
        console.error(`✗ Failed to regenerate events for grant ${grant.grant_number}:`, error);
        // Continue with other grants even if one fails
      }
    }

    console.log('Finished regenerating all vesting events');
  } catch (error) {
    console.error('Error regenerating all vesting events:', error);
    throw error;
  }
};
