import { useEffect, useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../lib/supabase';
import { ArrowLeftRight, MoreVertical, X, CheckCircle, XCircle, AlertCircle, Building2, User, DollarSign, Calendar } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

type BuybackStatus = 'pending' | 'approved' | 'rejected' | 'processing' | 'completed' | 'cancelled';
type BuybackType = 'voluntary' | 'mandatory' | 'termination';

interface BuybackRequest {
  id: string;
  company_id: string;
  request_number: string;
  employee_id: string | null;
  grant_id: string | null;
  shares_requested: number;
  requested_price_per_share: number | null;
  request_type: BuybackType;
  status: BuybackStatus;
  request_date: string;
  requested_by: string | null;
  approved_by: string | null;
  approved_at: string | null;
  rejection_reason: string | null;
  actual_price_per_share: number | null;
  total_amount: number | null;
  payment_status: string;
  payment_date: string | null;
  completion_date: string | null;
  created_at: string;
  companies?: {
    company_name_en: string;
    company_name_ar: string;
    tadawul_symbol: string;
  };
  employees?: {
    first_name_en: string;
    last_name_en: string;
    employee_number: string;
  };
}

export default function OperatorBuybackRequests() {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';
  const [requests, setRequests] = useState<BuybackRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedRequest, setSelectedRequest] = useState<BuybackRequest | null>(null);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editStatus, setEditStatus] = useState<BuybackStatus>('pending');
  const [editSaving, setEditSaving] = useState(false);
  const [editError, setEditError] = useState<string | null>(null);
  const { userRole, isSuperAdmin } = useAuth();

  const isSuperAdminUser = useMemo(() => {
    return isSuperAdmin() || userRole?.user_type === 'super_admin' || userRole?.role === 'super_admin';
  }, [userRole, isSuperAdmin]);

  useEffect(() => {
    if (!isSuperAdminUser) {
      setError('Access denied. Super admin only.');
      setLoading(false);
      return;
    }
    loadBuybackRequests();
  }, [isSuperAdminUser]);

  const loadBuybackRequests = async () => {
    try {
      setLoading(true);
      setError(null);

      const { data, error: requestsError } = await supabase
        .from('buyback_requests')
        .select(`
          *,
          companies:company_id (
            company_name_en,
            company_name_ar,
            tadawul_symbol
          ),
          employees:employee_id (
            first_name_en,
            last_name_en,
            employee_number
          )
        `)
        .order('created_at', { ascending: false });

      if (requestsError) throw requestsError;

      setRequests((data || []) as BuybackRequest[]);
    } catch (err) {
      console.error('Error loading buyback requests:', err);
      setError('Failed to load buyback requests.');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenEditModal = (request: BuybackRequest) => {
    setSelectedRequest(request);
    setEditStatus(request.status);
    setEditError(null);
    setShowEditModal(true);
  };

  const handleCloseEditModal = () => {
    setSelectedRequest(null);
    setEditError(null);
    setShowEditModal(false);
  };

  const handleSaveEdit = async () => {
    if (!selectedRequest) return;

    try {
      setEditSaving(true);
      setEditError(null);

      const updateData: any = {
        status: editStatus,
        updated_at: new Date().toISOString(),
      };

      if (editStatus === 'approved' && selectedRequest.status !== 'approved') {
        updateData.approved_by = (await supabase.auth.getUser()).data.user?.id;
        updateData.approved_at = new Date().toISOString();
      }

      if (editStatus === 'completed' && selectedRequest.actual_price_per_share) {
        updateData.total_amount = selectedRequest.shares_requested * selectedRequest.actual_price_per_share;
        updateData.completion_date = new Date().toISOString().split('T')[0];
      }

      const { error: updateError } = await supabase
        .from('buyback_requests')
        .update(updateData)
        .eq('id', selectedRequest.id);

      if (updateError) {
        console.error('Error updating buyback request:', updateError);
        setEditError(`Failed to save changes: ${updateError.message}`);
        return;
      }

      handleCloseEditModal();
      await loadBuybackRequests();
    } catch (err: any) {
      console.error('Error updating buyback request:', err);
      setEditError(`Failed to save changes: ${err?.message || 'Unknown error occurred'}`);
    } finally {
      setEditSaving(false);
    }
  };

  const formatStatus = (status: BuybackStatus) => {
    const statusMap = {
      pending: { label: 'Pending', color: 'bg-yellow-50 text-yellow-700 border-yellow-200', icon: AlertCircle },
      approved: { label: 'Approved', color: 'bg-blue-50 text-blue-700 border-blue-200', icon: CheckCircle },
      rejected: { label: 'Rejected', color: 'bg-red-50 text-red-700 border-red-200', icon: XCircle },
      processing: { label: 'Processing', color: 'bg-purple-50 text-purple-700 border-purple-200', icon: AlertCircle },
      completed: { label: 'Completed', color: 'bg-green-50 text-green-700 border-green-200', icon: CheckCircle },
      cancelled: { label: 'Cancelled', color: 'bg-gray-50 text-gray-700 border-gray-200', icon: XCircle },
    };
    return statusMap[status];
  };

  if (!isSuperAdminUser) {
    return (
      <div className="p-6">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-red-700">Access denied. Super admin only.</p>
        </div>
      </div>
    );
  }

  const pendingCount = requests.filter((r) => r.status === 'pending').length;
  const approvedCount = requests.filter((r) => r.status === 'approved').length;
  const completedCount = requests.filter((r) => r.status === 'completed').length;
  const totalValue = requests
    .filter((r) => r.status === 'completed' && r.total_amount)
    .reduce((sum, r) => sum + (r.total_amount || 0), 0);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Buyback Requests</h1>
          <p className="text-gray-600 mt-1">
            Manage employee share buyback requests
          </p>
        </div>
      </div>

      {error && (
        <div className="p-4 rounded-lg border border-red-200 bg-red-50 text-red-700">
          {error}
        </div>
      )}

      {/* Summary Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Total Requests</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{requests.length}</p>
            </div>
            <ArrowLeftRight className="w-8 h-8 text-blue-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Pending</p>
              <p className="text-2xl font-bold text-yellow-600 mt-1">{pendingCount}</p>
            </div>
            <AlertCircle className="w-8 h-8 text-yellow-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Approved</p>
              <p className="text-2xl font-bold text-blue-600 mt-1">{approvedCount}</p>
            </div>
            <CheckCircle className="w-8 h-8 text-blue-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Total Completed Value</p>
              <p className="text-2xl font-bold text-green-600 mt-1">
                {totalValue.toLocaleString()} SAR
              </p>
            </div>
            <DollarSign className="w-8 h-8 text-green-600" />
          </div>
        </div>
      </div>

      {loading ? (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading buyback requests...</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-blue-100 rounded-lg">
                <ArrowLeftRight className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-900">All Buyback Requests</h2>
                <p className="text-sm text-gray-500">Review and manage share buyback requests</p>
              </div>
            </div>
          </div>

          {requests.length === 0 ? (
            <div className="p-10 text-center text-gray-500">
              No buyback requests found.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Request #
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Company
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Employee
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Shares
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Price/Share
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Total Amount
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Request Date
                    </th>
                    <th scope="col" className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {requests.map((request) => {
                    const statusInfo = formatStatus(request.status);
                    const StatusIcon = statusInfo.icon;
                    const company = request.companies as any;
                    const employee = request.employees as any;
                    const totalAmount = request.total_amount || 
                      (request.requested_price_per_share ? request.shares_requested * request.requested_price_per_share : null);

                    return (
                      <tr key={request.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm font-medium text-gray-900">
                            {request.request_number}
                          </div>
                          <div className="text-xs text-gray-500">
                            {request.request_type}
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-sm font-medium text-gray-900">
                            {company?.company_name_en || 'N/A'}
                          </div>
                          {company?.tadawul_symbol && (
                            <div className="text-xs text-gray-500">
                              {company.tadawul_symbol}
                            </div>
                          )}
                        </td>
                        <td className="px-6 py-4">
                          {employee ? (
                            <>
                              <div className="text-sm font-medium text-gray-900">
                                {employee.first_name_en} {employee.last_name_en}
                              </div>
                              <div className="text-xs text-gray-500">
                                #{employee.employee_number}
                              </div>
                            </>
                          ) : (
                            <span className="text-sm text-gray-400">N/A</span>
                          )}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {request.shares_requested.toLocaleString()}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {request.actual_price_per_share || request.requested_price_per_share
                            ? `${(request.actual_price_per_share || request.requested_price_per_share)?.toLocaleString()} SAR`
                            : 'N/A'}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                          {totalAmount ? `${totalAmount.toLocaleString()} SAR` : 'N/A'}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span
                            className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${statusInfo.color}`}
                          >
                            <StatusIcon className="w-3 h-3 mr-1" />
                            {statusInfo.label}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {new Date(request.request_date).toLocaleDateString('en-GB')}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-right text-sm">
                          <button
                            onClick={() => handleOpenEditModal(request)}
                            className="p-2 rounded-full hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                            aria-label={`Actions for request ${request.request_number}`}
                          >
                            <MoreVertical className="w-5 h-5 text-gray-500" />
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {showEditModal && selectedRequest && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="bg-white rounded-xl shadow-xl max-w-lg w-full">
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
              <div>
                <h3 className="text-lg font-semibold text-gray-900">Update Buyback Request</h3>
                <p className="text-sm text-gray-500">
                  Request #{selectedRequest.request_number}
                </p>
              </div>
              <button
                onClick={handleCloseEditModal}
                className="text-gray-400 hover:text-gray-600"
                aria-label="Close edit modal"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="px-6 py-5 space-y-5">
              {editError && (
                <div className="p-3 rounded-lg border border-red-200 bg-red-50 text-red-700 text-sm">
                  {editError}
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Status</label>
                <select
                  value={editStatus}
                  onChange={(e) => setEditStatus(e.target.value as BuybackStatus)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="pending">Pending</option>
                  <option value="approved">Approved</option>
                  <option value="rejected">Rejected</option>
                  <option value="processing">Processing</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-200 bg-gray-50">
              <button
                onClick={handleCloseEditModal}
                className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-800"
                type="button"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveEdit}
                disabled={editSaving}
                className="px-5 py-2 text-sm font-semibold text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                type="button"
              >
                {editSaving ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

