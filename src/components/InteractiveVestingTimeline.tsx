import { useMemo, useState } from 'react';
import { Clock, TrendingUp, CheckCircle, AlertCircle, Calendar, X } from 'lucide-react';
import { formatShares } from '../lib/numberUtils';
import { formatDate } from '../lib/dateUtils';

interface VestingEvent {
  date: string;
  shares: number;
  cumulativeShares: number;
  percentage: number;
  cumulativePercentage: number;
  status: 'vested' | 'upcoming' | 'pending' | 'transferred' | 'exercised' | 'forfeited' | 'cancelled';
  type: 'time' | 'performance' | 'cliff';
}

interface IndividualVestingRecord {
  id: string;
  sequence_number: number;
  vesting_date: string;
  shares_to_vest: number;
  status: 'pending' | 'vested' | 'transferred' | 'exercised' | 'cancelled' | 'forfeited';
  actual_vest_date?: string | null;
  performance_condition_met?: boolean;
  event_type?: string;
}

interface InteractiveVestingTimelineProps {
  grantDate: string;
  totalShares: number;
  vestedShares: number;
  vestingSchedule: {
    cliff_months: number;
    total_duration_months: number;
    vesting_frequency: 'monthly' | 'quarterly' | 'annually';
  };
  individualVestingRecords?: IndividualVestingRecord[];
}

export default function InteractiveVestingTimeline({
  grantDate,
  totalShares,
  vestedShares,
  vestingSchedule,
  individualVestingRecords
}: InteractiveVestingTimelineProps) {
  const [selectedEvent, setSelectedEvent] = useState<VestingEvent | null>(null);
  const [hoveredEvent, setHoveredEvent] = useState<number | null>(null);
  const [showEventModal, setShowEventModal] = useState(false);
  const [selectedEventDetails, setSelectedEventDetails] = useState<{
    vestingEvent: VestingEvent;
    individualRecord?: IndividualVestingRecord;
    eventIndex: number;
  } | null>(null);

  const vestingEventsWithRecords = useMemo(() => {
    const eventsWithRecords: Array<{ event: VestingEvent; record?: IndividualVestingRecord }> = [];
    const today = new Date();

    // Use real vesting records if available
    if (individualVestingRecords && individualVestingRecords.length > 0) {
      // Debug logging for grants with multiple due events
      const dueRecords = individualVestingRecords.filter(record => {
        const vestingDate = new Date(record.vesting_date);
        const actualVestDate = record.actual_vest_date ? new Date(record.actual_vest_date) : null;
        const isVested = record.status === 'vested' || record.status === 'transferred' || record.status === 'exercised' || (actualVestDate && actualVestDate <= today);
        const isDue = !isVested && vestingDate <= today && record.status === 'pending';
        return isDue;
      });
      
      if (dueRecords.length > 2) {
        console.log('🔍 DEBUG: Multiple due events detected');
        console.log('Due records count:', dueRecords.length);
        console.log('Due records details:', dueRecords.map(r => ({
          sequence: r.sequence_number,
          date: r.vesting_date,
          shares: r.shares_to_vest,
          status: r.status,
          id: r.id,
          daysPastDue: Math.floor((today.getTime() - new Date(r.vesting_date).getTime()) / (1000 * 60 * 60 * 24))
        })));
        console.log('All records for this grant:', individualVestingRecords.map(r => ({
          sequence: r.sequence_number,
          date: r.vesting_date,
          shares: r.shares_to_vest,
          status: r.status
        })));
      }
      
      let cumulativeShares = 0;
      let cumulativePercentage = 0;

      individualVestingRecords.forEach((record) => {
        const vestingDate = new Date(record.vesting_date);
        const actualVestDate = record.actual_vest_date ? new Date(record.actual_vest_date) : null;
        
        // Determine if this event is vested - include vested, transferred, and exercised statuses
        const isVested = record.status === 'vested' || 
                        record.status === 'transferred' || 
                        record.status === 'exercised' || 
                        (actualVestDate && actualVestDate <= today);
        
        // Determine if event is due (scheduled date passed but not yet vested)
        const isDue = !isVested && vestingDate <= today && record.status === 'pending';

        cumulativeShares += Number(record.shares_to_vest);
        const percentage = (Number(record.shares_to_vest) / totalShares) * 100;
        cumulativePercentage += percentage;

        // Determine event type from database record, with fallback for old data
        const eventType = record.event_type === 'cliff' ? 'cliff' :
                         record.event_type === 'time_based' ? 'time' :
                         record.event_type === 'performance' ? 'performance' :
                         record.sequence_number === 1 ? 'cliff' : 'time';

        // Determine proper status - preserve the actual record status
        let eventStatus: 'vested' | 'pending' | 'upcoming' | 'transferred' | 'exercised' | 'forfeited' | 'cancelled';
        if (record.status === 'transferred' || record.status === 'exercised') {
          eventStatus = record.status;
        } else if (record.status === 'cancelled' || record.status === 'forfeited') {
          eventStatus = record.status;
        } else if (isVested) {
          eventStatus = 'vested';
        } else if (isDue) {
          eventStatus = 'pending'; // Due but not yet processed
        } else {
          eventStatus = 'upcoming'; // Future vesting date
        }

        eventsWithRecords.push({
          event: {
            date: record.vesting_date,
            shares: Number(record.shares_to_vest),
            cumulativeShares: Math.min(cumulativeShares, totalShares),
            percentage: percentage,
            cumulativePercentage: Math.min(cumulativePercentage, 100),
            status: eventStatus,
            type: eventType
          },
          record: record
        });
      });

      return eventsWithRecords;
    }

    // Fallback to calculated events when no real data is available
    const startDate = new Date(grantDate);
    const { cliff_months, total_duration_months, vesting_frequency } = vestingSchedule;

    let frequencyMonths = 1;
    if (vesting_frequency === 'quarterly') frequencyMonths = 3;
    if (vesting_frequency === 'annually') frequencyMonths = 12;

    const totalPeriods = Math.ceil((total_duration_months - cliff_months) / frequencyMonths); // periods after cliff

    // Build integer share allocations: floor for all but the last; last gets remainder
    const periodCountIncludingCliff = 1 + Math.max(0, totalPeriods);
    const rawPerPeriod = totalShares / periodCountIncludingCliff;
    const intAllocations: number[] = [];
    let allocated = 0;
    for (let i = 0; i < periodCountIncludingCliff; i++) {
      if (i === periodCountIncludingCliff - 1) {
        intAllocations.push(Math.max(0, totalShares - allocated));
      } else {
        const floored = Math.floor(rawPerPeriod);
        intAllocations.push(floored);
        allocated += floored;
      }
    }

    if (cliff_months > 0) {
      const cliffDate = new Date(startDate);
      cliffDate.setMonth(cliffDate.getMonth() + cliff_months);

      eventsWithRecords.push({
        event: {
          date: cliffDate.toISOString(),
          shares: intAllocations[0],
          cumulativeShares: intAllocations[0],
          percentage: (intAllocations[0] / totalShares) * 100,
          cumulativePercentage: (intAllocations[0] / totalShares) * 100,
          status: cliffDate <= today ? 'vested' : 'upcoming',
          type: 'cliff'
        }
      });
    }

    let cumulativeShares = cliff_months > 0 ? intAllocations[0] : 0;

    for (let i = 0; i < totalPeriods; i++) {
      const eventDate = new Date(startDate);
      eventDate.setMonth(eventDate.getMonth() + cliff_months + (i + 1) * frequencyMonths);

      if (eventDate.getMonth() > startDate.getMonth() + total_duration_months) break;
      const allocationIndex = cliff_months > 0 ? i + 1 : i;
      const sharesInt = intAllocations[allocationIndex] ?? 0;
      cumulativeShares += sharesInt;

      eventsWithRecords.push({
        event: {
          date: eventDate.toISOString(),
          shares: sharesInt,
          cumulativeShares: Math.min(cumulativeShares, totalShares),
          percentage: (sharesInt / totalShares) * 100,
          cumulativePercentage: Math.min((cumulativeShares / totalShares) * 100, 100),
          status: eventDate <= today ? 'vested' : 'upcoming',
          type: 'time'
        }
      });
    }

    return eventsWithRecords;
  }, [grantDate, totalShares, vestingSchedule, individualVestingRecords]);

  const vestingEvents = vestingEventsWithRecords.map(item => item.event);
  const progressPercentage = (vestedShares / totalShares) * 100;
  
  // Prioritize due events over upcoming events for display
  const nextVestingEvent = vestingEvents.find(e => e.status === 'pending') || 
                          vestingEvents.find(e => e.status === 'upcoming');

  const handleEventClick = (eventIndex: number) => {
    const eventWithRecord = vestingEventsWithRecords[eventIndex];
    setSelectedEventDetails({
      vestingEvent: eventWithRecord.event,
      individualRecord: eventWithRecord.record,
      eventIndex: eventIndex
    });
    setShowEventModal(true);
  };

  return (
    <div className="bg-white rounded-xl border border-gray-200 shadow-sm">
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="text-xl font-bold text-gray-900">Vesting Progress</h3>
            <p className="text-sm text-gray-600 mt-1">Track your share vesting journey</p>
          </div>
            <div className="text-right">
            <div className="text-3xl font-bold text-blue-600">{progressPercentage.toFixed(1)}%</div>
            <div className="text-sm text-gray-500">Vested</div>
          </div>
        </div>

        <div className="relative pt-2">
          <div className="flex mb-2 items-center justify-between">
            <div>
              <span className="text-xs font-semibold inline-block text-blue-600">
                {formatShares(vestedShares)} of {formatShares(totalShares)} shares
              </span>
            </div>
          </div>
          <div className="overflow-hidden h-4 mb-4 text-xs flex rounded-full bg-gray-200">
            <div
              style={{ width: `${progressPercentage}%` }}
              className="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-gradient-to-r from-blue-500 to-blue-600 transition-all duration-500"
            />
          </div>
        </div>

        {nextVestingEvent && (
          <div className={`mt-4 p-4 rounded-lg border ${
            nextVestingEvent.status === 'pending' 
              ? 'bg-yellow-50 border-yellow-200' 
              : 'bg-blue-50 border-blue-200'
          }`}>
            <div className="flex items-start space-x-3">
              {nextVestingEvent.status === 'pending' ? (
                <AlertCircle className="w-5 h-5 text-yellow-600 mt-0.5" />
              ) : (
                <Calendar className="w-5 h-5 text-blue-600 mt-0.5" />
              )}
              <div className="flex-1">
                <p className="text-sm font-semibold text-gray-900">
                  {nextVestingEvent.status === 'pending' ? 'Due Vesting Event' : 'Next Vesting Event'}
                </p>
                <p className="text-sm text-gray-600 mt-1">
                  {formatShares(nextVestingEvent.shares)} shares {
                    nextVestingEvent.status === 'pending' ? 'are due for vesting (scheduled' : 'vest'
                  } on {formatDate(nextVestingEvent.date)}
                  {nextVestingEvent.status === 'pending' && ')'}
                </p>
                <p className="text-xs text-gray-500 mt-1">
                  {(() => {
                    const daysDiff = Math.ceil((new Date(nextVestingEvent.date).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24));
                    if (nextVestingEvent.status === 'pending') {
                      return daysDiff <= 0 ? 'Ready for processing' : `Due ${Math.abs(daysDiff)} days ago`;
                    } else {
                      return `${daysDiff} days remaining`;
                    }
                  })()}
                </p>
              </div>
            </div>
          </div>
        )}
      </div>

      <div className="p-6">
        <div className="flex items-center justify-between mb-4">
          <h4 className="text-lg font-semibold text-gray-900">Vesting Timeline</h4>
          <p className="text-xs text-gray-500">Click events for details</p>
        </div>

        <div className="relative">
          <div className="absolute left-4 top-0 bottom-0 w-0.5 bg-gray-200" />

          <div className="space-y-6">
            {vestingEvents.map((event, index) => {
              const isHovered = hoveredEvent === index;
              const isSelected = selectedEvent?.date === event.date;

              return (
                <div
                  key={index}
                  className="relative pl-10 cursor-pointer transition-all"
                  onMouseEnter={() => setHoveredEvent(index)}
                  onMouseLeave={() => setHoveredEvent(null)}
                  onClick={() => handleEventClick(index)}
                >
                  <div className="absolute left-0 top-1">
                    <div
                      className={`w-8 h-8 rounded-full border-4 border-white flex items-center justify-center transition-all ${
                        event.status === 'vested'
                          ? 'bg-green-500 shadow-lg shadow-green-200'
                          : event.status === 'transferred'
                          ? 'bg-purple-500 shadow-lg shadow-purple-200'
                          : event.status === 'exercised'
                          ? 'bg-orange-500 shadow-lg shadow-orange-200'
                          : event.status === 'pending'
                          ? 'bg-yellow-500 shadow-lg shadow-yellow-200'
                          : event.status === 'forfeited' || event.status === 'cancelled'
                          ? 'bg-red-500 shadow-lg shadow-red-200'
                          : event.type === 'cliff'
                          ? 'bg-orange-500 shadow-lg shadow-orange-200'
                          : 'bg-gray-300'
                      } ${isHovered || isSelected ? 'scale-110' : ''}`}
                    >
                      {event.status === 'vested' || event.status === 'transferred' || event.status === 'exercised' ? (
                        <CheckCircle className="w-4 h-4 text-white" />
                      ) : event.status === 'pending' ? (
                        <AlertCircle className="w-4 h-4 text-white" />
                      ) : event.status === 'forfeited' || event.status === 'cancelled' ? (
                        <X className="w-4 h-4 text-white" />
                      ) : event.type === 'cliff' ? (
                        <AlertCircle className="w-4 h-4 text-white" />
                      ) : (
                        <Clock className="w-4 h-4 text-white" />
                      )}
                    </div>
                  </div>

                  <div
                    className={`bg-white border-2 rounded-lg p-4 transition-all cursor-pointer ${
                      isHovered || isSelected
                        ? 'border-blue-500 shadow-lg transform scale-[1.02]'
                        : 'border-gray-200 hover:border-blue-300 hover:shadow-md'
                    }`}
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center space-x-2">
                          <span className="text-sm font-semibold text-gray-900">
                            {formatDate(event.date)}
                          </span>
                          {event.type === 'cliff' && (
                            <span className="px-2 py-0.5 text-xs font-medium bg-orange-100 text-orange-700 rounded-full">
                              Cliff
                            </span>
                          )}
                          {(event.status === 'transferred' || event.status === 'exercised') ? (
                            <>
                              <span className="px-2 py-0.5 text-xs font-medium rounded-full bg-green-100 text-green-700">
                                Vested
                              </span>
                              <span
                                className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                                  event.status === 'transferred'
                                    ? 'bg-purple-100 text-purple-700'
                                    : 'bg-orange-100 text-orange-700'
                                }`}
                              >
                                {event.status === 'transferred' ? 'Transferred' : 'Exercised'}
                              </span>
                            </>
                          ) : (
                            <span
                              className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                                event.status === 'vested'
                                  ? 'bg-green-100 text-green-700'
                                  : event.status === 'pending'
                                  ? 'bg-yellow-100 text-yellow-700'
                                  : event.status === 'forfeited'
                                  ? 'bg-red-100 text-red-700'
                                  : event.status === 'cancelled'
                                  ? 'bg-red-100 text-red-700'
                                  : 'bg-gray-100 text-gray-600'
                              }`}
                            >
                              {event.status === 'vested' ? 'Vested' : 
                               event.status === 'pending' ? 'Due' : 
                               event.status === 'forfeited' ? 'Forfeited' :
                               event.status === 'cancelled' ? 'Cancelled' :
                               'Upcoming'}
                            </span>
                          )}
                        </div>
                        <p className="text-sm text-gray-600 mt-1">
                          {formatShares(event.shares)} shares ({event.percentage.toFixed(1)}%)
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="text-lg font-bold text-gray-900">
                          {formatShares(event.cumulativeShares)}
                        </p>
                        <p className="text-xs text-gray-500">
                          {event.cumulativePercentage.toFixed(1)}% total
                        </p>
                      </div>
                    </div>

                    {(isHovered || isSelected) && (
                      <div className="mt-3 pt-3 border-t border-gray-200">
                        <div className="grid grid-cols-2 gap-3 text-xs">
                          <div>
                            <p className="text-gray-500">This Period</p>
                            <p className="font-semibold text-gray-900">{formatShares(event.shares)} shares</p>
                          </div>
                          <div>
                            <p className="text-gray-500">Cumulative</p>
                            <p className="font-semibold text-gray-900">{formatShares(event.cumulativeShares)} shares</p>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      <div className="p-6 bg-gray-50 border-t border-gray-200 rounded-b-xl">
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-4">
          <div className="text-center">
            <div className="flex items-center justify-center space-x-2 mb-2">
              <div className="w-3 h-3 bg-green-500 rounded-full" />
              <span className="text-xs text-gray-600">Vested</span>
            </div>
            <p className="text-lg font-bold text-gray-900">
              {vestingEvents.filter(e => e.status === 'vested' || e.status === 'transferred' || e.status === 'exercised').length}
            </p>
          </div>
          <div className="text-center">
            <div className="flex items-center justify-center space-x-2 mb-2">
              <div className="w-3 h-3 bg-purple-500 rounded-full" />
              <span className="text-xs text-gray-600">Transferred</span>
            </div>
            <p className="text-lg font-bold text-gray-900">
              {vestingEvents.filter(e => e.status === 'transferred').length}
            </p>
          </div>
          <div className="text-center">
            <div className="flex items-center justify-center space-x-2 mb-2">
              <div className="w-3 h-3 bg-orange-500 rounded-full" />
              <span className="text-xs text-gray-600">Exercised</span>
            </div>
            <p className="text-lg font-bold text-gray-900">
              {vestingEvents.filter(e => e.status === 'exercised').length}
            </p>
          </div>
          <div className="text-center">
            <div className="flex items-center justify-center space-x-2 mb-2">
              <div className="w-3 h-3 bg-yellow-500 rounded-full" />
              <span className="text-xs text-gray-600">Due</span>
            </div>
            <p className="text-lg font-bold text-gray-900">
              {vestingEvents.filter(e => e.status === 'pending').length}
            </p>
          </div>
          <div className="text-center">
            <div className="flex items-center justify-center space-x-2 mb-2">
              <div className="w-3 h-3 bg-red-500 rounded-full" />
              <span className="text-xs text-gray-600">Forfeited</span>
            </div>
            <p className="text-lg font-bold text-gray-900">
              {vestingEvents.filter(e => e.status === 'forfeited').length}
            </p>
          </div>
          <div className="text-center">
            <div className="flex items-center justify-center space-x-2 mb-2">
              <div className="w-3 h-3 bg-red-600 rounded-full" />
              <span className="text-xs text-gray-600">Cancelled</span>
            </div>
            <p className="text-lg font-bold text-gray-900">
              {vestingEvents.filter(e => e.status === 'cancelled').length}
            </p>
          </div>
          <div className="text-center">
            <div className="flex items-center justify-center space-x-2 mb-2">
              <div className="w-3 h-3 bg-gray-300 rounded-full" />
              <span className="text-xs text-gray-600">Upcoming</span>
            </div>
            <p className="text-lg font-bold text-gray-900">
              {vestingEvents.filter(e => e.status === 'upcoming').length}
            </p>
          </div>
        </div>
      </div>

      {/* Vesting Event Details Modal */}
      {showEventModal && selectedEventDetails && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-xl font-bold text-gray-900">Vesting Event Details</h2>
                  <p className="text-gray-600 text-sm mt-1">
                    {formatDate(selectedEventDetails.vestingEvent.date)}
                  </p>
                </div>
                <button
                  onClick={() => setShowEventModal(false)}
                  className="text-gray-400 hover:text-gray-600 transition"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>
            </div>

            <div className="p-6 space-y-6">
              {/* Event Summary */}
              <div className="grid grid-cols-2 gap-6">
                <div className="space-y-4">
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-3">Event Information</h3>
                    <div className="space-y-3">
                      <div className="flex justify-between">
                        <span className="text-sm text-gray-600">Vesting Date:</span>
                        <span className="text-sm font-medium text-gray-900">
                          {formatDate(selectedEventDetails.vestingEvent.date)}
                        </span>
                      </div>
                      {selectedEventDetails.individualRecord && (
                        <>
                          <div className="flex justify-between">
                            <span className="text-sm text-gray-600">Sequence Number:</span>
                            <span className="text-sm font-medium text-gray-900">
                              #{selectedEventDetails.individualRecord.sequence_number}
                            </span>
                          </div>
                          {selectedEventDetails.individualRecord.actual_vest_date && (
                            <div className="flex justify-between">
                              <span className="text-sm text-gray-600">Actual Vest Date:</span>
                              <span className="text-sm font-medium text-gray-900">
                                {formatDate(selectedEventDetails.individualRecord.actual_vest_date)}
                              </span>
                            </div>
                          )}
                        </>
                      )}
                      <div className="flex justify-between">
                        <span className="text-sm text-gray-600">Event Type:</span>
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                          selectedEventDetails.vestingEvent.type === 'cliff' 
                            ? 'bg-orange-100 text-orange-700'
                            : selectedEventDetails.vestingEvent.type === 'performance'
                            ? 'bg-green-100 text-green-700'
                            : 'bg-blue-100 text-blue-700'
                        }`}>
                          {selectedEventDetails.vestingEvent.type === 'cliff' ? 'Cliff' : 
                           selectedEventDetails.vestingEvent.type === 'performance' ? 'Performance' : 'Time-Based'}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-sm text-gray-600">Status:</span>
                        <div className="flex items-center gap-2">
                          {(selectedEventDetails.vestingEvent.status === 'transferred' || selectedEventDetails.vestingEvent.status === 'exercised') ? (
                            <>
                              <span className="px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-700">
                                Vested
                              </span>
                              <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                                selectedEventDetails.vestingEvent.status === 'transferred'
                                  ? 'bg-purple-100 text-purple-700'
                                  : 'bg-orange-100 text-orange-700'
                              }`}>
                                {selectedEventDetails.vestingEvent.status === 'transferred' ? 'Transferred' : 'Exercised'}
                              </span>
                            </>
                          ) : (
                            <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                              selectedEventDetails.vestingEvent.status === 'vested'
                                ? 'bg-green-100 text-green-700'
                                : selectedEventDetails.vestingEvent.status === 'pending'
                                ? 'bg-yellow-100 text-yellow-700'
                                : selectedEventDetails.vestingEvent.status === 'forfeited'
                                ? 'bg-red-100 text-red-700'
                                : selectedEventDetails.vestingEvent.status === 'cancelled'
                                ? 'bg-red-100 text-red-700'
                                : 'bg-gray-100 text-gray-700'
                            }`}>
                              {selectedEventDetails.vestingEvent.status === 'vested' ? 'Vested' :
                               selectedEventDetails.vestingEvent.status === 'pending' ? 'Due (Not Yet Processed)' :
                               selectedEventDetails.vestingEvent.status === 'forfeited' ? 'Forfeited' :
                               selectedEventDetails.vestingEvent.status === 'cancelled' ? 'Cancelled' :
                               'Upcoming'}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="space-y-4">
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-3">Shares Information</h3>
                    <div className="space-y-3">
                      <div className="flex justify-between">
                        <span className="text-sm text-gray-600">Shares to Vest:</span>
                        <span className="text-sm font-bold text-gray-900">
                          {Math.floor(selectedEventDetails.vestingEvent.shares).toLocaleString()}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-sm text-gray-600">Percentage:</span>
                        <span className="text-sm font-medium text-gray-900">
                          {selectedEventDetails.vestingEvent.percentage.toFixed(2)}%
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-sm text-gray-600">Cumulative Shares:</span>
                        <span className="text-sm font-bold text-gray-900">
                          {Math.floor(selectedEventDetails.vestingEvent.cumulativeShares).toLocaleString()}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-sm text-gray-600">Cumulative %:</span>
                        <span className="text-sm font-medium text-gray-900">
                          {selectedEventDetails.vestingEvent.cumulativePercentage.toFixed(2)}%
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Progress Visualization */}
              <div className="border-t border-gray-200 pt-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-3">Vesting Progress</h3>
                <div className="space-y-3">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">Progress up to this event</span>
                    <span className="font-medium text-gray-900">
                      {selectedEventDetails.vestingEvent.cumulativePercentage.toFixed(1)}%
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-3">
                    <div
                      className="bg-blue-600 h-3 rounded-full transition-all"
                      style={{ width: `${selectedEventDetails.vestingEvent.cumulativePercentage}%` }}
                    ></div>
                  </div>
                  <div className="flex justify-between text-xs text-gray-500">
                    <span>0 shares</span>
                    <span>{totalShares.toLocaleString()} shares</span>
                  </div>
                </div>
              </div>

              {/* Additional Database Information */}
              {selectedEventDetails.individualRecord && (
                <div className="border-t border-gray-200 pt-6">
                  <h3 className="text-lg font-semibold text-gray-900 mb-3">Database Record Details</h3>
                  <div className="bg-gray-50 rounded-lg p-4 space-y-2">
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Record ID:</span>
                      <span className="text-sm font-mono text-gray-900">
                        {selectedEventDetails.individualRecord.id}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Record Status:</span>
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                        selectedEventDetails.individualRecord.status === 'vested' ||
                        selectedEventDetails.individualRecord.status === 'transferred' ||
                        selectedEventDetails.individualRecord.status === 'exercised'
                          ? 'bg-green-100 text-green-700'
                          : selectedEventDetails.individualRecord.status === 'pending'
                          ? 'bg-yellow-100 text-yellow-700'
                          : selectedEventDetails.individualRecord.status === 'cancelled' ||
                            selectedEventDetails.individualRecord.status === 'forfeited'
                          ? 'bg-red-100 text-red-700'
                          : 'bg-gray-100 text-gray-700'
                      }`}>
                        {selectedEventDetails.individualRecord.status}
                      </span>
                    </div>
                    {selectedEventDetails.individualRecord.performance_condition_met !== undefined && (
                      <div className="flex justify-between">
                        <span className="text-sm text-gray-600">Performance Condition:</span>
                        <span className={`text-sm font-medium ${
                          selectedEventDetails.individualRecord.performance_condition_met
                            ? 'text-green-600'
                            : 'text-red-600'
                        }`}>
                          {selectedEventDetails.individualRecord.performance_condition_met ? 'Met' : 'Not Met'}
                        </span>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* Days Information */}
              <div className="border-t border-gray-200 pt-6">
                <div className="flex items-center justify-center">
                  <div className="text-center">
                    <p className="text-sm text-gray-600 mb-1">
                      {(() => {
                        const vestingDate = new Date(selectedEventDetails.vestingEvent.date);
                        const today = new Date();
                        const daysDiff = Math.ceil((vestingDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
                        
                        if (daysDiff < 0) {
                          return `Vested ${Math.abs(daysDiff)} days ago`;
                        } else if (daysDiff === 0) {
                          return 'Vests today';
                        } else {
                          return `${daysDiff} days until vesting`;
                        }
                      })()}
                    </p>
                    <div className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
                      selectedEventDetails.vestingEvent.status === 'vested'
                        ? 'bg-green-100 text-green-800'
                        : 'bg-blue-100 text-blue-800'
                    }`}>
                      {selectedEventDetails.vestingEvent.status === 'vested' ? (
                        <>
                          <CheckCircle className="w-4 h-4 mr-1" />
                          Completed
                        </>
                      ) : (
                        <>
                          <Clock className="w-4 h-4 mr-1" />
                          Pending
                        </>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="p-6 border-t border-gray-200 bg-gray-50 flex justify-end">
              <button
                onClick={() => setShowEventModal(false)}
                className="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
