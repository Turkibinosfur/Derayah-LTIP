import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { formatDate } from '../lib/dateUtils';
import {
  PieChart, Plus, TrendingUp, Users, DollarSign, Calculator, Download,
  ChevronDown, ChevronUp, GripVertical, Eye, BarChart3, Layers, AlertCircle, MoreVertical, Edit, Trash2
} from 'lucide-react';

interface Shareholder {
  id: string;
  name: string;
  shareholder_type: string;
  shares_owned: number;
  ownership_percentage: number;
  share_class: string;
  investment_amount: number;
  preference_multiple?: number;
  liquidation_preference?: number;
  is_active: boolean;
}

interface FundingRound {
  id: string;
  round_name: string;
  round_type: string;
  amount_raised: number;
  valuation_post_money: number;
  valuation_pre_money: number;
  share_price: number;
  shares_issued: number;
  closing_date: string;
}

interface DilutionScenario {
  id: string;
  scenario_name: string;
  scenario_description: string;
  scenario_config: any;
  results: any;
  created_at: string;
}

interface WaterfallResult {
  shareholder: string;
  shares: number;
  ownership: number;
  payout: number;
  multiple: number;
}

export default function CapTable() {
  const [shareholders, setShareholders] = useState<Shareholder[]>([]);
  const [fundingRounds, setFundingRounds] = useState<FundingRound[]>([]);
  const [scenarios, setScenarios] = useState<DilutionScenario[]>([]);
  const [loading, setLoading] = useState(true);
  const [companyId, setCompanyId] = useState<string | null>(null);
  const [activeView, setActiveView] = useState<'table' | 'visualization' | 'dilution' | 'rounds' | 'waterfall'>('table');

  const [showAddShareholder, setShowAddShareholder] = useState(false);
  const [showDilutionModel, setShowDilutionModel] = useState(false);
  const [showRoundModel, setShowRoundModel] = useState(false);
  const [showWaterfallAnalysis, setShowWaterfallAnalysis] = useState(false);
  const [showViewShareholder, setShowViewShareholder] = useState(false);
  const [showEditShareholder, setShowEditShareholder] = useState(false);
  const [selectedShareholder, setSelectedShareholder] = useState<Shareholder | null>(null);
  const [draggedItem, setDraggedItem] = useState<number | null>(null);
  const [openDropdown, setOpenDropdown] = useState<string | null>(null);
  const [menuPosition, setMenuPosition] = useState<{ top: number; left: number } | null>(null);

  const [newShareholder, setNewShareholder] = useState({
    name: '',
    shareholder_type: 'founder',
    shares_owned: 0,
    share_class: 'Common',
    investment_amount: 0,
    liquidation_preference: 0,
    preference_multiple: 1,
  });

  const [editShareholder, setEditShareholder] = useState({
    name: '',
    shareholder_type: 'founder',
    shares_owned: 0,
    share_class: 'Common',
    investment_amount: 0,
    liquidation_preference: 0,
    preference_multiple: 1,
  });

  const [dilutionModel, setDilutionModel] = useState({
    scenario_name: '',
    new_investment: 0,
    new_shares: 0,
    valuation: 0,
    share_class: 'Preferred',
  });

  const [roundModel, setRoundModel] = useState({
    round_name: '',
    round_type: 'seed',
    amount_to_raise: 0,
    pre_money_valuation: 0,
    option_pool_increase: 0,
  });

  const [waterfallConfig, setWaterfallConfig] = useState({
    exit_value: 100000000,
    scenario_type: 'acquisition',
  });

  const [waterfallResults, setWaterfallResults] = useState<WaterfallResult[]>([]);

  useEffect(() => {
    loadCapTableData();
  }, []);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (openDropdown && !(event.target as Element).closest('.dropdown-container')) {
        setOpenDropdown(null);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [openDropdown]);

  const loadCapTableData = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: companyUser } = await supabase
        .from('company_users')
        .select('company_id')
        .eq('user_id', user.id)
        .maybeSingle();

      if (!companyUser) return;

      const compId = companyUser.company_id;
      setCompanyId(compId);

      const [shareholdersRes, roundsRes, scenariosRes] = await Promise.all([
        supabase
          .from('shareholders')
          .select('*')
          .eq('company_id', compId)
          .eq('is_active', true)
          .order('ownership_percentage', { ascending: false }),
        supabase
          .from('funding_rounds')
          .select('*')
          .eq('company_id', compId)
          .order('closing_date', { ascending: false }),
        supabase
          .from('dilution_scenarios')
          .select('*')
          .eq('company_id', compId)
          .order('created_at', { ascending: false })
          .limit(5),
      ]);

      if (shareholdersRes.data) setShareholders(shareholdersRes.data);
      if (roundsRes.data) setFundingRounds(roundsRes.data);
      if (scenariosRes.data) setScenarios(scenariosRes.data);
    } catch (error) {
      console.error('Error loading cap table:', error);
    } finally {
      setLoading(false);
    }
  };

  const totalShares = shareholders.reduce((sum, sh) => sum + Number(sh.shares_owned), 0);
  const totalInvestment = shareholders.reduce((sum, sh) => sum + Number(sh.investment_amount || 0), 0);

  const calculateOwnership = (shares: number, totalShares: number) => {
    return totalShares > 0 ? ((shares / totalShares) * 100).toFixed(2) : '0.00';
  };

  const handleViewShareholder = (shareholder: Shareholder) => {
    setSelectedShareholder(shareholder);
    setShowViewShareholder(true);
    setOpenDropdown(null);
  };

  const handleEditShareholder = (shareholder: Shareholder) => {
    setSelectedShareholder(shareholder);
    setEditShareholder({
      name: shareholder.name,
      shareholder_type: shareholder.shareholder_type,
      shares_owned: Number(shareholder.shares_owned),
      share_class: shareholder.share_class,
      investment_amount: Number(shareholder.investment_amount || 0),
      liquidation_preference: Number(shareholder.liquidation_preference || 0),
      preference_multiple: Number(shareholder.preference_multiple || 1),
    });
    setShowEditShareholder(true);
    setOpenDropdown(null);
  };

  const handleDeleteShareholder = async (shareholder: Shareholder) => {
    if (window.confirm(`Are you sure you want to delete ${shareholder.name}?`)) {
      try {
        const { error } = await supabase
          .from('shareholders')
          .delete()
          .eq('id', shareholder.id);

        if (error) {
          console.error('Error deleting shareholder:', error);
          alert('Failed to delete shareholder');
          return;
        }

        await loadCapTableData();
        await recalculateAllOwnership();
        setOpenDropdown(null);
      } catch (error) {
        console.error('Error deleting shareholder:', error);
        alert('Failed to delete shareholder');
      }
    }
  };

  const handleUpdateShareholder = async () => {
    if (!selectedShareholder || !editShareholder.name || editShareholder.shares_owned <= 0) {
      alert('Please fill in all required fields (Name and Shares must be greater than 0)');
      return;
    }

    try {
      const { error } = await supabase
        .from('shareholders')
        .update({
          name: editShareholder.name,
          shareholder_type: editShareholder.shareholder_type,
          shares_owned: editShareholder.shares_owned,
          share_class: editShareholder.share_class,
          investment_amount: editShareholder.investment_amount,
          liquidation_preference: editShareholder.liquidation_preference,
          preference_multiple: editShareholder.preference_multiple,
          updated_at: new Date().toISOString(),
        })
        .eq('id', selectedShareholder.id);

      if (error) {
        console.error('Error updating shareholder:', error);
        alert(`Failed to update shareholder: ${error.message}`);
        return;
      }

      await loadCapTableData();
      await recalculateAllOwnership();
      setShowEditShareholder(false);
      setSelectedShareholder(null);
    } catch (error) {
      console.error('Error updating shareholder:', error);
      alert('Failed to update shareholder');
    }
  };

  const handleAddShareholder = async () => {
    if (!companyId || !newShareholder.name || newShareholder.shares_owned <= 0) {
      alert('Please fill in all required fields (Name and Shares must be greater than 0)');
      return;
    }

    try {
      const newTotal = totalShares + newShareholder.shares_owned;
      const ownership = calculateOwnership(newShareholder.shares_owned, newTotal);

      const { error } = await supabase.from('shareholders').insert({
        company_id: companyId,
        ...newShareholder,
        ownership_percentage: parseFloat(ownership),
      });

      if (error) {
        console.error('Database error:', error);
        alert(`Failed to add shareholder: ${error.message}`);
        return;
      }

      setShowAddShareholder(false);
      resetShareholderForm();
      await loadCapTableData();
      await recalculateAllOwnership();
    } catch (error) {
      console.error('Error adding shareholder:', error);
      alert('An unexpected error occurred. Please try again.');
    }
  };

  const recalculateAllOwnership = async () => {
    if (!companyId) return;

    try {
      const { data: allShareholders, error: fetchError } = await supabase
        .from('shareholders')
        .select('*')
        .eq('company_id', companyId)
        .eq('is_active', true);

      if (fetchError || !allShareholders) return;

      const newTotal = allShareholders.reduce((sum, sh) => sum + Number(sh.shares_owned), 0);

      for (const sh of allShareholders) {
        const newOwnership = calculateOwnership(Number(sh.shares_owned), newTotal);
        await supabase
          .from('shareholders')
          .update({ ownership_percentage: parseFloat(newOwnership) })
          .eq('id', sh.id);
      }
    } catch (error) {
      console.error('Error recalculating ownership:', error);
    }
  };

  const handleRunDilutionModel = async () => {
    if (!companyId || !dilutionModel.scenario_name) return;

    try {
      const newTotalShares = totalShares + dilutionModel.new_shares;
      const results = shareholders.map(sh => ({
        name: sh.name,
        current_shares: sh.shares_owned,
        current_ownership: sh.ownership_percentage,
        new_ownership: calculateOwnership(Number(sh.shares_owned), newTotalShares),
        dilution: (sh.ownership_percentage - parseFloat(calculateOwnership(Number(sh.shares_owned), newTotalShares))).toFixed(2),
      }));

      results.push({
        name: 'New Investor',
        current_shares: 0,
        current_ownership: 0,
        new_ownership: calculateOwnership(dilutionModel.new_shares, newTotalShares),
        dilution: '0.00',
      });

      const { error } = await supabase.from('dilution_scenarios').insert({
        company_id: companyId,
        scenario_name: dilutionModel.scenario_name,
        scenario_description: `Investment: SAR ${dilutionModel.new_investment.toLocaleString()}, New shares: ${dilutionModel.new_shares.toLocaleString()}, Valuation: SAR ${dilutionModel.valuation.toLocaleString()}`,
        scenario_config: dilutionModel,
        results: { shareholders: results, new_total_shares: newTotalShares },
      });

      if (!error) {
        setShowDilutionModel(false);
        resetDilutionForm();
        loadCapTableData();
      }
    } catch (error) {
      console.error('Error creating scenario:', error);
    }
  };

  const handleRunRoundModel = async () => {
    if (!companyId || !roundModel.round_name) return;

    try {
      const postMoneyValuation = roundModel.pre_money_valuation + roundModel.amount_to_raise;
      const pricePerShare = roundModel.pre_money_valuation / totalShares;
      const newShares = roundModel.amount_to_raise / pricePerShare;
      const optionPoolShares = (roundModel.option_pool_increase / 100) * (totalShares + newShares);

      const { error } = await supabase.from('funding_rounds').insert({
        company_id: companyId,
        round_name: roundModel.round_name,
        round_type: roundModel.round_type,
        amount_raised: roundModel.amount_to_raise,
        valuation_pre_money: roundModel.pre_money_valuation,
        valuation_post_money: postMoneyValuation,
        share_price: pricePerShare,
        shares_issued: newShares,
        closing_date: new Date().toISOString().split('T')[0],
        notes: `Option pool increase: ${roundModel.option_pool_increase}%`,
      });

      if (!error) {
        setShowRoundModel(false);
        resetRoundForm();
        loadCapTableData();
      }
    } catch (error) {
      console.error('Error creating round:', error);
    }
  };

  const handleRunWaterfallAnalysis = () => {
    const exitValue = waterfallConfig.exit_value;
    const results: WaterfallResult[] = [];
    let remainingValue = exitValue;

    const sortedShareholders = [...shareholders].sort((a, b) => {
      const aIsPref = a.share_class.toLowerCase().includes('preferred');
      const bIsPref = b.share_class.toLowerCase().includes('preferred');
      if (aIsPref && !bIsPref) return -1;
      if (!aIsPref && bIsPref) return 1;
      return 0;
    });

    for (const sh of sortedShareholders) {
      const isPref = sh.share_class.toLowerCase().includes('preferred');
      let payout = 0;

      if (isPref && sh.liquidation_preference) {
        const prefPayout = sh.liquidation_preference * (sh.preference_multiple || 1);
        payout = Math.min(prefPayout, remainingValue);
        remainingValue -= payout;
      }

      results.push({
        shareholder: sh.name,
        shares: sh.shares_owned,
        ownership: sh.ownership_percentage,
        payout: payout,
        multiple: sh.investment_amount > 0 ? payout / sh.investment_amount : 0,
      });
    }

    if (remainingValue > 0) {
      results.forEach(result => {
        const shareholder = shareholders.find(sh => sh.name === result.shareholder);
        if (shareholder) {
          const proRataPayout = remainingValue * (shareholder.ownership_percentage / 100);
          result.payout += proRataPayout;
          result.multiple = shareholder.investment_amount > 0 ? result.payout / shareholder.investment_amount : 0;
        }
      });
    }

    setWaterfallResults(results);
    setShowWaterfallAnalysis(true);
  };

  const resetShareholderForm = () => {
    setNewShareholder({
      name: '',
      shareholder_type: 'founder',
      shares_owned: 0,
      share_class: 'Common',
      investment_amount: 0,
      liquidation_preference: 0,
      preference_multiple: 1,
    });
  };

  const resetDilutionForm = () => {
    setDilutionModel({
      scenario_name: '',
      new_investment: 0,
      new_shares: 0,
      valuation: 0,
      share_class: 'Preferred',
    });
  };

  const resetRoundForm = () => {
    setRoundModel({
      round_name: '',
      round_type: 'seed',
      amount_to_raise: 0,
      pre_money_valuation: 0,
      option_pool_increase: 0,
    });
  };

  const handleDragStart = (index: number) => {
    setDraggedItem(index);
  };

  const handleDragOver = (e: React.DragEvent, index: number) => {
    e.preventDefault();
    if (draggedItem === null || draggedItem === index) return;

    const newShareholders = [...shareholders];
    const draggedShareholder = newShareholders[draggedItem];
    newShareholders.splice(draggedItem, 1);
    newShareholders.splice(index, 0, draggedShareholder);

    setShareholders(newShareholders);
    setDraggedItem(index);
  };

  const handleDragEnd = () => {
    setDraggedItem(null);
  };

  const getTypeColor = (type: string) => {
    const colors: Record<string, string> = {
      founder: 'bg-blue-100 text-blue-800',
      investor: 'bg-green-100 text-green-800',
      employee: 'bg-purple-100 text-purple-800',
      institution: 'bg-gray-100 text-gray-800',
    };
    return colors[type] || colors.other;
  };

  const getShareholderColor = (index: number) => {
    const colors = [
      '#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6',
      '#EC4899', '#14B8A6', '#F97316', '#6366F1', '#84CC16'
    ];
    return colors[index % colors.length];
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-3">
            Cap Table Management
            <span className="inline-flex items-center justify-center w-10 h-10 rounded-full bg-blue-600 text-white text-lg font-semibold">
              {shareholders.length}
            </span>
          </h1>
          <p className="text-gray-600 mt-1">
            Comprehensive equity structure analysis and scenario modeling
          </p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={() => setShowWaterfallAnalysis(true)}
            className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700"
          >
            <Layers className="w-5 h-5" />
            Waterfall Analysis
          </button>
          <button
            onClick={() => setShowRoundModel(true)}
            className="flex items-center gap-2 px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700"
          >
            <TrendingUp className="w-5 h-5" />
            Model Round
          </button>
          <button
            onClick={() => setShowDilutionModel(true)}
            className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
          >
            <Calculator className="w-5 h-5" />
            Dilution Model
          </button>
          <button
            onClick={() => setShowAddShareholder(true)}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            <Plus className="w-5 h-5" />
            Add Shareholder
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-xl p-6 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-lg bg-blue-100">
              <Users className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <p className="text-sm text-gray-600">Shareholders</p>
              <p className="text-2xl font-bold text-gray-900">{shareholders.length}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl p-6 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-lg bg-green-100">
              <PieChart className="w-6 h-6 text-green-600" />
            </div>
            <div>
              <p className="text-sm text-gray-600">Total Shares</p>
              <p className="text-2xl font-bold text-gray-900">{totalShares.toLocaleString()}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl p-6 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-lg bg-purple-100">
              <DollarSign className="w-6 h-6 text-purple-600" />
            </div>
            <div>
              <p className="text-sm text-gray-600">Investment</p>
              <p className="text-2xl font-bold text-gray-900">SAR {(totalInvestment / 1000000).toFixed(1)}M</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl p-6 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="p-3 rounded-lg bg-orange-100">
              <TrendingUp className="w-6 h-6 text-orange-600" />
            </div>
            <div>
              <p className="text-sm text-gray-600">Funding Rounds</p>
              <p className="text-2xl font-bold text-gray-900">{fundingRounds.length}</p>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-gray-200">
        <div className="border-b border-gray-200 px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex gap-2">
              <button
                onClick={() => setActiveView('table')}
                className={`px-4 py-2 rounded-lg font-medium transition ${
                  activeView === 'table' ? 'bg-blue-100 text-blue-600' : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                Table View
              </button>
              <button
                onClick={() => setActiveView('visualization')}
                className={`px-4 py-2 rounded-lg font-medium transition ${
                  activeView === 'visualization' ? 'bg-blue-100 text-blue-600' : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                Visualization
              </button>
            </div>
            <button className="flex items-center gap-2 px-3 py-1.5 text-sm text-gray-600 hover:bg-gray-50 rounded-lg">
              <Download className="w-4 h-4" />
              Export
            </button>
          </div>
        </div>

        <div className="p-6">
          {activeView === 'table' && (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase w-8"></th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Shareholder
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Type
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Share Class
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Shares
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Ownership %
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Investment
                    </th>
                    <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider w-16">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {shareholders.map((shareholder, index) => (
                    <tr
                      key={shareholder.id}
                      draggable
                      onDragStart={() => handleDragStart(index)}
                      onDragOver={(e) => handleDragOver(e, index)}
                      onDragEnd={handleDragEnd}
                      className={`hover:bg-gray-50 cursor-move ${draggedItem === index ? 'opacity-50' : ''}`}
                    >
                      <td className="px-4 py-4">
                        <GripVertical className="w-4 h-4 text-gray-400" />
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center gap-3">
                          <div
                            className="w-3 h-3 rounded-full"
                            style={{ backgroundColor: getShareholderColor(index) }}
                          ></div>
                          <button
                            onClick={() => {
                              setSelectedShareholder(shareholder);
                              setShowViewShareholder(true);
                            }}
                            className="font-medium text-blue-600 hover:text-blue-800 hover:underline transition text-left"
                          >
                            {shareholder.name}
                          </button>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${getTypeColor(shareholder.shareholder_type)}`}>
                          {shareholder.shareholder_type.replace('_', ' ')}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                        {shareholder.share_class}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium text-gray-900">
                        {Number(shareholder.shares_owned).toLocaleString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right">
                        <div className="flex items-center justify-end gap-2">
                          <div className="w-24 bg-gray-200 rounded-full h-2">
                            <div
                              className="h-2 rounded-full"
                              style={{
                                width: `${Math.min(shareholder.ownership_percentage, 100)}%`,
                                backgroundColor: getShareholderColor(index),
                              }}
                            ></div>
                          </div>
                          <span className="text-sm font-semibold text-gray-900 w-16 text-right">
                            {Number(shareholder.ownership_percentage).toFixed(2)}%
                          </span>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm text-gray-600">
                        SAR {Number(shareholder.investment_amount || 0).toLocaleString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-center">
                        <div className="relative dropdown-container">
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              const button = e.currentTarget;
                              const rect = button.getBoundingClientRect();
                              const menuHeight = 120;
                              const spaceBelow = window.innerHeight - rect.bottom;
                              const spaceAbove = rect.top;
                              
                              let top;
                              if (spaceBelow >= menuHeight + 10) {
                                top = rect.bottom + 8;
                              } else if (spaceAbove >= menuHeight + 10) {
                                top = rect.top - menuHeight + 5;
                              } else {
                                top = window.innerHeight - menuHeight - 10;
                              }
                              
                              setMenuPosition({ top, left: rect.right - 150 });
                              setOpenDropdown(openDropdown === shareholder.id ? null : shareholder.id);
                            }}
                            className="p-1 rounded-full hover:bg-gray-100 transition-colors"
                          >
                            <MoreVertical className="w-4 h-4 text-gray-400" />
                          </button>
                          
                          {openDropdown === shareholder.id && menuPosition && (
                            <>
                              <div
                                className="fixed inset-0 z-10"
                                onClick={() => {
                                  setOpenDropdown(null);
                                  setMenuPosition(null);
                                }}
                              ></div>
                              <div 
                                className="fixed w-48 bg-white rounded-md shadow-lg z-50 border border-gray-200"
                                style={{ top: `${menuPosition.top}px`, left: `${menuPosition.left}px` }}
                              >
                                <div className="py-1">
                                  <button
                                    onClick={() => {
                                      handleViewShareholder(shareholder);
                                      setOpenDropdown(null);
                                      setMenuPosition(null);
                                    }}
                                    className="flex items-center gap-2 w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                                  >
                                    <Eye className="w-4 h-4" />
                                    View Details
                                  </button>
                                  <button
                                    onClick={() => {
                                      handleEditShareholder(shareholder);
                                      setOpenDropdown(null);
                                      setMenuPosition(null);
                                    }}
                                    className="flex items-center gap-2 w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                                  >
                                    <Edit className="w-4 h-4" />
                                    Edit
                                  </button>
                                  <button
                                    onClick={() => {
                                      handleDeleteShareholder(shareholder);
                                      setOpenDropdown(null);
                                      setMenuPosition(null);
                                    }}
                                    className="flex items-center gap-2 w-full px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                                  >
                                    <Trash2 className="w-4 h-4" />
                                    Delete
                                  </button>
                                </div>
                              </div>
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {activeView === 'visualization' && (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-6">Ownership Distribution</h3>
                <div className="relative">
                  <svg viewBox="0 0 200 200" className="w-full max-w-md mx-auto">
                    {shareholders.map((sh, index) => {
                      const startAngle = shareholders
                        .slice(0, index)
                        .reduce((sum, s) => sum + (s.ownership_percentage / 100) * 360, 0);
                      const angle = (sh.ownership_percentage / 100) * 360;
                      const endAngle = startAngle + angle;

                      const startRad = (startAngle - 90) * (Math.PI / 180);
                      const endRad = (endAngle - 90) * (Math.PI / 180);

                      const x1 = 100 + 90 * Math.cos(startRad);
                      const y1 = 100 + 90 * Math.sin(startRad);
                      const x2 = 100 + 90 * Math.cos(endRad);
                      const y2 = 100 + 90 * Math.sin(endRad);

                      const largeArc = angle > 180 ? 1 : 0;

                      return (
                        <path
                          key={sh.id}
                          d={`M 100 100 L ${x1} ${y1} A 90 90 0 ${largeArc} 1 ${x2} ${y2} Z`}
                          fill={getShareholderColor(index)}
                          stroke="white"
                          strokeWidth="2"
                        />
                      );
                    })}
                    <circle cx="100" cy="100" r="50" fill="white" />
                    <text x="100" y="95" textAnchor="middle" className="text-xl font-bold" fill="#111827">
                      {shareholders.length}
                    </text>
                    <text x="100" y="110" textAnchor="middle" className="text-xs" fill="#6B7280">
                      Shareholders
                    </text>
                  </svg>
                </div>
              </div>

              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-6">Breakdown by Type</h3>
                <div className="space-y-4">
                  {['founder', 'investor', 'employee', 'institution'].map(type => {
                    const typeShares = shareholders
                      .filter(sh => sh.shareholder_type === type)
                      .reduce((sum, sh) => sum + sh.ownership_percentage, 0);

                    if (typeShares === 0) return null;

                    return (
                      <div key={type} className="space-y-2">
                        <div className="flex items-center justify-between">
                          <span className="text-sm font-medium text-gray-700 capitalize">
                            {type.replace('_', ' ')}
                          </span>
                          <span className="text-sm font-semibold text-gray-900">
                            {typeShares.toFixed(2)}%
                          </span>
                        </div>
                        <div className="w-full bg-gray-200 rounded-full h-3">
                          <div
                            className={`h-3 rounded-full transition-all ${
                              type === 'founder' ? 'bg-blue-500' :
                              type === 'investor' ? 'bg-green-500' :
                              type === 'employee' ? 'bg-purple-500' :
                              'bg-gray-500'
                            }`}
                            style={{ width: `${typeShares}%` }}
                          ></div>
                        </div>
                      </div>
                    );
                  })}
                </div>

                <div className="mt-8 p-4 bg-blue-50 rounded-lg border border-blue-200">
                  <div className="flex items-start gap-3">
                    <AlertCircle className="w-5 h-5 text-blue-600 mt-0.5" />
                    <div>
                      <h4 className="font-medium text-blue-900">Fully Diluted Shares</h4>
                      <p className="text-sm text-blue-700 mt-1">
                        Total: {totalShares.toLocaleString()} shares
                      </p>
                      <p className="text-xs text-blue-600 mt-1">
                        Includes all issued and outstanding shares, options, and convertible securities
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {scenarios.length > 0 && (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-900">Recent Dilution Scenarios</h2>
            <button
              onClick={() => setShowDilutionModel(true)}
              className="text-sm text-blue-600 hover:text-blue-700 font-medium"
            >
              View All
            </button>
          </div>
          <div className="p-6 space-y-3">
            {scenarios.map((scenario) => (
              <div key={scenario.id} className="p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition cursor-pointer">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <p className="font-medium text-gray-900">{scenario.scenario_name}</p>
                      <Eye className="w-4 h-4 text-gray-400" />
                    </div>
                    <p className="text-sm text-gray-600 mt-1">{scenario.scenario_description}</p>
                  </div>
                  <p className="text-xs text-gray-500">
                    {formatDate(scenario.created_at)}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {fundingRounds.length > 0 && (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200">
            <h2 className="text-lg font-semibold text-gray-900">Funding History</h2>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Round</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Amount Raised</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Pre-Money</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Post-Money</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Price/Share</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {fundingRounds.map((round) => (
                  <tr key={round.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap font-medium text-gray-900">{round.round_name}</td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="px-2 py-1 text-xs font-medium bg-green-100 text-green-800 rounded-full">
                        {round.round_type}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right font-semibold text-gray-900">
                      SAR {(Number(round.amount_raised) / 1000000).toFixed(1)}M
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-gray-600">
                      SAR {(Number(round.valuation_pre_money || 0) / 1000000).toFixed(1)}M
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-gray-600">
                      SAR {(Number(round.valuation_post_money) / 1000000).toFixed(1)}M
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-gray-600">
                      SAR {Number(round.share_price || 0).toFixed(2)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(round.closing_date)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {showAddShareholder && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl p-6 w-full max-w-md max-h-[90vh] overflow-y-auto">
            <h3 className="text-xl font-semibold text-gray-900 mb-4">Add Shareholder</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
                <input
                  type="text"
                  value={newShareholder.name}
                  onChange={(e) => setNewShareholder({ ...newShareholder, name: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
                <select
                  value={newShareholder.shareholder_type}
                  onChange={(e) => setNewShareholder({ ...newShareholder, shareholder_type: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="founder">Founder</option>
                  <option value="investor">Investor</option>
                  <option value="employee">Employee Pool</option>
                  <option value="institution">Institution</option>
                </select>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Shares</label>
                  <input
                    type="number"
                    value={newShareholder.shares_owned}
                    onChange={(e) => setNewShareholder({ ...newShareholder, shares_owned: Number(e.target.value) })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Share Class</label>
                  <select
                    value={newShareholder.share_class}
                    onChange={(e) => setNewShareholder({ ...newShareholder, share_class: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="Common">Common</option>
                    <option value="Preferred">Preferred</option>
                    <option value="Series A">Series A</option>
                    <option value="Series B">Series B</option>
                  </select>
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Investment Amount (SAR)</label>
                <input
                  type="number"
                  value={newShareholder.investment_amount}
                  onChange={(e) => setNewShareholder({ ...newShareholder, investment_amount: Number(e.target.value) })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              {newShareholder.share_class !== 'Common' && (
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Liquidation Pref</label>
                    <input
                      type="number"
                      value={newShareholder.liquidation_preference}
                      onChange={(e) => setNewShareholder({ ...newShareholder, liquidation_preference: Number(e.target.value) })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Preference Multiple</label>
                    <input
                      type="number"
                      step="0.1"
                      value={newShareholder.preference_multiple}
                      onChange={(e) => setNewShareholder({ ...newShareholder, preference_multiple: Number(e.target.value) })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>
              )}
            </div>
            <div className="mt-6 flex gap-3">
              <button
                onClick={() => {
                  setShowAddShareholder(false);
                  resetShareholderForm();
                }}
                className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleAddShareholder}
                className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Add Shareholder
              </button>
            </div>
          </div>
        </div>
      )}

      {showDilutionModel && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <h3 className="text-xl font-semibold text-gray-900 mb-4">Dilution Scenario Model</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Scenario Name</label>
                <input
                  type="text"
                  value={dilutionModel.scenario_name}
                  onChange={(e) => setDilutionModel({ ...dilutionModel, scenario_name: e.target.value })}
                  placeholder="e.g., Series A Round"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">New Investment (SAR)</label>
                  <input
                    type="number"
                    value={dilutionModel.new_investment}
                    onChange={(e) => setDilutionModel({ ...dilutionModel, new_investment: Number(e.target.value) })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">New Shares to Issue</label>
                  <input
                    type="number"
                    value={dilutionModel.new_shares}
                    onChange={(e) => setDilutionModel({ ...dilutionModel, new_shares: Number(e.target.value) })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Post-Money Valuation (SAR)</label>
                  <input
                    type="number"
                    value={dilutionModel.valuation}
                    onChange={(e) => setDilutionModel({ ...dilutionModel, valuation: Number(e.target.value) })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Share Class</label>
                  <select
                    value={dilutionModel.share_class}
                    onChange={(e) => setDilutionModel({ ...dilutionModel, share_class: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="Preferred">Preferred</option>
                    <option value="Common">Common</option>
                    <option value="Series A">Series A</option>
                    <option value="Series B">Series B</option>
                  </select>
                </div>
              </div>

              {dilutionModel.new_shares > 0 && totalShares > 0 && (
                <div className="p-4 bg-blue-50 rounded-lg border border-blue-200">
                  <h4 className="font-medium text-blue-900 mb-2">Impact Preview</h4>
                  <div className="space-y-1 text-sm">
                    <div className="flex justify-between">
                      <span className="text-blue-700">New Total Shares:</span>
                      <span className="font-semibold text-blue-900">
                        {(totalShares + dilutionModel.new_shares).toLocaleString()}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-blue-700">New Investor Ownership:</span>
                      <span className="font-semibold text-blue-900">
                        {calculateOwnership(dilutionModel.new_shares, totalShares + dilutionModel.new_shares)}%
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-blue-700">Price per Share:</span>
                      <span className="font-semibold text-blue-900">
                        SAR {dilutionModel.new_shares > 0 ? (dilutionModel.new_investment / dilutionModel.new_shares).toFixed(2) : '0.00'}
                      </span>
                    </div>
                  </div>
                </div>
              )}
            </div>
            <div className="mt-6 flex gap-3">
              <button
                onClick={() => {
                  setShowDilutionModel(false);
                  resetDilutionForm();
                }}
                className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleRunDilutionModel}
                className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
              >
                Run Scenario
              </button>
            </div>
          </div>
        </div>
      )}

      {showRoundModel && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <h3 className="text-xl font-semibold text-gray-900 mb-4">Model Funding Round</h3>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Round Name</label>
                  <input
                    type="text"
                    value={roundModel.round_name}
                    onChange={(e) => setRoundModel({ ...roundModel, round_name: e.target.value })}
                    placeholder="e.g., Series A"
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Round Type</label>
                  <select
                    value={roundModel.round_type}
                    onChange={(e) => setRoundModel({ ...roundModel, round_type: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="seed">Seed</option>
                    <option value="series_a">Series A</option>
                    <option value="series_b">Series B</option>
                    <option value="series_c">Series C</option>
                    <option value="series_d">Series D</option>
                    <option value="ipo">IPO</option>
                  </select>
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Amount to Raise (SAR)</label>
                <input
                  type="number"
                  value={roundModel.amount_to_raise}
                  onChange={(e) => setRoundModel({ ...roundModel, amount_to_raise: Number(e.target.value) })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Pre-Money Valuation (SAR)</label>
                <input
                  type="number"
                  value={roundModel.pre_money_valuation}
                  onChange={(e) => setRoundModel({ ...roundModel, pre_money_valuation: Number(e.target.value) })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Option Pool Increase (%)</label>
                <input
                  type="number"
                  step="0.1"
                  value={roundModel.option_pool_increase}
                  onChange={(e) => setRoundModel({ ...roundModel, option_pool_increase: Number(e.target.value) })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              {roundModel.amount_to_raise > 0 && roundModel.pre_money_valuation > 0 && (
                <div className="p-4 bg-orange-50 rounded-lg border border-orange-200">
                  <h4 className="font-medium text-orange-900 mb-2">Round Summary</h4>
                  <div className="space-y-1 text-sm">
                    <div className="flex justify-between">
                      <span className="text-orange-700">Post-Money Valuation:</span>
                      <span className="font-semibold text-orange-900">
                        SAR {((roundModel.pre_money_valuation + roundModel.amount_to_raise) / 1000000).toFixed(1)}M
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-orange-700">Price per Share:</span>
                      <span className="font-semibold text-orange-900">
                        SAR {totalShares > 0 ? (roundModel.pre_money_valuation / totalShares).toFixed(2) : '0.00'}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-orange-700">New Shares Issued:</span>
                      <span className="font-semibold text-orange-900">
                        {totalShares > 0 ? Math.round(roundModel.amount_to_raise / (roundModel.pre_money_valuation / totalShares)).toLocaleString() : '0'}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-orange-700">Investor Ownership:</span>
                      <span className="font-semibold text-orange-900">
                        {totalShares > 0 ? ((roundModel.amount_to_raise / (roundModel.pre_money_valuation + roundModel.amount_to_raise)) * 100).toFixed(2) : '0.00'}%
                      </span>
                    </div>
                  </div>
                </div>
              )}
            </div>
            <div className="mt-6 flex gap-3">
              <button
                onClick={() => {
                  setShowRoundModel(false);
                  resetRoundForm();
                }}
                className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleRunRoundModel}
                className="flex-1 px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700"
              >
                Model Round
              </button>
            </div>
          </div>
        </div>
      )}

      {showWaterfallAnalysis && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl p-6 w-full max-w-4xl max-h-[90vh] overflow-y-auto">
            <h3 className="text-xl font-semibold text-gray-900 mb-4">Waterfall Analysis</h3>

            {waterfallResults.length === 0 ? (
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Exit Value (SAR)</label>
                  <input
                    type="number"
                    value={waterfallConfig.exit_value}
                    onChange={(e) => setWaterfallConfig({ ...waterfallConfig, exit_value: Number(e.target.value) })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Exit Scenario</label>
                  <select
                    value={waterfallConfig.scenario_type}
                    onChange={(e) => setWaterfallConfig({ ...waterfallConfig, scenario_type: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="acquisition">Acquisition</option>
                    <option value="ipo">IPO</option>
                    <option value="liquidation">Liquidation</option>
                  </select>
                </div>
                <div className="flex gap-3 mt-6">
                  <button
                    onClick={() => setShowWaterfallAnalysis(false)}
                    className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleRunWaterfallAnalysis}
                    className="flex-1 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700"
                  >
                    Run Analysis
                  </button>
                </div>
              </div>
            ) : (
              <div>
                <div className="mb-4 p-4 bg-purple-50 rounded-lg border border-purple-200">
                  <div className="flex items-center justify-between">
                    <div>
                      <h4 className="font-medium text-purple-900">Exit Scenario: {waterfallConfig.scenario_type}</h4>
                      <p className="text-sm text-purple-700 mt-1">
                        Total Exit Value: SAR {(waterfallConfig.exit_value / 1000000).toFixed(1)}M
                      </p>
                    </div>
                    <button
                      onClick={() => setWaterfallResults([])}
                      className="px-3 py-1.5 text-sm text-purple-600 hover:bg-purple-100 rounded-lg"
                    >
                      New Analysis
                    </button>
                  </div>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Shareholder</th>
                        <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Shares</th>
                        <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Ownership %</th>
                        <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Payout</th>
                        <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Multiple</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {waterfallResults.map((result, index) => (
                        <tr key={index} className="hover:bg-gray-50">
                          <td className="px-4 py-3 font-medium text-gray-900">{result.shareholder}</td>
                          <td className="px-4 py-3 text-right text-gray-600">{result.shares.toLocaleString()}</td>
                          <td className="px-4 py-3 text-right text-gray-600">{result.ownership.toFixed(2)}%</td>
                          <td className="px-4 py-3 text-right font-semibold text-gray-900">
                            SAR {(result.payout / 1000000).toFixed(2)}M
                          </td>
                          <td className="px-4 py-3 text-right">
                            <span className={`font-semibold ${
                              result.multiple >= 2 ? 'text-green-600' :
                              result.multiple >= 1 ? 'text-blue-600' :
                              'text-red-600'
                            }`}>
                              {result.multiple.toFixed(2)}x
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                    <tfoot className="bg-gray-50 font-semibold">
                      <tr>
                        <td className="px-4 py-3 text-gray-900">Total</td>
                        <td className="px-4 py-3 text-right text-gray-900">
                          {waterfallResults.reduce((sum, r) => sum + r.shares, 0).toLocaleString()}
                        </td>
                        <td className="px-4 py-3 text-right text-gray-900">
                          {waterfallResults.reduce((sum, r) => sum + r.ownership, 0).toFixed(2)}%
                        </td>
                        <td className="px-4 py-3 text-right text-gray-900">
                          SAR {(waterfallResults.reduce((sum, r) => sum + r.payout, 0) / 1000000).toFixed(2)}M
                        </td>
                        <td className="px-4 py-3"></td>
                      </tr>
                    </tfoot>
                  </table>
                </div>

                <div className="mt-6 flex gap-3">
                  <button
                    onClick={() => setShowWaterfallAnalysis(false)}
                    className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
                  >
                    Close
                  </button>
                  <button className="flex-1 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700">
                    <Download className="w-4 h-4 inline mr-2" />
                    Export Analysis
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {showViewShareholder && selectedShareholder && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h2 className="text-xl font-semibold text-gray-900">Shareholder Details</h2>
              <button
                onClick={() => setShowViewShareholder(false)}
                className="text-gray-400 hover:text-gray-600 transition"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div className="p-6 space-y-6">
              <div className="bg-gradient-to-r from-blue-50 to-blue-100 rounded-lg p-6 border border-blue-200">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h3 className="text-2xl font-bold text-gray-900">{selectedShareholder.name}</h3>
                    <span className={`inline-block px-3 py-1 text-sm rounded-full mt-2 ${getTypeColor(selectedShareholder.shareholder_type)}`}>
                      {selectedShareholder.shareholder_type.replace('_', ' ')}
                    </span>
                  </div>
                  <div className="text-right">
                    <p className="text-sm text-gray-600">Share Class</p>
                    <p className="text-xl font-bold text-gray-900">{selectedShareholder.share_class}</p>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="bg-white border border-gray-200 rounded-lg p-4">
                  <p className="text-sm text-gray-600 mb-2">Shares Owned</p>
                  <p className="text-3xl font-bold text-gray-900">{Number(selectedShareholder.shares_owned).toLocaleString()}</p>
                </div>
                <div className="bg-white border border-gray-200 rounded-lg p-4">
                  <p className="text-sm text-gray-600 mb-2">Ownership Percentage</p>
                  <p className="text-3xl font-bold text-blue-600">{selectedShareholder.ownership_percentage.toFixed(2)}%</p>
                </div>
                <div className="bg-white border border-gray-200 rounded-lg p-4">
                  <p className="text-sm text-gray-600 mb-2">Investment Amount</p>
                  <p className="text-xl font-bold text-gray-900">{selectedShareholder.investment_amount.toLocaleString()} SAR</p>
                </div>
                <div className="bg-white border border-gray-200 rounded-lg p-4">
                  <p className="text-sm text-gray-600 mb-2">Status</p>
                  <p className={`text-lg font-semibold ${selectedShareholder.is_active ? 'text-green-600' : 'text-red-600'}`}>
                    {selectedShareholder.is_active ? 'Active' : 'Inactive'}
                  </p>
                </div>
              </div>

              {(selectedShareholder.liquidation_preference || selectedShareholder.preference_multiple) && (
                <div className="bg-gray-50 rounded-lg p-4 border border-gray-200">
                  <h4 className="font-semibold text-gray-900 mb-3">Liquidation Rights</h4>
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    {selectedShareholder.liquidation_preference && (
                      <div>
                        <p className="text-gray-600">Liquidation Preference</p>
                        <p className="font-bold text-gray-900">{selectedShareholder.liquidation_preference.toLocaleString()} SAR</p>
                      </div>
                    )}
                    {selectedShareholder.preference_multiple && (
                      <div>
                        <p className="text-gray-600">Preference Multiple</p>
                        <p className="font-bold text-gray-900">{selectedShareholder.preference_multiple}x</p>
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>

            <div className="sticky bottom-0 bg-gray-50 border-t border-gray-200 px-6 py-4">
              <button
                onClick={() => setShowViewShareholder(false)}
                className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {showEditShareholder && selectedShareholder && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h2 className="text-xl font-semibold text-gray-900">Edit Shareholder</h2>
              <button
                onClick={() => setShowEditShareholder(false)}
                className="text-gray-400 hover:text-gray-600 transition"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div className="p-6 space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Name *</label>
                  <input
                    type="text"
                    value={editShareholder.name}
                    onChange={(e) => setEditShareholder({ ...editShareholder, name: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    placeholder="Enter shareholder name"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Type *</label>
                  <select
                    value={editShareholder.shareholder_type}
                    onChange={(e) => setEditShareholder({ ...editShareholder, shareholder_type: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  >
                    <option value="founder">Founder</option>
                    <option value="investor">Investor</option>
                    <option value="employee">Employee</option>
                    <option value="advisor">Advisor</option>
                    <option value="other">Other</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Shares Owned *</label>
                  <input
                    type="number"
                    value={editShareholder.shares_owned}
                    onChange={(e) => setEditShareholder({ ...editShareholder, shares_owned: Number(e.target.value) })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    placeholder="Enter number of shares"
                    min="0"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Share Class</label>
                  <select
                    value={editShareholder.share_class}
                    onChange={(e) => setEditShareholder({ ...editShareholder, share_class: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  >
                    <option value="Common">Common</option>
                    <option value="Preferred A">Preferred A</option>
                    <option value="Preferred B">Preferred B</option>
                    <option value="Preferred C">Preferred C</option>
                    <option value="Preferred D">Preferred D</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Investment Amount (SAR)</label>
                  <input
                    type="number"
                    value={editShareholder.investment_amount}
                    onChange={(e) => setEditShareholder({ ...editShareholder, investment_amount: Number(e.target.value) })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    placeholder="Enter investment amount"
                    min="0"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Liquidation Preference (SAR)</label>
                  <input
                    type="number"
                    value={editShareholder.liquidation_preference}
                    onChange={(e) => setEditShareholder({ ...editShareholder, liquidation_preference: Number(e.target.value) })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    placeholder="Enter liquidation preference"
                    min="0"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Preference Multiple</label>
                  <input
                    type="number"
                    value={editShareholder.preference_multiple}
                    onChange={(e) => setEditShareholder({ ...editShareholder, preference_multiple: Number(e.target.value) })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    placeholder="Enter preference multiple"
                    min="1"
                    step="0.1"
                  />
                </div>
              </div>
            </div>

            <div className="sticky bottom-0 bg-gray-50 border-t border-gray-200 px-6 py-4 flex gap-3">
              <button
                onClick={() => setShowEditShareholder(false)}
                className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition font-medium"
              >
                Cancel
              </button>
              <button
                onClick={handleUpdateShareholder}
                className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
              >
                Update Shareholder
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
