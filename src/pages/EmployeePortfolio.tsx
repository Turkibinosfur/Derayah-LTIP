import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Briefcase, DollarSign, TrendingUp, Package, ArrowRightLeft, Calendar, CheckCircle, Clock } from 'lucide-react';
import { formatDate } from '../lib/dateUtils';
import PortfolioValuation from '../components/PortfolioValuation';

interface PortfolioData {
  id: string;
  portfolio_type: 'employee_vested';
  total_shares: number;
  available_shares: number;
  locked_shares: number;
  portfolio_number: string;
  created_at: string;
  updated_at: string;
}

interface GrantData {
  id: string;
  grant_number: string;
  total_shares: number;
  vested_shares: number;
  remaining_unvested_shares: number;
  grant_date: string;
  status: string;
  incentive_plans?: {
    plan_name_en: string;
    plan_code: string;
    plan_type: string;
    exercise_price?: number;
  };
}

interface TransferData {
  id: string;
  transfer_number: string;
  shares_transferred: number;
  transfer_date: string;
  status: string;
  transfer_type: string;
  grants?: {
    grant_number: string;
    incentive_plans?: {
      plan_name_en: string;
      plan_code: string;
    };
  };
}

export default function EmployeePortfolio() {
  const [portfolio, setPortfolio] = useState<PortfolioData | null>(null);
  const [grants, setGrants] = useState<GrantData[]>([]);
  const [transfers, setTransfers] = useState<TransferData[]>([]);
  const [loading, setLoading] = useState(true);
  const [companyInfo, setCompanyInfo] = useState<any>(null);
  const [sharePrice, setSharePrice] = useState<number>(30);
  const [tadawulSymbol, setTadawulSymbol] = useState('');

  useEffect(() => {
    loadPortfolioData();
  }, []);

  const loadPortfolioData = async () => {
    try {
      setLoading(true);
      
      // Get current user
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        window.location.href = '/employee/login';
        return;
      }

      // Get employee data
      const { data: employee, error: employeeError } = await supabase
        .from('employees')
        .select('id, company_id, first_name_en, last_name_en')
        .eq('user_id', user.id)
        .maybeSingle();

      if (employeeError || !employee) {
        console.error('Error loading employee:', employeeError);
        setLoading(false);
        return;
      }

      // Load company info, portfolio data, and grants in parallel
      const [companyRes, portfolioRes, grantsRes] = await Promise.all([
        supabase
          .from('companies')
          .select('company_name_en, tadawul_symbol, current_fmv, fmv_source')
          .eq('id', employee.company_id)
          .maybeSingle(),
        supabase
          .from('portfolios')
          .select('*')
          .eq('company_id', employee.company_id)
          .eq('employee_id', employee.id)
          .eq('portfolio_type', 'employee_vested')
          .maybeSingle(),
        supabase
          .from('grants')
          .select(`
            id,
            grant_number,
            total_shares,
            vested_shares,
            remaining_unvested_shares,
            grant_date,
            status,
            incentive_plans:plan_id (
              plan_name_en,
              plan_code,
              plan_type,
              exercise_price
            )
          `)
          .eq('employee_id', employee.id)
          .eq('status', 'active')
          .order('grant_date', { ascending: false })
      ]);

      if (companyRes.data) {
        setCompanyInfo(companyRes.data);
        setTadawulSymbol(companyRes.data.tadawul_symbol || '');
        // Use current_fmv if available, otherwise default to 30
        const fmv = companyRes.data.current_fmv;
        setSharePrice(fmv ? Number(fmv) : 30);
      }

      if (portfolioRes.data) {
        setPortfolio(portfolioRes.data);
        
        // Load transfers with correct portfolio ID
        const { data: transfersData, error: transfersError } = await supabase
          .from('transfers')
          .select(`
            id,
            transfer_number,
            shares_transferred,
            transfer_date,
            status,
            transfer_type,
            grants:grant_id (
              grant_number,
              incentive_plans:plan_id (
                plan_name_en,
                plan_code
              )
            )
          `)
          .eq('to_portfolio_id', portfolioRes.data.id)
          .order('transfer_date', { ascending: false })
          .limit(10);
        
        if (!transfersError && transfersData) {
          setTransfers(transfersData as TransferData[]);
        }
      }

      if (grantsRes.data) {
        setGrants(grantsRes.data as GrantData[]);
      }

    } catch (error) {
      console.error('Error loading portfolio data:', error);
    } finally {
      setLoading(false);
    }
  };

  // Calculate totals
  const totalShares = portfolio?.total_shares || 0;
  const availableShares = portfolio?.available_shares || 0;
  const lockedShares = portfolio?.locked_shares || 0;
  const totalVestedFromGrants = grants.reduce((sum, grant) => sum + Number(grant.vested_shares || 0), 0);
  const totalUnvestedFromGrants = grants.reduce((sum, grant) => sum + Number(grant.remaining_unvested_shares || 0), 0);

  // Calculate portfolio value
  const portfolioValue = totalShares * sharePrice;

  if (loading) {
    return (
      <div className="flex items-center justify-center" style={{ minHeight: 'calc(100vh - 200px)' }}>
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600 mx-auto"></div>
          <p className="text-gray-500 mt-4">Loading your portfolio...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">My Portfolio</h1>
        <p className="text-gray-600 mt-1">
          View your equity portfolio and transaction history
        </p>
      </div>

      {/* Portfolio Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Total Shares */}
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Total Shares</p>
              <p className="text-2xl font-bold text-gray-900 mt-1">
                {totalShares.toLocaleString()}
              </p>
            </div>
            <Package className="w-8 h-8 text-blue-600" />
          </div>
        </div>

        {/* Available Shares */}
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Available Shares</p>
              <p className="text-2xl font-bold text-green-600 mt-1">
                {availableShares.toLocaleString()}
              </p>
            </div>
            <CheckCircle className="w-8 h-8 text-green-600" />
          </div>
        </div>

        {/* Locked Shares */}
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Locked Shares</p>
              <p className="text-2xl font-bold text-amber-600 mt-1">
                {lockedShares.toLocaleString()}
              </p>
            </div>
            <Clock className="w-8 h-8 text-amber-600" />
          </div>
        </div>

        {/* Portfolio Value */}
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Portfolio Value</p>
              <p className="text-2xl font-bold text-purple-600 mt-1">
                SAR {portfolioValue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </p>
              <p className="text-xs text-gray-500 mt-1">
                @ SAR {sharePrice.toFixed(2)} per share
              </p>
            </div>
            <DollarSign className="w-8 h-8 text-purple-600" />
          </div>
        </div>
      </div>

      {/* Portfolio Details */}
      {portfolio ? (
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-6">
          <div className="flex items-center space-x-3 mb-4">
            <Briefcase className="w-6 h-6 text-blue-600" />
            <h2 className="text-xl font-bold text-gray-900">Portfolio Details</h2>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-500">Portfolio Number</p>
              <p className="text-lg font-semibold text-gray-900 mt-1">
                {portfolio.portfolio_number}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Company</p>
              <p className="text-lg font-semibold text-gray-900 mt-1">
                {companyInfo?.company_name_en || 'N/A'}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Created Date</p>
              <p className="text-lg font-semibold text-gray-900 mt-1">
                {formatDate(portfolio.created_at)}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Last Updated</p>
              <p className="text-lg font-semibold text-gray-900 mt-1">
                {formatDate(portfolio.updated_at)}
              </p>
            </div>
          </div>
        </div>
      ) : (
        <div className="bg-yellow-50 border border-yellow-200 rounded-xl p-6">
          <div className="flex items-center space-x-3">
            <Clock className="w-6 h-6 text-yellow-600" />
            <div>
              <h3 className="text-lg font-semibold text-yellow-900">No Portfolio Found</h3>
              <p className="text-sm text-yellow-700 mt-1">
                Your portfolio will be created automatically when shares are transferred to you.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Portfolio Valuation Chart */}
      {portfolio && tadawulSymbol && (
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Portfolio Valuation</h2>
          <PortfolioValuation
            tadawulSymbol={tadawulSymbol}
            vestedShares={totalVestedFromGrants}
            unvestedShares={totalUnvestedFromGrants}
          />
        </div>
      )}

      {/* Grants Breakdown */}
      {grants.length > 0 && (
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-6">
          <div className="flex items-center space-x-3 mb-4">
            <TrendingUp className="w-6 h-6 text-blue-600" />
            <h2 className="text-xl font-bold text-gray-900">Grants Breakdown</h2>
          </div>
          
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Grant Number
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Plan
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Total Shares
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Vested
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Unvested
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Grant Date
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {grants.map((grant) => (
                  <tr key={grant.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {grant.grant_number}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      <div>
                        <div className="font-medium">
                          {grant.incentive_plans?.plan_name_en || 'N/A'}
                        </div>
                        <div className="text-xs text-gray-500">
                          {grant.incentive_plans?.plan_code || ''} ({grant.incentive_plans?.plan_type || ''})
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {Number(grant.total_shares || 0).toLocaleString()}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-green-600 font-medium">
                      {Number(grant.vested_shares || 0).toLocaleString()}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                      {Number(grant.remaining_unvested_shares || 0).toLocaleString()}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(grant.grant_date)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Transaction History */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-6">
        <div className="flex items-center space-x-3 mb-4">
          <ArrowRightLeft className="w-6 h-6 text-blue-600" />
          <h2 className="text-xl font-bold text-gray-900">Transaction History</h2>
        </div>
        
        {transfers.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Transfer Number
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Grant
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Shares
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Date
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {transfers.map((transfer) => (
                  <tr key={transfer.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {transfer.transfer_number}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {transfer.grants?.grant_number || 'N/A'}
                      {transfer.grants?.incentive_plans?.plan_name_en && (
                        <div className="text-xs text-gray-500">
                          {transfer.grants.incentive_plans.plan_name_en}
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {Number(transfer.shares_transferred || 0).toLocaleString()}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(transfer.transfer_date)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        transfer.status === 'completed' 
                          ? 'bg-green-100 text-green-800'
                          : transfer.status === 'pending'
                          ? 'bg-yellow-100 text-yellow-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}>
                        {transfer.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500">
            <Calendar className="w-12 h-12 mx-auto mb-3 text-gray-400" />
            <p>No transactions yet</p>
            <p className="text-sm mt-1">Your transfer history will appear here once shares are transferred to your portfolio.</p>
          </div>
        )}
      </div>
    </div>
  );
}

