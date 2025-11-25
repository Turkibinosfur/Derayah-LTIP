import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../lib/supabase';
import { TrendingUp, Briefcase, Lock, DollarSign, Calendar, AlertCircle, ArrowRightLeft, Package, Activity } from 'lucide-react';
import { formatDate } from '../lib/dateUtils';

interface PortfolioData {
  id: string;
  portfolio_type: 'company_reserved' | 'employee_vested';
  total_shares: number;
  available_shares: number;
  locked_shares: number;
  portfolio_number: string;
}

interface GrantSummary {
  total_grants: number;
  total_shares: number;
  vested_shares: number;
  unvested_shares: number;
}

interface PlanSummary {
  total_allocated: number;
  total_granted: number;
  total_available: number;
}

interface RecentTransfer {
  id: string;
  transfer_number: string;
  shares_transferred: number;
  transfer_date: string;
  status: string;
  transfer_type: string;
  employees?: {
    first_name_en: string;
    last_name_en: string;
  };
  grants?: {
    grant_number: string;
  };
}

export default function Portfolio() {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';
  const [portfolios, setPortfolios] = useState<PortfolioData[]>([]);
  const [grantSummary, setGrantSummary] = useState<GrantSummary>({
    total_grants: 0,
    total_shares: 0,
    vested_shares: 0,
    unvested_shares: 0,
  });
  const [planSummary, setPlanSummary] = useState<PlanSummary>({
    total_allocated: 0,
    total_granted: 0,
    total_available: 0,
  });
  const [loading, setLoading] = useState(true);
  const [companyInfo, setCompanyInfo] = useState<any>(null);
  const [recentTransfers, setRecentTransfers] = useState<RecentTransfer[]>([]);
  const [esopPoolTotal, setEsopPoolTotal] = useState<number>(0);

  useEffect(() => {
    loadPortfolioData();
  }, []);

  const loadPortfolioData = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: companyUser } = await supabase
        .from('company_users')
        .select('company_id, companies(*)')
        .eq('user_id', user.id)
        .maybeSingle();

      if (companyUser) {
        setCompanyInfo(companyUser);

        const [portfoliosRes, grantsRes, plansRes, employeeShareholdersRes] = await Promise.all([
          supabase
            .from('portfolios')
            .select('*')
            .eq('company_id', companyUser.company_id),
          supabase
            .from('grants')
            .select('id, total_shares, vested_shares, remaining_unvested_shares, status')
            .eq('company_id', companyUser.company_id),
          supabase
            .from('incentive_plans')
            .select('total_shares_allocated, shares_granted')
            .eq('company_id', companyUser.company_id),
          supabase
            .from('shareholders')
            .select('shares_owned')
            .eq('company_id', companyUser.company_id)
            .eq('shareholder_type', 'employee')
            .eq('is_active', true),
        ]);

        setPortfolios(portfoliosRes.data || []);

        // Get all active grant IDs first
        const activeGrantIds = (grantsRes.data || [])
          .filter(grant => grant.status === 'active')
          .map(grant => grant.id);

        // Load vesting events to calculate ACTUAL vested shares
        // Use the same logic as LTIP Pools page which correctly shows 2,516 vested
        let vestingEventsData: any[] = [];
        if (activeGrantIds.length > 0) {
          const { data: vestingEvents, error: vestingEventsError } = await supabase
            .from('vesting_events')
            .select('grant_id, shares_to_vest, status')
            .in('grant_id', activeGrantIds);

          if (vestingEventsError) {
            console.warn('Error loading vesting events:', vestingEventsError);
          } else {
            vestingEventsData = vestingEvents || [];
          }
        }

        // Calculate actual vested shares from vesting_events
        // Match LTIP Pools page logic: vested statuses = ['vested', 'transferred', 'exercised', 'due']
        const vestedSharesByGrant: { [key: string]: number } = {};
        const vestedStatuses = ['vested', 'transferred', 'exercised', 'due'];
        
        vestingEventsData.forEach((event: any) => {
          if (!vestedSharesByGrant[event.grant_id]) {
            vestedSharesByGrant[event.grant_id] = 0;
          }
          
          // Count shares as vested if status matches vested statuses (same as LTIP Pools page)
          if (vestedStatuses.includes(event.status)) {
            vestedSharesByGrant[event.grant_id] += Math.floor(Number(event.shares_to_vest || 0));
          }
        });

        // Calculate grant summary from actual data
        // Match LTIP Pools page: count ALL grants (not just active) for total granted shares
        if (grantsRes.data) {
          // Get ALL grants for total granted calculation (like LTIP Pools page)
          const allGrants = grantsRes.data;
          // But only active grants for vested/unvested calculation (they have vesting events)
          const activeGrants = allGrants.filter(grant => grant.status === 'active');
          
          // Calculate total granted shares from ALL grants (regardless of status)
          // This matches LTIP Pools page logic
          const totalGrantedShares = allGrants.reduce(
            (sum, grant) => sum + Math.floor(Number(grant.total_shares || 0)),
            0
          );
          
          // Calculate vested and unvested only from active grants (they have vesting events)
          const vestedUnvestedSummary = activeGrants.reduce(
            (acc, grant) => {
              const totalShares = Number(grant.total_shares || 0);
              const actualVestedShares = vestedSharesByGrant[grant.id] || 0;
              // Ensure we don't exceed total shares
              const cappedVestedShares = Math.min(actualVestedShares, totalShares);
              const unvestedShares = Math.max(0, totalShares - cappedVestedShares);
              
              return {
                total_grants: acc.total_grants + 1,
                vested_shares: acc.vested_shares + cappedVestedShares,
                unvested_shares: acc.unvested_shares + unvestedShares,
              };
            },
            { total_grants: 0, vested_shares: 0, unvested_shares: 0 }
          );
          
          // Debug logging
          console.log('📊 Portfolio Calculation Debug:');
          console.log('All grants (total):', allGrants.length);
          console.log('Active grants:', activeGrants.length);
          console.log('Active grant IDs:', activeGrantIds);
          console.log('Vesting events found:', vestingEventsData?.length || 0);
          console.log('Vested shares by grant:', vestedSharesByGrant);
          console.log('Vested statuses used:', vestedStatuses);
          
          // Show status breakdown
          const statusBreakdown: Record<string, number> = {};
          vestingEventsData.forEach((event: any) => {
            const status = event.status || 'unknown';
            statusBreakdown[status] = (statusBreakdown[status] || 0) + Math.floor(Number(event.shares_to_vest || 0));
          });
          console.log('Status breakdown (shares per status):', statusBreakdown);
          
          const summary = {
            total_grants: vestedUnvestedSummary.total_grants,
            total_shares: totalGrantedShares, // Total from ALL grants (matches LTIP Pools)
            vested_shares: vestedUnvestedSummary.vested_shares,
            unvested_shares: vestedUnvestedSummary.unvested_shares,
          };
          
          console.log('Final summary:', summary);
          console.log('Total granted (all grants):', totalGrantedShares);
          console.log('Vested (active grants only):', vestedUnvestedSummary.vested_shares);
          console.log('Unvested (active grants only):', vestedUnvestedSummary.unvested_shares);
          setGrantSummary(summary);
        }

        // Get LTIP pools total
        const { data: esopPoolsData } = await supabase
          .from('ltip_pools')
          .select('total_shares_allocated')
          .eq('company_id', companyUser.company_id)
          .eq('status', 'active');
        
        if (esopPoolsData) {
          const totalEsopShares = esopPoolsData.reduce(
            (sum, pool) => sum + Number(pool.total_shares_allocated || 0),
            0
          );
          setEsopPoolTotal(totalEsopShares);
        }
        
        // Calculate LTIP Pool from grants data (total shares granted to employees)
        if (grantsRes.data && grantsRes.data.length > 0) {
          // Use all grants (active and inactive) to show total shares ever granted to employees
          const totalGrantedShares = grantsRes.data.reduce(
            (sum, grant) => sum + Number(grant.total_shares || 0),
            0
          );
          
          // Get total allocated from LTIP pools (priority) or incentive plans
          let totalAllocatedShares = esopPoolsData?.reduce(
            (sum, pool) => sum + Number(pool.total_shares_allocated || 0),
            0
          ) || 0;
          
          // If no LTIP pools, use incentive plans
          if (totalAllocatedShares === 0 && plansRes.data) {
            totalAllocatedShares = plansRes.data.reduce(
              (sum, plan) => sum + Number(plan.total_shares_allocated || 0),
              0
            );
          }
          
          const planTotal = {
            total_allocated: totalAllocatedShares, // Total shares allocated in LTIP pools or plans
            total_granted: totalGrantedShares,       // Total shares granted to employees (all grants)
            total_available: totalAllocatedShares - totalGrantedShares, // Available = allocated - granted
          };
          setPlanSummary(planTotal);
        } else if (plansRes.data) {
          // Fallback to incentive plans if no grants found
          const planTotal = plansRes.data.reduce(
            (acc, plan) => ({
              total_allocated: acc.total_allocated + Number(plan.total_shares_allocated || 0),
              total_granted: acc.total_granted + Number(plan.shares_granted || 0),
              total_available: acc.total_available + (Number(plan.total_shares_allocated || 0) - Number(plan.shares_granted || 0)),
            }),
            { total_allocated: 0, total_granted: 0, total_available: 0 }
          );
          setPlanSummary(planTotal);
        }
        
        // Load recent transfers
        const { data: transfersData } = await supabase
          .from('share_transfers')
          .select(`
            id,
            transfer_number,
            shares_transferred,
            transfer_date,
            status,
            transfer_type,
            employees (
              first_name_en,
              last_name_en
            ),
            grants (
              grant_number
            )
          `)
          .eq('company_id', companyUser.company_id)
          .order('created_at', { ascending: false })
          .limit(10);
        
        if (transfersData) {
          setRecentTransfers(transfersData as RecentTransfer[]);
        }
      }
    } catch (error) {
      console.error('Error loading portfolio data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  const companyReserved = portfolios.find(p => p.portfolio_type === 'company_reserved');
  const employeeVested = portfolios.find(p => p.portfolio_type === 'employee_vested');

  return (
    <div className={`space-y-6 ${isRTL ? 'text-right' : 'text-left'}`} dir={isRTL ? 'rtl' : 'ltr'}>
      <div>
        <h1 className="text-2xl font-bold text-gray-900">{t('portfolio.title')}</h1>
        <p className="text-gray-600 mt-1">{t('portfolio.description')}</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="bg-blue-100 p-3 rounded-lg">
              <Briefcase className="w-6 h-6 text-blue-600" />
            </div>
          </div>
          <p className="text-sm text-gray-600 mb-1">{t('portfolio.ltipPoolAllocated')}</p>
          <p className="text-2xl font-bold text-gray-900">
            {planSummary.total_allocated.toLocaleString()}
          </p>
          <p className="text-xs text-gray-500 mt-2">
            Available: {planSummary.total_available.toLocaleString()}
          </p>
        </div>

        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="bg-green-100 p-3 rounded-lg">
              <TrendingUp className="w-6 h-6 text-green-600" />
            </div>
          </div>
          <p className="text-sm text-gray-600 mb-1">{t('portfolio.grantedShares')}</p>
          <p className="text-2xl font-bold text-gray-900">
            {grantSummary.total_shares.toLocaleString()}
          </p>
          <p className="text-xs text-gray-500 mt-2">
            Active Grants: {grantSummary.total_grants}
          </p>
        </div>

        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="bg-emerald-100 p-3 rounded-lg">
              <DollarSign className="w-6 h-6 text-emerald-600" />
            </div>
          </div>
          <p className="text-sm text-gray-600 mb-1">{t('portfolio.vestedShares')}</p>
          <p className="text-2xl font-bold text-emerald-600">
            {grantSummary.vested_shares.toLocaleString()}
          </p>
          <p className="text-xs text-gray-500 mt-2">
            {grantSummary.total_shares > 0 ? ((grantSummary.vested_shares / grantSummary.total_shares) * 100).toFixed(1) : 0}% of Granted
          </p>
        </div>

        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="bg-amber-100 p-3 rounded-lg">
              <Calendar className="w-6 h-6 text-amber-600" />
            </div>
          </div>
          <p className="text-sm text-gray-600 mb-1">{t('portfolio.unvestedShares')}</p>
          <p className="text-2xl font-bold text-gray-900">
            {grantSummary.unvested_shares.toLocaleString()}
          </p>
          <p className="text-xs text-gray-500 mt-2">
            {grantSummary.total_shares > 0 ? ((grantSummary.unvested_shares / grantSummary.total_shares) * 100).toFixed(1) : 0}% of Granted
          </p>
        </div>
      </div>

      <div className="bg-white rounded-lg border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-lg font-semibold text-gray-900">{t('portfolio.grantSummary')}</h2>
        </div>
        <div className="p-6">
          <div className="space-y-4">
            <div className="flex items-center justify-between pb-4 border-b border-gray-200">
              <span className="text-sm text-gray-600">{t('portfolio.totalGrantsIssued')}</span>
              <span className="text-lg font-semibold text-gray-900">{grantSummary.total_grants}</span>
            </div>
            <div className="flex items-center justify-between pb-4 border-b border-gray-200">
              <span className="text-sm text-gray-600">{t('portfolio.totalSharesGranted')}</span>
              <span className="text-lg font-semibold text-gray-900">{grantSummary.total_shares.toLocaleString()}</span>
            </div>
            <div className="flex items-center justify-between pb-4 border-b border-gray-200">
              <span className="text-sm text-gray-600">{t('portfolio.vestedSharesLabel')}</span>
              <span className="text-lg font-semibold text-green-600">{grantSummary.vested_shares.toLocaleString()}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">{t('portfolio.unvestedSharesLabel')}</span>
              <span className="text-lg font-semibold text-gray-900">{grantSummary.unvested_shares.toLocaleString()}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Company Reserved Portfolio - Enhanced */}
      {companyReserved && (
        <div className="bg-white rounded-lg border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
                  <Package className="w-5 h-5 text-blue-600" />
                  Company Reserved Portfolio
                </h2>
                <p className="text-sm text-gray-600 mt-1">Portfolio Number: {companyReserved.portfolio_number}</p>
                {esopPoolTotal > 0 && (
                  <p className="text-xs text-blue-600 mt-1">
                    Synced with LTIP Pools: {esopPoolTotal.toLocaleString()} shares
                  </p>
                )}
              </div>
              <div className="text-right">
                <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium ${
                  Number(companyReserved.available_shares) > 0 
                    ? 'bg-green-100 text-green-800' 
                    : 'bg-gray-100 text-gray-800'
                }`}>
                  {Number(companyReserved.available_shares) > 0 ? t('portfolio.active') : t('portfolio.fullyAllocated')}
                </span>
              </div>
            </div>
          </div>
          
          <div className="p-6">
            {/* Share Metrics */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
              <div className="bg-gray-50 rounded-lg p-4">
                <div className="flex items-center justify-between mb-2">
                  <p className="text-sm text-gray-600">{t('portfolio.totalShares')}</p>
                  <Briefcase className="w-4 h-4 text-gray-400" />
                </div>
                <p className="text-2xl font-bold text-gray-900">{Number(companyReserved.total_shares).toLocaleString()}</p>
                <p className="text-xs text-gray-500 mt-1">
                  {companyReserved.total_shares > 0 
                    ? `${((companyReserved.total_shares / (planSummary.total_allocated || companyReserved.total_shares)) * 100).toFixed(1)}% of LTIP Pool`
                    : t('portfolio.noSharesAllocated')
                  }
                </p>
              </div>
              
              <div className="bg-green-50 rounded-lg p-4">
                <div className="flex items-center justify-between mb-2">
                  <p className="text-sm text-gray-600">{t('portfolio.available')}</p>
                  <TrendingUp className="w-4 h-4 text-green-400" />
                </div>
                <p className="text-2xl font-bold text-green-600">{Number(companyReserved.available_shares).toLocaleString()}</p>
                <p className="text-xs text-gray-500 mt-1">
                  {companyReserved.total_shares > 0 
                    ? `${((companyReserved.available_shares / companyReserved.total_shares) * 100).toFixed(1)}% of total`
                    : t('portfolio.noSharesAvailable')
                  }
                </p>
              </div>
              
              <div className="bg-amber-50 rounded-lg p-4">
                <div className="flex items-center justify-between mb-2">
                  <p className="text-sm text-gray-600">Locked (Granted)</p>
                  <Lock className="w-4 h-4 text-amber-400" />
                </div>
                <p className="text-2xl font-bold text-gray-900">{Number(companyReserved.locked_shares).toLocaleString()}</p>
                <p className="text-xs text-gray-500 mt-1">
                  {companyReserved.total_shares > 0 
                    ? `${((companyReserved.locked_shares / companyReserved.total_shares) * 100).toFixed(1)}% of total`
                    : t('portfolio.noSharesLocked')
                  }
                </p>
              </div>
            </div>
            
            {/* Visual Progress Bar */}
            {companyReserved.total_shares > 0 && (
              <div className="mb-6">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-gray-700">Portfolio Allocation</span>
                  <span className="text-xs text-gray-500">
                    {((companyReserved.available_shares / companyReserved.total_shares) * 100).toFixed(1)}% Available
                  </span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-4 overflow-hidden">
                  <div className="flex h-full">
                    <div 
                      className="bg-green-500 transition-all duration-300"
                      style={{ width: `${(companyReserved.available_shares / companyReserved.total_shares) * 100}%` }}
                    />
                    <div 
                      className="bg-amber-500 transition-all duration-300"
                      style={{ width: `${(companyReserved.locked_shares / companyReserved.total_shares) * 100}%` }}
                    />
                  </div>
                </div>
                <div className="flex items-center justify-between mt-2 text-xs text-gray-600">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-green-500 rounded"></div>
                    <span>{t('portfolio.available')}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 bg-amber-500 rounded"></div>
                    <span>Locked (Granted)</span>
                  </div>
                </div>
              </div>
            )}
            
            {/* Share Movement Flow */}
            <div className="border-t border-gray-200 pt-6">
              <h3 className="text-sm font-semibold text-gray-900 mb-4 flex items-center gap-2">
                <Activity className="w-4 h-4" />
                Share Movement Flow
              </h3>
              <div className="flex items-center justify-between text-xs text-gray-600">
                <div className="flex-1 text-center">
                  <div className="bg-blue-50 rounded-lg p-3 mb-2">
                    <p className="font-semibold text-blue-900">{t('portfolio.ltipPools')}</p>
                    <p className="text-blue-700">{planSummary.total_allocated.toLocaleString()} shares</p>
                  </div>
                </div>
                <ArrowRightLeft className="w-5 h-5 text-gray-400 mx-2" />
                <div className="flex-1 text-center">
                  <div className="bg-purple-50 rounded-lg p-3 mb-2">
                    <p className="font-semibold text-purple-900">{t('portfolio.companyPortfolio')}</p>
                    <p className="text-purple-700">{companyReserved.total_shares.toLocaleString()} shares</p>
                  </div>
                </div>
                <ArrowRightLeft className="w-5 h-5 text-gray-400 mx-2" />
                <div className="flex-1 text-center">
                  <div className="bg-green-50 rounded-lg p-3 mb-2">
                    <p className="font-semibold text-green-900">{t('portfolio.employeeGrants')}</p>
                    <p className="text-green-700">{grantSummary.total_shares.toLocaleString()} shares</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
      
      {/* Recent Transfers */}
      {recentTransfers.length > 0 && (
        <div className="bg-white rounded-lg border border-gray-200">
          <div className="p-6 border-b border-gray-200">
            <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
              <ArrowRightLeft className="w-5 h-5 text-blue-600" />
              {t('portfolio.recentTransfers')}
            </h2>
            <p className="text-sm text-gray-600 mt-1">{t('portfolio.latestShareMovements')}</p>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Transfer #
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Employee
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
                {recentTransfers.map((transfer) => (
                  <tr key={transfer.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {transfer.transfer_number}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {transfer.employees 
                        ? `${transfer.employees.first_name_en} ${transfer.employees.last_name_en}`
                        : 'N/A'
                      }
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {transfer.grants?.grant_number || 'N/A'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {Number(transfer.shares_transferred).toLocaleString()}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(transfer.transfer_date)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                        transfer.status === 'transferred' 
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
        </div>
      )}

      <div className="bg-blue-50 rounded-lg border border-blue-200 p-4">
        <div className="flex items-start space-x-3">
          <AlertCircle className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" />
          <div className="flex-1">
            <h3 className="text-sm font-semibold text-blue-900 mb-1">{t('portfolio.portfolioOverview')}</h3>
            <p className="text-sm text-blue-800 mb-2">
              <strong>LTIP Pool:</strong> Total shares allocated across all LTIP pools or incentive plans for employee equity grants.<br/>
              <strong>Company Reserved Portfolio:</strong> Automatically synced with LTIP pools, tracks total shares, available shares, and locked (granted) shares.<br/>
              <strong>Granted Shares:</strong> Total shares granted to employees through active equity grants (these shares are locked in the company portfolio until transferred).<br/>
              <strong>Vested/Unvested:</strong> Breakdown of granted shares based on vesting status.
            </p>
            <p className="text-xs text-blue-700 mt-2">
              <strong>Note:</strong> The Company Reserved Portfolio automatically updates when LTIP pools, incentive plans, or grants are created or modified.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
