import { useEffect, useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../lib/supabase';
import { Building2, MoreVertical, X, CheckCircle, XCircle, AlertCircle, Users, FileText, Award, TrendingUp } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';

type VerificationStatus = 'pending' | 'verified' | 'rejected';
type CompanyStatus = 'active' | 'suspended' | 'inactive';

interface Company {
  id: string;
  company_name_en: string;
  company_name_ar: string;
  tadawul_symbol: string;
  commercial_registration_number: string;
  verification_status: VerificationStatus;
  status: CompanyStatus;
  total_reserved_shares: number;
  available_shares: number;
  created_at: string;
  updated_at: string;
  // Statistics
  employee_count?: number;
  plan_count?: number;
  grant_count?: number;
  admin_user_count?: number;
}

export default function OperatorCompanies() {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';
  const [companies, setCompanies] = useState<Company[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedCompany, setSelectedCompany] = useState<Company | null>(null);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editStatus, setEditStatus] = useState<CompanyStatus>('active');
  const [editVerificationStatus, setEditVerificationStatus] = useState<VerificationStatus>('pending');
  const [editSaving, setEditSaving] = useState(false);
  const [editError, setEditError] = useState<string | null>(null);
  const { userRole, setActiveCompany, isSuperAdmin } = useAuth();
  const navigate = useNavigate();

  const isSuperAdminUser = useMemo(() => {
    return isSuperAdmin() || userRole?.user_type === 'super_admin' || userRole?.role === 'super_admin';
  }, [userRole, isSuperAdmin]);

  useEffect(() => {
    if (!isSuperAdminUser) {
      setError(t('operatorConsole.accessDenied'));
      setLoading(false);
      return;
    }
    loadCompanies();
  }, [isSuperAdminUser]);

  const loadCompanies = async () => {
    try {
      setLoading(true);
      setError(null);

      // Load all companies
      const { data: companiesData, error: companiesError } = await supabase
        .from('companies')
        .select('*')
        .order('created_at', { ascending: false });

      if (companiesError) throw companiesError;

      // Load statistics for each company
      const companiesWithStats = await Promise.all(
        (companiesData || []).map(async (company) => {
          // Get employee count
          const { count: employeeCount } = await supabase
            .from('employees')
            .select('*', { count: 'exact', head: true })
            .eq('company_id', company.id);

          // Get plan count
          const { count: planCount } = await supabase
            .from('incentive_plans')
            .select('*', { count: 'exact', head: true })
            .eq('company_id', company.id);

          // Get grant count
          const { count: grantCount } = await supabase
            .from('grants')
            .select('*', { count: 'exact', head: true })
            .eq('company_id', company.id);

          // Get admin user count
          const { count: adminUserCount } = await supabase
            .from('company_users')
            .select('*', { count: 'exact', head: true })
            .eq('company_id', company.id)
            .eq('is_active', true);

          return {
            ...company,
            employee_count: employeeCount || 0,
            plan_count: planCount || 0,
            grant_count: grantCount || 0,
            admin_user_count: adminUserCount || 0,
          } as Company;
        })
      );

      setCompanies(companiesWithStats);
    } catch (err) {
      console.error('Error loading companies:', err);
      setError(t('operatorConsole.failedToLoad'));
    } finally {
      setLoading(false);
    }
  };

  const handleOpenEditModal = (company: Company) => {
    setSelectedCompany(company);
    setEditStatus(company.status);
    setEditVerificationStatus(company.verification_status);
    setEditError(null);
    setShowEditModal(true);
  };

  const handleCloseEditModal = () => {
    setSelectedCompany(null);
    setEditError(null);
    setShowEditModal(false);
  };

  const handleSaveEdit = async () => {
    if (!selectedCompany) return;

    try {
      setEditSaving(true);
      setEditError(null);

      const { error: updateError } = await supabase
        .from('companies')
        .update({
          status: editStatus,
          verification_status: editVerificationStatus,
          updated_at: new Date().toISOString(),
        })
        .eq('id', selectedCompany.id);

      if (updateError) {
        console.error('Error updating company:', updateError);
        setEditError(`Failed to save changes: ${updateError.message}`);
        return;
      }

      handleCloseEditModal();
      await loadCompanies();
    } catch (err: any) {
      console.error('Error updating company:', err);
      setEditError(`Failed to save changes: ${err?.message || 'Unknown error occurred'}`);
    } finally {
      setEditSaving(false);
    }
  };

  const handleViewCompany = (companyId: string, companyName: string) => {
    setActiveCompany(companyId, companyName);
    navigate('/dashboard');
  };

  const formatVerificationStatus = (status: VerificationStatus) => {
    const statusMap = {
      pending: { label: t('operatorConsole.pending'), color: 'bg-yellow-50 text-yellow-700 border-yellow-200', icon: AlertCircle },
      verified: { label: t('operatorConsole.verified'), color: 'bg-green-50 text-green-700 border-green-200', icon: CheckCircle },
      rejected: { label: t('operatorConsole.rejected'), color: 'bg-red-50 text-red-700 border-red-200', icon: XCircle },
    };
    return statusMap[status];
  };

  const formatCompanyStatus = (status: CompanyStatus) => {
    const statusMap = {
      active: { label: 'Active', color: 'bg-green-50 text-green-700' },
      suspended: { label: t('operatorConsole.suspended'), color: 'bg-yellow-50 text-yellow-700' },
      inactive: { label: t('operatorConsole.inactive'), color: 'bg-gray-100 text-gray-500' },
    };
    return statusMap[status];
  };

  if (!isSuperAdminUser) {
    return (
      <div className="p-6">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-red-700">{t('operatorConsole.accessDenied')}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">{t('operatorConsole.title')}</h1>
          <p className="text-gray-600 mt-1">
            {t('operatorConsole.description')}
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
              <p className="text-sm text-gray-500">{t('operatorConsole.totalCompanies')}</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{companies.length}</p>
            </div>
            <Building2 className="w-8 h-8 text-blue-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">{t('operatorConsole.verified')}</p>
              <p className="text-2xl font-bold text-green-600 mt-1">
                {companies.filter((c) => c.verification_status === 'verified').length}
              </p>
            </div>
            <CheckCircle className="w-8 h-8 text-green-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">{t('operatorConsole.pending')}</p>
              <p className="text-2xl font-bold text-yellow-600 mt-1">
                {companies.filter((c) => c.verification_status === 'pending').length}
              </p>
            </div>
            <AlertCircle className="w-8 h-8 text-yellow-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">{t('operatorConsole.active')}</p>
              <p className="text-2xl font-bold text-blue-600 mt-1">
                {companies.filter((c) => c.status === 'active').length}
              </p>
            </div>
            <TrendingUp className="w-8 h-8 text-blue-600" />
          </div>
        </div>
      </div>

      {loading ? (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">{t('operatorConsole.loadingCompanies')}</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-blue-100 rounded-lg">
                <Building2 className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-900">{t('operatorConsole.allCompanies')}</h2>
                <p className="text-sm text-gray-500">{t('operatorConsole.manageCompanies')}</p>
              </div>
            </div>
          </div>

          {companies.length === 0 ? (
            <div className="p-10 text-center text-gray-500">
              {t('operatorConsole.noCompanies')}
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {t('operatorConsole.company')}
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {t('operatorConsole.tadawulSymbol')}
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {t('operatorConsole.verification')}
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {t('operatorConsole.status')}
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {t('operatorConsole.statistics')}
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {t('operatorConsole.shares')}
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {t('operatorConsole.created')}
                    </th>
                    <th scope="col" className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                      {t('operatorConsole.actions')}
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {companies.map((company) => {
                    const verificationStatusInfo = formatVerificationStatus(company.verification_status);
                    const companyStatusInfo = formatCompanyStatus(company.status);
                    const StatusIcon = verificationStatusInfo.icon;

                    return (
                      <tr key={company.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4">
                          <div className="text-sm font-medium text-gray-900">
                            {company.company_name_en}
                          </div>
                          <div className="text-sm text-gray-500" dir="rtl">
                            {company.company_name_ar}
                          </div>
                          <div className="text-xs text-gray-400 mt-1">
                            CR: {company.commercial_registration_number}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-700">
                            {company.tadawul_symbol}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span
                            className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${verificationStatusInfo.color}`}
                          >
                            <StatusIcon className="w-3 h-3 mr-1" />
                            {verificationStatusInfo.label}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span
                            className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold ${companyStatusInfo.color}`}
                          >
                            {companyStatusInfo.label}
                          </span>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex flex-wrap gap-2 text-xs">
                            <div className="flex items-center text-gray-600">
                              <Users className="w-3 h-3 mr-1" />
                              {company.employee_count || 0}
                            </div>
                            <div className="flex items-center text-gray-600">
                              <FileText className="w-3 h-3 mr-1" />
                              {company.plan_count || 0}
                            </div>
                            <div className="flex items-center text-gray-600">
                              <Award className="w-3 h-3 mr-1" />
                              {company.grant_count || 0}
                            </div>
                            <div className="flex items-center text-gray-600">
                              <Users className="w-3 h-3 mr-1" />
                              {company.admin_user_count || 0} admins
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <div>Total: {company.total_reserved_shares?.toLocaleString() || 0}</div>
                          <div className="text-xs">Available: {company.available_shares?.toLocaleString() || 0}</div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {new Date(company.created_at).toLocaleDateString('en-GB')}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-right text-sm">
                          <div className="flex items-center justify-end gap-2">
                            <button
                              onClick={() => handleViewCompany(company.id, company.company_name_en)}
                              className="px-3 py-1 text-xs font-medium text-blue-600 hover:bg-blue-50 rounded-lg transition"
                            >
                              View
                            </button>
                            <button
                              onClick={() => handleOpenEditModal(company)}
                              className="p-2 rounded-full hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                              aria-label={`Actions for ${company.company_name_en}`}
                            >
                              <MoreVertical className="w-5 h-5 text-gray-500" />
                            </button>
                          </div>
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

      {showEditModal && selectedCompany && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="bg-white rounded-xl shadow-xl max-w-lg w-full">
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
              <div>
                <h3 className="text-lg font-semibold text-gray-900">Manage Company</h3>
                <p className="text-sm text-gray-500">
                  Update verification and status for {selectedCompany.company_name_en}
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
                <label className="block text-sm font-medium text-gray-700 mb-2">{t('operatorConsole.verificationStatus')}</label>
                <select
                  value={editVerificationStatus}
                  onChange={(e) => setEditVerificationStatus(e.target.value as VerificationStatus)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="pending">{t('operatorConsole.pending')}</option>
                  <option value="verified">{t('operatorConsole.verified')}</option>
                  <option value="rejected">{t('operatorConsole.rejected')}</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">{t('operatorConsole.companyStatus')}</label>
                <select
                  value={editStatus}
                  onChange={(e) => setEditStatus(e.target.value as CompanyStatus)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="active">{t('operatorConsole.active')}</option>
                  <option value="suspended">{t('operatorConsole.suspended')}</option>
                  <option value="inactive">{t('operatorConsole.inactive')}</option>
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
                {editSaving ? t('common.loading') : t('operatorConsole.saveChanges')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

