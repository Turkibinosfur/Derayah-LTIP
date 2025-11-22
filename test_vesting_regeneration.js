/**
 * Test script to regenerate vesting events for grant GR-20251101-000010
 * This can be run in the browser console when on the Company Portal
 */

async function regenerateVestingForTest9() {
  console.log('=== REGENERATING VESTING EVENTS FOR GR-20251101-000010 ===');
  
  try {
    // Import the supabase client and vesting utilities
    const { supabase } = await import('./src/lib/supabase.js');
    const { generateIndividualVestingRecords } = await import('./src/lib/vestingUtils.js');
    
    console.log('🔍 Looking for grant GR-20251101-000010...');
    
    // Find the grant
    const { data: grants, error: grantError } = await supabase
      .from('grants')
      .select('*, incentive_plans(vesting_schedule_template_id)')
      .eq('grant_number', 'GR-20251101-000010')
      .single();
    
    if (grantError) {
      console.error('❌ Error finding grant:', grantError);
      return;
    }
    
    console.log('✅ Found grant:', grants.id);
    console.log('📊 Total shares:', grants.total_shares);
    console.log('📅 Vesting start:', grants.vesting_start_date);
    console.log('📋 Plan template ID:', grants.incentive_plans?.vesting_schedule_template_id);
    
    if (!grants.incentive_plans?.vesting_schedule_template_id) {
      console.error('❌ This plan does not have a template!');
      return;
    }
    
    const templateId = grants.incentive_plans.vesting_schedule_template_id;
    
    // Count existing events
    const { data: existingEvents, error: countError } = await supabase
      .from('vesting_events')
      .select('id, shares_to_vest')
      .eq('grant_id', grants.id);
    
    if (countError) {
      console.error('❌ Error counting events:', countError);
      return;
    }
    
    const existingTotal = existingEvents?.reduce((sum, e) => sum + Number(e.shares_to_vest), 0) || 0;
    console.log('📊 Existing events:', existingEvents?.length || 0);
    console.log('📊 Existing total shares:', existingTotal);
    console.log('📊 Missing shares:', grants.total_shares - existingTotal);
    
    if (existingEvents && existingEvents.length > 0) {
      console.log('🗑️  Deleting existing events...');
      const { error: deleteError } = await supabase
        .from('vesting_events')
        .delete()
        .eq('grant_id', grants.id);
      
      if (deleteError) {
        console.error('❌ Error deleting events:', deleteError);
        return;
      }
      
      console.log('✅ Deleted', existingEvents.length, 'events');
    }
    
    console.log('🔄 Generating new vesting events...');
    
    // Get template with milestones
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
    
    if (templateError) {
      console.error('❌ Error fetching template:', templateError);
      return;
    }
    
    console.log('✅ Template:', template.name);
    console.log('📊 Milestones:', template.vesting_milestones?.length || 0);
    
    // Show milestones
    template.vesting_milestones?.forEach((m, idx) => {
      console.log(`  ${idx + 1}. Sequence ${m.sequence_order}: ${m.vesting_percentage}% at month ${m.months_from_start}`);
    });
    
    // Call the generation function
    await generateIndividualVestingRecords(grants.id, templateId);
    
    console.log('✅ Vesting events generated successfully!');
    
    // Verify the results
    const { data: newEvents, error: verifyError } = await supabase
      .from('vesting_events')
      .select('id, sequence_number, vesting_percentage, shares_to_vest, vesting_date')
      .eq('grant_id', grants.id)
      .order('sequence_number');
    
    if (verifyError) {
      console.error('❌ Error verifying:', verifyError);
      return;
    }
    
    const newTotal = newEvents?.reduce((sum, e) => sum + Number(e.shares_to_vest), 0) || 0;
    
    console.log('');
    console.log('=== VERIFICATION ===');
    console.log('Events created:', newEvents?.length || 0);
    console.log('Total shares:', newTotal);
    console.log('Expected shares:', grants.total_shares);
    console.log('Match:', newTotal === grants.total_shares ? '✅ YES' : '❌ NO');
    console.log('');
    
    console.log('=== EVENT DETAILS ===');
    newEvents?.forEach(event => {
      console.log(`Sequence ${event.sequence_number}: ${event.shares_to_vest} shares on ${event.vesting_date}`);
    });
    
    console.log('=== REGENERATION COMPLETE ===');
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Export for use in browser console
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { regenerateVestingForTest9 };
}

// Also run if this is called directly
if (typeof window !== 'undefined') {
  window.regenerateVestingForTest9 = regenerateVestingForTest9;
  console.log('🔧 Function registered: window.regenerateVestingForTest9()');
}

