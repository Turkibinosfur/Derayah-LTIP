// Debug Version of handleAcceptContract
// Add this enhanced logging to your EmployeeDashboard.tsx

const handleAcceptContract = async () => {
  if (!selectedGrant) return;
  
  console.log('=== CONTRACT ACCEPTANCE DEBUG ===');
  console.log('Selected Grant:', selectedGrant);
  console.log('Grant ID:', selectedGrant.id);
  console.log('Current Status:', selectedGrant.status);
  
  try {
    // Calculate vested shares based on grant date and current date
    const grantDate = new Date(selectedGrant.grant_date || new Date());
    const currentDate = new Date();
    const totalShares = Number(selectedGrant.total_shares) || 0;
    
    console.log('Grant Date:', grantDate);
    console.log('Current Date:', currentDate);
    console.log('Total Shares:', totalShares);
    
    // Calculate months since grant date
    const monthsSinceGrant = Math.max(0, 
      (currentDate.getFullYear() - grantDate.getFullYear()) * 12 + 
      (currentDate.getMonth() - grantDate.getMonth())
    );
    
    console.log('Months Since Grant:', monthsSinceGrant);
    
    // Standard 4-year vesting with 1-year cliff
    let vestedShares = 0;
    if (monthsSinceGrant >= 12) {
      // After 1-year cliff, 25% vests immediately, then monthly vesting
      const cliffShares = Math.floor(totalShares * 0.25);
      const remainingShares = totalShares - cliffShares;
      const monthlyVesting = remainingShares / 36; // 36 months remaining after cliff
      const additionalMonths = Math.min(monthsSinceGrant - 12, 36);
      vestedShares = cliffShares + (monthlyVesting * additionalMonths);
    }
    
    // Ensure vested shares don't exceed total shares
    vestedShares = Math.min(vestedShares, totalShares);
    const remainingUnvested = totalShares - vestedShares;
    
    console.log('Calculated Vested Shares:', vestedShares);
    console.log('Calculated Remaining Unvested:', remainingUnvested);
    
    // Update grant status to active with calculated vesting
    const updateData = { 
      status: 'active',
      employee_acceptance_at: new Date().toISOString(),
      vested_shares: Math.floor(vestedShares),
      remaining_unvested_shares: Math.floor(remainingUnvested)
    };
    
    console.log('Update Data:', updateData);
    console.log('Grant ID to update:', selectedGrant.id);
    
    const { data, error } = await supabase
      .from('grants')
      .update(updateData)
      .eq('id', selectedGrant.id)
      .select();
    
    console.log('Update Result - Data:', data);
    console.log('Update Result - Error:', error);
    
    if (error) {
      console.error('Error accepting contract:', error);
      alert(`Failed to accept contract: ${error.message}`);
      return;
    }
    
    console.log('Contract accepted successfully!');
    
    // Close modal and reload data
    setShowContractModal(false);
    setSelectedGrant(null);
    
    console.log('Reloading employee data...');
    await loadEmployeeData();
    
    alert(`Contract accepted successfully! Your grant is now active.\n\nVested shares: ${Math.floor(vestedShares).toLocaleString()}\nRemaining unvested: ${Math.floor(remainingUnvested).toLocaleString()}`);
  } catch (error) {
    console.error('Error accepting contract:', error);
    alert('Failed to accept contract. Please try again.');
  }
};
