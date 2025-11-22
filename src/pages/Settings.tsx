import { useEffect, useState, useMemo } from 'react';
import { supabase } from '../lib/supabase';
import { Building2, Users, Shield, Globe, Save, AlertCircle, TrendingUp, RefreshCw, ChevronDown, Search, X } from 'lucide-react';
import { TADAWUL_COMPANIES, searchCompanies, getCompanyBySymbol, type TadawulCompany } from '../data/tadawulCompanies';
import { updateCompanyPriceFromTadawul } from '../lib/tadawulPriceFetcher';

interface CompanySettings {
  id: string;
  company_name_en: string;
  company_name_ar: string;
  registration_number: string;
  total_reserved_shares: number;
  available_shares: number;
  shares_granted: number;
  shares_vested: number;
  fiscal_year_end: string;
  tadawul_symbol: string;
  tadawul_market?: 'main' | 'nomu';
  current_fmv: number | null;
  share_price: number | null;
  fmv_source: 'manual' | 'tadawul' | null;
  last_price_fetch?: string | null;
}

export default function Settings() {
  const [settings, setSettings] = useState<CompanySettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [fetchingPrice, setFetchingPrice] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  
  // Tadawul company selector state
  const [showCompanyDropdown, setShowCompanyDropdown] = useState(false);
  const [companySearchQuery, setCompanySearchQuery] = useState('');
  const [selectedMarket, setSelectedMarket] = useState<'main' | 'nomu'>('main');

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: companyUser } = await supabase
        .from('company_users')
        .select('company_id, companies(*)')
        .eq('user_id', user.id)
        .maybeSingle();

      if (companyUser?.companies) {
        const company = companyUser.companies as Partial<CompanySettings> & Record<string, any>;
        
        // Determine market from company data or default to main
        const companyData = getCompanyBySymbol(company.tadawul_symbol || '');
        const market = company.tadawul_market || companyData?.market || 'main';

        setSettings({
          ...(company as CompanySettings),
          tadawul_symbol: (company.tadawul_symbol || '').toUpperCase(),
          tadawul_market: market,
          current_fmv:
            typeof company.current_fmv === 'number' && !Number.isNaN(company.current_fmv)
              ? company.current_fmv
              : null,
          share_price: typeof company.current_fmv === 'number' && !Number.isNaN(company.current_fmv)
            ? company.current_fmv
            : null,
          fmv_source: (company.fmv_source as CompanySettings['fmv_source']) ?? 'tadawul',
          last_price_fetch: company.last_price_fetch || null,
        });
        
        setSelectedMarket(market);
      }
    } catch (error) {
      console.error('Error loading settings:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleFetchPrice = async () => {
    if (!settings || !settings.tadawul_symbol) {
      setMessage({ type: 'error', text: 'Please select a Tadawul symbol first.' });
      return;
    }

    setFetchingPrice(true);
    setMessage(null);

    try {
      const result = await updateCompanyPriceFromTadawul(
        settings.id,
        settings.tadawul_symbol,
        selectedMarket
      );

      if (result.success && result.price !== undefined) {
        // Also update market_data table with the fetched price
        await handleUpdateMarketData(result.price);
        
        setSettings((prev) =>
          prev
            ? {
                ...prev,
                share_price: result.price!,
                current_fmv: result.price!,
                fmv_source: 'tadawul',
                last_price_fetch: new Date().toISOString(),
              }
            : prev
        );
        setMessage({
          type: 'success',
          text: `Price fetched successfully: SAR ${result.price.toFixed(2)} (Note: Data may be delayed up to 15 minutes)`,
        });
      } else {
        // Show error but allow manual entry
        const errorMessage = result.error || 'Failed to fetch price from Tadawul.';
        
        // Check if it's because Edge Function is not deployed
        if (errorMessage.includes('not deployed') || errorMessage.includes('Function not found')) {
          setMessage({
            type: 'error',
            text: 'Edge Function not deployed. Please deploy it using: supabase functions deploy fetch-tadawul-price. For now, you can enter the price manually in the "Current Share Price" field above.',
          });
        } else {
          setMessage({
            type: 'error',
            text: `${errorMessage} You can enter the price manually in the "Current Share Price" field above.`,
          });
        }
      }
    } catch (error: any) {
      console.error('Error fetching price:', error);
      setMessage({ type: 'error', text: error?.message || 'Failed to fetch price from Tadawul' });
    } finally {
      setFetchingPrice(false);
    }
  };

  const handleUpdateMarketData = async (price: number) => {
    if (!settings || !settings.tadawul_symbol) return;

    try {
      // Update market_data table using the function
      // Note: p_symbol and p_closing_price are required, others are optional
      const { error } = await supabase.rpc('update_market_price', {
        p_symbol: settings.tadawul_symbol,
        p_closing_price: price,
        p_trading_date: new Date().toISOString().split('T')[0],
        p_source: 'Manual Update from Settings',
      });

      if (error) {
        console.error('Error updating market_data:', error);
        // If RPC fails, try direct insert/update
        const { error: directError } = await supabase
          .from('market_data')
          .upsert({
            tadawul_symbol: settings.tadawul_symbol,
            trading_date: new Date().toISOString().split('T')[0],
            closing_price: price,
            opening_price: price,
            high_price: price,
            low_price: price,
            source: 'Manual Update from Settings',
            last_updated: new Date().toISOString(),
          }, {
            onConflict: 'tadawul_symbol,trading_date',
          });

        if (directError) {
          console.error('Error with direct update:', directError);
        }
      }
    } catch (error) {
      console.error('Error updating market data:', error);
    }
  };

  const handleSave = async () => {
    if (!settings) return;

    setSaving(true);
    setMessage(null);

    try {
      const symbol = (settings.tadawul_symbol || '').trim().toUpperCase();

      if (!symbol) {
        setMessage({ type: 'error', text: 'Tadawul symbol is required to save settings.' });
        setSaving(false);
        return;
      }

      // Use share_price if set, otherwise use current_fmv
      const sharePrice = settings.share_price !== null && settings.share_price !== undefined
        ? settings.share_price
        : settings.current_fmv;

      // Determine source: if manual FMV is set and different from share price, use manual
      const useManual = settings.current_fmv !== null && 
                       settings.current_fmv !== sharePrice &&
                       settings.current_fmv > 0;

      const { error } = await supabase
        .from('companies')
        .update({
          company_name_en: settings.company_name_en,
          company_name_ar: settings.company_name_ar,
          fiscal_year_end: settings.fiscal_year_end,
          tadawul_symbol: symbol,
          current_fmv: sharePrice,
          fmv_source: useManual ? 'manual' : (sharePrice ? 'tadawul' : null),
          updated_at: new Date().toISOString(),
        })
        .eq('id', settings.id);

      if (error) throw error;

      setSettings((prev) =>
        prev
          ? {
              ...prev,
              tadawul_symbol: symbol,
              current_fmv: sharePrice,
              fmv_source: useManual ? 'manual' : (sharePrice ? 'tadawul' : null),
            }
          : prev
      );

      setMessage({ type: 'success', text: 'Settings saved successfully' });
    } catch (error) {
      console.error('Error saving settings:', error);
      setMessage({ type: 'error', text: 'Failed to save settings' });
    } finally {
      setSaving(false);
    }
  };

  // Filter companies based on search and market
  const filteredCompanies = useMemo(() => {
    let companies = TADAWUL_COMPANIES.filter(c => c.market === selectedMarket);
    
    if (companySearchQuery.trim()) {
      companies = searchCompanies(companySearchQuery).filter(c => c.market === selectedMarket);
    }
    
    return companies.slice(0, 50); // Limit to 50 results
  }, [companySearchQuery, selectedMarket]);

  const handleSelectCompany = (company: TadawulCompany) => {
    setSettings((prev) =>
      prev
        ? {
            ...prev,
            tadawul_symbol: company.symbol,
            tadawul_market: company.market,
          }
        : prev
    );
    setSelectedMarket(company.market);
    setShowCompanyDropdown(false);
    setCompanySearchQuery('');
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!settings) {
    return (
      <div className="bg-white rounded-xl p-12 border border-gray-200 text-center">
        <AlertCircle className="w-12 h-12 text-gray-400 mx-auto mb-4" />
        <h3 className="text-lg font-bold text-gray-900 mb-2">No Company Found</h3>
        <p className="text-gray-600">Unable to load company settings</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Settings</h1>
        <p className="text-gray-600 mt-1">Manage your company configuration and preferences</p>
      </div>

      {message && (
        <div
          className={`p-4 rounded-lg border ${
            message.type === 'success'
              ? 'bg-green-50 border-green-200 text-green-800'
              : 'bg-red-50 border-red-200 text-red-800'
          }`}
        >
          <div className="flex items-center space-x-2">
            <AlertCircle className="w-5 h-5" />
            <span className="font-medium">{message.text}</span>
          </div>
        </div>
      )}

      <div className="bg-white rounded-xl border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center space-x-3">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Building2 className="w-5 h-5 text-blue-600" />
            </div>
            <h2 className="text-lg font-bold text-gray-900">Company Information</h2>
          </div>
        </div>

        <div className="p-6 space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Company Name (English)
              </label>
              <input
                type="text"
                value={settings.company_name_en}
                onChange={(e) =>
                  setSettings({ ...settings, company_name_en: e.target.value })
                }
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Company Name (Arabic)
              </label>
              <input
                type="text"
                value={settings.company_name_ar}
                onChange={(e) =>
                  setSettings({ ...settings, company_name_ar: e.target.value })
                }
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-right"
                dir="rtl"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Registration Number
              </label>
              <input
                type="text"
                value={settings.registration_number}
                disabled
                className="w-full px-4 py-2 border border-gray-300 rounded-lg bg-gray-50 text-gray-500 cursor-not-allowed"
              />
              <p className="text-xs text-gray-500 mt-1">Cannot be changed</p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Fiscal Year End
              </label>
              <input
                type="date"
                value={settings.fiscal_year_end}
                onChange={(e) =>
                  setSettings({ ...settings, fiscal_year_end: e.target.value })
                }
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            {/* Tadawul Symbol Selection */}
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Tadawul Symbol
              </label>
              
              {/* Market Selector */}
              <div className="flex gap-2 mb-2">
                <button
                  type="button"
                  onClick={() => {
                    setSelectedMarket('main');
                    setShowCompanyDropdown(false);
                    setCompanySearchQuery('');
                  }}
                  className={`px-4 py-2 rounded-lg text-sm font-medium transition ${
                    selectedMarket === 'main'
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  Main Market
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setSelectedMarket('nomu');
                    setShowCompanyDropdown(false);
                    setCompanySearchQuery('');
                  }}
                  className={`px-4 py-2 rounded-lg text-sm font-medium transition ${
                    selectedMarket === 'nomu'
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  NOMU Market
                </button>
              </div>

              {/* Company Selector Dropdown */}
              <div className="relative">
                <div className="flex gap-2">
                  <div className="flex-1 relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                    <input
                      type="text"
                      value={companySearchQuery || settings.tadawul_symbol}
                      onChange={(e) => {
                        setCompanySearchQuery(e.target.value);
                        setShowCompanyDropdown(true);
                        if (!e.target.value) {
                          setSettings((prev) =>
                            prev ? { ...prev, tadawul_symbol: '' } : prev
                          );
                        }
                      }}
                      onFocus={() => setShowCompanyDropdown(true)}
                      className="w-full pl-10 pr-10 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent uppercase"
                      placeholder="Search or select company..."
                    />
                    {companySearchQuery && (
                      <button
                        type="button"
                        onClick={() => {
                          setCompanySearchQuery('');
                          setShowCompanyDropdown(false);
                        }}
                        className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                      >
                        <X className="w-4 h-4" />
                      </button>
                    )}
                  </div>
                  <button
                    type="button"
                    onClick={() => setShowCompanyDropdown(!showCompanyDropdown)}
                    className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                  >
                    <ChevronDown className={`w-5 h-5 transition-transform ${showCompanyDropdown ? 'rotate-180' : ''}`} />
                  </button>
                </div>

                {/* Dropdown List */}
                {showCompanyDropdown && (
                  <>
                    <div
                      className="absolute z-50 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-60 overflow-y-auto"
                    >
                      {filteredCompanies.length > 0 ? (
                        filteredCompanies.map((company) => (
                          <button
                            key={company.symbol}
                            type="button"
                            onClick={() => handleSelectCompany(company)}
                            className="w-full px-4 py-3 text-left hover:bg-blue-50 border-b border-gray-100 last:border-b-0 transition"
                          >
                            <div className="flex items-center justify-between">
                              <div className="flex-1">
                                <div className="font-medium text-gray-900">
                                  {company.symbol} - {company.name_en}
                                </div>
                                <div className="text-sm text-gray-500">{company.name_ar}</div>
                              </div>
                              <span className="text-xs px-2 py-1 bg-blue-100 text-blue-700 rounded ml-2">
                                {company.market.toUpperCase()}
                              </span>
                            </div>
                          </button>
                        ))
                      ) : (
                        <div className="px-4 py-3 text-sm text-gray-500 text-center">
                          No companies found. Try a different search term.
                        </div>
                      )}
                    </div>
                    <div
                      className="fixed inset-0 z-40"
                      onClick={() => setShowCompanyDropdown(false)}
                    />
                  </>
                )}
              </div>
              <p className="text-xs text-gray-500 mt-1">
                Search and select from listed companies or type a custom symbol.
              </p>
            </div>

            {/* Current Share Price */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Current Share Price (SAR)
              </label>
              <div className="flex gap-2">
                <input
                  type="number"
                  step="0.01"
                  min="0"
                  value={settings.share_price ?? settings.current_fmv ?? ''}
                  onChange={(e) => {
                    const value = e.target.value;
                    const numValue = value === '' ? null : Number(value);
                    setSettings({
                      ...settings,
                      share_price: numValue,
                      current_fmv: numValue,
                    });
                    
                    // Update market_data table when price is manually entered
                    if (numValue !== null && numValue > 0 && settings.tadawul_symbol) {
                      handleUpdateMarketData(numValue);
                    }
                  }}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="0.00"
                />
                <button
                  type="button"
                  onClick={handleFetchPrice}
                  disabled={fetchingPrice || !settings.tadawul_symbol}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition flex items-center gap-2"
                  title="Fetch latest price from Tadawul (may be delayed up to 15 minutes)"
                >
                  {fetchingPrice ? (
                    <>
                      <RefreshCw className="w-4 h-4 animate-spin" />
                      <span className="hidden sm:inline">Fetching...</span>
                    </>
                  ) : (
                    <>
                      <TrendingUp className="w-4 h-4" />
                      <span className="hidden sm:inline">Fetch</span>
                    </>
                  )}
                </button>
              </div>
              <div className="mt-1 flex items-center justify-between">
                <p className="text-xs text-gray-500">
                  {settings.fmv_source === 'tadawul' ? (
                    <span className="text-green-600">Source: Tadawul</span>
                  ) : settings.fmv_source === 'manual' ? (
                    <span className="text-blue-600">Source: Manual</span>
                  ) : (
                    <span className="text-gray-500">Not set</span>
                  )}
                </p>
                {settings.last_price_fetch && (
                  <p className="text-xs text-gray-500">
                    Last fetched: {new Date(settings.last_price_fetch).toLocaleString()}
                  </p>
                )}
              </div>
              <p className="text-xs text-gray-500 mt-1">
                Price may be delayed up to 15 minutes from Tadawul.
              </p>
            </div>

            {/* Manual FMV Override */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Manual FMV Override (SAR)
              </label>
              <input
                type="number"
                step="0.01"
                min="0"
                value={settings.current_fmv && settings.current_fmv !== settings.share_price ? settings.current_fmv : ''}
                onChange={(e) => {
                  const value = e.target.value;
                  setSettings({
                    ...settings,
                    current_fmv: value === '' ? settings.share_price : Number(value),
                    fmv_source: value === '' ? 'tadawul' : 'manual',
                  });
                }}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Optional override"
              />
              <p className="text-xs text-gray-500 mt-1">
                Optional: Override share price with manual FMV. Leave blank to use share price above.
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center space-x-3">
            <div className="p-2 bg-green-100 rounded-lg">
              <Shield className="w-5 h-5 text-green-600" />
            </div>
            <h2 className="text-lg font-bold text-gray-900">Share Pool Configuration</h2>
          </div>
        </div>

        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="p-4 bg-blue-50 rounded-lg">
              <p className="text-sm text-gray-600 mb-1">Total Reserved</p>
              <p className="text-2xl font-bold text-gray-900">
                {Number(settings.total_reserved_shares).toLocaleString()}
              </p>
            </div>

            <div className="p-4 bg-green-50 rounded-lg">
              <p className="text-sm text-gray-600 mb-1">Available</p>
              <p className="text-2xl font-bold text-green-700">
                {Number(settings.available_shares).toLocaleString()}
              </p>
            </div>

            <div className="p-4 bg-orange-50 rounded-lg">
              <p className="text-sm text-gray-600 mb-1">Granted</p>
              <p className="text-2xl font-bold text-orange-700">
                {Number(settings.shares_granted).toLocaleString()}
              </p>
            </div>

            <div className="p-4 bg-purple-50 rounded-lg">
              <p className="text-sm text-gray-600 mb-1">Vested</p>
              <p className="text-2xl font-bold text-purple-700">
                {Number(settings.shares_vested).toLocaleString()}
              </p>
            </div>
          </div>

          <div className="mt-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
            <div className="flex items-start space-x-3">
              <AlertCircle className="w-5 h-5 text-yellow-600 mt-0.5 flex-shrink-0" />
              <div>
                <p className="text-sm font-medium text-yellow-900">Share pool is read-only</p>
                <p className="text-sm text-yellow-800 mt-1">
                  Share allocations are automatically calculated based on your incentive plans
                  and grants. Contact support to adjust the total reserved shares.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="flex justify-end">
        <button
          onClick={handleSave}
          disabled={saving}
          className="flex items-center space-x-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition"
        >
          <Save className="w-5 h-5" />
          <span className="font-medium">{saving ? 'Saving...' : 'Save Changes'}</span>
        </button>
      </div>
    </div>
  );
}
