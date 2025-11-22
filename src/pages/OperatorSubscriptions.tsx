import { useEffect, useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../lib/supabase';
import { CreditCard, MoreVertical, X, CheckCircle, XCircle, AlertCircle, Building2, Calendar, DollarSign } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

type SubscriptionStatus = 'active' | 'suspended' | 'cancelled' | 'expired' | 'trial';
type SubscriptionPlan = 'basic' | 'professional' | 'enterprise' | 'custom';
type BillingCycle = 'monthly' | 'quarterly' | 'annual';

interface Subscription {
  id: string;
  company_id: string;
  subscription_plan: SubscriptionPlan;
  status: SubscriptionStatus;
  billing_cycle: BillingCycle;
  start_date: string;
  end_date: string | null;
  renewal_date: string | null;
  price_per_cycle: number;
  currency: string;
  max_employees: number | null;
  max_plans: number | null;
  payment_status: string;
  last_payment_date: string | null;
  next_payment_date: string | null;
  created_at: string;
  updated_at: string;
  companies?: {
    company_name_en: string;
    company_name_ar: string;
    tadawul_symbol: string;
  };
}

export default function OperatorSubscriptions() {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedSubscription, setSelectedSubscription] = useState<Subscription | null>(null);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editStatus, setEditStatus] = useState<SubscriptionStatus>('active');
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
    loadSubscriptions();
  }, [isSuperAdminUser]);

  const loadSubscriptions = async () => {
    try {
      setLoading(true);
      setError(null);

      const { data, error: subscriptionsError } = await supabase
        .from('company_subscriptions')
        .select(`
          *,
          companies:company_id (
            company_name_en,
            company_name_ar,
            tadawul_symbol
          )
        `)
        .order('created_at', { ascending: false });

      if (subscriptionsError) throw subscriptionsError;

      setSubscriptions((data || []) as Subscription[]);
    } catch (err) {
      console.error('Error loading subscriptions:', err);
      setError('Failed to load subscriptions.');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenEditModal = (subscription: Subscription) => {
    setSelectedSubscription(subscription);
    setEditStatus(subscription.status);
    setEditError(null);
    setShowEditModal(true);
  };

  const handleCloseEditModal = () => {
    setSelectedSubscription(null);
    setEditError(null);
    setShowEditModal(false);
  };

  const handleSaveEdit = async () => {
    if (!selectedSubscription) return;

    try {
      setEditSaving(true);
      setEditError(null);

      const { error: updateError } = await supabase
        .from('company_subscriptions')
        .update({
          status: editStatus,
          updated_at: new Date().toISOString(),
        })
        .eq('id', selectedSubscription.id);

      if (updateError) {
        console.error('Error updating subscription:', updateError);
        setEditError(`Failed to save changes: ${updateError.message}`);
        return;
      }

      handleCloseEditModal();
      await loadSubscriptions();
    } catch (err: any) {
      console.error('Error updating subscription:', err);
      setEditError(`Failed to save changes: ${err?.message || 'Unknown error occurred'}`);
    } finally {
      setEditSaving(false);
    }
  };

  const formatStatus = (status: SubscriptionStatus | null | undefined) => {
    const statusMap: Record<string, { label: string; color: string; icon: any }> = {
      active: { label: 'Active', color: 'bg-green-50 text-green-700 border-green-200', icon: CheckCircle },
      suspended: { label: 'Suspended', color: 'bg-yellow-50 text-yellow-700 border-yellow-200', icon: AlertCircle },
      cancelled: { label: 'Cancelled', color: 'bg-red-50 text-red-700 border-red-200', icon: XCircle },
      expired: { label: 'Expired', color: 'bg-gray-50 text-gray-700 border-gray-200', icon: XCircle },
      trial: { label: 'Trial', color: 'bg-blue-50 text-blue-700 border-blue-200', icon: AlertCircle },
    };
    return statusMap[status || 'active'] || statusMap['active'];
  };

  const formatPlan = (plan: SubscriptionPlan) => {
    const planMap = {
      basic: 'Basic',
      professional: 'Professional',
      enterprise: 'Enterprise',
      custom: 'Custom',
    };
    return planMap[plan];
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

  const activeCount = subscriptions.filter((s) => s.status === 'active').length;
  const trialCount = subscriptions.filter((s) => s.status === 'trial').length;
  const suspendedCount = subscriptions.filter((s) => s.status === 'suspended').length;
  const totalRevenue = subscriptions
    .filter((s) => s.status === 'active')
    .reduce((sum, s) => sum + (s.price_per_cycle || 0), 0);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Subscriptions Management</h1>
          <p className="text-gray-600 mt-1">
            Manage company subscription plans and billing
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
              <p className="text-sm text-gray-500">Total Subscriptions</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{subscriptions.length}</p>
            </div>
            <CreditCard className="w-8 h-8 text-blue-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Active</p>
              <p className="text-2xl font-bold text-green-600 mt-1">{activeCount}</p>
            </div>
            <CheckCircle className="w-8 h-8 text-green-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Trial</p>
              <p className="text-2xl font-bold text-yellow-600 mt-1">{trialCount}</p>
            </div>
            <AlertCircle className="w-8 h-8 text-yellow-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Monthly Revenue</p>
              <p className="text-2xl font-bold text-blue-600 mt-1">
                {totalRevenue.toLocaleString()} SAR
              </p>
            </div>
            <DollarSign className="w-8 h-8 text-blue-600" />
          </div>
        </div>
      </div>

      {loading ? (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading subscriptions...</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-blue-100 rounded-lg">
                <CreditCard className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-900">All Subscriptions</h2>
                <p className="text-sm text-gray-500">Manage company subscription plans</p>
              </div>
            </div>
          </div>

          {subscriptions.length === 0 ? (
            <div className="p-10 text-center text-gray-500">
              No subscriptions found.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Company
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Plan
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Billing
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Price
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Next Payment
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Limits
                    </th>
                    <th scope="col" className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {subscriptions.map((subscription) => {
                    const statusInfo = formatStatus(subscription.status);
                    const StatusIcon = statusInfo?.icon || CheckCircle;
                    const company = subscription.companies as any;

                    return (
                      <tr key={subscription.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4">
                          <div className="text-sm font-medium text-gray-900">
                            {company?.company_name_en || 'N/A'}
                          </div>
                          <div className="text-sm text-gray-500" dir="rtl">
                            {company?.company_name_ar || ''}
                          </div>
                          {company?.tadawul_symbol && (
                            <div className="text-xs text-gray-400 mt-1">
                              {company.tadawul_symbol}
                            </div>
                          )}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-blue-50 text-blue-700">
                            {formatPlan(subscription.subscription_plan)}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span
                            className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${statusInfo?.color || 'bg-gray-50 text-gray-700 border-gray-200'}`}
                          >
                            <StatusIcon className="w-3 h-3 mr-1" />
                            {statusInfo?.label || 'Unknown'}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {subscription.billing_cycle.charAt(0).toUpperCase() + subscription.billing_cycle.slice(1)}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {subscription.price_per_cycle?.toLocaleString() || 0} {subscription.currency}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {subscription.next_payment_date
                            ? new Date(subscription.next_payment_date).toLocaleDateString('en-GB')
                            : 'N/A'}
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-500">
                          <div className="text-xs">
                            {subscription.max_employees && (
                              <div>Employees: {subscription.max_employees}</div>
                            )}
                            {subscription.max_plans && (
                              <div>Plans: {subscription.max_plans}</div>
                            )}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-right text-sm">
                          <button
                            onClick={() => handleOpenEditModal(subscription)}
                            className="p-2 rounded-full hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                            aria-label={`Actions for subscription`}
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

      {showEditModal && selectedSubscription && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="bg-white rounded-xl shadow-xl max-w-lg w-full">
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
              <div>
                <h3 className="text-lg font-semibold text-gray-900">Update Subscription</h3>
                <p className="text-sm text-gray-500">
                  Change subscription status
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
                  onChange={(e) => setEditStatus(e.target.value as SubscriptionStatus)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="active">Active</option>
                  <option value="suspended">Suspended</option>
                  <option value="cancelled">Cancelled</option>
                  <option value="expired">Expired</option>
                  <option value="trial">Trial</option>
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

