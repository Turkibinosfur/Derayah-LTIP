import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { TrendingUp, TrendingDown, DollarSign, RefreshCw, AlertCircle } from 'lucide-react';

interface PortfolioValuationProps {
  tadawulSymbol: string;
  vestedShares: number;
  unvestedShares: number;
}

interface StockPrice {
  price: number;
  change: number;
  changePercent: number;
  lastUpdate: string;
}

export default function PortfolioValuation({
  tadawulSymbol,
  vestedShares,
  unvestedShares
}: PortfolioValuationProps) {
  const { t } = useTranslation();
  const [stockPrice, setStockPrice] = useState<StockPrice>({
    price: 85.50,
    change: 2.30,
    changePercent: 2.76,
    lastUpdate: new Date().toISOString()
  });
  const [loading, setLoading] = useState(false);
  const [autoRefresh, setAutoRefresh] = useState(true);

  const refreshPrice = async () => {
    setLoading(true);
    await new Promise(resolve => setTimeout(resolve, 1000));

    const mockChange = (Math.random() - 0.5) * 5;
    const newPrice = stockPrice.price + mockChange;
    const changePercent = (mockChange / stockPrice.price) * 100;

    setStockPrice({
      price: newPrice,
      change: mockChange,
      changePercent: changePercent,
      lastUpdate: new Date().toISOString()
    });
    setLoading(false);
  };

  useEffect(() => {
    if (autoRefresh) {
      const interval = setInterval(refreshPrice, 60000);
      return () => clearInterval(interval);
    }
  }, [autoRefresh, stockPrice.price]);

  const vestedValue = vestedShares * stockPrice.price;
  const unvestedValue = unvestedShares * stockPrice.price;
  const totalValue = vestedValue + unvestedValue;

  return (
    <div className="bg-gradient-to-br from-blue-600 to-blue-800 rounded-xl shadow-lg text-white">
      <div className="p-6">
        <div className="flex items-start justify-between mb-6">
          <div>
            <h3 className="text-lg font-semibold mb-1">{t('charts.portfolioValue')}</h3>
            <p className="text-blue-200 text-sm">{t('charts.realTimeTadawulPricing')}</p>
          </div>
          <div className="flex items-center space-x-2">
            <button
              onClick={() => setAutoRefresh(!autoRefresh)}
              className={`px-3 py-1.5 text-xs font-medium rounded-lg transition ${
                autoRefresh
                  ? 'bg-white/20 text-white'
                  : 'bg-white/10 text-blue-200 hover:bg-white/20'
              }`}
            >
              {autoRefresh ? t('charts.autoRefreshON') : t('charts.autoRefreshOFF')}
            </button>
            <button
              onClick={refreshPrice}
              disabled={loading}
              className="p-2 bg-white/20 hover:bg-white/30 rounded-lg transition disabled:opacity-50"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>

        <div className="bg-white/10 backdrop-blur-sm rounded-lg p-4 mb-4">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center space-x-2">
              <span className="text-sm text-blue-200">{t('charts.stockSymbol')}</span>
              <span className="text-lg font-bold">{tadawulSymbol}</span>
            </div>
            <div className={`flex items-center space-x-1 ${stockPrice.change >= 0 ? 'text-green-300' : 'text-red-300'}`}>
              {stockPrice.change >= 0 ? (
                <TrendingUp className="w-4 h-4" />
              ) : (
                <TrendingDown className="w-4 h-4" />
              )}
              <span className="text-sm font-semibold">
                {stockPrice.changePercent >= 0 ? '+' : ''}{stockPrice.changePercent.toFixed(2)}%
              </span>
            </div>
          </div>
          <div className="flex items-baseline space-x-2">
            <span className="text-3xl font-bold">{stockPrice.price.toFixed(2)}</span>
            <span className="text-sm text-blue-200">SAR</span>
            <span className={`text-sm font-medium ml-2 ${stockPrice.change >= 0 ? 'text-green-300' : 'text-red-300'}`}>
              {stockPrice.change >= 0 ? '+' : ''}{stockPrice.change.toFixed(2)}
            </span>
          </div>
          <p className="text-xs text-blue-300 mt-2">
            Last updated: {new Date(stockPrice.lastUpdate).toLocaleTimeString()}
          </p>
        </div>

        <div className="space-y-3">
          <div className="bg-white/10 backdrop-blur-sm rounded-lg p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-blue-200 mb-1">{t('charts.vestedValue')}</p>
                <p className="text-2xl font-bold">{vestedValue.toLocaleString('en-SA', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} SAR</p>
                <p className="text-xs text-blue-300 mt-1">{vestedShares.toLocaleString()} shares × {stockPrice.price.toFixed(2)} SAR</p>
              </div>
              <div className="w-16 h-16 bg-green-500/20 rounded-full flex items-center justify-center">
                <DollarSign className="w-8 h-8 text-green-300" />
              </div>
            </div>
          </div>

          <div className="bg-white/10 backdrop-blur-sm rounded-lg p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-blue-200 mb-1">{t('charts.unvestedValue')}</p>
                <p className="text-2xl font-bold">{unvestedValue.toLocaleString('en-SA', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} SAR</p>
                <p className="text-xs text-blue-300 mt-1">{unvestedShares.toLocaleString()} shares × {stockPrice.price.toFixed(2)} SAR</p>
              </div>
              <div className="w-16 h-16 bg-blue-500/20 rounded-full flex items-center justify-center">
                <DollarSign className="w-8 h-8 text-blue-300" />
              </div>
            </div>
          </div>

          <div className="bg-gradient-to-r from-yellow-400/20 to-orange-400/20 backdrop-blur-sm rounded-lg p-4 border border-white/20">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-white/90 mb-1 font-semibold">{t('charts.totalValue')}</p>
                <p className="text-3xl font-bold">{totalValue.toLocaleString('en-SA', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} SAR</p>
                <p className="text-xs text-white/80 mt-1">{(vestedShares + unvestedShares).toLocaleString()} total shares</p>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-4 p-3 bg-white/10 rounded-lg flex items-start space-x-2">
          <AlertCircle className="w-4 h-4 text-blue-300 mt-0.5 flex-shrink-0" />
          <p className="text-xs text-blue-200">
            Prices are indicative and may not reflect real-time Tadawul values. For actual trading, please consult official market sources.
          </p>
        </div>
      </div>
    </div>
  );
}
