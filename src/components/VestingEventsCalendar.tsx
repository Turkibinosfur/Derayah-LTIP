import React, { useState, useEffect, useMemo } from 'react';
import { ChevronLeft, ChevronRight, Clock, Users, TrendingUp, Calendar, List } from 'lucide-react';
import { formatVestingEventId, formatDate } from '../lib/dateUtils';
import type { VestingEventWithDetails } from '../lib/vestingEventsService';

interface VestingEventsCalendarProps {
  events: VestingEventWithDetails[];
  onEventClick?: (event: VestingEventWithDetails) => void;
}

interface CalendarDay {
  date: Date;
  isCurrentMonth: boolean;
  isToday: boolean;
  events: VestingEventWithDetails[];
}

type ViewMode = 'monthly' | 'annually' | 'decade';

export default function VestingEventsCalendar({ events, onEventClick }: VestingEventsCalendarProps) {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [calendarDays, setCalendarDays] = useState<CalendarDay[]>([]);
  const [viewMode, setViewMode] = useState<ViewMode>('decade');

  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  useEffect(() => {
    generateCalendarDays();
  }, [currentDate, events]);

  const generateCalendarDays = () => {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    
    // First day of the month
    const firstDay = new Date(year, month, 1);
    // Last day of the month
    const lastDay = new Date(year, month + 1, 0);
    
    // Start from the first Sunday before or on the first day
    const startDate = new Date(firstDay);
    startDate.setDate(startDate.getDate() - startDate.getDay());
    
    // End on the last Saturday after or on the last day
    const endDate = new Date(lastDay);
    endDate.setDate(endDate.getDate() + (6 - endDate.getDay()));
    
    const days: CalendarDay[] = [];
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    for (let date = new Date(startDate); date <= endDate; date.setDate(date.getDate() + 1)) {
      const dayEvents = events.filter(event => {
        const eventDate = new Date(event.vesting_date);
        return eventDate.toDateString() === date.toDateString();
      });
      
      days.push({
        date: new Date(date),
        isCurrentMonth: date.getMonth() === month,
        isToday: date.toDateString() === today.toDateString(),
        events: dayEvents
      });
    }
    
    setCalendarDays(days);
  };

  const navigateMonth = (direction: 'prev' | 'next') => {
    const newDate = new Date(currentDate);
    if (direction === 'prev') {
      newDate.setMonth(newDate.getMonth() - 1);
    } else {
      newDate.setMonth(newDate.getMonth() + 1);
    }
    setCurrentDate(newDate);
  };

  const navigateYear = (direction: 'prev' | 'next') => {
    const newDate = new Date(currentDate);
    if (direction === 'prev') {
      newDate.setFullYear(newDate.getFullYear() - 1);
    } else {
      newDate.setFullYear(newDate.getFullYear() + 1);
    }
    setCurrentDate(newDate);
  };

  const navigateDecade = (direction: 'prev' | 'next') => {
    const newDate = new Date(currentDate);
    const step = direction === 'prev' ? -10 : 10;
    newDate.setFullYear(newDate.getFullYear() + step);
    setCurrentDate(newDate);
  };

  const goToToday = () => {
    setCurrentDate(new Date());
  };

  const getYearlyEventsByMonth = () => {
    const year = currentDate.getFullYear();
    const monthlyData = [];
    
    for (let month = 0; month < 12; month++) {
      const monthEvents = events.filter(event => {
        const eventDate = new Date(event.vesting_date);
        return eventDate.getFullYear() === year && eventDate.getMonth() === month;
      });
      
      monthlyData.push({
        month,
        monthName: monthNames[month],
        events: monthEvents,
        totalShares: monthEvents.reduce((sum, event) => sum + event.shares_to_vest, 0),
        eventCount: monthEvents.length
      });
    }
    
    return monthlyData;
  };

  const yearlyEvents = useMemo(() => getYearlyEventsByMonth(), [currentDate, events]);

  const monthlyEventCount = useMemo(() => {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();

    return events.filter(event => {
      const eventDate = new Date(event.vesting_date);
      return eventDate.getFullYear() === year && eventDate.getMonth() === month;
    }).length;
  }, [events, currentDate]);

  const decadeYearRange = useMemo(() => {
    const eventYears = events
      .map(event => new Date(event.vesting_date).getFullYear())
      .filter(year => !Number.isNaN(year));

    if (eventYears.length === 0) {
      const start = currentDate.getFullYear();
      const end = start + 9;
      return {
        start,
        end,
        label: `Upcoming 10 Years (${start} – ${end})`,
        derivedFromEvents: false
      };
    }

    const start = Math.min(...eventYears);
    const end = Math.max(...eventYears);

    return {
      start,
      end,
      label: `Vesting Outlook (${start} – ${end})`,
      derivedFromEvents: true
    };
  }, [events, currentDate]);

  const decadeEvents = useMemo(() => {
    const { start, end } = decadeYearRange;
    if (start === undefined || end === undefined || end < start) {
      return [];
    }

    const yearCount = end - start + 1;

    return Array.from({ length: Math.max(yearCount, 0) }, (_, offset) => {
      const year = start + offset;
      const yearEvents = events.filter(event => {
        const eventDate = new Date(event.vesting_date);
        return eventDate.getFullYear() === year;
      });

      const totalShares = yearEvents.reduce((sum, event) => sum + event.shares_to_vest, 0);
      const monthlyCounts = yearEvents.reduce((acc, event) => {
        const month = new Date(event.vesting_date).getMonth();
        acc[month] = (acc[month] ?? 0) + 1;
        return acc;
      }, {} as Record<number, number>);

      const [peakMonthIndex] = Object.entries(monthlyCounts).sort(([, a], [, b]) => b - a)[0] ?? [];

      return {
        year,
        eventCount: yearEvents.length,
        totalShares,
        peakMonth: peakMonthIndex !== undefined ? monthNames[Number(peakMonthIndex)] : null,
        sampleEvents: yearEvents.slice(0, 3)
      };
    });
  }, [events, monthNames, decadeYearRange]);

  const decadeSummary = useMemo(() => {
    if (decadeEvents.length === 0) {
      return {
        totalEvents: 0,
        totalShares: 0,
        activeYears: 0,
        peakYear: null as number | null
      };
    }

    const totalEvents = decadeEvents.reduce((sum, year) => sum + year.eventCount, 0);
    const totalShares = decadeEvents.reduce((sum, year) => sum + year.totalShares, 0);
    const activeYears = decadeEvents.filter(year => year.eventCount > 0).length;
    const peakYearEntry = decadeEvents.reduce((peak, year) => {
      if (year.eventCount > peak.eventCount) {
        return year;
      }
      return peak;
    }, decadeEvents[0]);

    return {
      totalEvents,
      totalShares,
      activeYears,
      peakYear: peakYearEntry.eventCount > 0 ? peakYearEntry.year : null
    };
  }, [decadeEvents]);

  const totalEventsForView = useMemo(() => {
    switch (viewMode) {
      case 'monthly':
        return monthlyEventCount;
      case 'annually':
        return yearlyEvents.reduce((sum, month) => sum + month.eventCount, 0);
      case 'decade':
        return decadeEvents.reduce((sum, year) => sum + year.eventCount, 0);
      default:
        return 0;
    }
  }, [viewMode, monthlyEventCount, yearlyEvents, decadeEvents]);

  const getEventTypeColor = (eventType: string) => {
    switch (eventType) {
      case 'cliff':
        return 'bg-orange-500';
      case 'time_based':
        return 'bg-blue-500';
      case 'performance_based':
        return 'bg-purple-500';
      default:
        return 'bg-gray-500';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'due':
        return 'border-red-500 bg-red-50';
      case 'pending':
        return 'border-blue-500 bg-blue-50';
      case 'vested':
        return 'border-green-500 bg-green-50';
      case 'exercised':
      case 'transferred':
        return 'border-gray-500 bg-gray-50';
      default:
        return 'border-gray-300 bg-gray-50';
    }
  };

  return (
    <div className="bg-white rounded-xl border border-gray-200">
      {/* Calendar Header */}
      <div className="flex items-center justify-between p-4 border-b border-gray-200">
        <div className="flex items-center gap-4">
          <h3 className="text-lg font-semibold text-gray-900">
            {viewMode === 'monthly'
              ? `${monthNames[currentDate.getMonth()]} ${currentDate.getFullYear()}`
              : viewMode === 'annually'
                ? `${currentDate.getFullYear()}`
                : decadeYearRange.label
          }
          </h3>
          <div className="flex items-center gap-3">
            <button
              onClick={goToToday}
              className="px-3 py-1 text-sm bg-blue-100 text-blue-700 rounded-md hover:bg-blue-200 transition"
            >
              Today
            </button>
            <div
              className="inline-flex h-8 w-8 items-center justify-center rounded-full bg-gray-900 text-sm font-semibold text-white"
              title="Total vesting events in view"
            >
              {totalEventsForView}
            </div>
          </div>
        </div>
        
        <div className="flex items-center gap-4">
          {/* View Mode Switch */}
          <div className="flex items-center bg-gray-100 rounded-lg p-1">
            <button
              onClick={() => setViewMode('monthly')}
              className={`flex items-center gap-2 px-3 py-1 rounded-md text-sm font-medium transition ${
                viewMode === 'monthly'
                  ? 'bg-white text-gray-900 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              <Calendar className="w-4 h-4" />
              Monthly
            </button>
            <button
              onClick={() => setViewMode('annually')}
              className={`flex items-center gap-2 px-3 py-1 rounded-md text-sm font-medium transition ${
                viewMode === 'annually'
                  ? 'bg-white text-gray-900 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              <List className="w-4 h-4" />
              Annually
            </button>
            <button
              onClick={() => setViewMode('decade')}
              className={`flex items-center gap-2 px-3 py-1 rounded-md text-sm font-medium transition ${
                viewMode === 'decade'
                  ? 'bg-white text-gray-900 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              <TrendingUp className="w-4 h-4" />
              10-Year Outlook
            </button>
          </div>

          {/* Navigation */}
          <div className="flex items-center gap-2">
            <button
              onClick={() => {
                if (viewMode === 'monthly') {
                  navigateMonth('prev');
                } else if (viewMode === 'annually') {
                  navigateYear('prev');
                } else if (!decadeYearRange.derivedFromEvents) {
                  navigateDecade('prev');
                }
              }}
              className="p-2 hover:bg-gray-100 rounded-md transition"
            >
              <ChevronLeft className="w-5 h-5 text-gray-600" />
            </button>
            <button
              onClick={() => {
                if (viewMode === 'monthly') {
                  navigateMonth('next');
                } else if (viewMode === 'annually') {
                  navigateYear('next');
                } else if (!decadeYearRange.derivedFromEvents) {
                  navigateDecade('next');
                }
              }}
              className="p-2 hover:bg-gray-100 rounded-md transition"
            >
              <ChevronRight className="w-5 h-5 text-gray-600" />
            </button>
          </div>
        </div>
      </div>

      {/* Calendar Content */}
      <div className="p-4">
        {viewMode === 'monthly' ? (
          <>
            {/* Day Headers */}
            <div className="grid grid-cols-7 gap-1 mb-2">
              {dayNames.map(day => (
                <div key={day} className="p-2 text-center text-sm font-medium text-gray-500">
                  {day}
                </div>
              ))}
            </div>

            {/* Calendar Days */}
            <div className="grid grid-cols-7 gap-1">
              {calendarDays.map((day, index) => (
                <div
                  key={index}
                  className={`min-h-[100px] p-2 border rounded-lg ${
                    day.isCurrentMonth ? 'bg-white' : 'bg-gray-50'
                  } ${day.isToday ? 'ring-2 ring-blue-500' : 'border-gray-200'}`}
                >
                  {/* Date Number */}
                  <div className={`text-sm font-medium mb-1 ${
                    day.isCurrentMonth ? 'text-gray-900' : 'text-gray-400'
                  } ${day.isToday ? 'text-blue-600' : ''}`}>
                    {day.date.getDate()}
                  </div>

                  {/* Events */}
                  <div className="space-y-1">
                    {day.events.slice(0, 3).map((event, eventIndex) => (
                      <div
                        key={event.id}
                        onClick={() => onEventClick?.(event)}
                        className={`p-1 rounded text-xs cursor-pointer hover:opacity-80 transition ${getStatusColor(event.status)}`}
                        title={`${event.employee_name} - ${event.plan_name} (${event.shares_to_vest} shares)`}
                      >
                        <div className="flex items-center gap-1">
                          <div className={`w-2 h-2 rounded-full ${getEventTypeColor(event.event_type)}`} />
                          <span className="truncate font-medium">
                            {event.employee_name.split(' ')[0]}
                          </span>
                        </div>
                        <div className="text-gray-600 truncate">
                          {Math.floor(event.shares_to_vest).toLocaleString()} shares
                        </div>
                      </div>
                    ))}
                    
                    {/* Show "more" indicator if there are additional events */}
                    {day.events.length > 3 && (
                      <div className="text-xs text-gray-500 text-center py-1">
                        +{day.events.length - 3} more
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </>
        ) : viewMode === 'annually' ? (
          /* Annual View */
          <div className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {yearlyEvents.map((monthData) => (
                <div
                  key={monthData.month}
                  className={`p-4 rounded-lg border transition hover:shadow-md ${
                    monthData.eventCount > 0 ? 'border-blue-200 bg-blue-50' : 'border-gray-200 bg-gray-50'
                  }`}
                >
                  <div className="flex items-center justify-between mb-3">
                    <h4 className="font-semibold text-gray-900">{monthData.monthName}</h4>
                    {monthData.eventCount > 0 && (
                      <span className="px-2 py-1 text-xs font-medium bg-blue-100 text-blue-800 rounded-full">
                        {monthData.eventCount} events
                      </span>
                    )}
                  </div>
                  
                  {monthData.eventCount > 0 ? (
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">Total Shares:</span>
                        <span className="font-medium">{Math.floor(monthData.totalShares).toLocaleString()}</span>
                      </div>
                      
                      <div className="space-y-1">
                        {monthData.events.slice(0, 3).map((event) => (
                          <div
                            key={event.id}
                            onClick={() => onEventClick?.(event)}
                            className="flex items-center justify-between p-2 bg-white rounded cursor-pointer hover:bg-gray-50 transition"
                          >
                            <div className="flex items-center gap-2">
                              <div className={`w-2 h-2 rounded-full ${getEventTypeColor(event.event_type)}`} />
                              <span className="text-sm font-medium truncate">
                                {event.employee_name.split(' ')[0]}
                              </span>
                            </div>
                            <div className="flex items-center gap-2">
                              <span className="text-xs text-gray-500">
                                {new Date(event.vesting_date).getDate()}
                              </span>
                              <span className={`px-1 py-0.5 text-xs rounded ${getStatusColor(event.status)}`}>
                                {event.status.charAt(0).toUpperCase()}
                              </span>
                            </div>
                          </div>
                        ))}
                        
                        {monthData.events.length > 3 && (
                          <div className="text-center py-1">
                            <span className="text-xs text-gray-500">
                              +{monthData.events.length - 3} more events
                            </span>
                          </div>
                        )}
                      </div>
                    </div>
                  ) : (
                    <div className="text-center py-4">
                      <Clock className="w-8 h-8 text-gray-300 mx-auto mb-2" />
                      <p className="text-sm text-gray-400">No events</p>
                    </div>
                  )}
                </div>
              ))}
            </div>
            
            {/* Annual Summary */}
            <div className="mt-6 p-4 bg-gray-50 rounded-lg">
              <h4 className="font-semibold text-gray-900 mb-3">
                {currentDate.getFullYear()} Summary
              </h4>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                <div>
                  <span className="text-gray-600">Total Events:</span>
                  <span className="ml-2 font-medium">
                    {yearlyEvents.reduce((sum, month) => sum + month.eventCount, 0)}
                  </span>
                </div>
                <div>
                  <span className="text-gray-600">Total Shares:</span>
                  <span className="ml-2 font-medium">
                    {Math.floor(yearlyEvents.reduce((sum, month) => sum + month.totalShares, 0)).toLocaleString()}
                  </span>
                </div>
                <div>
                  <span className="text-gray-600">Active Months:</span>
                  <span className="ml-2 font-medium">
                    {yearlyEvents.filter(month => month.eventCount > 0).length}
                  </span>
                </div>
                <div>
                  <span className="text-gray-600">Peak Month:</span>
                  <span className="ml-2 font-medium">
                    {yearlyEvents.reduce((peak, month) => 
                      month.eventCount > peak.eventCount ? month : peak
                    ).monthName}
                  </span>
                </div>
              </div>
            </div>
          </div>
        ) : (
          /* Decade View */
          <div className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {decadeEvents.map((yearData) => (
                <div
                  key={yearData.year}
                  className={`p-4 rounded-lg border transition hover:shadow-md ${
                    yearData.eventCount > 0 ? 'border-blue-200 bg-blue-50' : 'border-gray-200 bg-gray-50'
                  }`}
                >
                  <div className="flex items-center justify-between mb-3">
                    <h4 className="font-semibold text-gray-900">{yearData.year}</h4>
                    {yearData.eventCount > 0 && (
                      <span className="px-2 py-1 text-xs font-medium bg-blue-100 text-blue-800 rounded-full">
                        {yearData.eventCount} events
                      </span>
                    )}
                  </div>

                  {yearData.eventCount > 0 ? (
                    <>
                      <div className="flex justify-between text-sm mb-3">
                        <span className="text-gray-600">Total Shares:</span>
                        <span className="font-medium">{Math.floor(yearData.totalShares).toLocaleString()}</span>
                      </div>
                      {yearData.peakMonth && (
                        <div className="text-sm text-gray-600 mb-3">
                          Peak month: <span className="font-medium text-gray-900">{yearData.peakMonth}</span>
                        </div>
                      )}
                      <div className="space-y-2">
                        {yearData.sampleEvents.map((event) => (
                          <div
                            key={event.id}
                            onClick={() => onEventClick?.(event)}
                            className="flex items-center justify-between p-2 bg-white rounded cursor-pointer border border-gray-200 hover:bg-gray-50 transition"
                          >
                            <div className="flex items-center gap-2">
                              <div className={`w-2 h-2 rounded-full ${getEventTypeColor(event.event_type)}`} />
                              <span className="text-sm font-medium truncate">
                                {event.employee_name.split(' ')[0]}
                              </span>
                            </div>
                            <div className="flex items-center gap-2">
                              <span className="text-xs text-gray-500">
                                {monthNames[new Date(event.vesting_date).getMonth()]} {new Date(event.vesting_date).getDate()}
                              </span>
                              <span className={`px-1 py-0.5 text-xs rounded ${getStatusColor(event.status)}`}>
                                {event.status.charAt(0).toUpperCase()}
                              </span>
                            </div>
                          </div>
                        ))}
                      </div>
                      {yearData.sampleEvents.length < yearData.eventCount && (
                        <div className="text-center py-1">
                          <span className="text-xs text-gray-500">
                            +{yearData.eventCount - yearData.sampleEvents.length} more events
                          </span>
                        </div>
                      )}
                    </>
                  ) : (
                    <div className="text-center py-4">
                      <Clock className="w-8 h-8 text-gray-300 mx-auto mb-2" />
                      <p className="text-sm text-gray-400">No events</p>
                    </div>
                  )}
                </div>
              ))}
            </div>

            {/* Decade Summary */}
            <div className="mt-6 p-4 bg-gray-50 rounded-lg">
              <h4 className="font-semibold text-gray-900 mb-3">
                Upcoming 10-Year Summary
              </h4>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                <div>
                  <span className="text-gray-600">Total Events:</span>
                  <span className="ml-2 font-medium">
                    {decadeSummary.totalEvents}
                  </span>
                </div>
                <div>
                  <span className="text-gray-600">Total Shares:</span>
                  <span className="ml-2 font-medium">
                    {Math.floor(decadeSummary.totalShares).toLocaleString()}
                  </span>
                </div>
                <div>
                  <span className="text-gray-600">Active Years:</span>
                  <span className="ml-2 font-medium">
                    {decadeSummary.activeYears}
                  </span>
                </div>
                <div>
                  <span className="text-gray-600">Peak Year:</span>
                  <span className="ml-2 font-medium">
                    {decadeSummary.peakYear ?? '—'}
                  </span>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Legend */}
      <div className="px-4 pb-4 border-t border-gray-200 pt-4">
        <div className="flex flex-wrap items-center gap-4 text-sm">
          <div className="flex items-center gap-2">
            <span className="font-medium text-gray-700">Event Types:</span>
            <div className="flex items-center gap-1">
              <div className="w-3 h-3 rounded-full bg-orange-500" />
              <span className="text-gray-600">Cliff</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-3 h-3 rounded-full bg-blue-500" />
              <span className="text-gray-600">Vesting</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-3 h-3 rounded-full bg-purple-500" />
              <span className="text-gray-600">Performance</span>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <span className="font-medium text-gray-700">Status:</span>
            <div className="flex items-center gap-1">
              <div className="w-3 h-3 border-2 border-red-500 bg-red-50" />
              <span className="text-gray-600">Due</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-3 h-3 border-2 border-blue-500 bg-blue-50" />
              <span className="text-gray-600">Pending</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-3 h-3 border-2 border-green-500 bg-green-50" />
              <span className="text-gray-600">Vested</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
