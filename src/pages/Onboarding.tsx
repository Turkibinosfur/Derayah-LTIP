import { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { generateIndividualVestingRecords } from '../lib/vestingUtils';

type StepKey = 'pool' | 'vesting_schedule' | 'plan' | 'employee' | 'grant';

const stepTitles: Record<StepKey, string> = {
  pool: 'Create Your ESOP Pool',
  vesting_schedule: 'Create a Vesting Schedule Template',
  plan: 'Create Your First Incentive Plan',
  employee: 'Add Your First Employee',
  grant: 'Issue Your First Grant',
};

const stepDescriptions: Record<StepKey, string> = {
  pool: 'Define the share pool that powers your equity program.',
  vesting_schedule: 'Design the vesting template that your grants will follow.',
  plan: 'Describe vesting rules and plan details for your ESOP.',
  employee: 'Add at least one employee who will receive a grant.',
  grant: 'Connect plan and employee to issue the first allocation.',
};

const STEP_ORDER: StepKey[] = ['pool', 'vesting_schedule', 'plan', 'employee', 'grant'];

function determineCurrentStep(progress: ReturnType<typeof useAuth>['onboardingProgress']): StepKey {
  if (!progress) return 'pool';
  if (!progress.has_pool) return 'pool';
  if (!progress.has_vesting_schedule) return 'vesting_schedule';
  if (!progress.has_plan) return 'plan';
  if (!progress.has_employee) return 'employee';
  return 'grant';
}

export default function Onboarding() {
  const {
    user,
    userRole,
    activeCompanyId,
    onboardingProgress,
    refreshOnboardingProgress,
    isOnboardingComplete,
  } = useAuth();
  const navigate = useNavigate();

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const [pools, setPools] = useState<any[]>([]);
  const [vestingSchedules, setVestingSchedules] = useState<any[]>([]);
  const [plans, setPlans] = useState<any[]>([]);
  const [employees, setEmployees] = useState<any[]>([]);

  const [poolName, setPoolName] = useState('');
  const [poolShares, setPoolShares] = useState('');
  const [poolType, setPoolType] = useState('general');

  const [planName, setPlanName] = useState('');
  const [planShares, setPlanShares] = useState('');
  const [planDurationMonths, setPlanDurationMonths] = useState(48);
  const [planCliffMonths, setPlanCliffMonths] = useState(12);
  const [selectedPoolId, setSelectedPoolId] = useState<string | null>(null);
  const [selectedScheduleId, setSelectedScheduleId] = useState<string | null>(null);

  const [employeeFirstName, setEmployeeFirstName] = useState('');
  const [employeeLastName, setEmployeeLastName] = useState('');
  const [employeeEmail, setEmployeeEmail] = useState('');
  const [employeeNumber, setEmployeeNumber] = useState('');
  const [employeeNationalId, setEmployeeNationalId] = useState('');
  const [employeeJobTitle, setEmployeeJobTitle] = useState('');
  const [employeeDepartment, setEmployeeDepartment] = useState('');

  const [selectedPlanId, setSelectedPlanId] = useState<string | null>(null);
  const [selectedEmployeeId, setSelectedEmployeeId] = useState<string | null>(null);
  const [grantShares, setGrantShares] = useState('');
  const [grantStartDate, setGrantStartDate] = useState(() => new Date().toISOString().slice(0, 10));

  const [scheduleName, setScheduleName] = useState('');
  const [scheduleDescription, setScheduleDescription] = useState('');
  const [scheduleType, setScheduleType] = useState<'time_based' | 'performance_based' | 'hybrid'>('time_based');
  const [scheduleDurationMonths, setScheduleDurationMonths] = useState(48);
  const [scheduleCliffMonths, setScheduleCliffMonths] = useState(12);
  const [scheduleFrequency, setScheduleFrequency] = useState<'monthly' | 'quarterly' | 'annually'>('monthly');

  const recommendedStep = useMemo(
    () => determineCurrentStep(onboardingProgress),
    [onboardingProgress]
  );
  const [activeStep, setActiveStep] = useState<StepKey>(recommendedStep);

  const isStepCompleted = useCallback(
    (step: StepKey) => {
      if (!onboardingProgress) return false;
      switch (step) {
        case 'pool':
          return onboardingProgress.has_pool;
        case 'vesting_schedule':
          return onboardingProgress.has_vesting_schedule;
        case 'plan':
          return onboardingProgress.has_plan;
        case 'employee':
          return onboardingProgress.has_employee;
        case 'grant':
          return onboardingProgress.has_grant;
        default:
          return false;
      }
    },
    [onboardingProgress]
  );

  useEffect(() => {
    setActiveStep((previous) => {
      if (!onboardingProgress) {
        return previous;
      }
      if (!isStepCompleted(previous)) {
        return previous;
      }
      return recommendedStep;
    });
  }, [onboardingProgress, recommendedStep, isStepCompleted]);

  const companyContextId = useMemo(
    () => activeCompanyId ?? onboardingProgress?.company_id ?? null,
    [activeCompanyId, onboardingProgress?.company_id]
  );

  useEffect(() => {
    if (!user) {
      navigate('/login');
      return;
    }

    if (userRole?.role !== 'super_admin' && userRole?.user_type === 'employee') {
      navigate('/employee/dashboard');
    }
  }, [user, userRole, navigate]);

  useEffect(() => {
    if (isOnboardingComplete()) {
      navigate('/dashboard');
    }
  }, [navigate, onboardingProgress, isOnboardingComplete]);

  const loadReferenceData = useCallback(async () => {
    if (!companyContextId) return;

    const [
      { data: poolRows, error: poolsError } = { data: [], error: null },
      { data: vestingScheduleRows, error: schedulesError } = { data: [], error: null },
      { data: planRows, error: plansError } = { data: [], error: null },
      { data: employeeRows, error: employeesError } = { data: [], error: null },
    ] = await Promise.all([
      supabase
        .from('ltip_pools')
        .select('id, pool_name_en, total_shares_allocated, pool_type')
        .eq('company_id', companyContextId)
        .order('created_at', { ascending: true }),
      supabase
        .from('vesting_schedules')
        .select('id, name, schedule_type, total_duration_months, cliff_months, vesting_frequency, is_template')
        .eq('company_id', companyContextId)
        .eq('is_template', true)
        .order('created_at', { ascending: true }),
      supabase
        .from('incentive_plans')
        .select(
          'id, plan_name_en, plan_code, total_shares_allocated, shares_granted, shares_available, status, vesting_config, vesting_schedule_template_id'
        )
        .eq('company_id', companyContextId)
        .order('created_at', { ascending: true }),
      supabase
        .from('employees')
        .select('id, first_name_en, last_name_en, email, employee_number')
        .eq('company_id', companyContextId)
        .order('created_at', { ascending: true }),
    ]);

    if (poolsError) console.error('Error loading pools during onboarding:', poolsError);
    if (schedulesError) console.error('Error loading vesting schedules during onboarding:', schedulesError);
    if (plansError) console.error('Error loading plans during onboarding:', plansError);
    if (employeesError) console.error('Error loading employees during onboarding:', employeesError);

    const poolList = poolRows ?? [];
    const vestingScheduleList = vestingScheduleRows ?? [];
    const planList = planRows ?? [];
    const employeeList = employeeRows ?? [];

    setPools(poolList);
    setVestingSchedules(vestingScheduleList);
    setPlans(planList);
    setEmployees(employeeList);

    if ((!selectedPoolId || !poolList.some((pool) => pool.id === selectedPoolId)) && poolList.length > 0) {
      setSelectedPoolId(poolList[0].id);
    }

    if (
      (!selectedScheduleId || !vestingScheduleList.some((schedule) => schedule.id === selectedScheduleId)) &&
      vestingScheduleList.length > 0
    ) {
      setSelectedScheduleId(vestingScheduleList[0].id);
    }

    if ((!selectedPlanId || !planList.some((plan) => plan.id === selectedPlanId)) && planList.length > 0) {
      setSelectedPlanId(planList[0].id);
    }

    if (
      (!selectedEmployeeId || !employeeList.some((employee) => employee.id === selectedEmployeeId)) &&
      employeeList.length > 0
    ) {
      setSelectedEmployeeId(employeeList[0].id);
    }
  }, [
    companyContextId,
    selectedPoolId,
    selectedScheduleId,
    selectedPlanId,
    selectedEmployeeId,
  ]);

  useEffect(() => {
    loadReferenceData();
  }, [loadReferenceData]);

  useEffect(() => {
    if (!selectedScheduleId) return;
    const schedule = vestingSchedules.find((item) => item.id === selectedScheduleId);
    if (!schedule) return;

    if (schedule.total_duration_months && schedule.total_duration_months !== planDurationMonths) {
      setPlanDurationMonths(schedule.total_duration_months);
    }

    if (
      typeof schedule.cliff_months === 'number' &&
      schedule.cliff_months >= 0 &&
      schedule.cliff_months !== planCliffMonths
    ) {
      setPlanCliffMonths(schedule.cliff_months);
    }
  }, [selectedScheduleId, vestingSchedules, planDurationMonths, planCliffMonths]);

  const handleAfterAction = async (step: StepKey, message: string) => {
    const { error: rpcError } = await supabase.rpc('complete_company_onboarding_step', { p_step: step });
    if (rpcError) {
      throw rpcError;
    }
    await refreshOnboardingProgress();
    await loadReferenceData();
    setError(null);
    setSuccessMessage(message);
  };

  const handleCreatePool = async () => {
    if (!companyContextId) {
      throw new Error('Company context not available');
    }

    if (!poolName.trim() || !poolShares.trim()) {
      throw new Error('Pool name and share amount are required');
    }

    const poolCode = `POOL-${Date.now()}`;
    const totalShares = Number(poolShares);

    if (Number.isNaN(totalShares) || totalShares <= 0) {
      throw new Error('Total shares must be a positive number');
    }

    const { error: insertError } = await supabase.from('ltip_pools').insert({
      company_id: companyContextId,
      pool_name_en: poolName.trim(),
      pool_name_ar: poolName.trim(),
      pool_code: poolCode,
      total_shares_allocated: totalShares,
      pool_type: poolType,
      status: 'active',
    });

    if (insertError) {
      throw insertError;
    }

    setPoolName('');
    setPoolShares('');
    await handleAfterAction('pool', 'ESOP pool created successfully!');
  };

  const handleCreateVestingSchedule = async () => {
    if (!companyContextId) {
      throw new Error('Company context not available');
    }

    if (!scheduleName.trim()) {
      throw new Error('Schedule name is required');
    }

    const { data: insertedSchedule, error: insertError } = await supabase
      .from('vesting_schedules')
      .insert({
        company_id: companyContextId,
        name: scheduleName.trim(),
        description: scheduleDescription.trim() || null,
        schedule_type: scheduleType,
        total_duration_months: scheduleDurationMonths,
        cliff_months: scheduleCliffMonths,
        vesting_frequency: scheduleFrequency,
        is_template: true,
      })
      .select('id')
      .single();

    if (insertError) {
      throw insertError;
    }

    if (insertedSchedule?.id) {
      setSelectedScheduleId(insertedSchedule.id);
    }

    setScheduleName('');
    setScheduleDescription('');
    setScheduleType('time_based');
    setScheduleDurationMonths(48);
    setScheduleCliffMonths(12);
    setScheduleFrequency('monthly');

    await handleAfterAction('vesting_schedule', 'Vesting schedule template created successfully!');
  };

  const handleCreatePlan = async () => {
    if (!companyContextId) {
      throw new Error('Company context not available');
    }

    if (!planName.trim() || !planShares.trim()) {
      throw new Error('Plan name and allocated shares are required');
    }

    if (!selectedPoolId) {
      throw new Error('Select an ESOP pool before creating a plan');
    }

    if (!selectedScheduleId) {
      throw new Error('Select a vesting schedule template before creating a plan');
    }

    const totalShares = Number(planShares);

    if (Number.isNaN(totalShares) || totalShares <= 0) {
      throw new Error('Total shares must be a positive number');
    }

    const selectedSchedule = vestingSchedules.find((schedule) => schedule.id === selectedScheduleId);

    const vestingConfig = {
      totalMonths: planDurationMonths,
      cliffMonths: planCliffMonths,
      frequency: selectedSchedule?.vesting_frequency ?? 'monthly',
      type: (selectedSchedule?.schedule_type ?? 'time_based') === 'time_based' ? 'standard' : selectedSchedule?.schedule_type,
    };

    const { data: insertedPlan, error: insertError } = await supabase
      .from('incentive_plans')
      .insert({
        company_id: companyContextId,
        plan_name_en: planName.trim(),
        plan_name_ar: planName.trim(),
        plan_type: 'ESOP',
        plan_code: `PLAN-${Date.now()}`,
        description_en: 'Created via onboarding wizard',
        description_ar: 'تم الإنشاء عبر معالج البدء السريع',
        vesting_schedule_type: selectedSchedule?.schedule_type ?? 'time_based',
        vesting_config: vestingConfig,
        total_shares_allocated: totalShares,
        shares_available: totalShares,
        start_date: new Date().toISOString().slice(0, 10),
        status: 'draft',
        approval_status: 'pending',
        ltip_pool_id: selectedPoolId,
        vesting_schedule_template_id: selectedScheduleId,
      })
      .select('id')
      .single();

    if (insertError) {
      throw insertError;
    }

    if (insertedPlan?.id) {
      setSelectedPlanId(insertedPlan.id);
    }

    setPlanName('');
    setPlanShares('');
    await handleAfterAction('plan', 'Incentive plan created successfully!');
  };

  const handleCreateEmployee = async () => {
    if (!companyContextId) {
      throw new Error('Company context not available');
    }

    if (
      !employeeFirstName.trim() ||
      !employeeLastName.trim() ||
      !employeeEmail.trim() ||
      !employeeNumber.trim() ||
      !employeeNationalId.trim()
    ) {
      throw new Error('All required employee fields must be filled');
    }

    const { error: insertError } = await supabase.from('employees').insert({
      company_id: companyContextId,
      employee_number: employeeNumber.trim(),
      national_id: employeeNationalId.trim(),
      email: employeeEmail.trim(),
      phone: null,
      first_name_en: employeeFirstName.trim(),
      last_name_en: employeeLastName.trim(),
      first_name_ar: employeeFirstName.trim(),
      last_name_ar: employeeLastName.trim(),
      department: employeeDepartment.trim() || null,
      job_title: employeeJobTitle.trim() || null,
      hire_date: new Date().toISOString().slice(0, 10),
    });

    if (insertError) {
      throw insertError;
    }

    setEmployeeFirstName('');
    setEmployeeLastName('');
    setEmployeeEmail('');
    setEmployeeNumber('');
    setEmployeeNationalId('');
    setEmployeeJobTitle('');
    setEmployeeDepartment('');

    await handleAfterAction('employee', 'Employee added successfully!');
  };

  const handleCreateGrant = async () => {
    if (!companyContextId) {
      throw new Error('Company context not available');
    }

    if (!onboardingProgress?.has_vesting_schedule) {
      throw new Error('Complete the vesting schedule step before creating a grant.');
    }

    if (!selectedPlanId || !selectedEmployeeId) {
      throw new Error('Select both a plan and an employee to continue');
    }

    const selectedPlan = plans.find((plan) => plan.id === selectedPlanId);

    if (!selectedPlan) {
      throw new Error('Selected plan could not be found');
    }

    const totalShares = Number(grantShares);

    if (Number.isNaN(totalShares) || totalShares <= 0) {
      throw new Error('Grant shares must be a positive number');
    }

    const baseSharesAvailable = Number(
      selectedPlan.shares_available ?? selectedPlan.total_shares_allocated ?? 0
    );
    const currentSharesGranted = Number(selectedPlan.shares_granted ?? 0);
    const planSharesAvailable =
      selectedPlan.shares_available == null
        ? baseSharesAvailable - currentSharesGranted
        : baseSharesAvailable;

    if (planSharesAvailable < totalShares) {
      throw new Error('Not enough shares available in the selected plan');
    }

    const startDate = grantStartDate || new Date().toISOString().slice(0, 10);
    const start = new Date(startDate);
    const durationMonths =
      selectedPlan?.vesting_config?.totalMonths ??
      selectedPlan?.vesting_config?.durationMonths ??
      planDurationMonths;
    const end = new Date(start);
    end.setMonth(end.getMonth() + durationMonths);

    const grantNumber = `GR-${start.getFullYear()}-${Math.floor(100000 + Math.random() * 900000)}`;

    const { data: grantInsert, error: insertError } = await supabase
      .from('grants')
      .insert({
        grant_number: grantNumber,
        company_id: companyContextId,
        plan_id: selectedPlanId,
        employee_id: selectedEmployeeId,
        grant_date: startDate,
        total_shares: totalShares,
        vesting_start_date: startDate,
        vesting_end_date: end.toISOString().slice(0, 10),
        status: 'active',
      })
      .select('id');

    if (insertError) {
      throw insertError;
    }

    const newGrant = grantInsert?.[0];

    const nextSharesGranted = currentSharesGranted + totalShares;
    const nextSharesAvailable = baseSharesAvailable - totalShares;

    await supabase
      .from('incentive_plans')
      .update({
        shares_granted: nextSharesGranted,
        shares_available: nextSharesAvailable,
      })
      .eq('id', selectedPlanId);

    if (newGrant?.id && selectedPlan.vesting_schedule_template_id) {
      try {
        await generateIndividualVestingRecords(newGrant.id, selectedPlan.vesting_schedule_template_id);
      } catch (error) {
        console.error('Error generating vesting records during onboarding:', error);
      }
    }

    setGrantShares('');

    await handleAfterAction('grant', 'Grant created successfully! You are all set.');
  };

  const handleSubmit = async () => {
    setLoading(true);
    setError(null);
    setSuccessMessage(null);

    try {
      switch (activeStep) {
        case 'pool':
          await handleCreatePool();
          break;
        case 'vesting_schedule':
          await handleCreateVestingSchedule();
          break;
        case 'plan':
          await handleCreatePlan();
          break;
        case 'employee':
          await handleCreateEmployee();
          break;
        case 'grant':
          await handleCreateGrant();
          break;
        default:
          break;
      }
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const renderStepContent = () => {
    switch (activeStep) {
      case 'pool':
        return (
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Pool Name</label>
              <input
                type="text"
                value={poolName}
                onChange={(e) => setPoolName(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                placeholder="2025 Employee ESOP Pool"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Total Shares</label>
              <input
                type="number"
                value={poolShares}
                onChange={(e) => setPoolShares(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                placeholder="5000000"
                min="1"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Pool Type</label>
              <select
                value={poolType}
                onChange={(e) => setPoolType(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              >
                <option value="general">General</option>
                <option value="employee">Employee</option>
                <option value="executive">Executive</option>
                <option value="retention">Retention</option>
                <option value="performance">Performance</option>
              </select>
            </div>
          </>
        );
      case 'vesting_schedule':
        return (
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Schedule Name</label>
              <input
                type="text"
                value={scheduleName}
                onChange={(e) => setScheduleName(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                placeholder="Standard 4-Year Vesting"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Description (optional)</label>
              <textarea
                value={scheduleDescription}
                onChange={(e) => setScheduleDescription(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                rows={3}
                placeholder="Outline any special notes about this schedule"
              />
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Schedule Type</label>
                <select
                  value={scheduleType}
                  onChange={(e) => setScheduleType(e.target.value as typeof scheduleType)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                >
                  <option value="time_based">Time-Based</option>
                  <option value="performance_based">Performance-Based</option>
                  <option value="hybrid">Hybrid</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Vesting Frequency</label>
                <select
                  value={scheduleFrequency}
                  onChange={(e) => setScheduleFrequency(e.target.value as typeof scheduleFrequency)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                >
                  <option value="monthly">Monthly</option>
                  <option value="quarterly">Quarterly</option>
                  <option value="annually">Annually</option>
                </select>
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Total Duration (months)</label>
                <input
                  type="number"
                  value={scheduleDurationMonths}
                  onChange={(e) => setScheduleDurationMonths(Number(e.target.value))}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  min="1"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Cliff (months)</label>
                <input
                  type="number"
                  value={scheduleCliffMonths}
                  onChange={(e) => setScheduleCliffMonths(Number(e.target.value))}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  min="0"
                />
              </div>
            </div>
          </>
        );
      case 'plan':
        return (
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Select Vesting Schedule Template</label>
              <select
                value={selectedScheduleId ?? ''}
                onChange={(e) => setSelectedScheduleId(e.target.value || null)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Choose a template</option>
                {vestingSchedules.map((schedule) => (
                  <option key={schedule.id} value={schedule.id}>
                    {schedule.name} • {schedule.total_duration_months} months • {schedule.vesting_frequency}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Select ESOP Pool</label>
              <select
                value={selectedPoolId ?? ''}
                onChange={(e) => setSelectedPoolId(e.target.value || null)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Choose a pool</option>
                {pools.map((pool) => (
                  <option key={pool.id} value={pool.id}>
                    {pool.pool_name_en} ({Number(pool.total_shares_allocated ?? 0).toLocaleString()} shares)
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Plan Name</label>
              <input
                type="text"
                value={planName}
                onChange={(e) => setPlanName(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                placeholder="ESOP 2025 Plan"
              />
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Allocated Shares</label>
                <input
                  type="number"
                  value={planShares}
                  onChange={(e) => setPlanShares(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  placeholder="1000000"
                  min="1"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Vesting Duration (months)</label>
                <input
                  type="number"
                  value={planDurationMonths}
                  onChange={(e) => setPlanDurationMonths(Number(e.target.value))}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  min="1"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Cliff (months)</label>
                <input
                  type="number"
                  value={planCliffMonths}
                  onChange={(e) => setPlanCliffMonths(Number(e.target.value))}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  min="0"
                />
              </div>
            </div>
          </>
        );
      case 'employee':
        return (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">First Name</label>
                <input
                  type="text"
                  value={employeeFirstName}
                  onChange={(e) => setEmployeeFirstName(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Last Name</label>
                <input
                  type="text"
                  value={employeeLastName}
                  onChange={(e) => setEmployeeLastName(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Email</label>
              <input
                type="email"
                value={employeeEmail}
                onChange={(e) => setEmployeeEmail(e.target.value)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                placeholder="employee@company.com"
              />
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Employee Number</label>
                <input
                  type="text"
                  value={employeeNumber}
                  onChange={(e) => setEmployeeNumber(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  placeholder="EMP-0001"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">National ID</label>
                <input
                  type="text"
                  value={employeeNationalId}
                  onChange={(e) => setEmployeeNationalId(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  placeholder="1010123456"
                />
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Job Title (optional)</label>
                <input
                  type="text"
                  value={employeeJobTitle}
                  onChange={(e) => setEmployeeJobTitle(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Department (optional)</label>
                <input
                  type="text"
                  value={employeeDepartment}
                  onChange={(e) => setEmployeeDepartment(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>
          </>
        );
      case 'grant':
      default:
        return (
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Select Plan</label>
              <select
                value={selectedPlanId ?? ''}
                onChange={(e) => setSelectedPlanId(e.target.value || null)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Choose a plan</option>
                {plans.map((plan) => (
                  <option key={plan.id} value={plan.id}>
                    {plan.plan_name_en} ({Number(plan.total_shares_allocated ?? 0).toLocaleString()} shares)
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Select Employee</label>
              <select
                value={selectedEmployeeId ?? ''}
                onChange={(e) => setSelectedEmployeeId(e.target.value || null)}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Choose an employee</option>
                {employees.map((employee) => (
                  <option key={employee.id} value={employee.id}>
                    {employee.first_name_en} {employee.last_name_en} ({employee.employee_number})
                  </option>
                ))}
              </select>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Grant Shares</label>
                <input
                  type="number"
                  value={grantShares}
                  onChange={(e) => setGrantShares(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  placeholder="10000"
                  min="1"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Vesting Start Date</label>
                <input
                  type="date"
                  value={grantStartDate}
                  onChange={(e) => setGrantStartDate(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>
          </>
        );
    }
  };

  const completedStepsCount = useMemo(() => {
    if (!onboardingProgress) return 0;
    return STEP_ORDER.filter((step) => isStepCompleted(step)).length;
  }, [onboardingProgress, isStepCompleted]);

  return (
    <div className="min-h-screen bg-slate-50 py-12 px-4">
      <div className="max-w-5xl mx-auto">
        <div className="mb-10">
          <h1 className="text-3xl font-bold text-gray-900">Welcome to Your Equity Studio</h1>
          <p className="text-gray-600 mt-2">
            Follow these five guided steps to configure your ESOP workspace. Finish the wizard to unlock
            the full company dashboard.
          </p>
        </div>

        <div className="bg-white rounded-2xl shadow-lg p-8 mb-8">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-blue-600 uppercase tracking-wide">Onboarding Progress</p>
              <h2 className="text-2xl font-semibold text-gray-900 mt-1">{stepTitles[activeStep]}</h2>
              <p className="text-gray-600 mt-2 max-w-2xl">{stepDescriptions[activeStep]}</p>
            </div>
            <div className="ml-6">
              <div className="relative">
                <svg className="w-16 h-16 text-blue-100" viewBox="0 0 100 100">
                  <circle className="text-blue-100" stroke="currentColor" strokeWidth="10" fill="none" cx="50" cy="50" r="40" />
                  <circle
                    className="text-blue-600"
                    stroke="currentColor"
                    strokeWidth="10"
                    strokeLinecap="round"
                    fill="none"
                    cx="50"
                    cy="50"
                    r="40"
                    strokeDasharray={`${(completedStepsCount / STEP_ORDER.length) * 251} 1000`}
                    transform="rotate(-90 50 50)"
                  />
                </svg>
                <span className="absolute inset-0 flex items-center justify-center text-xl font-semibold text-blue-700">
                  {completedStepsCount}/{STEP_ORDER.length}
                </span>
              </div>
            </div>
          </div>

          <div className="mt-8 grid grid-cols-1 md:grid-cols-5 gap-4">
            {STEP_ORDER.map((step) => {
              const isCompleted = isStepCompleted(step);
              const isCurrent = step === activeStep;

              return (
                <div
                  key={step}
                  role="button"
                  tabIndex={0}
                  onClick={() => setActiveStep(step)}
                  onKeyDown={(event) => {
                    if (event.key === 'Enter' || event.key === ' ') {
                      event.preventDefault();
                      setActiveStep(step);
                    }
                  }}
                  className={`p-4 border rounded-xl transition-shadow focus:outline-none focus:ring-2 focus:ring-blue-400 ${
                    isCompleted ? 'border-green-200 bg-green-50' : isCurrent ? 'border-blue-200 bg-blue-50' : 'border-slate-200'
                  } ${isCurrent ? 'shadow-md cursor-pointer' : 'cursor-pointer hover:shadow-md'}`}
                >
                  <p className="text-sm font-medium text-gray-500 uppercase">{`Step ${STEP_ORDER.indexOf(step) + 1}`}</p>
                  <p className="mt-2 font-semibold text-gray-900">{stepTitles[step]}</p>
                  <div className="mt-4">
                    {isCompleted ? (
                      <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-700">
                        Completed
                      </span>
                    ) : isCurrent ? (
                      <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-700">
                        In progress
                      </span>
                    ) : (
                      <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-slate-100 text-slate-500">
                        Pending
                      </span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        <div className="bg-white rounded-2xl shadow-lg p-8">
          {error && (
            <div className="mb-6 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-red-700">
              {error}
            </div>
          )}
          {successMessage && (
            <div className="mb-6 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-green-700">
              {successMessage}
            </div>
          )}

          <div className="space-y-6">{renderStepContent()}</div>

          <div className="mt-8 flex items-center justify-between">
            <button
              type="button"
              className="text-sm font-medium text-gray-500 hover:text-gray-700"
              onClick={() => navigate('/dashboard')}
            >
              Skip for now
            </button>
            <button
              type="button"
              onClick={handleSubmit}
              disabled={loading}
              className="inline-flex items-center px-6 py-3 rounded-lg bg-blue-600 text-white font-medium hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Saving...' : activeStep === 'grant' ? 'Finish Setup' : 'Save and Continue'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}


