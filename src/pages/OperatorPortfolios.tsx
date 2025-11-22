import { useEffect, useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../lib/supabase';
import { Briefcase, MoreVertical, Building2, User, TrendingUp, Lock, DollarSign, Users } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';

type PortfolioType = 'company_reserved' | 'employee_vested';

interface Portfolio {
  id: string;
  portfolio_type: PortfolioType;
  company_id: string;
  employee_id: string | null;
  total_shares: number;
  available_shares: number;
  locked_shares: number;
  portfolio_number: string;
  created_at: string;
  updated_at: string;
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

export default function OperatorPortfolios() {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';
  const [portfolios, setPortfolios] = useState<Portfolio[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filterType, setFilterType] = useState<'all' | PortfolioType>('all');
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
    loadPortfolios();
  }, [isSuperAdminUser]);

  const loadPortfolios = async () => {
    try {
      setLoading(true);
      setError(null);

      const { data, error: portfoliosError } = await supabase
        .from('portfolios')
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

      if (portfoliosError) throw portfoliosError;

      setPortfolios((data || []) as Portfolio[]);
    } catch (err) {
      console.error('Error loading portfolios:', err);
      setError('Failed to load portfolios.');
    } finally {
      setLoading(false);
    }
  };

  const filteredPortfolios = useMemo(() => {
    if (filterType === 'all') return portfolios;
    return portfolios.filter((p) => p.portfolio_type === filterType);
  }, [portfolios, filterType]);

  const statistics = useMemo(() => {
    const companyPortfolios = portfolios.filter((p) => p.portfolio_type === 'company_reserved');
    const employeePortfolios = portfolios.filter((p) => p.portfolio_type === 'employee_vested');
    
    const totalCompanyShares = companyPortfolios.reduce((sum, p) => sum + (p.total_shares || 0), 0);
    const totalEmployeeShares = employeePortfolios.reduce((sum, p) => sum + (p.total_shares || 0), 0);
    const totalAvailableShares = portfolios.reduce((sum, p) => sum + (p.available_shares || 0), 0);
    const totalLockedShares = portfolios.reduce((sum, p) => sum + (p.locked_shares || 0), 0);
    
    const uniqueCompanies = new Set(portfolios.map((p) => p.company_id)).size;
    const uniqueEmployees = new Set(employeePortfolios.map((p) => p.employee_id).filter(Boolean)).size;

    return {
      totalPortfolios: portfolios.length,
      companyPortfolios: companyPortfolios.length,
      employeePortfolios: employeePortfolios.length,
      totalCompanyShares,
      totalEmployeeShares,
      totalAvailableShares,
      totalLockedShares,
      uniqueCompanies,
      uniqueEmployees,
    };
  }, [portfolios]);

  if (!isSuperAdminUser) {
    return (
      <div className="p-6">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-red-700">Access denied. Super admin only.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">All Portfolios</h1>
          <p className="text-gray-600 mt-1">
            View all portfolios across all companies with statistics
          </p>
        </div>
        <div className="flex items-center gap-2">
          <select
            value={filterType}
            onChange={(e) => setFilterType(e.target.value as 'all' | PortfolioType)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="all">All Types</option>
            <option value="company_reserved">Company Reserved</option>
            <option value="employee_vested">Employee Vested</option>
          </select>
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
              <p className="text-sm text-gray-500">Total Portfolios</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">{statistics.totalPortfolios}</p>
              <p className="text-xs text-gray-500 mt-1">
                {statistics.companyPortfolios} company, {statistics.employeePortfolios} employee
              </p>
            </div>
            <Briefcase className="w-8 h-8 text-blue-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Total Companies</p>
              <p className="text-2xl font-bold text-blue-600 mt-1">{statistics.uniqueCompanies}</p>
            </div>
            <Building2 className="w-8 h-8 text-blue-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Total Shares</p>
              <p className="text-2xl font-bold text-green-600 mt-1">
                {(statistics.totalCompanyShares + statistics.totalEmployeeShares).toLocaleString()}
              </p>
              <p className="text-xs text-gray-500 mt-1">
                {statistics.totalCompanyShares.toLocaleString()} company, {statistics.totalEmployeeShares.toLocaleString()} employee
              </p>
            </div>
            <TrendingUp className="w-8 h-8 text-green-600" />
          </div>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Available Shares</p>
              <p className="text-2xl font-bold text-blue-600 mt-1">
                {statistics.totalAvailableShares.toLocaleString()}
              </p>
              <p className="text-xs text-gray-500 mt-1">
                {statistics.totalLockedShares.toLocaleString()} locked
              </p>
            </div>
            <Lock className="w-8 h-8 text-blue-600" />
          </div>
        </div>
      </div>

      {loading ? (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading portfolios...</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="p-2 bg-blue-100 rounded-lg">
                <Briefcase className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-900">All Portfolios</h2>
                <p className="text-sm text-gray-500">
                  Showing {filteredPortfolios.length} of {portfolios.length} portfolios
                </p>
              </div>
            </div>
          </div>

          {filteredPortfolios.length === 0 ? (
            <div className="p-10 text-center text-gray-500">
              No portfolios found.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Portfolio #
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Type
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Company
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Owner
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Total Shares
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Available
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Locked
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Created
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {filteredPortfolios.map((portfolio) => {
                    const company = portfolio.companies as any;
                    const employee = portfolio.employees as any;

                    return (
                      <tr key={portfolio.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm font-medium text-gray-900">
                            {portfolio.portfolio_number}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span
                            className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold ${
                              portfolio.portfolio_type === 'company_reserved'
                                ? 'bg-blue-50 text-blue-700'
                                : 'bg-green-50 text-green-700'
                            }`}
                          >
                            {portfolio.portfolio_type === 'company_reserved' ? (
                              <>
                                <Building2 className="w-3 h-3 mr-1" />
                                Company
                              </>
                            ) : (
                              <>
                                <User className="w-3 h-3 mr-1" />
                                Employee
                              </>
                            )}
                          </span>
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
                          {portfolio.portfolio_type === 'employee_vested' && employee ? (
                            <>
                              <div className="text-sm font-medium text-gray-900">
                                {employee.first_name_en} {employee.last_name_en}
                              </div>
                              <div className="text-xs text-gray-500">
                                #{employee.employee_number}
                              </div>
                            </>
                          ) : (
                            <span className="text-sm text-gray-400">Company Reserved</span>
                          )}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                          {portfolio.total_shares?.toLocaleString() || 0}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-green-600">
                          {portfolio.available_shares?.toLocaleString() || 0}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {portfolio.locked_shares?.toLocaleString() || 0}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {new Date(portfolio.created_at).toLocaleDateString('en-GB')}
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
    </div>
  );
}

