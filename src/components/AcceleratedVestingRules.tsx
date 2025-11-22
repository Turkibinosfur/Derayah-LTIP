import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Zap, Plus, Trash2, AlertCircle } from 'lucide-react';

interface AcceleratedVestingRule {
  id?: string;
  vesting_schedule_id: string;
  trigger_event: 'termination_good_leaver' | 'termination_bad_leaver' | 'change_of_control' | 'ipo' | 'acquisition' | 'death' | 'disability' | 'retirement';
  acceleration_type: 'full' | 'partial' | 'none';
  acceleration_percentage: number;
  conditions: any;
  priority_order: number;
  is_active: boolean;
}

interface AcceleratedVestingRulesProps {
  scheduleId: string;
  onUpdate?: () => void;
}

export default function AcceleratedVestingRules({ scheduleId, onUpdate }: AcceleratedVestingRulesProps) {
  const [rules, setRules] = useState<AcceleratedVestingRule[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [newRule, setNewRule] = useState<AcceleratedVestingRule>({
    vesting_schedule_id: scheduleId,
    trigger_event: 'termination_good_leaver',
    acceleration_type: 'full',
    acceleration_percentage: 100,
    conditions: {},
    priority_order: 0,
    is_active: true
  });

  useEffect(() => {
    loadRules();
  }, [scheduleId]);

  const loadRules = async () => {
    try {
      const { data, error } = await supabase
        .from('accelerated_vesting_rules')
        .select('*')
        .eq('vesting_schedule_id', scheduleId)
        .order('priority_order', { ascending: true });

      if (error) throw error;
      if (data) setRules(data);
    } catch (error) {
      console.error('Error loading accelerated vesting rules:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAddRule = async () => {
    try {
      const { error } = await supabase
        .from('accelerated_vesting_rules')
        .insert({
          ...newRule,
          priority_order: rules.length
        });

      if (error) throw error;

      setShowAddModal(false);
      resetNewRule();
      loadRules();
      onUpdate?.();
    } catch (error) {
      console.error('Error adding rule:', error);
      alert('Failed to add accelerated vesting rule');
    }
  };

  const handleDeleteRule = async (id: string) => {
    if (!confirm('Are you sure you want to delete this rule?')) return;

    try {
      const { error } = await supabase
        .from('accelerated_vesting_rules')
        .delete()
        .eq('id', id);

      if (error) throw error;

      loadRules();
      onUpdate?.();
    } catch (error) {
      console.error('Error deleting rule:', error);
      alert('Failed to delete rule');
    }
  };

  const handleToggleActive = async (id: string, isActive: boolean) => {
    try {
      const { error } = await supabase
        .from('accelerated_vesting_rules')
        .update({ is_active: !isActive })
        .eq('id', id);

      if (error) throw error;

      loadRules();
      onUpdate?.();
    } catch (error) {
      console.error('Error toggling rule:', error);
    }
  };

  const resetNewRule = () => {
    setNewRule({
      vesting_schedule_id: scheduleId,
      trigger_event: 'termination_good_leaver',
      acceleration_type: 'full',
      acceleration_percentage: 100,
      conditions: {},
      priority_order: 0,
      is_active: true
    });
  };

  const getTriggerEventLabel = (event: string) => {
    const labels: Record<string, string> = {
      'termination_good_leaver': 'Good Leaver Termination',
      'termination_bad_leaver': 'Bad Leaver Termination',
      'change_of_control': 'Change of Control',
      'ipo': 'IPO',
      'acquisition': 'Acquisition',
      'death': 'Death',
      'disability': 'Disability',
      'retirement': 'Retirement'
    };
    return labels[event] || event;
  };

  const getAccelerationTypeColor = (type: string) => {
    switch (type) {
      case 'full': return 'bg-green-100 text-green-800';
      case 'partial': return 'bg-yellow-100 text-yellow-800';
      case 'none': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  if (loading) {
    return <div className="text-center py-4 text-gray-500">Loading rules...</div>;
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <Zap className="w-5 h-5 text-orange-600" />
          <h3 className="text-lg font-semibold text-gray-900">Accelerated Vesting Rules</h3>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="flex items-center space-x-2 px-3 py-1.5 bg-orange-600 text-white text-sm rounded-lg hover:bg-orange-700 transition"
        >
          <Plus className="w-4 h-4" />
          <span>Add Rule</span>
        </button>
      </div>

      <div className="bg-blue-50 border border-blue-200 rounded-lg p-3 flex items-start space-x-2">
        <AlertCircle className="w-4 h-4 text-blue-600 mt-0.5 flex-shrink-0" />
        <p className="text-sm text-blue-800">
          Accelerated vesting rules automatically speed up vesting when specific events occur, such as good leaver termination or company acquisition.
        </p>
      </div>

      {rules.length === 0 ? (
        <div className="bg-gray-50 rounded-lg border border-gray-200 p-8 text-center">
          <Zap className="w-12 h-12 text-gray-400 mx-auto mb-3" />
          <p className="text-gray-600 mb-4">No accelerated vesting rules defined</p>
          <button
            onClick={() => setShowAddModal(true)}
            className="inline-flex items-center space-x-2 px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition"
          >
            <Plus className="w-4 h-4" />
            <span>Add Your First Rule</span>
          </button>
        </div>
      ) : (
        <div className="space-y-3">
          {rules.map((rule) => (
            <div
              key={rule.id}
              className={`border rounded-lg p-4 transition ${
                rule.is_active
                  ? 'border-gray-200 bg-white'
                  : 'border-gray-200 bg-gray-50 opacity-60'
              }`}
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center space-x-3 mb-2">
                    <h4 className="font-semibold text-gray-900">
                      {getTriggerEventLabel(rule.trigger_event)}
                    </h4>
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${getAccelerationTypeColor(rule.acceleration_type)}`}>
                      {rule.acceleration_type} ({rule.acceleration_percentage}%)
                    </span>
                    {!rule.is_active && (
                      <span className="px-2 py-1 text-xs font-medium rounded-full bg-gray-100 text-gray-600">
                        Inactive
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-gray-600">
                    Priority: {rule.priority_order + 1}
                  </p>
                </div>
                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => handleToggleActive(rule.id!, rule.is_active)}
                    className={`px-3 py-1 text-xs rounded-lg transition ${
                      rule.is_active
                        ? 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                        : 'bg-green-100 text-green-700 hover:bg-green-200'
                    }`}
                  >
                    {rule.is_active ? 'Deactivate' : 'Activate'}
                  </button>
                  <button
                    onClick={() => handleDeleteRule(rule.id!)}
                    className="text-gray-400 hover:text-red-600 transition"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {showAddModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-2xl w-full">
            <div className="p-6 border-b border-gray-200">
              <h2 className="text-xl font-bold text-gray-900">Add Accelerated Vesting Rule</h2>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Trigger Event
                </label>
                <select
                  value={newRule.trigger_event}
                  onChange={(e) => setNewRule({ ...newRule, trigger_event: e.target.value as any })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                >
                  <option value="termination_good_leaver">Good Leaver Termination</option>
                  <option value="termination_bad_leaver">Bad Leaver Termination</option>
                  <option value="change_of_control">Change of Control</option>
                  <option value="ipo">IPO</option>
                  <option value="acquisition">Acquisition</option>
                  <option value="death">Death</option>
                  <option value="disability">Disability</option>
                  <option value="retirement">Retirement</option>
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Acceleration Type
                  </label>
                  <select
                    value={newRule.acceleration_type}
                    onChange={(e) => {
                      const type = e.target.value as any;
                      setNewRule({
                        ...newRule,
                        acceleration_type: type,
                        acceleration_percentage: type === 'full' ? 100 : type === 'none' ? 0 : 50
                      });
                    }}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                  >
                    <option value="full">Full Acceleration</option>
                    <option value="partial">Partial Acceleration</option>
                    <option value="none">No Acceleration</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Acceleration Percentage
                  </label>
                  <input
                    type="number"
                    value={newRule.acceleration_percentage}
                    onChange={(e) => setNewRule({ ...newRule, acceleration_percentage: parseFloat(e.target.value) || 0 })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                    min="0"
                    max="100"
                    disabled={newRule.acceleration_type === 'full'}
                  />
                </div>
              </div>

              <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3">
                <p className="text-sm text-yellow-800">
                  <strong>Good Leaver:</strong> Employees who leave on good terms (resignation, mutual agreement, redundancy).<br />
                  <strong>Bad Leaver:</strong> Employees terminated for cause or breach of contract.
                </p>
              </div>
            </div>

            <div className="p-6 border-t border-gray-200 flex items-center justify-end space-x-3">
              <button
                onClick={() => {
                  setShowAddModal(false);
                  resetNewRule();
                }}
                className="px-6 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
              >
                Cancel
              </button>
              <button
                onClick={handleAddRule}
                className="px-6 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition"
              >
                Add Rule
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
