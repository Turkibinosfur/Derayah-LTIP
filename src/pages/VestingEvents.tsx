// @ts-nocheck
import { useEffect, useState, useRef } from 'react';
import { 
  getAllVestingEvents,
  getUpcomingVestingEvents, 
  processVestingEvent, 
  exerciseVestingEvent, 
  transferVestingEvent,
  getVestingEventStats,
  generateVestingEventsForExistingGrants,
  getGrantsWithoutVestingEvents,
  updateVestingEventStatuses,
  type VestingEventWithDetails 
} from '../lib/vestingEventsService';
import { formatDate, formatDaysRemaining, formatVestingEventId } from '../lib/dateUtils';
import { formatShares } from '../lib/numberUtils';
import { supabase } from '../lib/supabase';
import { 
  Calendar, 
  Clock, 
  TrendingUp, 
  Award, 
  CheckCircle, 
  AlertCircle, 
  DollarSign,
  ArrowRight,
  Filter,
  Download,
  X,
  XCircle,
  Users,
  Search,
  PieChart,
  ChevronDown,
  ChevronUp,
  CheckSquare,
  Square,
  Target
} from 'lucide-react';

interface VestingEventStats {
  total_events: number;
  total_total_shares: number;
  pending_events: number;
  due_events: number;
  vested_events: number;
  transferred_events: number;
  exercised_events: number;
  forfeited_events: number;
  cancelled_events: number;
  processed_events: number;
  total_pending_shares: number;
  total_due_shares: number;
  total_vested_shares: number;
  total_transferred_shares: number;
  total_exercised_shares: number;
  total_forfeited_shares: number;
  total_cancelled_shares: number;
  cliff_events: number;
  time_based_events: number;
}

export default function VestingEvents() {
  const [vestingEvents, setVestingEvents] = useState<VestingEventWithDetails[]>([]);
  const [stats, setStats] = useState<VestingEventStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedStatus, setSelectedStatus] = useState<string>('all');
  const [selectedEventType, setSelectedEventType] = useState<string>('all');
  const [processingEvent, setProcessingEvent] = useState<string | null>(null);
  const [grantsWithoutEvents, setGrantsWithoutEvents] = useState<any[]>([]);
  const [selectedGrantIdsForGeneration, setSelectedGrantIdsForGeneration] = useState<string[]>([]);
  const [showGenerateModal, setShowGenerateModal] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<VestingEventWithDetails | null>(null);
  const [showEventDetailsModal, setShowEventDetailsModal] = useState(false);
  const [showEmployeeFilterModal, setShowEmployeeFilterModal] = useState(false);
  const [selectedEmployees, setSelectedEmployees] = useState<string[]>([]);
  const [employeeFilterSearch, setEmployeeFilterSearch] = useState('');
  const [employees, setEmployees] = useState<any[]>([]);
  const [showGrantFilterModal, setShowGrantFilterModal] = useState(false);
  const [selectedGrants, setSelectedGrants] = useState<string[]>([]);
  const [grantFilterSearch, setGrantFilterSearch] = useState('');
  const [grants, setGrants] = useState<any[]>([]);
  const [eventsChartExpanded, setEventsChartExpanded] = useState(true);
  const [sharesChartExpanded, setSharesChartExpanded] = useState(true);
  const [highlightedEventStatus, setHighlightedEventStatus] = useState<string | null>(null);
  const [eventsHighlightLocked, setEventsHighlightLocked] = useState<string | null>(null);
  const [highlightedShareStatus, setHighlightedShareStatus] = useState<string | null>(null);
  const [sharesHighlightLocked, setSharesHighlightLocked] = useState<string | null>(null);
  const [hoveredEventItem, setHoveredEventItem] = useState<{ label: string; value: number; percentage: number; x: number; y: number } | null>(null);
  const [hoveredShareItem, setHoveredShareItem] = useState<{ label: string; value: number; percentage: number; x: number; y: number } | null>(null);
  const eventsChartRef = useRef<HTMLDivElement>(null);
  const sharesChartRef = useRef<HTMLDivElement>(null);
  const [statsCollapsed, setStatsCollapsed] = useState(true);
  const [dueExpanded, setDueExpanded] = useState(true);
  const [showPerformanceModal, setShowPerformanceModal] = useState(false);
  const [performanceEvent, setPerformanceEvent] = useState<VestingEventWithDetails | null>(null);
  const [performanceConfirmation, setPerformanceConfirmation] = useState({
    confirmed: false,
    notes: '',
    actualValue: ''
  });
  const [performanceProcessing, setPerformanceProcessing] = useState(false);
  const [metricConfirmations, setMetricConfirmations] = useState<Record<string, boolean>>({});
  const [showTransferModal, setShowTransferModal] = useState(false);
  const [transferEvent, setTransferEvent] = useState<VestingEventWithDetails | null>(null);
  const [transferData, setTransferData] = useState<{
    employeePortfolio: any | null;
    financialInfo: any | null;
    fromPortfolio: any | null;
    toPortfolio: any | null;
    sharesToTransfer: number;
  } | null>(null);
  const [loadingTransferData, setLoadingTransferData] = useState(false);
  const [transferProcessing, setTransferProcessing] = useState(false);

  const isPerformanceEventType = (eventType: string) =>
    ['performance', 'performance_based', 'hybrid'].includes(eventType);

  // Store the actual displayed events to use for counting
  const [displayedVestingEvents, setDisplayedVestingEvents] = useState<VestingEventWithDetails[]>([]);

  useEffect(() => {
    loadVestingEvents();
    loadStats();
    loadEmployees();
    loadGrants();
  }, [selectedStatus, selectedEventType, selectedEmployees, selectedGrants]);

  // Note: Grant counts are now loaded directly from the database in loadGrants()
  // This ensures counts show the total number of vesting events per grant,
  // regardless of any filters applied to the displayed events

  const loadVestingEvents = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      console.log('👤 Current user:', user?.id, user?.email);
      if (!user) return;

      const { data: companyUser } = await supabase
        .from('company_users')
        .select('company_id')
        .eq('user_id', user.id)
        .single();

      console.log('🏢 Company user data:', companyUser);
      if (!companyUser) {
        console.warn('⚠️ No company association found for user');
        return;
      }

      console.log('🔍 Loading vesting events for company:', companyUser.company_id);
      
      // Update vesting event statuses before loading (mark pending events as due if past vesting date)
      await updateVestingEventStatuses();
      
      // Load events - if grants are selected, filter in database query (more efficient)
      // This ensures we get ALL events for the selected grants, not just the first N events
      const grantIdsForQuery = selectedGrants.length > 0 ? selectedGrants : undefined;
      
      // When loading for counting (no grant filter), use a much higher limit to ensure
      // we get events for all grants, not just the first 100 by date
      // When filtering by grants, the limit is increased in getAllVestingEvents
      const limitForCounting = grantIdsForQuery ? 100 : 1000; // Higher limit when counting all grants
      
      let eventsForCounting = await getAllVestingEvents(
        companyUser.company_id, 
        selectedStatus, 
        selectedEventType, 
        limitForCounting,  // Use higher limit for accurate counting
        grantIdsForQuery  // Pass grant IDs to filter in database query
      );
      
      // Apply employee filter if any employees are selected (for counting)
      if (selectedEmployees.length > 0) {
        eventsForCounting = eventsForCounting.filter(event => 
          selectedEmployees.includes(event.employee_id)
        );
      }
      
      // Store events for counting (before grant filter is applied for display)
      // This allows counts to show for all grants, not just filtered ones
      console.log('📊 Events for counting:', eventsForCounting.length);
      setDisplayedVestingEvents(eventsForCounting);
      
      // Events are already filtered by grant in the database query if grantIdsForQuery was provided
      // So we can use eventsForCounting directly for display
      let events = eventsForCounting;
      
      console.log('📊 Loaded vesting events for table:', events.length);
      setVestingEvents(events);
    } catch (error) {
      console.error('❌ Error loading vesting events:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: companyUser } = await supabase
        .from('company_users')
        .select('company_id')
        .eq('user_id', user.id)
        .single();

      if (!companyUser) return;

      const result = await getVestingEventStats(companyUser.company_id);
      if (result.success) {
        setStats(result.data);
      }
    } catch (error) {
      console.error('Error loading vesting stats:', error);
    }
  };

  const loadEmployees = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: companyUser } = await supabase
        .from('company_users')
        .select('company_id')
        .eq('user_id', user.id)
        .single();

      if (!companyUser) return;

      const { data: employeesData, error } = await supabase
        .from('employees')
        .select('id, employee_number, first_name_en, last_name_en, email, department')
        .eq('company_id', companyUser.company_id)
        .eq('employment_status', 'active')
        .order('first_name_en', { ascending: true });

      if (error) throw error;
      if (employeesData) setEmployees(employeesData);
    } catch (error) {
      console.error('Error loading employees:', error);
    }
  };

  const loadGrants = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: companyUser } = await supabase
        .from('company_users')
        .select('company_id')
        .eq('user_id', user.id)
        .single();

      if (!companyUser) return;

      // First, get all grants
      const { data: grantsData, error: grantsError } = await supabase
        .from('grants')
        .select(`
          id,
          grant_number,
          total_shares,
          status,
          vesting_start_date,
          employees!inner (
            first_name_en,
            last_name_en
          ),
          incentive_plans!inner (
            plan_name_en,
            plan_code
          )
        `)
        .eq('company_id', companyUser.company_id)
        .in('status', ['active', 'pending_signature'])
        .order('grant_number', { ascending: true });

      if (grantsError) throw grantsError;
      if (!grantsData) return;

      // Get all grant IDs to query vesting event counts
      const grantIds = grantsData.map(g => g.id);
      
      // Query actual vesting event counts from the database for each grant
      // This shows the total count regardless of filters
      const { data: vestingEventsData, error: eventsError } = await supabase
        .from('vesting_events')
        .select('grant_id')
        .in('grant_id', grantIds);
      
      if (eventsError) {
        console.error('Error loading vesting event counts:', eventsError);
      }
      
      // Count events per grant
      const eventCountMap: Record<string, number> = {};
      if (vestingEventsData) {
        vestingEventsData.forEach(event => {
          eventCountMap[event.grant_id] = (eventCountMap[event.grant_id] || 0) + 1;
        });
      }
      
      // Map grants with their actual vesting event counts
      const grantsWithEventCounts = grantsData.map(grant => ({
        ...grant,
        vesting_event_count: eventCountMap[grant.id] || 0
      }));

      setGrants(grantsWithEventCounts);
    } catch (error) {
      console.error('Error loading grants:', error);
    }
  };

  const clearEmployeeFilter = () => {
    setSelectedEmployees([]);
  };

  const toggleEmployeeSelection = (employeeId: string) => {
    setSelectedEmployees(prev => 
      prev.includes(employeeId) 
        ? prev.filter(id => id !== employeeId)
        : [...prev, employeeId]
    );
  };

  const filteredEmployeesForModal = employees.filter(emp => 
    emp.first_name_en.toLowerCase().includes(employeeFilterSearch.toLowerCase()) ||
    emp.last_name_en.toLowerCase().includes(employeeFilterSearch.toLowerCase()) ||
    emp.employee_number.toLowerCase().includes(employeeFilterSearch.toLowerCase())
  );

  const clearGrantFilter = () => {
    setSelectedGrants([]);
  };

  const toggleGrantSelection = (grantId: string) => {
    setSelectedGrants(prev => 
      prev.includes(grantId) 
        ? prev.filter(id => id !== grantId)
        : [...prev, grantId]
    );
  };

  const filteredGrantsForModal = grants.filter(grant => 
    grant.grant_number.toLowerCase().includes(grantFilterSearch.toLowerCase()) ||
    (grant.employees?.first_name_en + ' ' + grant.employees?.last_name_en).toLowerCase().includes(grantFilterSearch.toLowerCase()) ||
    grant.incentive_plans?.plan_name_en.toLowerCase().includes(grantFilterSearch.toLowerCase())
  );

  const loadGrantsWithoutEvents = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: companyUser } = await supabase
        .from('company_users')
        .select('company_id')
        .eq('user_id', user.id)
        .single();

      if (!companyUser) return;

      const result = await getGrantsWithoutVestingEvents(companyUser.company_id);
      if (result.success) {
        setGrantsWithoutEvents(result.data || []);
      }
    } catch (error) {
      console.error('Error loading grants without events:', error);
    }
  };

  const toggleGrantSelectionForGeneration = (grantId: string) => {
    setSelectedGrantIdsForGeneration(prev => 
      prev.includes(grantId)
        ? prev.filter(id => id !== grantId)
        : [...prev, grantId]
    );
  };

  const isAllGenerationSelected = selectedGrantIdsForGeneration.length > 0 && selectedGrantIdsForGeneration.length === grantsWithoutEvents.length;

  const toggleSelectAllGeneration = () => {
    if (isAllGenerationSelected) {
      setSelectedGrantIdsForGeneration([]);
    } else {
      setSelectedGrantIdsForGeneration(grantsWithoutEvents.map(grant => grant.id));
    }
  };

  const handleGenerateVestingEvents = async () => {
    setGenerating(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: companyUser } = await supabase
        .from('company_users')
        .select('company_id')
        .eq('user_id', user.id)
        .single();

      if (!companyUser) return;

      const result = await generateVestingEventsForExistingGrants(companyUser.company_id, selectedGrantIdsForGeneration);
      
      if (result.success) {
        const data = result.data;
        alert(`Vesting events generation completed!\n\nProcessed: ${data.processed} grants\nSkipped: ${data.skipped} grants\nErrors: ${data.errors} grants`);
        
        // Reload data
        await loadVestingEvents();
        await loadStats();
        await loadGrantsWithoutEvents();
        setSelectedGrantIdsForGeneration([]);
        setShowGenerateModal(false);
      } else {
        alert(`Error: ${result.error}`);
      }
    } catch (error) {
      console.error('Error generating vesting events:', error);
      alert('Failed to generate vesting events');
    } finally {
      setGenerating(false);
    }
  };

  const handleEventIdClick = (event: VestingEventWithDetails) => {
    setSelectedEvent(event);
    setShowEventDetailsModal(true);
  };

  const handleProcessEvent = async (
    eventId: string,
    action: 'vest' | 'exercise' | 'transfer',
    options?: { skipPerformanceCheck?: boolean }
  ) => {
    setProcessingEvent(eventId);
    try {
      // If processing vesting, check if contract is signed
      if (action === 'vest') {
        const event = vestingEvents.find(e => e.id === eventId);
        if (event && !event.grants?.employee_acceptance_at) {
          alert('Cannot process vesting: The employee contract has not been signed yet. The employee needs to sign the contract in order to proceed with vesting the shares and transferring them to the employee portfolio.');
          setProcessingEvent(null);
          return;
        }

        if (
          event &&
          event.requiresPerformanceConfirmation &&
          !options?.skipPerformanceCheck &&
          isPerformanceEventType(event.event_type)
        ) {
          setPerformanceEvent(event);
          setPerformanceConfirmation({
            confirmed: false,
            notes: event.performance_notes || '',
            actualValue: event.performanceMetric?.actual_value !== undefined && event.performanceMetric?.actual_value !== null
              ? String(event.performanceMetric.actual_value)
              : ''
          });
          const metricList = (event.grantPerformanceMetrics && event.grantPerformanceMetrics.length > 0)
            ? event.grantPerformanceMetrics
            : event.performanceMetric
              ? [event.performanceMetric]
              : [];
          const initialConfirmations: Record<string, boolean> = {};
          metricList.forEach(metric => {
            if (metric?.id) {
              initialConfirmations[metric.id] = false;
            }
          });
          setMetricConfirmations(initialConfirmations);
          setProcessingEvent(null);
          setShowPerformanceModal(true);
          return;
        }
      }

      // If transferring shares, show confirmation modal instead of directly transferring
      if (action === 'transfer') {
        const event = vestingEvents.find(e => e.id === eventId);
        if (event) {
          setTransferEvent(event);
          setShowTransferModal(true);
          setProcessingEvent(null);
          // Load transfer data (portfolio and financial info)
          await loadTransferConfirmationData(eventId, event);
          return;
        }
      }
      
      let result;
      
      switch (action) {
        case 'vest':
          result = await processVestingEvent(eventId);
          break;
        case 'exercise':
          result = await exerciseVestingEvent(eventId);
          break;
        case 'transfer':
          result = await transferVestingEvent(eventId);
          break;
      }

      if (result.success) {
        // Reload events and stats
        await loadVestingEvents();
        await loadStats();
        if (action === 'transfer') {
          alert(`Transfer request created successfully! The transfer request has been added to the Transfers page for processing.`);
        } else {
          alert(`Successfully ${action}ed vesting event!`);
        }
      } else {
        alert(`Error: ${result.error}`);
      }
    } catch (error) {
      console.error(`Error ${action}ing vesting event:`, error);
      alert(`Failed to ${action} vesting event`);
    } finally {
      setProcessingEvent(null);
    }
  };

  const closePerformanceModal = () => {
    setShowPerformanceModal(false);
    setPerformanceEvent(null);
    setPerformanceConfirmation({
      confirmed: false,
      notes: '',
      actualValue: ''
    });
    setPerformanceProcessing(false);
    setMetricConfirmations({});
  };

  const loadTransferConfirmationData = async (eventId: string, event: VestingEventWithDetails) => {
    setLoadingTransferData(true);
    try {
      const companyId = event.company_id || event.grants?.company_id;
      const employeeId = event.employee_id;

      if (!companyId || !employeeId) {
        alert('Missing company or employee information');
        setShowTransferModal(false);
        return;
      }

      // Fetch employee portfolio
      const { data: portfolios, error: portfolioError } = await supabase
        .from('portfolios')
        .select('*')
        .eq('company_id', companyId);

      if (portfolioError) throw portfolioError;

      const fromPortfolio = portfolios?.find(p => 
        p.portfolio_type === 'company_reserved' && 
        p.company_id === companyId &&
        p.employee_id === null
      );

      const toPortfolio = portfolios?.find(p => 
        p.portfolio_type === 'employee_vested' && 
        p.employee_id === employeeId &&
        p.company_id === companyId
      );

      // Fetch employee financial info
      const { data: financialInfo, error: financialError } = await supabase
        .from('employee_financial_info')
        .select('*')
        .eq('employee_id', employeeId)
        .maybeSingle();

      if (financialError && financialError.code !== 'PGRST116') {
        console.error('Error fetching financial info:', financialError);
      }

      setTransferData({
        employeePortfolio: toPortfolio || null,
        financialInfo: financialInfo || null,
        fromPortfolio: fromPortfolio || null,
        toPortfolio: toPortfolio || null,
        sharesToTransfer: Math.floor(event.shares_to_vest)
      });
    } catch (error) {
      console.error('Error loading transfer confirmation data:', error);
      alert('Failed to load transfer confirmation data');
      setShowTransferModal(false);
    } finally {
      setLoadingTransferData(false);
    }
  };

  const handleConfirmTransfer = async () => {
    if (!transferEvent) return;

    // Validate financial info before proceeding
    if (transferData?.financialInfo) {
      // Check if financial info exists and has required Investment Account fields
      if (!transferData.financialInfo.broker_custodian_name || 
          !transferData.financialInfo.broker_account_number || 
          !transferData.financialInfo.tadawul_investor_number || 
          !transferData.financialInfo.investment_account_number) {
        alert('Cannot transfer shares: The financial information and portfolio details are missing and need to be completed in order to proceed with the share transfer. Please ensure the employee has Investment Account Information (for Share Transfers) configured.');
        return;
      }

      // Check if account status is verified
      if (transferData.financialInfo.account_status !== 'verified') {
        alert('Cannot transfer shares: Employee financial account must be verified by a finance admin before shares can be transferred. Please verify the account first.');
        return;
      }
    } else {
      alert('Cannot transfer shares: Financial information is missing. Please add financial information before transferring shares.');
      return;
    }

    setTransferProcessing(true);
    try {
      const result = await transferVestingEvent(transferEvent.id);

      if (result.success) {
        await loadVestingEvents();
        await loadStats();
        alert(`Transfer request created successfully! The transfer request has been added to the Transfers page for processing.`);
        closeTransferModal();
      } else {
        alert(`Error: ${result.error}`);
      }
    } catch (error) {
      console.error('Error transferring vesting event:', error);
      alert('Failed to transfer vesting event');
    } finally {
      setTransferProcessing(false);
    }
  };

  const closeTransferModal = () => {
    setShowTransferModal(false);
    setTransferEvent(null);
    setTransferData(null);
    setTransferProcessing(false);
  };

  const handleConfirmPerformanceVest = async () => {
    if (!performanceEvent) {
      return;
    }

    const metricsList =
      performanceEvent.grantPerformanceMetrics && performanceEvent.grantPerformanceMetrics.length > 0
        ? performanceEvent.grantPerformanceMetrics
        : performanceEvent.performanceMetric
        ? [performanceEvent.performanceMetric]
        : [];

    const allMetricsConfirmed =
      metricsList.length === 0
        ? true
        : metricsList.every(metric =>
            metric?.id ? Boolean(metricConfirmations[metric.id]) : true
          );

    if (!allMetricsConfirmed) {
      alert('Please confirm all performance metrics before vesting this event.');
      return;
    }

    setPerformanceProcessing(true);

    try {
      const updates: Promise<any>[] = [
        supabase
          .from('vesting_events')
          .update({
            performance_condition_met: true,
            performance_notes: performanceConfirmation.notes || null,
            updated_at: new Date().toISOString()
          })
          .eq('id', performanceEvent.id)
      ];

      if (performanceEvent.performanceMilestoneId) {
        const actualValueInput = performanceConfirmation.actualValue.trim();
        const actualValueNumber =
          actualValueInput === '' ? null : Number(actualValueInput);

        updates.push(
          supabase
            .from('vesting_milestones')
            .update({
              is_achieved: true,
              achieved_at: new Date().toISOString(),
              actual_value:
                actualValueNumber === null || Number.isNaN(actualValueNumber)
                  ? null
                  : actualValueNumber
            })
            .eq('id', performanceEvent.performanceMilestoneId)
        );
      }

      await Promise.all(updates);

      closePerformanceModal();

      await handleProcessEvent(performanceEvent.id, 'vest', { skipPerformanceCheck: true });
    } catch (error) {
      console.error('Error confirming performance metric:', error);
      alert('Failed to confirm performance metric. Please try again.');
    } finally {
      setPerformanceProcessing(false);
    }
  };

  const getStatusBadge = (status: string) => {
    const badges = {
      pending: 'bg-yellow-100 text-yellow-800',
      due: 'bg-red-100 text-red-800',
      vested: 'bg-green-100 text-green-800',
      transferred: 'bg-blue-100 text-blue-800',
      exercised: 'bg-purple-100 text-purple-800',
      forfeited: 'bg-gray-100 text-gray-800',
      cancelled: 'bg-gray-100 text-gray-800'
    };
    return badges[status as keyof typeof badges] || 'bg-gray-100 text-gray-800';
  };

  const getEventTypeBadge = (eventType: string) => {
    const badges = {
      cliff: 'bg-orange-100 text-orange-800',
      time_based: 'bg-blue-100 text-blue-800',
      performance: 'bg-green-100 text-green-800',
      acceleration: 'bg-purple-100 text-purple-800'
    };
    return badges[eventType as keyof typeof badges] || 'bg-gray-100 text-gray-800';
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-3">
            Vesting Events
            <span className="inline-flex items-center justify-center w-10 h-10 rounded-full bg-blue-600 text-white text-lg font-semibold">
              {vestingEvents.length}
            </span>
          </h1>
          <p className="text-gray-600 mt-1">Manage and process vesting events for all grants</p>
        </div>
        <div className="flex gap-3">
          <button 
            onClick={() => {
              loadGrantsWithoutEvents();
              setShowGenerateModal(true);
            }}
            className="flex items-center space-x-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition"
          >
            <TrendingUp className="w-4 h-4" />
            <span>Generate Events</span>
          </button>
          <button className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition">
            <Download className="w-4 h-4" />
            <span>Export</span>
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      {stats && (
        <div className="bg-white rounded-xl border border-gray-200">
          <div 
            onClick={() => setStatsCollapsed(!statsCollapsed)}
            className="px-4 py-3 border-b border-gray-200 flex items-center justify-between cursor-pointer hover:bg-gray-50 transition"
            title={statsCollapsed ? 'Expand' : 'Collapse'}
            role="button"
            tabIndex={0}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                setStatsCollapsed(!statsCollapsed);
              }
            }}
          >
            <h2 className="text-sm font-semibold text-gray-900">Summary</h2>
            <div className="text-gray-500">
              {statsCollapsed ? <ChevronDown className="w-5 h-5" /> : <ChevronUp className="w-5 h-5" />}
            </div>
          </div>
          {!statsCollapsed && (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-3 p-4">
            <div
              className="bg-white rounded-lg p-4 border border-gray-200 cursor-pointer hover:border-blue-300 hover:bg-blue-50 transition"
              onClick={() => setSelectedStatus('all')}
              role="button"
              title="Show all events"
            >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Total Events</p>
                  <p className="text-xl font-bold text-gray-900">{stats.total_events}</p>
                <p className="text-xs text-gray-500">{formatShares(stats.total_total_shares)} shares</p>
              </div>
                <Calendar className="w-5 h-5 text-blue-600" />
            </div>
          </div>

            <div
              className="bg-white rounded-lg p-4 border border-gray-200 cursor-pointer hover:border-red-300 hover:bg-red-50 transition"
              onClick={() => setSelectedStatus('due')}
              role="button"
              title="Filter: Due Now"
            >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Due Now</p>
                  <p className="text-xl font-bold text-red-600">{stats.due_events}</p>
                <p className="text-xs text-gray-500">{formatShares(stats.total_due_shares)} shares</p>
              </div>
                <AlertCircle className="w-5 h-5 text-red-600" />
            </div>
          </div>

            <div
              className="bg-white rounded-lg p-4 border border-gray-200 cursor-pointer hover:border-yellow-300 hover:bg-yellow-50 transition"
              onClick={() => setSelectedStatus('pending')}
              role="button"
              title="Filter: Pending"
            >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Pending</p>
                  <p className="text-xl font-bold text-yellow-600">{stats.pending_events}</p>
                <p className="text-xs text-gray-500">{formatShares(stats.total_pending_shares)} shares</p>
              </div>
                <Clock className="w-5 h-5 text-yellow-600" />
            </div>
          </div>

            <div
              className="bg-white rounded-lg p-4 border border-gray-200 cursor-pointer hover:border-green-300 hover:bg-green-50 transition"
              onClick={() => setSelectedStatus('transferred')}
              role="button"
              title="Filter: Transferred"
            >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Transferred</p>
                  <p className="text-xl font-bold text-green-600">{stats.transferred_events}</p>
                <p className="text-xs text-gray-500">{formatShares(stats.total_transferred_shares)} shares</p>
              </div>
                <CheckCircle className="w-5 h-5 text-green-600" />
            </div>
          </div>

            <div
              className="bg-white rounded-lg p-4 border border-gray-200 cursor-pointer hover:border-purple-300 hover:bg-purple-50 transition"
              onClick={() => setSelectedStatus('exercised')}
              role="button"
              title="Filter: Exercised"
            >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Exercised</p>
                  <p className="text-xl font-bold text-purple-600">{stats.exercised_events}</p>
                <p className="text-xs text-gray-500">{formatShares(stats.total_exercised_shares)} shares</p>
              </div>
                <Award className="w-5 h-5 text-purple-600" />
            </div>
          </div>

            <div
              className="bg-white rounded-lg p-4 border border-gray-200 cursor-pointer hover:border-blue-300 hover:bg-blue-50 transition"
              onClick={() => setSelectedStatus('vested')}
              role="button"
              title="Filter: Vested"
            >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Vested</p>
                  <p className="text-xl font-bold text-blue-600">{stats.vested_events}</p>
                <p className="text-xs text-gray-500">{formatShares(stats.total_vested_shares)} shares</p>
              </div>
                <TrendingUp className="w-5 h-5 text-blue-600" />
            </div>
          </div>

            <div
              className="bg-white rounded-lg p-4 border border-gray-200 cursor-pointer hover:border-gray-300 hover:bg-gray-50 transition"
              onClick={() => setSelectedStatus('forfeited')}
              role="button"
              title="Filter: Forfeited / Cancelled"
            >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Forfeited / Cancelled</p>
                  <p className="text-xl font-bold text-gray-600">{stats.forfeited_events + stats.cancelled_events}</p>
                <p className="text-xs text-gray-500">{formatShares(stats.total_forfeited_shares + stats.total_cancelled_shares)} shares</p>
              </div>
                <XCircle className="w-5 h-5 text-gray-600" />
              </div>
            </div>
          </div>
          )}
        </div>
      )}

      {/* Pie Chart Cards */}
      {stats && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Events by Status Pie Chart */}
          <div className="bg-white rounded-xl border border-gray-200 shadow-sm">
            <div 
              onClick={() => setEventsChartExpanded(!eventsChartExpanded)}
              className="p-4 border-b border-gray-200 flex items-center justify-between cursor-pointer hover:bg-gray-50 transition"
              title={eventsChartExpanded ? "Collapse legend" : "Expand legend"}
              role="button"
              tabIndex={0}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  e.preventDefault();
                  setEventsChartExpanded(!eventsChartExpanded);
                }
              }}
            >
              <div className="flex items-center space-x-2">
                <PieChart className="w-5 h-5 text-blue-600" />
                <h3 className="text-lg font-semibold text-gray-900">Events by Status</h3>
              </div>
              <div className="text-gray-500">
                {eventsChartExpanded ? <ChevronUp className="w-5 h-5" /> : <ChevronDown className="w-5 h-5" />}
              </div>
            </div>
            <div className="p-4">
              {(() => {
                const eventsData = [
                  { label: 'Due Now', value: stats.due_events, color: '#ef4444' },
                  { label: 'Pending', value: stats.pending_events, color: '#f59e0b' },
                  { label: 'Transferred', value: stats.transferred_events, color: '#10b981' },
                  { label: 'Exercised', value: stats.exercised_events, color: '#8b5cf6' },
                  { label: 'Vested', value: stats.vested_events, color: '#06b6d4' },
                  { label: 'Forfeited/Cancelled', value: stats.forfeited_events + stats.cancelled_events, color: '#6b7280' },
                ].filter(d => d.value > 0);
                
                const totalEvents = eventsData.reduce((sum, d) => sum + d.value, 0);
                
                if (eventsData.length === 0 || totalEvents === 0) {
                  return (
                    <div className="text-center py-8 text-gray-500">
                      No events available
                    </div>
                  );
                }

                return (
                  <div className="space-y-3">
                    <div 
                      ref={eventsChartRef} 
                      className="relative w-full h-40 flex items-center justify-center"
                      onClick={(e) => {
                        if (e.target === e.currentTarget || (e.target as HTMLElement).tagName === 'svg') {
                          setEventsHighlightLocked(null);
                          setHighlightedEventStatus(null);
                          setHoveredEventItem(null);
                        }
                      }}
                    >
                      <svg 
                        viewBox="0 0 120 120" 
                        className="w-full max-w-40 h-40 cursor-pointer"
                        onMouseLeave={() => {
                          setHoveredEventItem(null);
                          if (!eventsHighlightLocked) {
                            setHighlightedEventStatus(null);
                          }
                        }}
                      >
                        {eventsData.map((item, index) => {
                          const startAngle = eventsData
                            .slice(0, index)
                            .reduce((sum, d) => sum + (d.value / totalEvents) * 360, 0);
                          const angle = (item.value / totalEvents) * 360;
                          const endAngle = startAngle + angle;

                          const startRad = (startAngle - 90) * (Math.PI / 180);
                          const endRad = (endAngle - 90) * (Math.PI / 180);

                          const x1 = 60 + 50 * Math.cos(startRad);
                          const y1 = 60 + 50 * Math.sin(startRad);
                          const x2 = 60 + 50 * Math.cos(endRad);
                          const y2 = 60 + 50 * Math.sin(endRad);

                          const largeArc = angle > 180 ? 1 : 0;
                          const percentage = (item.value / totalEvents) * 100;
                          const isLocked = eventsHighlightLocked === item.label;
                          const isHighlighted = highlightedEventStatus === item.label;
                          const isDimmed = eventsHighlightLocked
                            ? !isLocked
                            : highlightedEventStatus !== null && !isHighlighted;
                          
                          return (
                            <path
                              key={item.label}
                              d={`M 60 60 L ${x1} ${y1} A 50 50 0 ${largeArc} 1 ${x2} ${y2} Z`}
                              fill={item.color}
                              stroke="white"
                              strokeWidth={isLocked || isHighlighted ? 3 : 2}
                              className="cursor-pointer"
                              style={{
                                opacity: isLocked ? 1 : isDimmed ? 0.3 : isHighlighted ? 1 : 0.8,
                                filter:
                                  isLocked || isHighlighted
                                    ? 'brightness(1.2)'
                                    : eventsHighlightLocked
                                    ? 'brightness(0.5)'
                                    : 'none',
                                transition: 'none'
                              }}
                              onMouseEnter={(e) => {
                                if (eventsChartRef.current) {
                                  const containerRect = eventsChartRef.current.getBoundingClientRect();
                                  const mouseX = e.clientX - containerRect.left;
                                  const mouseY = e.clientY - containerRect.top;
                                  if (!eventsHighlightLocked) {
                                    setHighlightedEventStatus(item.label);
                                  }
                                  setHoveredEventItem({
                                    label: item.label,
                                    value: item.value,
                                    percentage,
                                    x: mouseX,
                                    y: mouseY
                                  });
                                }
                              }}
                              onMouseLeave={() => {
                                setHoveredEventItem(null);
                                if (!eventsHighlightLocked) {
                                  setHighlightedEventStatus(null);
                                }
                              }}
                              onClick={(e) => {
                                e.stopPropagation();
                                if (eventsChartRef.current) {
                                  const containerRect = eventsChartRef.current.getBoundingClientRect();
                                  const mouseX = e.clientX - containerRect.left;
                                  const mouseY = e.clientY - containerRect.top;
                                  setHoveredEventItem({
                                    label: item.label,
                                    value: item.value,
                                    percentage,
                                    x: mouseX,
                                    y: mouseY
                                  });
                                }
                                setEventsHighlightLocked((prev) => {
                                  const next = prev === item.label ? null : item.label;
                                  setHighlightedEventStatus(next);
                                  return next;
                                });
                              }}
                            />
                          );
                        })}
                        <circle cx="60" cy="60" r="30" fill="white" />
                        {(() => {
                          const eventsText = totalEvents.toLocaleString();
                          const fontSize = eventsText.length > 12 ? '9' : eventsText.length > 9 ? '10' : eventsText.length > 6 ? '11' : '12';
                          return (
                            <text x="60" y="56" textAnchor="middle" className="font-bold" fill="#111827" fontSize={fontSize}>
                              {eventsText}
                            </text>
                          );
                        })()}
                        <text x="60" y="70" textAnchor="middle" fill="#6b7280" fontSize="9">
                          Events
                        </text>
                      </svg>
                      {hoveredEventItem && (
                        <div 
                          className="absolute z-10 bg-gray-900 text-white text-xs rounded-lg px-3 py-2 shadow-lg pointer-events-none whitespace-nowrap"
                          style={{
                            left: `${hoveredEventItem.x}px`,
                            top: `${hoveredEventItem.y - 30}px`,
                            transform: 'translateX(-50%)'
                          }}
                        >
                          <div className="font-semibold">{hoveredEventItem.label}</div>
                          <div className="text-gray-300">
                            {hoveredEventItem.value.toLocaleString()} events ({hoveredEventItem.percentage.toFixed(1)}%)
                          </div>
                        </div>
                      )}
                    </div>
                    {eventsChartExpanded && (
                      <div className="space-y-1 max-h-48 overflow-y-auto">
                        {eventsData.map((item) => {
                          const percentage = (item.value / totalEvents) * 100;
                          const isLocked = eventsHighlightLocked === item.label;
                          const isHighlighted = highlightedEventStatus === item.label;
                          return (
                            <div 
                              key={item.label} 
                              className={`flex items-center gap-2 text-xs p-1 rounded cursor-pointer transition-colors ${
                                isLocked || isHighlighted ? 'bg-blue-50' : 'hover:bg-gray-50'
                              }`}
                              onMouseEnter={() => {
                                if (eventsChartRef.current) {
                                  const containerRect = eventsChartRef.current.getBoundingClientRect();
                                  setHoveredEventItem({
                                    label: item.label,
                                    value: item.value,
                                    percentage,
                                    x: containerRect.width / 2,
                                    y: containerRect.height / 2
                                  });
                                  if (!eventsHighlightLocked) {
                                    setHighlightedEventStatus(item.label);
                                  }
                                }
                              }}
                              onMouseLeave={() => {
                                setHoveredEventItem(null);
                                if (!eventsHighlightLocked) {
                                  setHighlightedEventStatus(null);
                                }
                              }}
                              onClick={(e) => {
                                e.stopPropagation();
                                setEventsHighlightLocked((prev) => {
                                  const next = prev === item.label ? null : item.label;
                                  setHighlightedEventStatus(next);
                                  return next;
                                });
                              }}
                            >
                              <div 
                                className="w-3 h-3 rounded-full flex-shrink-0"
                                style={{ backgroundColor: item.color }}
                              />
                              <span className="flex-1 truncate">
                                {item.label}
                                <span className="ml-2 text-gray-700">({item.value.toLocaleString()})</span>
                              </span>
                              <span className="font-medium">{percentage.toFixed(1)}%</span>
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                );
              })()}
            </div>
          </div>

          {/* Shares by Status Pie Chart */}
          <div className="bg-white rounded-xl border border-gray-200 shadow-sm">
            <div 
              onClick={() => setSharesChartExpanded(!sharesChartExpanded)}
              className="p-4 border-b border-gray-200 flex items-center justify-between cursor-pointer hover:bg-gray-50 transition"
              title={sharesChartExpanded ? "Collapse legend" : "Expand legend"}
              role="button"
              tabIndex={0}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  e.preventDefault();
                  setSharesChartExpanded(!sharesChartExpanded);
                }
              }}
            >
              <div className="flex items-center space-x-2">
                <PieChart className="w-5 h-5 text-green-600" />
                <h3 className="text-lg font-semibold text-gray-900">Shares by Status</h3>
              </div>
              <div className="text-gray-500">
                {sharesChartExpanded ? <ChevronUp className="w-5 h-5" /> : <ChevronDown className="w-5 h-5" />}
              </div>
            </div>
            <div className="p-4">
              {(() => {
                const sharesData = [
                  { label: 'Due Now', value: stats.total_due_shares, color: '#ef4444' },
                  { label: 'Pending', value: stats.total_pending_shares, color: '#f59e0b' },
                  { label: 'Transferred', value: stats.total_transferred_shares, color: '#10b981' },
                  { label: 'Exercised', value: stats.total_exercised_shares, color: '#8b5cf6' },
                  { label: 'Vested', value: stats.total_vested_shares, color: '#06b6d4' },
                  { label: 'Forfeited/Cancelled', value: stats.total_forfeited_shares + stats.total_cancelled_shares, color: '#6b7280' },
                ].filter(d => d.value > 0);
                
                const totalShares = sharesData.reduce((sum, d) => sum + d.value, 0);
                
                if (sharesData.length === 0 || totalShares === 0) {
                  return (
                    <div className="text-center py-8 text-gray-500">
                      No shares available
                    </div>
                  );
                }

                return (
                  <div className="space-y-3">
                    <div 
                      ref={sharesChartRef} 
                      className="relative w-full h-40 flex items-center justify-center"
                      onClick={(e) => {
                        if (e.target === e.currentTarget || (e.target as HTMLElement).tagName === 'svg') {
                          setSharesHighlightLocked(null);
                          setHighlightedShareStatus(null);
                          setHoveredShareItem(null);
                        }
                      }}
                    >
                      <svg 
                        viewBox="0 0 120 120" 
                        className="w-full max-w-40 h-40 cursor-pointer"
                        onMouseLeave={() => {
                          setHoveredShareItem(null);
                          if (highlightedShareStatus && !sharesChartExpanded) {
                            setHighlightedShareStatus(null);
                          }
                        }}
                      >
                        {sharesData.map((item, index) => {
                          const startAngle = sharesData
                            .slice(0, index)
                            .reduce((sum, d) => sum + (d.value / totalShares) * 360, 0);
                          const angle = (item.value / totalShares) * 360;
                          const endAngle = startAngle + angle;

                          const startRad = (startAngle - 90) * (Math.PI / 180);
                          const endRad = (endAngle - 90) * (Math.PI / 180);

                          const x1 = 60 + 50 * Math.cos(startRad);
                          const y1 = 60 + 50 * Math.sin(startRad);
                          const x2 = 60 + 50 * Math.cos(endRad);
                          const y2 = 60 + 50 * Math.sin(endRad);

                          const largeArc = angle > 180 ? 1 : 0;
                          const percentage = (item.value / totalShares) * 100;
                          const isLocked = sharesHighlightLocked === item.label;
                          const isHighlighted = highlightedShareStatus === item.label;
                          const isDimmed = sharesHighlightLocked
                            ? !isLocked
                            : highlightedShareStatus !== null && !isHighlighted;
                          
                          return (
                            <path
                              key={item.label}
                              d={`M 60 60 L ${x1} ${y1} A 50 50 0 ${largeArc} 1 ${x2} ${y2} Z`}
                              fill={item.color}
                              stroke="white"
                              strokeWidth={isLocked || isHighlighted ? 3 : 2}
                              className="cursor-pointer"
                              style={{
                                opacity: isLocked ? 1 : isDimmed ? 0.3 : isHighlighted ? 1 : 0.8,
                                filter:
                                  isLocked || isHighlighted
                                    ? 'brightness(1.2)'
                                    : sharesHighlightLocked
                                    ? 'brightness(0.5)'
                                    : 'none',
                                transition: 'none'
                              }}
                              onMouseEnter={(e) => {
                                if (sharesChartRef.current) {
                                  const containerRect = sharesChartRef.current.getBoundingClientRect();
                                  const mouseX = e.clientX - containerRect.left;
                                  const mouseY = e.clientY - containerRect.top;
                                  if (!sharesHighlightLocked) {
                                    setHighlightedShareStatus(item.label);
                                  }
                                  setHoveredShareItem({
                                    label: item.label,
                                    value: item.value,
                                    percentage,
                                    x: mouseX,
                                    y: mouseY
                                  });
                                }
                              }}
                              onMouseLeave={() => {
                                setHoveredShareItem(null);
                                if (!sharesHighlightLocked) {
                                  setHighlightedShareStatus(null);
                                }
                              }}
                              onClick={(e) => {
                                e.stopPropagation();
                                if (sharesChartRef.current) {
                                  const containerRect = sharesChartRef.current.getBoundingClientRect();
                                  const mouseX = e.clientX - containerRect.left;
                                  const mouseY = e.clientY - containerRect.top;
                                  setHoveredShareItem({
                                    label: item.label,
                                    value: item.value,
                                    percentage,
                                    x: mouseX,
                                    y: mouseY
                                  });
                                }
                                setSharesHighlightLocked((prev) => {
                                  const next = prev === item.label ? null : item.label;
                                  setHighlightedShareStatus(next);
                                  return next;
                                });
                              }}
                            />
                          );
                        })}
                        <circle cx="60" cy="60" r="30" fill="white" />
                        {(() => {
                          const sharesText = totalShares.toLocaleString();
                          const fontSize = sharesText.length > 12 ? '9' : sharesText.length > 9 ? '10' : sharesText.length > 6 ? '11' : '12';
                          return (
                            <text x="60" y="56" textAnchor="middle" className="font-bold" fill="#111827" fontSize={fontSize}>
                              {sharesText}
                            </text>
                          );
                        })()}
                        <text x="60" y="70" textAnchor="middle" fill="#6b7280" fontSize="9">
                          Shares
                        </text>
                      </svg>
                      {hoveredShareItem && (
                        <div 
                          className="absolute z-10 bg-gray-900 text-white text-xs rounded-lg px-3 py-2 shadow-lg pointer-events-none whitespace-nowrap"
                          style={{
                            left: `${hoveredShareItem.x}px`,
                            top: `${hoveredShareItem.y - 30}px`,
                            transform: 'translateX(-50%)'
                          }}
                        >
                          <div className="font-semibold">{hoveredShareItem.label}</div>
                          <div className="text-gray-300">
                            {hoveredShareItem.value.toLocaleString()} shares ({hoveredShareItem.percentage.toFixed(1)}%)
                          </div>
                        </div>
                      )}
                    </div>
                    {sharesChartExpanded && (
                      <div className="space-y-1 max-h-48 overflow-y-auto">
                        {sharesData.map((item) => {
                          const percentage = (item.value / totalShares) * 100;
                          const isLocked = sharesHighlightLocked === item.label;
                          const isHighlighted = highlightedShareStatus === item.label;
                          return (
                            <div 
                              key={item.label} 
                              className={`flex items-center gap-2 text-xs p-1 rounded cursor-pointer transition-colors ${
                                isLocked || isHighlighted ? 'bg-blue-50' : 'hover:bg-gray-50'
                              }`}
                              onMouseEnter={() => {
                                if (sharesChartRef.current) {
                                  const containerRect = sharesChartRef.current.getBoundingClientRect();
                                  setHoveredShareItem({
                                    label: item.label,
                                    value: item.value,
                                    percentage,
                                    x: containerRect.width / 2,
                                    y: containerRect.height / 2
                                  });
                                  if (!sharesHighlightLocked) {
                                    setHighlightedShareStatus(item.label);
                                  }
                                }
                              }}
                              onMouseLeave={() => {
                                setHoveredShareItem(null);
                                if (!sharesHighlightLocked) {
                                  setHighlightedShareStatus(null);
                                }
                              }}
                              onClick={(e) => {
                                e.stopPropagation();
                                setSharesHighlightLocked((prev) => {
                                  const next = prev === item.label ? null : item.label;
                                  setHighlightedShareStatus(next);
                                  return next;
                                });
                              }}
                            >
                              <div 
                                className="w-3 h-3 rounded-full flex-shrink-0"
                                style={{ backgroundColor: item.color }}
                              />
                              <span className="flex-1 truncate">
                                {item.label}
                                <span className="ml-2 text-gray-700">({item.value.toLocaleString()})</span>
                              </span>
                              <span className="font-medium">{percentage.toFixed(1)}%</span>
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                );
              })()}
            </div>
          </div>

          {/* Due Events List */}
          <div className="bg-white rounded-xl border border-gray-200 shadow-sm">
            <div className="p-4 border-b border-gray-200 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <h3 className="text-lg font-semibold text-gray-900">Due Events</h3>
                {(() => {
                  const count = vestingEvents.filter(e => e.status === 'due').length;
                  return (
                    <span className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-red-600 text-white text-xs font-semibold">
                      {count}
                    </span>
                  );
                })()}
              </div>
              {vestingEvents.filter(e => e.status === 'due').length > 2 && (
                <button
                  onClick={() => setDueExpanded(!dueExpanded)}
                  className="text-gray-500 hover:text-gray-700 transition p-1 hover:bg-gray-100 rounded"
                  title={dueExpanded ? 'Collapse' : 'Expand'}
                  aria-label={dueExpanded ? 'Collapse' : 'Expand'}
                >
                  {dueExpanded ? <ChevronUp className="w-5 h-5" /> : <ChevronDown className="w-5 h-5" />}
                </button>
              )}
            </div>
            <div className="p-4">
              {(() => {
                const dueEvents = vestingEvents.filter(e => e.status === 'due');
                if (dueEvents.length === 0) {
                  return <div className="text-center py-8 text-gray-500">No due events</div>;
                }
                return (
                  <div className="space-y-2 max-h-64 overflow-y-auto">
                    {(dueExpanded ? dueEvents : dueEvents.slice(0, 2)).map((ev) => {
                      const idInfo = formatVestingEventId(
                        ev.id,
                        ev.sequence_number,
                        ev.vesting_date,
                        ev.grants?.grant_number ?? ev.grant_id
                      );
                      return (
                        <button
                          key={ev.id}
                          onClick={() => handleEventIdClick(ev)}
                          className="w-full text-left p-3 border border-gray-200 rounded-lg hover:bg-gray-50 hover:border-blue-300 transition"
                          title={`Open ${idInfo.displayId}`}
                        >
                          <div className="flex items-center justify-between">
                            <div>
                              <div className="text-sm font-semibold text-gray-900">{idInfo.displayId}</div>
                              <div className="text-xs text-gray-500">{ev.employee_name}</div>
                            </div>
                            <div className="text-right">
                              <div className="text-sm font-medium text-gray-900">{Math.floor(ev.shares_to_vest).toLocaleString()}</div>
                              <div className="text-xs text-gray-500">{formatDate(ev.vesting_date)}</div>
                            </div>
                          </div>
                        </button>
                      );
                    })}
                  </div>
                );
              })()}
            </div>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="bg-white rounded-xl p-6 border border-gray-200">
        <div className="flex items-center gap-4 flex-wrap">
          <Filter className="w-5 h-5 text-gray-400" />
          <div className="flex gap-4 flex-wrap">
            <select
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="all">All Statuses</option>
              <option value="pending">Pending</option>
              <option value="due">Due</option>
              <option value="vested">Vested</option>
              <option value="transferred">Transferred</option>
              <option value="exercised">Exercised</option>
            </select>

            <select
              value={selectedEventType}
              onChange={(e) => setSelectedEventType(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="all">All Types</option>
              <option value="cliff">Cliff Events</option>
              <option value="time_based">Time-Based</option>
              <option value="performance">Performance</option>
            </select>

            <button
              onClick={() => setShowEmployeeFilterModal(true)}
              className={`flex items-center space-x-2 px-4 py-2 border rounded-lg transition ${
                selectedEmployees.length > 0
                  ? 'border-blue-500 bg-blue-50 text-blue-700'
                  : 'border-gray-300 bg-white text-gray-700 hover:bg-gray-50'
              }`}
            >
              <Users className="w-4 h-4" />
              <span className="text-sm font-medium">
                {selectedEmployees.length > 0 
                  ? `Employees (${selectedEmployees.length})` 
                  : 'Filter by Employee'
                }
              </span>
            </button>

            <button
              onClick={() => setShowGrantFilterModal(true)}
              className={`flex items-center space-x-2 px-4 py-2 border rounded-lg transition ${
                selectedGrants.length > 0
                  ? 'border-green-500 bg-green-50 text-green-700'
                  : 'border-gray-300 bg-white text-gray-700 hover:bg-gray-50'
              }`}
            >
              <Award className="w-4 h-4" />
              <span className="text-sm font-medium">
                {selectedGrants.length > 0 
                  ? `Grants (${selectedGrants.length})` 
                  : 'Filter by Grant ID'
                }
              </span>
            </button>
          </div>
        </div>
        
        {/* Active Filters */}
        {(selectedEmployees.length > 0 || selectedGrants.length > 0) && (
          <div className="mt-4 flex items-center gap-2 flex-wrap">
            {selectedEmployees.length > 0 && (
              <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-blue-100 text-blue-800 rounded-lg text-sm font-medium">
                <Users className="w-4 h-4" />
                <span>
                  Employees: {selectedEmployees.length === 1 
                    ? employees.find(emp => emp.id === selectedEmployees[0])?.first_name_en + ' ' + 
                      employees.find(emp => emp.id === selectedEmployees[0])?.last_name_en
                    : `${selectedEmployees.length} selected`
                  }
                </span>
                <button
                  onClick={clearEmployeeFilter}
                  className="ml-1 hover:bg-blue-200 rounded-full p-0.5 transition"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              </div>
            )}
            
            {selectedGrants.length > 0 && (
              <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-green-100 text-green-800 rounded-lg text-sm font-medium">
                <Award className="w-4 h-4" />
                <span>
                  Grants: {selectedGrants.length === 1 
                    ? grants.find(grant => grant.id === selectedGrants[0])?.grant_number
                    : `${selectedGrants.length} selected`
                  }
                </span>
                <button
                  onClick={clearGrantFilter}
                  className="ml-1 hover:bg-green-200 rounded-full p-0.5 transition"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Vesting Events Table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Vesting Events</h3>
        </div>

        {vestingEvents.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Event ID
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Employee
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Plan
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Event Type
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Vesting Date
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Shares
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {vestingEvents.map((event) => (
                  <tr key={event.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <button
                          onClick={() => handleEventIdClick(event)}
                          className="text-sm font-medium text-blue-600 hover:text-blue-800 hover:underline cursor-pointer"
                        >
                          {formatVestingEventId(
                            event.id,
                            event.sequence_number,
                            event.vesting_date,
                            event.grants?.grant_number ?? event.grant_id
                          ).displayId}
                        </button>
                        <div className="text-sm text-gray-500 font-mono">
                          {formatVestingEventId(
                            event.id,
                            event.sequence_number,
                            event.vesting_date,
                            event.grants?.grant_number ?? event.grant_id
                          ).dateInfo}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm font-medium text-gray-900">
                          {event.employee_name}
                        </div>
                        <div className="text-sm text-gray-500">
                          Grant ID: {event.grants?.grant_number || 'N/A'}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm font-medium text-gray-900">
                          {event.plan_name}
                        </div>
                        <div className="text-sm text-gray-500">
                          {event.plan_code} • {event.plan_type}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${getEventTypeBadge(event.event_type)}`}>
                        {event.event_type.replace('_', ' ').toUpperCase()}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm text-gray-900">
                          {formatDate(event.vesting_date)}
                        </div>
                        <div className="text-sm text-gray-500">
                          {formatDaysRemaining(event.days_remaining)}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div>
                        <div className="text-sm font-medium text-gray-900">
                          {Math.floor(event.shares_to_vest).toLocaleString()}
                        </div>
                        {event.exercise_price && (
                          <div className="text-sm text-gray-500">
                            ${event.exercise_price.toFixed(2)}/share
                          </div>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusBadge(event.status)}`}>
                        {event.status.toUpperCase()}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                      <div className="flex gap-2">
                        {event.status === 'due' && (
                          <button
                            onClick={() => handleProcessEvent(event.id, 'vest')}
                            disabled={processingEvent === event.id}
                            className="text-green-600 hover:text-green-900 disabled:opacity-50"
                          >
                            Vest
                          </button>
                        )}
                        {event.status === 'vested' && event.requires_exercise && (
                          <button
                            onClick={() => handleProcessEvent(event.id, 'exercise')}
                            disabled={processingEvent === event.id}
                            className="text-purple-600 hover:text-purple-900 disabled:opacity-50"
                          >
                            Exercise
                          </button>
                        )}
                        {event.status === 'vested' && !event.requires_exercise && (
                          <button
                            onClick={() => handleProcessEvent(event.id, 'transfer')}
                            disabled={processingEvent === event.id}
                            className="text-blue-600 hover:text-blue-900 disabled:opacity-50"
                          >
                            Transfer
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="text-center py-12">
            <Award className="w-12 h-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No vesting events found</h3>
            <p className="text-gray-500">No vesting events match the current filters.</p>
          </div>
        )}
      </div>

      {/* Performance Confirmation Modal */}
      {showPerformanceModal && performanceEvent && (() => {
        const metricsForConfirmation =
          performanceEvent.grantPerformanceMetrics && performanceEvent.grantPerformanceMetrics.length > 0
            ? performanceEvent.grantPerformanceMetrics
            : performanceEvent.performanceMetric
            ? [performanceEvent.performanceMetric]
            : [];

        const allMetricsConfirmed =
          metricsForConfirmation.length === 0
            ? true
            : metricsForConfirmation.every(metric => {
                const metricId = metric?.id;
                return metricId ? Boolean(metricConfirmations[metricId]) : true;
              });

        return (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl max-w-2xl w-full shadow-lg overflow-hidden">
              <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">Confirm Performance Metric</h3>
                  <p className="text-sm text-gray-500 mt-1">
                    Review the performance criteria before vesting this event.
                  </p>
                </div>
                <button
                  onClick={() => {
                    if (!performanceProcessing) closePerformanceModal();
                  }}
                  className="text-gray-400 hover:text-gray-600 transition"
                  disabled={performanceProcessing}
                  aria-label="Close performance confirmation"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>

              <div className="px-6 py-5 space-y-4">
                {metricsForConfirmation.map(metric => {
                  const metricId = metric?.id || '';
                  const isPrimaryMetric = performanceEvent.performanceMetric?.id === metricId;
                  const metricConfirmed = metricId ? Boolean(metricConfirmations[metricId]) : true;

                  return (
                    <div key={metricId || `metric-${Math.random()}`} className="p-4 bg-gray-50 rounded-lg border border-gray-200 space-y-4">
                      <div className="flex items-center gap-3">
                        <Target className="w-5 h-5 text-blue-600" />
                        <div>
                          <h4 className="text-sm font-semibold text-gray-900">
                            {metric?.name || 'Performance Metric'}
                          </h4>
                          <p className="text-xs text-gray-500">
                            {performanceEvent.grants?.grant_number || performanceEvent.grant_id}
                            {isPrimaryMetric ? ' • Milestone Metric' : ''}
                          </p>
                        </div>
                      </div>

                      {metric?.description && (
                        <p className="text-sm text-gray-600">
                          {metric.description}
                        </p>
                      )}

                      {isPrimaryMetric && (
                        <>
                          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-sm">
                            <div className="p-3 rounded-lg border border-gray-200 bg-white">
                              <span className="text-gray-500 block text-xs uppercase tracking-wide">Target Value</span>
                              <span className="text-gray-900 font-semibold">
                                {metric?.target_value !== undefined && metric?.target_value !== null
                                  ? metric.target_value.toLocaleString()
                                  : '—'}
                                {metric?.unit_of_measure ? ` ${metric.unit_of_measure}` : ''}
                              </span>
                            </div>
                            <div className="p-3 rounded-lg border border-gray-200 bg-white">
                              <span className="text-gray-500 block text-xs uppercase tracking-wide">Current Status</span>
                              <span className="text-gray-900 font-semibold">
                                {metric?.is_achieved ? 'Achieved' : 'Pending'}
                              </span>
                            </div>
                            <div className="p-3 rounded-lg border border-gray-200 bg-white">
                              <span className="text-gray-500 block text-xs uppercase tracking-wide">Event Type</span>
                              <span className="text-gray-900 font-semibold capitalize">
                                {performanceEvent.event_type.replace('_', ' ')}
                              </span>
                            </div>
                          </div>

                          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                              <label className="block text-xs font-medium text-gray-600 mb-1">
                                Actual Value (optional)
                              </label>
                              <input
                                type="number"
                                value={performanceConfirmation.actualValue}
                                onChange={(e) =>
                                  setPerformanceConfirmation(prev => ({
                                    ...prev,
                                    actualValue: e.target.value
                                  }))
                                }
                                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
                                placeholder="Enter actual value achieved"
                                min="0"
                              />
                            </div>
                            <div>
                              <label className="block text-xs font-medium text-gray-600 mb-1">
                                Notes (optional)
                              </label>
                              <textarea
                                value={performanceConfirmation.notes}
                                onChange={(e) =>
                                  setPerformanceConfirmation(prev => ({
                                    ...prev,
                                    notes: e.target.value
                                  }))
                                }
                                rows={3}
                                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
                                placeholder="Add supporting details or links"
                              />
                            </div>
                          </div>
                        </>
                      )}

                      {metricId && (
                        <label className="flex items-start gap-3 p-3 rounded-lg border border-gray-200 cursor-pointer bg-white hover:bg-gray-50 transition">
                          <input
                            type="checkbox"
                            className="mt-1 w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                            checked={metricConfirmed}
                            onChange={(e) =>
                              setMetricConfirmations(prev => ({
                                ...prev,
                                [metricId]: e.target.checked
                              }))
                            }
                            disabled={performanceProcessing}
                          />
                          <div className="text-sm text-gray-700">
                            <span className="font-semibold text-gray-900 block">
                              Confirm metric achieved
                            </span>
                            Confirm that the required metric has been met and vesting can proceed.
                          </div>
                        </label>
                      )}
                    </div>
                  );
                })}
              </div>

              <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-200 bg-gray-50">
                <button
                  onClick={closePerformanceModal}
                  className="px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-100 transition"
                  disabled={performanceProcessing}
                >
                  Cancel
                </button>
                <button
                  onClick={handleConfirmPerformanceVest}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
                  disabled={!allMetricsConfirmed || performanceProcessing}
                >
                  {performanceProcessing ? 'Processing...' : 'Confirm & Vest'}
                </button>
              </div>
            </div>
          </div>
        );
      })()}

      {/* Transfer Confirmation Modal */}
      {showTransferModal && transferEvent && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl max-w-3xl w-full shadow-lg overflow-hidden max-h-[90vh] flex flex-col">
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
              <div>
                <h3 className="text-lg font-semibold text-gray-900">Confirm Share Transfer</h3>
                <p className="text-sm text-gray-500 mt-1">
                  Review employee portfolio and financial information before confirming the transfer.
                </p>
              </div>
              <button
                onClick={() => {
                  if (!transferProcessing) closeTransferModal();
                }}
                className="text-gray-400 hover:text-gray-600 transition"
                disabled={transferProcessing}
                aria-label="Close transfer confirmation"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto px-6 py-5">
              {loadingTransferData ? (
                <div className="flex items-center justify-center py-12">
                  <div className="text-center">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
                    <p className="text-gray-600">Loading transfer details...</p>
                  </div>
                </div>
              ) : transferData ? (
                <div className="space-y-6">
                  {/* Transfer Summary */}
                  <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                    <div className="flex items-center gap-3 mb-3">
                      <ArrowRight className="w-5 h-5 text-blue-600" />
                      <h4 className="text-sm font-semibold text-blue-900">Transfer Summary</h4>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
                      <div>
                        <span className="text-blue-700 block mb-1">From Portfolio:</span>
                        <span className="font-medium text-blue-900">
                          {transferData.fromPortfolio?.portfolio_number || 'Company Reserved'}
                        </span>
                      </div>
                      <div>
                        <span className="text-blue-700 block mb-1">To Portfolio:</span>
                        <span className="font-medium text-blue-900">
                          {transferData.toPortfolio?.portfolio_number || 'Employee Vested Portfolio'}
                        </span>
                      </div>
                      <div>
                        <span className="text-blue-700 block mb-1">Employee:</span>
                        <span className="font-medium text-blue-900">{transferEvent.employee_name}</span>
                      </div>
                      <div>
                        <span className="text-blue-700 block mb-1">Shares to Transfer:</span>
                        <span className="font-medium text-blue-900 text-lg">
                          {transferData.sharesToTransfer.toLocaleString()}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Employee Portfolio Details */}
                  <div className="border border-gray-200 rounded-lg p-4">
                    <h4 className="text-sm font-semibold text-gray-900 mb-4 flex items-center gap-2">
                      <PieChart className="w-5 h-5 text-gray-600" />
                      Employee Portfolio Details
                    </h4>
                    {transferData.employeePortfolio ? (
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                        <div>
                          <span className="text-xs text-gray-500 block mb-1">Portfolio Number</span>
                          <span className="text-sm font-medium text-gray-900">
                            {transferData.employeePortfolio.portfolio_number}
                          </span>
                        </div>
                        <div>
                          <span className="text-xs text-gray-500 block mb-1">Total Shares</span>
                          <span className="text-sm font-medium text-gray-900">
                            {Number(transferData.employeePortfolio.total_shares || 0).toLocaleString()}
                          </span>
                        </div>
                        <div>
                          <span className="text-xs text-gray-500 block mb-1">Available Shares</span>
                          <span className="text-sm font-medium text-gray-900">
                            {Number(transferData.employeePortfolio.available_shares || 0).toLocaleString()}
                          </span>
                        </div>
                        <div>
                          <span className="text-xs text-gray-500 block mb-1">After Transfer</span>
                          <span className="text-sm font-medium text-green-600">
                            {(
                              Number(transferData.employeePortfolio.total_shares || 0) + 
                              transferData.sharesToTransfer
                            ).toLocaleString()}
                          </span>
                        </div>
                      </div>
                    ) : (
                      <div className="text-sm text-amber-600 bg-amber-50 border border-amber-200 rounded p-3">
                        <AlertCircle className="w-4 h-4 inline mr-2" />
                        Employee portfolio will be created automatically during transfer.
                      </div>
                    )}
                  </div>

                  {/* Financial Information */}
                  <div className="border border-gray-200 rounded-lg p-4">
                    <h4 className="text-sm font-semibold text-gray-900 mb-4 flex items-center gap-2">
                      <DollarSign className="w-5 h-5 text-gray-600" />
                      Employee Financial Information
                    </h4>
                    {transferData.financialInfo ? (
                      <div className="space-y-3">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                          <div>
                            <span className="text-xs text-gray-500 block mb-1">Account Status</span>
                            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                              transferData.financialInfo.account_status === 'verified' 
                                ? 'bg-green-100 text-green-800' 
                                : transferData.financialInfo.account_status === 'pending'
                                ? 'bg-yellow-100 text-yellow-800'
                                : 'bg-red-100 text-red-800'
                            }`}>
                              {transferData.financialInfo.account_status?.toUpperCase() || 'NOT SET'}
                            </span>
                          </div>
                          {transferData.financialInfo.investment_account_number && (
                            <div>
                              <span className="text-xs text-gray-500 block mb-1">Investment Account Number</span>
                              <span className="text-sm font-medium text-gray-900 font-mono">
                                {transferData.financialInfo.investment_account_number}
                              </span>
                            </div>
                          )}
                          {transferData.financialInfo.broker_custodian_name && (
                            <div>
                              <span className="text-xs text-gray-500 block mb-1">Broker/Custodian</span>
                              <span className="text-sm font-medium text-gray-900">
                                {transferData.financialInfo.broker_custodian_name}
                              </span>
                            </div>
                          )}
                          {transferData.financialInfo.broker_account_number && (
                            <div>
                              <span className="text-xs text-gray-500 block mb-1">Broker Account Number</span>
                              <span className="text-sm font-medium text-gray-900 font-mono">
                                {transferData.financialInfo.broker_account_number}
                              </span>
                            </div>
                          )}
                          {transferData.financialInfo.tadawul_investor_number && (
                            <div>
                              <span className="text-xs text-gray-500 block mb-1">Tadawul Investor Number</span>
                              <span className="text-sm font-medium text-gray-900 font-mono">
                                {transferData.financialInfo.tadawul_investor_number}
                              </span>
                            </div>
                          )}
                        </div>
                        {transferData.financialInfo.account_status !== 'verified' && (
                          <div className="mt-3 text-sm text-amber-600 bg-amber-50 border border-amber-200 rounded p-3">
                            <AlertCircle className="w-4 h-4 inline mr-2" />
                            Financial account is not verified. Please verify the account before transferring shares.
                          </div>
                        )}
                      </div>
                    ) : (
                      <div className="text-sm text-amber-600 bg-amber-50 border border-amber-200 rounded p-3">
                        <AlertCircle className="w-4 h-4 inline mr-2" />
                        No financial information found for this employee. Please add financial information before transferring shares.
                      </div>
                    )}
                  </div>

                  {/* Event Details */}
                  <div className="border border-gray-200 rounded-lg p-4 bg-gray-50">
                    <h4 className="text-sm font-semibold text-gray-900 mb-3">Vesting Event Details</h4>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
                      <div>
                        <span className="text-gray-600 block mb-1">Event ID:</span>
                        <span className="font-medium text-gray-900 font-mono text-xs">
                          {formatVestingEventId(
                            transferEvent.id,
                            transferEvent.sequence_number,
                            transferEvent.vesting_date,
                            transferEvent.grants?.grant_number ?? transferEvent.grant_id
                          ).displayId}
                        </span>
                      </div>
                      <div>
                        <span className="text-gray-600 block mb-1">Grant Number:</span>
                        <span className="font-medium text-gray-900">
                          {transferEvent.grants?.grant_number || 'N/A'}
                        </span>
                      </div>
                      <div>
                        <span className="text-gray-600 block mb-1">Plan:</span>
                        <span className="font-medium text-gray-900">
                          {transferEvent.plan_name || transferEvent.plan_code || 'N/A'}
                        </span>
                      </div>
                      <div>
                        <span className="text-gray-600 block mb-1">Vesting Date:</span>
                        <span className="font-medium text-gray-900">
                          {formatDate(transferEvent.vesting_date)}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="text-center py-8 text-gray-500">
                  <AlertCircle className="w-12 h-12 mx-auto mb-3 text-gray-400" />
                  <p>Failed to load transfer details. Please try again.</p>
                </div>
              )}
            </div>

            <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-200 bg-gray-50">
              <button
                onClick={closeTransferModal}
                className="px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-100 transition"
                disabled={transferProcessing}
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmTransfer}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
                disabled={!transferData || loadingTransferData || transferProcessing || (transferData.financialInfo && transferData.financialInfo.account_status !== 'verified')}
              >
                {transferProcessing ? 'Processing...' : 'Confirm & Transfer'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Generate Vesting Events Modal */}
      {showGenerateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 max-w-2xl w-full mx-4 max-h-[80vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-gray-900">Generate Vesting Events</h3>
              <button
                onClick={() => setShowGenerateModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="mb-6">
              <p className="text-gray-600 mb-4">
                This will generate vesting events for all existing grants that don't already have vesting events.
              </p>

              {grantsWithoutEvents.length > 0 ? (
                <div>
                  <p className="text-sm font-medium text-gray-900 mb-3">
                    Grants without vesting events ({grantsWithoutEvents.length}):
                  </p>
                  <div className="max-h-60 overflow-y-auto border border-gray-200 rounded-lg">
                    <table className="w-full text-sm">
                      <thead className="bg-gray-50">
                        <tr>
                          <th className="px-3 py-2 w-12">
                            <button
                              onClick={toggleSelectAllGeneration}
                              className="flex items-center justify-center w-full text-gray-600 hover:text-gray-900 transition"
                              aria-label={isAllGenerationSelected ? 'Deselect all grants' : 'Select all grants'}
                            >
                              {isAllGenerationSelected ? (
                                <CheckSquare className="w-4 h-4" />
                              ) : (
                                <Square className="w-4 h-4" />
                              )}
                            </button>
                          </th>
                          <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase">Employee</th>
                          <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase">Grant ID</th>
                          <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase">Plan</th>
                          <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase">Shares</th>
                          <th className="px-3 py-2 text-left text-xs font-medium text-gray-500 uppercase">Start Date</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-200">
                        {grantsWithoutEvents.map((grant) => (
                          <tr key={grant.id} className="hover:bg-gray-50 transition">
                            <td className="px-3 py-2 text-gray-900 font-medium">
                              <button
                                onClick={() => toggleGrantSelectionForGeneration(grant.id)}
                                className="flex items-center justify-center w-full text-gray-600 hover:text-gray-900 transition"
                                aria-label={selectedGrantIdsForGeneration.includes(grant.id) ? 'Deselect grant' : 'Select grant'}
                              >
                                {selectedGrantIdsForGeneration.includes(grant.id) ? (
                                  <CheckSquare className="w-4 h-4 text-blue-600" />
                                ) : (
                                  <Square className="w-4 h-4" />
                                )}
                              </button>
                            </td>
                            <td className="px-3 py-2 text-gray-900">{grant.employee_name}</td>
                            <td className="px-3 py-2 text-gray-600 font-mono text-xs">
                              {grant.grant_number ? grant.grant_number : 'N/A'}
                            </td>
                            <td className="px-3 py-2 text-gray-600">{grant.plan_code}</td>
                            <td className="px-3 py-2 text-gray-900">{grant.total_shares.toLocaleString()}</td>
                            <td className="px-3 py-2 text-gray-600">
                              {formatDate(grant.vesting_start_date)}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              ) : (
                <div className="text-center py-8">
                  <CheckCircle className="w-12 h-12 text-green-500 mx-auto mb-3" />
                  <p className="text-gray-600">All grants already have vesting events!</p>
                </div>
              )}
            </div>

            <div className="flex justify-end gap-3">
              <button
                onClick={() => setShowGenerateModal(false)}
                className="px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 transition"
              >
                Cancel
              </button>
              {grantsWithoutEvents.length > 0 && (
                <button
                  onClick={handleGenerateVestingEvents}
                  disabled={generating || selectedGrantIdsForGeneration.length === 0}
                  className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition disabled:opacity-50"
                >
                  {generating ? 'Generating...' : `Generate Events for ${selectedGrantIdsForGeneration.length || 0} Grant${selectedGrantIdsForGeneration.length === 1 ? '' : 's'}`}
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Event Details Modal */}
      {showEventDetailsModal && selectedEvent && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 max-w-4xl w-full mx-4 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h3 className="text-xl font-semibold text-gray-900">
                  Vesting Event Details
                </h3>
                <p className="text-gray-600">
                  {formatVestingEventId(
                    selectedEvent.id,
                    selectedEvent.sequence_number,
                    selectedEvent.vesting_date,
                    selectedEvent.grants?.grant_number ?? selectedEvent.grant_id
                  ).displayId}
                </p>
              </div>
              <button
                onClick={() => setShowEventDetailsModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Event Information */}
              <div className="space-y-4">
                <div>
                  <h4 className="text-lg font-medium text-gray-900 mb-3">Event Information</h4>
                  <div className="space-y-3">
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Event ID:</span>
                      <span className="text-sm font-medium text-gray-900">
                        {formatVestingEventId(
                          selectedEvent.id,
                          selectedEvent.sequence_number,
                          selectedEvent.vesting_date,
                          selectedEvent.grants?.grant_number ?? selectedEvent.grant_id
                        ).displayId}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Event Type:</span>
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${getEventTypeBadge(selectedEvent.event_type)}`}>
                        {selectedEvent.event_type.replace('_', ' ').toUpperCase()}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Sequence:</span>
                      <span className="text-sm font-medium text-gray-900">
                        #{selectedEvent.sequence_number}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Status:</span>
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusBadge(selectedEvent.status)}`}>
                        {selectedEvent.status.toUpperCase()}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Vesting Date:</span>
                      <span className="text-sm font-medium text-gray-900">
                        {formatDate(selectedEvent.vesting_date)}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Days Remaining:</span>
                      <span className="text-sm font-medium text-gray-900">
                        {formatDaysRemaining(selectedEvent.days_remaining)}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Employee Information */}
                <div>
                  <h4 className="text-lg font-medium text-gray-900 mb-3">Employee</h4>
                  <div className="space-y-3">
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Name:</span>
                      <span className="text-sm font-medium text-gray-900">
                        {selectedEvent.employee_name}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Employee ID:</span>
                      <span className="text-sm font-medium text-gray-900 font-mono">
                        {selectedEvent.employee_id}
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Shares & Financial Information */}
              <div className="space-y-4">
                <div>
                  <h4 className="text-lg font-medium text-gray-900 mb-3">Shares & Financial</h4>
                  <div className="space-y-3">
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Shares to Vest:</span>
                      <span className="text-sm font-medium text-gray-900">
                        {Math.floor(selectedEvent.shares_to_vest).toLocaleString()}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Cumulative Shares:</span>
                      <span className="text-sm font-medium text-gray-900">
                        {Math.floor(selectedEvent.cumulative_shares_vested).toLocaleString()}
                      </span>
                    </div>
                    {selectedEvent.exercise_price && (
                      <>
                        <div className="flex justify-between">
                          <span className="text-sm text-gray-600">Exercise Price:</span>
                          <span className="text-sm font-medium text-gray-900">
                            ${selectedEvent.exercise_price.toFixed(2)}
                          </span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-sm text-gray-600">Total Exercise Cost:</span>
                          <span className="text-sm font-medium text-gray-900">
                            ${(selectedEvent.shares_to_vest * selectedEvent.exercise_price).toFixed(2)}
                          </span>
                        </div>
                      </>
                    )}
                    {selectedEvent.fair_market_value && (
                      <div className="flex justify-between">
                        <span className="text-sm text-gray-600">Fair Market Value:</span>
                        <span className="text-sm font-medium text-gray-900">
                          ${selectedEvent.fair_market_value.toFixed(2)}
                        </span>
                      </div>
                    )}
                  </div>
                </div>

                {/* Plan Information */}
                <div>
                  <h4 className="text-lg font-medium text-gray-900 mb-3">Plan Details</h4>
                  <div className="space-y-3">
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Plan Name:</span>
                      <span className="text-sm font-medium text-gray-900">
                        {selectedEvent.plan_name}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Plan Code:</span>
                      <span className="text-sm font-medium text-gray-900">
                        {selectedEvent.plan_code}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Plan Type:</span>
                      <span className="text-sm font-medium text-gray-900">
                        {selectedEvent.plan_type}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-sm text-gray-600">Requires Exercise:</span>
                      <span className="text-sm font-medium text-gray-900">
                        {selectedEvent.requires_exercise ? 'Yes' : 'No'}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Technical Details */}
            <div className="mt-6 pt-6 border-t border-gray-200">
              <h4 className="text-lg font-medium text-gray-900 mb-3">Technical Details</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">Grant ID:</span>
                  <span className="text-sm font-medium text-gray-900 font-mono">
                    {selectedEvent.grants?.grant_number ?? selectedEvent.grant_id}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">Event UUID:</span>
                  <span className="text-sm font-medium text-gray-900 font-mono">
                    {selectedEvent.id}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">Company ID:</span>
                  <span className="text-sm font-medium text-gray-900 font-mono">
                    {selectedEvent.company_id}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">Created:</span>
                  <span className="text-sm font-medium text-gray-900">
                    {formatDate(selectedEvent.created_at)}
                  </span>
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="mt-6 pt-6 border-t border-gray-200 flex justify-end gap-3">
              <button
                onClick={() => setShowEventDetailsModal(false)}
                className="px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 transition"
              >
                Close
              </button>
              
              {selectedEvent.status === 'due' && (
                <button
                  onClick={async () => {
                    // Check if contract is signed before processing
                    const grant = selectedEvent.grants;
                    if (!grant?.employee_acceptance_at) {
                      alert('Cannot process vesting: The employee contract has not been signed yet. The employee needs to sign the contract in order to proceed with vesting the shares and transferring them to the employee portfolio.');
                      return;
                    }
                    handleProcessEvent(selectedEvent.id, 'vest');
                    setShowEventDetailsModal(false);
                  }}
                  className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition"
                >
                  Process Vesting ({Math.floor(selectedEvent.shares_to_vest).toLocaleString()} shares)
                </button>
              )}
              
              {selectedEvent.status === 'vested' && selectedEvent.requires_exercise && (
                <button
                  onClick={() => {
                    handleProcessEvent(selectedEvent.id, 'exercise');
                    setShowEventDetailsModal(false);
                  }}
                  className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition"
                >
                  Exercise Options
                </button>
              )}
              
              {selectedEvent.status === 'vested' && !selectedEvent.requires_exercise && (
                <button
                  onClick={async () => {
                    // Check if employee has Investment Account Information before transferring
                    try {
                      const { data: financialInfo, error: financialError } = await supabase
                        .from('employee_financial_info')
                        .select('*')
                        .eq('employee_id', selectedEvent.employee_id)
                        .maybeSingle();

                      if (financialError) {
                        console.error('Error checking financial info:', financialError);
                        alert('Error checking financial information. Please try again.');
                        return;
                      }

                      // Check if financial info exists and has required Investment Account fields
                      if (!financialInfo || 
                          !financialInfo.broker_custodian_name || 
                          !financialInfo.broker_account_number || 
                          !financialInfo.tadawul_investor_number || 
                          !financialInfo.investment_account_number) {
                        alert('Cannot transfer shares: The financial information and portfolio details are missing and need to be completed in order to proceed with the share transfer. Please ensure the employee has Investment Account Information (for Share Transfers) configured.');
                        return;
                      }

                      // Check if account status is verified
                      if (financialInfo.account_status !== 'verified') {
                        alert('Cannot transfer shares: Employee financial account must be verified by a finance admin before shares can be transferred. Please verify the account first.');
                        return;
                      }

                      handleProcessEvent(selectedEvent.id, 'transfer');
                      setShowEventDetailsModal(false);
                    } catch (error) {
                      console.error('Error validating financial info:', error);
                      alert('Error validating financial information. Please try again.');
                    }
                  }}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
                >
                  Transfer Shares
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Employee Filter Modal */}
      {showEmployeeFilterModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl max-w-md w-full max-h-[80vh] flex flex-col">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-xl font-bold text-gray-900">Filter by Employee</h2>
                  <p className="text-gray-600 text-sm mt-1">Select one or more employees to filter vesting events</p>
                </div>
                <button
                  onClick={() => setShowEmployeeFilterModal(false)}
                  className="text-gray-400 hover:text-gray-600 transition"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>
            </div>

            <div className="p-6 border-b border-gray-200">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search employees..."
                  value={employeeFilterSearch}
                  onChange={(e) => setEmployeeFilterSearch(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
                />
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-6">
              <div className="space-y-2">
                {filteredEmployeesForModal.length === 0 ? (
                  <div className="text-center py-8">
                    <Users className="w-12 h-12 text-gray-400 mx-auto mb-3" />
                    <p className="text-gray-600 text-sm">No employees found</p>
                  </div>
                ) : (
                  <>
                    <div className="flex items-center justify-between mb-4">
                      <p className="text-sm text-gray-600">
                        {filteredEmployeesForModal.length} employee{filteredEmployeesForModal.length !== 1 ? 's' : ''} available
                      </p>
                      {selectedEmployees.length > 0 && (
                        <button
                          onClick={() => setSelectedEmployees([])}
                          className="text-sm text-red-600 hover:text-red-800 transition"
                        >
                          Clear all
                        </button>
                      )}
                    </div>
                    {filteredEmployeesForModal.map((employee) => {
                      const isSelected = selectedEmployees.includes(employee.id);
                      return (
                        <label
                          key={employee.id}
                          className={`flex items-center p-3 rounded-lg border cursor-pointer transition ${
                            isSelected 
                              ? 'border-blue-500 bg-blue-50' 
                              : 'border-gray-200 hover:bg-gray-50'
                          }`}
                        >
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => toggleEmployeeSelection(employee.id)}
                            className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                          />
                          <div className="ml-3 flex-1">
                            <div className="flex items-center">
                              <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0">
                                <Users className="w-4 h-4 text-blue-600" />
                              </div>
                              <div className="ml-3">
                                <div className="text-sm font-medium text-gray-900">
                                  {employee.first_name_en} {employee.last_name_en}
                                </div>
                                <div className="text-xs text-gray-500 flex items-center space-x-2">
                                  <span>{employee.employee_number}</span>
                                  {employee.department && (
                                    <>
                                      <span>•</span>
                                      <span>{employee.department}</span>
                                    </>
                                  )}
                                </div>
                              </div>
                            </div>
                          </div>
                        </label>
                      );
                    })}
                  </>
                )}
              </div>
            </div>

            <div className="p-6 border-t border-gray-200 bg-gray-50 flex items-center justify-between">
              <div className="text-sm text-gray-600">
                {selectedEmployees.length} employee{selectedEmployees.length !== 1 ? 's' : ''} selected
              </div>
              <div className="flex items-center space-x-3">
                <button
                  onClick={() => setShowEmployeeFilterModal(false)}
                  className="px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg transition text-sm"
                >
                  Cancel
                </button>
                <button
                  onClick={() => setShowEmployeeFilterModal(false)}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition text-sm font-medium"
                >
                  Apply Filter
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Grant Filter Modal */}
      {showGrantFilterModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl max-w-md w-full max-h-[80vh] flex flex-col">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-xl font-bold text-gray-900">Filter by Grant ID</h2>
                  <p className="text-gray-600 text-sm mt-1">Select one or more grants to filter vesting events</p>
                </div>
                <button
                  onClick={() => setShowGrantFilterModal(false)}
                  className="text-gray-400 hover:text-gray-600 transition"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>
            </div>

            <div className="p-6 border-b border-gray-200">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search grants..."
                  value={grantFilterSearch}
                  onChange={(e) => setGrantFilterSearch(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
                />
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-6">
              <div className="space-y-2">
                {filteredGrantsForModal.length === 0 ? (
                  <div className="text-center py-8">
                    <Award className="w-12 h-12 text-gray-400 mx-auto mb-3" />
                    <p className="text-gray-600 text-sm">No grants found</p>
                  </div>
                ) : (
                  <>
                    <div className="flex items-center justify-between mb-4">
                      <p className="text-sm text-gray-600">
                        {filteredGrantsForModal.length} grant{filteredGrantsForModal.length !== 1 ? 's' : ''} available
                      </p>
                      {selectedGrants.length > 0 && (
                        <button
                          onClick={() => setSelectedGrants([])}
                          className="text-sm text-red-600 hover:text-red-800 transition"
                        >
                          Clear all
                        </button>
                      )}
                    </div>
                    {filteredGrantsForModal.map((grant) => {
                      const isSelected = selectedGrants.includes(grant.id);
                      return (
                        <label
                          key={grant.id}
                          className={`flex items-center p-3 rounded-lg border cursor-pointer transition ${
                            isSelected 
                              ? 'border-green-500 bg-green-50' 
                              : 'border-gray-200 hover:bg-gray-50'
                          }`}
                        >
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => toggleGrantSelection(grant.id)}
                            className="w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
                          />
                          <div className="ml-3 flex-1">
                            <div className="flex items-center">
                              <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center flex-shrink-0">
                                <Award className="w-4 h-4 text-green-600" />
                              </div>
                              <div className="ml-3">
                                <div className="text-sm font-medium text-gray-900 flex items-center space-x-2">
                                  <span>{grant.grant_number}</span>
                                  <span className="inline-flex items-center justify-center w-5 h-5 bg-blue-100 text-blue-800 text-xs font-medium rounded-full">
                                    {grant.vesting_event_count || 0}
                                  </span>
                                </div>
                                <div className="text-xs text-gray-500 flex items-center space-x-2">
                                  <span>{grant.employees?.first_name_en} {grant.employees?.last_name_en}</span>
                                  <span>•</span>
                                  <span>{grant.incentive_plans?.plan_code}</span>
                                  <span>•</span>
                                  <span>{grant.total_shares.toLocaleString()} shares</span>
                                </div>
                              </div>
                            </div>
                          </div>
                        </label>
                      );
                    })}
                  </>
                )}
              </div>
            </div>

            <div className="p-6 border-t border-gray-200 bg-gray-50 flex items-center justify-between">
              <div className="text-sm text-gray-600">
                {selectedGrants.length} grant{selectedGrants.length !== 1 ? 's' : ''} selected
              </div>
              <div className="flex items-center space-x-3">
                <button
                  onClick={() => setShowGrantFilterModal(false)}
                  className="px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg transition text-sm"
                >
                  Cancel
                </button>
                <button
                  onClick={() => setShowGrantFilterModal(false)}
                  className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition text-sm font-medium"
                >
                  Apply Filter
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
