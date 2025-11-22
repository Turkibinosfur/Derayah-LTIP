import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../lib/supabase';
import { Calendar, Plus, Edit, Trash2, Clock, TrendingUp, Zap, CheckCircle } from 'lucide-react';

interface VestingSchedule {
  id: string;
  company_id: string;
  name: string;
  description: string | null;
  schedule_type: 'time_based' | 'performance_based' | 'hybrid';
  total_duration_months: number;
  cliff_months: number;
  vesting_frequency: 'monthly' | 'quarterly' | 'annually';
  is_template: boolean;
  created_at: string;
  milestones?: VestingMilestone[];
}

interface VestingMilestone {
  id?: string;
  vesting_schedule_id?: string;
  milestone_type: 'time' | 'performance' | 'hybrid';
  sequence_order: number;
  vesting_percentage: number;
  months_from_start: number | null;
  performance_metric_id: string | null;
  target_value: number | null;
}

interface PerformanceMetric {
  id: string;
  name: string;
  description: string | null;
  metric_type: 'financial' | 'operational' | 'personal';
  unit_of_measure: string;
}

export default function VestingSchedules() {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';
  const [schedules, setSchedules] = useState<VestingSchedule[]>([]);
  const [metrics, setMetrics] = useState<PerformanceMetric[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showViewModal, setShowViewModal] = useState(false);
  const [selectedSchedule, setSelectedSchedule] = useState<VestingSchedule | null>(null);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState<string | null>(null);

  // Helper function to truncate description to first 5 words
  const truncateDescription = (description: string | null, maxWords: number = 5): string => {
    if (!description) return '';
    const words = description.split(' ');
    if (words.length <= maxWords) return description;
    return words.slice(0, maxWords).join(' ') + '...';
  };

  const [newSchedule, setNewSchedule] = useState({
    name: '',
    description: '',
    schedule_type: 'time_based' as 'time_based' | 'performance_based' | 'hybrid',
    total_duration_months: 48,
    cliff_months: 12,
    vesting_frequency: 'monthly' as 'monthly' | 'quarterly' | 'annually',
    is_template: true,
  });

  const [milestones, setMilestones] = useState<VestingMilestone[]>([]);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: companyUser } = await supabase
        .from('company_users')
        .select('company_id')
        .eq('user_id', user.id)
        .single();

      if (!companyUser) return;

      const [schedulesResult, metricsResult] = await Promise.all([
        supabase
          .from('vesting_schedules')
          .select('*')
          .eq('company_id', companyUser.company_id)
          .order('created_at', { ascending: false }),
        supabase
          .from('performance_metrics')
          .select('*')
          .eq('company_id', companyUser.company_id)
          .order('name', { ascending: true })
      ]);

      if (schedulesResult.data) setSchedules(schedulesResult.data);
      if (metricsResult.data) setMetrics(metricsResult.data);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const generateDefaultMilestones = () => {
    const totalMonths = newSchedule.total_duration_months;
    const cliffMonths = newSchedule.cliff_months;
    const frequency = newSchedule.vesting_frequency === 'monthly' ? 1 :
                     newSchedule.vesting_frequency === 'quarterly' ? 3 : 12;
    
    // Use the schedule_type to determine milestone_type
    const milestoneType = newSchedule.schedule_type === 'time_based' ? 'time' :
                         newSchedule.schedule_type === 'performance_based' ? 'performance' :
                         'hybrid';

    const milestones: VestingMilestone[] = [];
    let order = 0;

    if (cliffMonths > 0) {
      milestones.push({
        milestone_type: milestoneType,
        sequence_order: order++,
        vesting_percentage: 25,
        months_from_start: cliffMonths,
        performance_metric_id: null,
        target_value: null,
      });
    }

    const remainingMonths = totalMonths - cliffMonths;
    const periods = Math.floor(remainingMonths / frequency);
    const percentagePerPeriod = 75 / periods;

    for (let i = 1; i <= periods; i++) {
      milestones.push({
        milestone_type: milestoneType,
        sequence_order: order++,
        vesting_percentage: percentagePerPeriod,
        months_from_start: cliffMonths + (i * frequency),
        performance_metric_id: null,
        target_value: null,
      });
    }

    setMilestones(milestones);
  };

  const handleCreateSchedule = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: companyUser } = await supabase
        .from('company_users')
        .select('company_id')
        .eq('user_id', user.id)
        .single();

      if (!companyUser) return;

      const { data: schedule, error: scheduleError } = await supabase
        .from('vesting_schedules')
        .insert({
          company_id: companyUser.company_id,
          ...newSchedule,
        })
        .select()
        .single();

      if (scheduleError) throw scheduleError;

      // If no milestones were manually added, auto-generate them
      let milestonesToSave = [...milestones];
      if (milestonesToSave.length === 0) {
        const totalMonths = newSchedule.total_duration_months;
        const cliffMonths = newSchedule.cliff_months;
        const frequency = newSchedule.vesting_frequency === 'monthly' ? 1 :
                         newSchedule.vesting_frequency === 'quarterly' ? 3 : 12;
        
        // Use the schedule_type to determine milestone_type
        const milestoneType = newSchedule.schedule_type === 'time_based' ? 'time' :
                             newSchedule.schedule_type === 'performance_based' ? 'performance' :
                             'hybrid';

        let order = 0;

        if (cliffMonths > 0) {
          milestonesToSave.push({
            milestone_type: milestoneType,
            sequence_order: order++,
            vesting_percentage: 25,
            months_from_start: cliffMonths,
            performance_metric_id: null,
            target_value: null,
          });
        }

        const remainingMonths = totalMonths - cliffMonths;
        const periods = Math.floor(remainingMonths / frequency);
        const percentagePerPeriod = 75 / periods;

        for (let i = 1; i <= periods; i++) {
          milestonesToSave.push({
            milestone_type: milestoneType,
            sequence_order: order++,
            vesting_percentage: percentagePerPeriod,
            months_from_start: cliffMonths + (i * frequency),
            performance_metric_id: null,
            target_value: null,
          });
        }
      }

      if (schedule && milestonesToSave.length > 0) {
        const milestonesWithScheduleId = milestonesToSave.map(m => ({
          ...m,
          vesting_schedule_id: schedule.id,
        }));

        const { error: milestonesError } = await supabase
          .from('vesting_milestones')
          .insert(milestonesWithScheduleId);

        if (milestonesError) throw milestonesError;
      }

      setShowCreateModal(false);
      resetForm();
      loadData();
    } catch (error) {
      console.error('Error creating schedule:', error);
      alert('Failed to create vesting schedule');
    }
  };

  const handleViewSchedule = (schedule: VestingSchedule) => {
    setSelectedSchedule(schedule);
    setShowViewModal(true);
  };

  const handleDeleteSchedule = async (id: string) => {
    try {
      console.log('🗑️ Attempting to delete vesting schedule:', id);
      
      // First, check if we can see the schedule
      const { data: schedule, error: checkError } = await supabase
        .from('vesting_schedules')
        .select('id, name, company_id')
        .eq('id', id)
        .single();

      if (checkError) {
        console.error('❌ Error checking schedule:', checkError);
        alert(`Cannot access schedule: ${checkError.message}`);
        return;
      }

      if (!schedule) {
        alert('Schedule not found');
        return;
      }

      console.log('✅ Schedule found:', schedule);

      // Try to delete (without select first to avoid RLS issues with select)
      const { error: deleteError, data: deleteData } = await supabase
        .from('vesting_schedules')
        .delete()
        .eq('id', id);

      if (deleteError) {
        console.error('❌ Delete error:', deleteError);
        console.error('Error details:', JSON.stringify(deleteError, null, 2));
        alert(`Failed to delete vesting schedule:\n\n${deleteError.message || 'Unknown error'}\n\nCode: ${deleteError.code || 'N/A'}\nDetails: ${deleteError.details || 'N/A'}\nHint: ${deleteError.hint || 'N/A'}`);
        throw deleteError;
      }

      console.log('✅ Delete query executed. Data returned:', deleteData);

      // Verify the schedule was actually deleted
      const { data: verifySchedule, error: verifyError } = await supabase
        .from('vesting_schedules')
        .select('id, name')
        .eq('id', id)
        .single();

      if (verifyError && verifyError.code === 'PGRST116') {
        // PGRST116 means no rows found - this is good, it means the delete worked!
        console.log('✅ Schedule successfully deleted (not found on verify)');
        setShowDeleteConfirm(null);
        loadData();
      } else if (verifySchedule) {
        // Schedule still exists - delete didn't work
        console.error('❌ Schedule still exists after delete!', verifySchedule);
        alert('Failed to delete vesting schedule: The schedule still exists. This might be due to Row Level Security (RLS) policy restrictions. Please check your permissions.');
      } else if (verifyError) {
        console.error('❌ Error verifying deletion:', verifyError);
        // Could be an RLS issue - check if we can't see it
        alert(`Delete may have succeeded, but couldn't verify: ${verifyError.message}`);
        setShowDeleteConfirm(null);
        loadData();
      } else {
        // Shouldn't happen, but just in case
        console.log('⚠️ Unexpected verify result');
        setShowDeleteConfirm(null);
        loadData();
      }
    } catch (error: any) {
      console.error('❌ Exception deleting schedule:', error);
      // Only show alert if error message wasn't already shown
      if (!error?.message || error.message.includes('Unknown error')) {
        const errorMsg = error?.message || error?.toString() || 'Unknown error';
        alert(`Failed to delete vesting schedule: ${errorMsg}`);
      }
    }
  };

  const addMilestone = () => {
    const lastOrder = milestones.length > 0 ? Math.max(...milestones.map(m => m.sequence_order)) : -1;
    setMilestones([...milestones, {
      milestone_type: newSchedule.schedule_type === 'time_based' ? 'time' :
                     newSchedule.schedule_type === 'performance_based' ? 'performance' : 'hybrid',
      sequence_order: lastOrder + 1,
      vesting_percentage: 0,
      months_from_start: null,
      performance_metric_id: null,
      target_value: null,
    }]);
  };

  const removeMilestone = (index: number) => {
    const newMilestones = milestones.filter((_, i) => i !== index);
    newMilestones.forEach((m, i) => m.sequence_order = i);
    setMilestones(newMilestones);
  };

  const updateMilestone = (index: number, field: keyof VestingMilestone, value: any) => {
    const newMilestones = [...milestones];
    (newMilestones[index] as any)[field] = value;
    setMilestones(newMilestones);
  };

  const resetForm = () => {
    setNewSchedule({
      name: '',
      description: '',
      schedule_type: 'time_based',
      total_duration_months: 48,
      cliff_months: 12,
      vesting_frequency: 'monthly',
      is_template: true,
    });
    setMilestones([]);
  };

  const getScheduleTypeIcon = (type: string) => {
    switch (type) {
      case 'time_based': return <Clock className="w-5 h-5" />;
      case 'performance_based': return <TrendingUp className="w-5 h-5" />;
      case 'hybrid': return <Zap className="w-5 h-5" />;
      default: return <Calendar className="w-5 h-5" />;
    }
  };

  const getScheduleTypeColor = (type: string) => {
    switch (type) {
      case 'time_based': return 'bg-blue-100 text-blue-800';
      case 'performance_based': return 'bg-green-100 text-green-800';
      case 'hybrid': return 'bg-purple-100 text-purple-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const totalPercentage = milestones.reduce((sum, m) => sum + m.vesting_percentage, 0);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading vesting schedules...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-3">
            {t('vestingSchedules.title')}
            <span className="inline-flex items-center justify-center w-10 h-10 rounded-full bg-blue-600 text-white text-lg font-semibold">
              {schedules.length}
            </span>
          </h1>
          <p className="mt-1 text-sm text-gray-500">
            {t('vestingSchedules.description')}
          </p>
        </div>
        <button
          onClick={() => setShowCreateModal(true)}
          className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
        >
          <Plus className="w-4 h-4" />
          <span>{t('vestingSchedules.createSchedule')}</span>
        </button>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {t('vestingSchedules.scheduleName')}
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {t('vestingSchedules.type')}
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {t('vestingSchedules.duration')}
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {t('vestingSchedules.cliffPeriod')}
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {t('vestingSchedules.frequency')}
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {t('vestingSchedules.template')}
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {t('vestingSchedules.actions')}
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {schedules.map((schedule) => (
                <tr key={schedule.id} className="hover:bg-gray-50 transition">
                  <td className="px-6 py-4">
                    <button
                      onClick={() => handleViewSchedule(schedule)}
                      className="text-left"
                    >
                      <div className="font-medium text-blue-600 hover:text-blue-800 hover:underline">
                        {schedule.name}
                      </div>
                      {schedule.description && (
                        <div className="text-sm text-gray-500 mt-1">
                          {truncateDescription(schedule.description)}
                        </div>
                      )}
                    </button>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getScheduleTypeColor(schedule.schedule_type)}`}>
                      <span className="mr-1">{getScheduleTypeIcon(schedule.schedule_type)}</span>
                      {schedule.schedule_type.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {schedule.total_duration_months} {t('vestingSchedules.months')}
                    <div className="text-xs text-gray-500">{(schedule.total_duration_months / 12).toFixed(1)} {t('vestingSchedules.years')}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {schedule.cliff_months} {t('vestingSchedules.months')}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 capitalize">
                    {schedule.vesting_frequency}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {schedule.is_template ? (
                      <span className="inline-flex items-center text-green-600">
                        <CheckCircle className="w-4 h-4 mr-1" />
                        <span className="text-sm font-medium">{t('vestingSchedules.yes')}</span>
                      </span>
                    ) : (
                      <span className="text-sm text-gray-500">{t('vestingSchedules.no')}</span>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <div className="flex items-center justify-end space-x-2">
                      <button
                        onClick={() => handleViewSchedule(schedule)}
                        className="text-blue-600 hover:text-blue-800 transition"
                      >
                        {t('vestingSchedules.view')}
                      </button>
                      <button
                        onClick={() => setShowDeleteConfirm(schedule.id)}
                        className="text-red-600 hover:text-red-800 transition"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {schedules.length === 0 && (
        <div className="bg-white rounded-lg border border-gray-200 p-12 text-center">
          <Calendar className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-gray-900 mb-2">{t('vestingSchedules.noSchedulesYet')}</h3>
          <p className="text-gray-600 mb-6">{t('vestingSchedules.createFirstSchedule')}</p>
          <button
            onClick={() => setShowCreateModal(true)}
            className="inline-flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
          >
            <Plus className="w-4 h-4" />
            <span>{t('vestingSchedules.createSchedule')}</span>
          </button>
        </div>
      )}

      {showCreateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-4xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-gray-200">
              <h2 className="text-xl font-bold text-gray-900">{t('vestingSchedules.createVestingSchedule')}</h2>
            </div>

            <div className="p-6 space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {t('vestingSchedules.scheduleName')}
                  </label>
                  <input
                    type="text"
                    value={newSchedule.name}
                    onChange={(e) => setNewSchedule({ ...newSchedule, name: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="e.g., 4-year with 1-year cliff"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {t('vestingSchedules.scheduleType')}
                  </label>
                  <select
                    value={newSchedule.schedule_type}
                    onChange={(e) => {
                      setNewSchedule({ ...newSchedule, schedule_type: e.target.value as any });
                      setMilestones([]);
                    }}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="time_based">{t('vestingSchedules.timeBased')}</option>
                    <option value="performance_based">{t('vestingSchedules.performanceBased')}</option>
                    <option value="hybrid">{t('vestingSchedules.hybrid')}</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {t('vestingSchedules.descriptionOptional')}
                </label>
                <textarea
                  value={newSchedule.description}
                  onChange={(e) => setNewSchedule({ ...newSchedule, description: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  rows={2}
                  placeholder="Brief description of this vesting schedule"
                />
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {t('vestingSchedules.totalDurationMonths')}
                  </label>
                  <input
                    type="number"
                    value={newSchedule.total_duration_months}
                    onChange={(e) => setNewSchedule({ ...newSchedule, total_duration_months: parseInt(e.target.value) || 48 })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {t('vestingSchedules.cliffPeriodMonths')}
                  </label>
                  <input
                    type="number"
                    value={newSchedule.cliff_months}
                    onChange={(e) => setNewSchedule({ ...newSchedule, cliff_months: parseInt(e.target.value) || 0 })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    {t('vestingSchedules.vestingFrequency')}
                  </label>
                  <select
                    value={newSchedule.vesting_frequency}
                    onChange={(e) => setNewSchedule({ ...newSchedule, vesting_frequency: e.target.value as any })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="monthly">{t('vestingSchedules.monthly')}</option>
                    <option value="quarterly">{t('vestingSchedules.quarterly')}</option>
                    <option value="annually">{t('vestingSchedules.annually')}</option>
                  </select>
                </div>
              </div>

              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="is_template"
                  checked={newSchedule.is_template}
                  onChange={(e) => setNewSchedule({ ...newSchedule, is_template: e.target.checked })}
                  className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                />
                <label htmlFor="is_template" className="ml-2 text-sm text-gray-700">
                  Save as reusable template
                </label>
              </div>

              <div className="border-t border-gray-200 pt-6">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900">Vesting Milestones</h3>
                    <p className="text-sm text-gray-600">Define when and how much vests at each milestone</p>
                  </div>
                  <div className="flex items-center space-x-3">
                    <button
                      onClick={generateDefaultMilestones}
                      className="px-3 py-1 text-sm border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
                    >
                      Auto Generate
                    </button>
                    <button
                      onClick={addMilestone}
                      className="px-3 py-1 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
                    >
                      Add Milestone
                    </button>
                  </div>
                </div>

                {milestones.length > 0 && (
                  <div className="mb-4 p-3 bg-gray-50 rounded-lg">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-gray-600">Total Vesting Percentage:</span>
                      <span className={`font-bold ${totalPercentage === 100 ? 'text-green-600' : 'text-red-600'}`}>
                        {totalPercentage.toFixed(2)}%
                      </span>
                    </div>
                    {totalPercentage !== 100 && (
                      <p className="text-xs text-red-600 mt-1">Total must equal 100%</p>
                    )}
                  </div>
                )}

                <div className="space-y-3">
                  {milestones.map((milestone, index) => (
                    <div key={index} className="p-4 border border-gray-200 rounded-lg bg-gray-50">
                      <div className="flex items-start justify-between mb-3">
                        <span className="text-sm font-medium text-gray-700">Milestone {index + 1}</span>
                        <button
                          onClick={() => removeMilestone(index)}
                          className="text-gray-400 hover:text-red-600 transition"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>

                      <div className="grid grid-cols-2 gap-3">
                        <div>
                          <label className="block text-xs font-medium text-gray-600 mb-1">
                            Vesting %
                          </label>
                          <input
                            type="number"
                            value={milestone.vesting_percentage}
                            onChange={(e) => updateMilestone(index, 'vesting_percentage', parseFloat(e.target.value) || 0)}
                            className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                            step="0.01"
                            min="0"
                            max="100"
                          />
                        </div>

                        {(newSchedule.schedule_type === 'time_based' || newSchedule.schedule_type === 'hybrid') && (
                          <div>
                            <label className="block text-xs font-medium text-gray-600 mb-1">
                              Months from Start
                            </label>
                            <input
                              type="number"
                              value={milestone.months_from_start || ''}
                              onChange={(e) => updateMilestone(index, 'months_from_start', parseInt(e.target.value) || null)}
                              className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                            />
                          </div>
                        )}

                        {(newSchedule.schedule_type === 'performance_based' || newSchedule.schedule_type === 'hybrid') && (
                          <>
                            <div>
                              <label className="block text-xs font-medium text-gray-600 mb-1">
                                Performance Metric
                              </label>
                              <select
                                value={milestone.performance_metric_id || ''}
                                onChange={(e) => updateMilestone(index, 'performance_metric_id', e.target.value || null)}
                                className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                              >
                                <option value="">Select metric...</option>
                                {metrics.map(metric => (
                                  <option key={metric.id} value={metric.id}>{metric.name}</option>
                                ))}
                              </select>
                            </div>
                            <div>
                              <label className="block text-xs font-medium text-gray-600 mb-1">
                                Target Value
                              </label>
                              <input
                                type="number"
                                value={milestone.target_value || ''}
                                onChange={(e) => updateMilestone(index, 'target_value', parseFloat(e.target.value) || null)}
                                className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                              />
                            </div>
                          </>
                        )}
                      </div>
                    </div>
                  ))}
                </div>

                {milestones.length === 0 && (
                  <div className="text-center py-8 text-gray-500 text-sm">
                    No milestones added yet. Click "Auto Generate" or "Add Milestone" to start.
                  </div>
                )}
              </div>
            </div>

            <div className="p-6 border-t border-gray-200 flex items-center justify-end space-x-3">
              <button
                onClick={() => {
                  setShowCreateModal(false);
                  resetForm();
                }}
                className="px-6 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
              >
                Cancel
              </button>
              <button
                onClick={handleCreateSchedule}
                disabled={!newSchedule.name || totalPercentage !== 100 || milestones.length === 0}
                className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Create Schedule
              </button>
            </div>
          </div>
        </div>
      )}

      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-md w-full p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Delete Vesting Schedule</h3>
            <p className="text-gray-600 mb-6">
              Are you sure you want to delete this vesting schedule? This action cannot be undone.
            </p>
            <div className="flex items-center justify-end space-x-3">
              <button
                onClick={() => setShowDeleteConfirm(null)}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
              >
                Cancel
              </button>
              <button
                onClick={() => handleDeleteSchedule(showDeleteConfirm)}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}

      {showViewModal && selectedSchedule && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h2 className="text-xl font-semibold text-gray-900">Vesting Schedule Details</h2>
              <button
                onClick={() => setShowViewModal(false)}
                className="text-gray-400 hover:text-gray-600 transition"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div className="p-6 space-y-6">
              <div className="bg-gradient-to-r from-blue-50 to-blue-100 rounded-lg p-6 border border-blue-200">
                <div className="flex items-center space-x-3 mb-4">
                  <div className={`p-3 rounded-lg ${getScheduleTypeColor(selectedSchedule.schedule_type)}`}>
                    {getScheduleTypeIcon(selectedSchedule.schedule_type)}
                  </div>
                  <div>
                    <h3 className="text-xl font-bold text-gray-900">{selectedSchedule.name}</h3>
                    <span className={`inline-block px-3 py-1 text-sm rounded-full mt-1 ${getScheduleTypeColor(selectedSchedule.schedule_type)}`}>
                      {selectedSchedule.schedule_type.replace('_', ' ')}
                    </span>
                  </div>
                </div>
                {selectedSchedule.description && (
                  <p className="text-gray-700">{truncateDescription(selectedSchedule.description, 8)}</p>
                )}
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="bg-white border border-gray-200 rounded-lg p-4">
                  <p className="text-sm text-gray-600 mb-2">Total Duration</p>
                  <p className="text-2xl font-bold text-gray-900">{selectedSchedule.total_duration_months} months</p>
                  <p className="text-xs text-gray-500 mt-1">{(selectedSchedule.total_duration_months / 12).toFixed(1)} years</p>
                </div>
                <div className="bg-white border border-gray-200 rounded-lg p-4">
                  <p className="text-sm text-gray-600 mb-2">Cliff Period</p>
                  <p className="text-2xl font-bold text-gray-900">{selectedSchedule.cliff_months} months</p>
                </div>
                <div className="bg-white border border-gray-200 rounded-lg p-4">
                  <p className="text-sm text-gray-600 mb-2">Vesting Frequency</p>
                  <p className="text-lg font-semibold text-gray-900 capitalize">{selectedSchedule.vesting_frequency}</p>
                </div>
                <div className="bg-white border border-gray-200 rounded-lg p-4">
                  <p className="text-sm text-gray-600 mb-2">Template</p>
                  <p className="text-lg font-semibold text-gray-900">{selectedSchedule.is_template ? 'Yes' : 'No'}</p>
                </div>
              </div>

              {selectedSchedule.milestones && selectedSchedule.milestones.length > 0 && (
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 mb-3">Vesting Milestones</h3>
                  <div className="space-y-3">
                    {selectedSchedule.milestones.map((milestone, index) => (
                      <div key={milestone.id || index} className="bg-gray-50 rounded-lg p-4 border border-gray-200">
                        <div className="flex items-center justify-between mb-2">
                          <span className="text-sm font-semibold text-gray-700">Milestone {index + 1}</span>
                          <span className="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-sm font-medium">
                            {milestone.vesting_percentage}%
                          </span>
                        </div>
                        <div className="grid grid-cols-2 gap-3 text-sm">
                          <div>
                            <p className="text-gray-600">Type</p>
                            <p className="font-medium text-gray-900 capitalize">{milestone.milestone_type.replace('_', ' ')}</p>
                          </div>
                          {milestone.months_from_start !== null && (
                            <div>
                              <p className="text-gray-600">Timing</p>
                              <p className="font-medium text-gray-900">{milestone.months_from_start} months</p>
                            </div>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            <div className="sticky bottom-0 bg-gray-50 border-t border-gray-200 px-6 py-4">
              <button
                onClick={() => setShowViewModal(false)}
                className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
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
