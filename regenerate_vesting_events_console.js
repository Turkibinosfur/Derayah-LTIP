/**
 * Vesting Events Regeneration Utility
 * 
 * Copy and paste this script into your browser console to regenerate vesting events
 * 
 * Usage:
 * 1. Open browser console (F12 or Cmd+Option+I)
 * 2. Navigate to the Grants page in your app
 * 3. Paste this entire script and press Enter
 * 4. Use the commands below
 * 
 * Commands:
 * - regenerateGrantEvents('GRANT_ID') - Regenerate events for a specific grant
 * - regenerateAllEvents() - Regenerate events for all grants
 * - regenerateCompanyEvents('COMPANY_ID') - Regenerate events for all grants in a company
 */

// Import the functions dynamically
async function loadVestingUtils() {
  // This assumes the app is built and these functions are available
  // We'll need to use the actual imports
  const module = await import('./src/lib/vestingUtils.ts');
  return module;
}

// Wrapper functions for console use
window.regenerateGrantEvents = async (grantId) => {
  try {
    console.log(`Starting regeneration for grant: ${grantId}`);
    const utils = await loadVestingUtils();
    await utils.regenerateVestingEventsForGrant(grantId);
    console.log(`✓ Successfully regenerated events for grant ${grantId}`);
    alert('Vesting events regenerated successfully!');
  } catch (error) {
    console.error('Failed to regenerate events:', error);
    alert('Failed to regenerate vesting events. Check console for details.');
  }
};

window.regenerateAllEvents = async () => {
  try {
    console.log('Starting regeneration for all grants...');
    const utils = await loadVestingUtils();
    await utils.regenerateAllVestingEvents();
    console.log('✓ Successfully regenerated all events');
    alert('All vesting events regenerated successfully!');
  } catch (error) {
    console.error('Failed to regenerate events:', error);
    alert('Failed to regenerate vesting events. Check console for details.');
  }
};

window.regenerateCompanyEvents = async (companyId) => {
  try {
    console.log(`Starting regeneration for company: ${companyId}`);
    const utils = await loadVestingUtils();
    await utils.regenerateAllVestingEvents(companyId);
    console.log(`✓ Successfully regenerated events for company ${companyId}`);
    alert('Company vesting events regenerated successfully!');
  } catch (error) {
    console.error('Failed to regenerate events:', error);
    alert('Failed to regenerate vesting events. Check console for details.');
  }
};

console.log('✓ Vesting Events Regeneration Utilities loaded!');
console.log('Available commands:');
console.log('  - regenerateGrantEvents("GRANT_ID")');
console.log('  - regenerateAllEvents()');
console.log('  - regenerateCompanyEvents("COMPANY_ID")');
console.log('');
console.log('Example: regenerateGrantEvents("123e4567-e89b-12d3-a456-426614174000")');

