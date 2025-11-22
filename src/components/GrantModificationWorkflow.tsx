import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { formatDate } from '../lib/dateUtils';
import { FileEdit, Plus, X, CheckCircle, Clock, AlertCircle } from 'lucide-react';

interface GrantModification {
  id?: string;
  grant_id: string;
  modification_type: 'shares_adjustment' | 'vesting_change' | 'exercise_price_change' | 'schedule_change' | 'acceleration' | 'cancellation';
  previous_value: any;
  new_value: any;
  reason: string;
  approval_status: 'pending' | 'approved' | 'rejected';
  requested_by: string;
  approved_by: string | null;
  effective_date: string;
  created_at?: string;
}

interface GrantModificationWorkflowProps {
  grantId: string;
  grantData?: any;
  onUpdate?: () => void;
}

export default function GrantModificationWorkflow({ grantId, grantData, onUpdate }: GrantModificationWorkflowProps) {
  const [modifications, setModifications] = useState<GrantModification[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [newModification, setNewModification] = useState<Partial<GrantModification>>({
    grant_id: grantId,
    modification_type: 'shares_adjustment',
    previous_value: {},
    new_value: {},
    reason: '',
    approval_status: 'pending',
    effective_date: new Date().toISOString().split('T')[0]
  });

  useEffect(() => {
    loadModifications();
  }, [grantId]);

  const loadModifications = async () => {
    try {
      const { data, error } = await supabase
        .from('grant_modifications')
        .select('*')
        .eq('grant_id', grantId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      if (data) setModifications(data);
    } catch (error) {
      console.error('Error loading modifications:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateModification = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { error } = await supabase
        .from('grant_modifications')
        .insert({
          ...newModification,
          requested_by: user.id
        });

      if (error) throw error;

      setShowAddModal(false);
      resetForm();
      loadModifications();
      onUpdate?.();
    } catch (error) {
      console.error('Error creating modification:', error);
      alert('Failed to create modification request');
    }
  };

  const handleApproveModification = async (modificationId: string) => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { error } = await supabase
        .from('grant_modifications')
        .update({
          approval_status: 'approved',
          approved_by: user.id
        })
        .eq('id', modificationId);

      if (error) throw error;

      loadModifications();
      onUpdate?.();
    } catch (error) {
      console.error('Error approving modification:', error);
      alert('Failed to approve modification');
    }
  };

  const handleRejectModification = async (modificationId: string) => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { error } = await supabase
        .from('grant_modifications')
        .update({
          approval_status: 'rejected',
          approved_by: user.id
        })
        .eq('id', modificationId);

      if (error) throw error;

      loadModifications();
      onUpdate?.();
    } catch (error) {
      console.error('Error rejecting modification:', error);
      alert('Failed to reject modification');
    }
  };

  const resetForm = () => {
    setNewModification({
      grant_id: grantId,
      modification_type: 'shares_adjustment',
      previous_value: {},
      new_value: {},
      reason: '',
      approval_status: 'pending',
      effective_date: new Date().toISOString().split('T')[0]
    });
  };

  const getModificationTypeLabel = (type: string) => {
    const labels: Record<string, string> = {
      'shares_adjustment': 'Shares Adjustment',
      'vesting_change': 'Vesting Schedule Change',
      'exercise_price_change': 'Exercise Price Change',
      'schedule_change': 'Schedule Modification',
      'acceleration': 'Vesting Acceleration',
      'cancellation': 'Grant Cancellation'
    };
    return labels[type] || type;
  };

  const getStatusBadge = (status: string) => {
    const styles = {
      pending: 'bg-yellow-100 text-yellow-800',
      approved: 'bg-green-100 text-green-800',
      rejected: 'bg-red-100 text-red-800'
    };
    const icons = {
      pending: <Clock className="w-3 h-3" />,
      approved: <CheckCircle className="w-3 h-3" />,
      rejected: <X className="w-3 h-3" />
    };
    return (
      <span className={`inline-flex items-center space-x-1 px-2 py-1 text-xs font-medium rounded-full ${styles[status as keyof typeof styles]}`}>
        {icons[status as keyof typeof icons]}
        <span className="capitalize">{status}</span>
      </span>
    );
  };

  if (loading) {
    return <div className="text-center py-4 text-gray-500">Loading modifications...</div>;
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <FileEdit className="w-5 h-5 text-blue-600" />
          <h3 className="text-lg font-semibold text-gray-900">Grant Modifications</h3>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="flex items-center space-x-2 px-3 py-1.5 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700 transition"
        >
          <Plus className="w-4 h-4" />
          <span>Request Modification</span>
        </button>
      </div>

      <div className="bg-blue-50 border border-blue-200 rounded-lg p-3 flex items-start space-x-2">
        <AlertCircle className="w-4 h-4 text-blue-600 mt-0.5 flex-shrink-0" />
        <p className="text-sm text-blue-800">
          All grant modifications require approval before taking effect. Track changes and maintain a complete audit trail.
        </p>
      </div>

      {modifications.length === 0 ? (
        <div className="bg-gray-50 rounded-lg border border-gray-200 p-8 text-center">
          <FileEdit className="w-12 h-12 text-gray-400 mx-auto mb-3" />
          <p className="text-gray-600">No modifications recorded for this grant</p>
        </div>
      ) : (
        <div className="space-y-3">
          {modifications.map((mod) => (
            <div
              key={mod.id}
              className="border border-gray-200 rounded-lg p-4 bg-white"
            >
              <div className="flex items-start justify-between mb-3">
                <div>
                  <div className="flex items-center space-x-2 mb-1">
                    <h4 className="font-semibold text-gray-900">
                      {getModificationTypeLabel(mod.modification_type)}
                    </h4>
                    {getStatusBadge(mod.approval_status)}
                  </div>
                  <p className="text-sm text-gray-600">
                    Effective Date: {formatDate(mod.effective_date)}
                  </p>
                </div>
                {mod.approval_status === 'pending' && (
                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => handleApproveModification(mod.id!)}
                      className="px-3 py-1 text-xs bg-green-600 text-white rounded-lg hover:bg-green-700 transition"
                    >
                      Approve
                    </button>
                    <button
                      onClick={() => handleRejectModification(mod.id!)}
                      className="px-3 py-1 text-xs bg-red-600 text-white rounded-lg hover:bg-red-700 transition"
                    >
                      Reject
                    </button>
                  </div>
                )}
              </div>

              <div className="bg-gray-50 rounded p-3">
                <p className="text-sm text-gray-700 mb-2">
                  <strong>Reason:</strong> {mod.reason}
                </p>
                <div className="text-xs text-gray-500">
                  Requested on {formatDate(mod.created_at)}
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
              <h2 className="text-xl font-bold text-gray-900">Request Grant Modification</h2>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Modification Type
                </label>
                <select
                  value={newModification.modification_type}
                  onChange={(e) => setNewModification({ ...newModification, modification_type: e.target.value as any })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="shares_adjustment">Shares Adjustment</option>
                  <option value="vesting_change">Vesting Schedule Change</option>
                  <option value="exercise_price_change">Exercise Price Change</option>
                  <option value="schedule_change">Schedule Modification</option>
                  <option value="acceleration">Vesting Acceleration</option>
                  <option value="cancellation">Grant Cancellation</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Effective Date
                </label>
                <input
                  type="date"
                  value={newModification.effective_date}
                  onChange={(e) => setNewModification({ ...newModification, effective_date: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Reason for Modification
                </label>
                <textarea
                  value={newModification.reason}
                  onChange={(e) => setNewModification({ ...newModification, reason: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  rows={4}
                  placeholder="Provide detailed reason for this modification..."
                />
              </div>
            </div>

            <div className="p-6 border-t border-gray-200 flex items-center justify-end space-x-3">
              <button
                onClick={() => {
                  setShowAddModal(false);
                  resetForm();
                }}
                className="px-6 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
              >
                Cancel
              </button>
              <button
                onClick={handleCreateModification}
                disabled={!newModification.reason}
                className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Submit Request
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
