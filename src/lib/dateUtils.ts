/**
 * Date utility functions for consistent formatting across the application
 */

/**
 * Formats a date to dd/mm/yyyy format
 * @param date - Date string or Date object
 * @returns Formatted date string in dd/mm/yyyy format
 */
export const formatDate = (date: string | Date): string => {
  try {
    const dateObj = typeof date === 'string' ? new Date(date) : date;
    return dateObj.toLocaleDateString('en-GB'); // This gives dd/mm/yyyy format
  } catch (error) {
    console.error('Error formatting date:', error);
    return 'Invalid Date';
  }
};

/**
 * Formats a date to dd/mm/yyyy with time
 * @param date - Date string or Date object
 * @returns Formatted date string in dd/mm/yyyy, HH:mm format
 */
export const formatDateTime = (date: string | Date): string => {
  try {
    const dateObj = typeof date === 'string' ? new Date(date) : date;
    return dateObj.toLocaleDateString('en-GB') + ', ' + dateObj.toLocaleTimeString('en-GB', { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  } catch (error) {
    console.error('Error formatting datetime:', error);
    return 'Invalid Date';
  }
};

/**
 * Calculates days remaining until a future date
 * @param targetDate - Target date string or Date object
 * @returns Number of days remaining (can be negative for past dates)
 */
export const calculateDaysRemaining = (targetDate: string | Date): number => {
  try {
    const target = typeof targetDate === 'string' ? new Date(targetDate) : targetDate;
    const today = new Date();
    const diffTime = target.getTime() - today.getTime();
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  } catch (error) {
    console.error('Error calculating days remaining:', error);
    return 0;
  }
};

/**
 * Formats days remaining with appropriate text
 * @param daysRemaining - Number of days remaining
 * @returns Formatted string like "5 days remaining" or "2 days overdue"
 */
export const formatDaysRemaining = (daysRemaining: number): string => {
  if (daysRemaining > 0) {
    return `${daysRemaining} days remaining`;
  } else if (daysRemaining === 0) {
    return 'Due today';
  } else {
    return `${Math.abs(daysRemaining)} days overdue`;
  }
};

/**
 * Formats a vesting event ID for display based on vesting date, sequence, and unique identifier
 * @param eventId - UUID of the vesting event
 * @param sequenceNumber - Sequence number of the event within the grant
 * @param vestingDate - The vesting date of the event
 * @param grantId - Grant ID for uniqueness (optional)
 * @returns Formatted event ID like "VE-251224-A1B2-001" (VE-DDMMYY-UNIQ-SEQ)
 */
export const formatVestingEventId = (
  eventId: string, 
  sequenceNumber?: number, 
  vestingDate?: string,
  grantId?: string
): { displayId: string; shortId: string; dateInfo: string } => {
  // Create date-based ID format: VE-DDMMYY-UNIQ-SEQ
  // Check for sequenceNumber !== undefined && !== null (not just truthy) to allow 0
  if (vestingDate && sequenceNumber !== undefined && sequenceNumber !== null) {
    const date = new Date(vestingDate);
    const year = date.getFullYear().toString().slice(-2); // Last 2 digits of year
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const sequence = sequenceNumber.toString().padStart(3, '0');
    
    // Use grant identifier (prefer human-readable grant number) or event ID for uniqueness
    const uniqueSource = grantId
      ? grantId.replace(/[^a-zA-Z0-9]/g, '')
      : eventId.replace(/[^a-zA-Z0-9]/g, '');
    const uniqueId = uniqueSource.substring(0, 4).toUpperCase();
    
    const dateInfo = `${day}${month}${year}`;
    const displayId = `VE-${dateInfo}-${uniqueId}-${sequence}`;
    
    return { 
      displayId, 
      shortId: eventId.substring(0, 8),
      dateInfo: `${day}/${month}/${date.getFullYear()}`
    };
  }
  
  // Fallback to UUID-based ID if date/sequence not available
  const shortId = eventId.substring(0, 8).toUpperCase();
  const displayId = `VE-${shortId}`;
  
  return { 
    displayId, 
    shortId: eventId.substring(0, 8),
    dateInfo: 'N/A'
  };
};