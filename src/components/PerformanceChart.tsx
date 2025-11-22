import { useState, useMemo } from 'react';
import { TrendingUp, TrendingDown, Calendar } from 'lucide-react';

interface PerformanceChartProps {
  currentPrice: number;
  vestedShares: number;
}

interface DataPoint {
  date: string;
  price: number;
  value: number;
}

export default function PerformanceChart({ currentPrice, vestedShares }: PerformanceChartProps) {
  const [timeframe, setTimeframe] = useState<'1M' | '3M' | '6M' | '1Y' | 'ALL'>('3M');

  const historicalData = useMemo(() => {
    const data: DataPoint[] = [];
    const now = new Date();
    let daysBack = 90;

    switch (timeframe) {
      case '1M': daysBack = 30; break;
      case '3M': daysBack = 90; break;
      case '6M': daysBack = 180; break;
      case '1Y': daysBack = 365; break;
      case 'ALL': daysBack = 730; break;
    }

    let price = currentPrice * 0.85;

    for (let i = daysBack; i >= 0; i--) {
      const date = new Date(now);
      date.setDate(date.getDate() - i);

      const volatility = (Math.random() - 0.5) * 2;
      const trend = (daysBack - i) / daysBack * 0.15;
      price = price * (1 + (volatility / 100) + (trend / 100));

      data.push({
        date: date.toISOString().split('T')[0],
        price: Number(price.toFixed(2)),
        value: Number((price * vestedShares).toFixed(2))
      });
    }

    return data;
  }, [timeframe, currentPrice, vestedShares]);

  const stats = useMemo(() => {
    const firstPrice = historicalData[0]?.price || 0;
    const lastPrice = historicalData[historicalData.length - 1]?.price || 0;
    const change = lastPrice - firstPrice;
    const changePercent = firstPrice > 0 ? (change / firstPrice) * 100 : 0;

    const prices = historicalData.map(d => d.price);
    const maxPrice = Math.max(...prices);
    const minPrice = Math.min(...prices);

    const firstValue = historicalData[0]?.value || 0;
    const lastValue = historicalData[historicalData.length - 1]?.value || 0;
    const valueChange = lastValue - firstValue;

    return {
      change,
      changePercent,
      maxPrice,
      minPrice,
      valueChange,
      firstValue,
      lastValue
    };
  }, [historicalData]);

  const chartHeight = 200;
  const chartWidth = 600;
  const padding = { top: 20, right: 20, bottom: 30, left: 60 };

  const priceRange = stats.maxPrice - stats.minPrice;
  const yScale = (price: number) => {
    return chartHeight - padding.bottom - ((price - stats.minPrice) / priceRange) * (chartHeight - padding.top - padding.bottom);
  };

  const xScale = (index: number) => {
    return padding.left + (index / (historicalData.length - 1)) * (chartWidth - padding.left - padding.right);
  };

  const pathD = historicalData.map((d, i) => {
    const x = xScale(i);
    const y = yScale(d.price);
    return `${i === 0 ? 'M' : 'L'} ${x} ${y}`;
  }).join(' ');

  const areaPathD = `${pathD} L ${xScale(historicalData.length - 1)} ${chartHeight - padding.bottom} L ${padding.left} ${chartHeight - padding.bottom} Z`;

  return (
    <div className="bg-white rounded-xl border border-gray-200 shadow-sm">
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="text-xl font-bold text-gray-900">Performance History</h3>
            <p className="text-sm text-gray-600 mt-1">Track your portfolio value over time</p>
          </div>
          <div className="flex items-center space-x-2">
            {(['1M', '3M', '6M', '1Y', 'ALL'] as const).map((period) => (
              <button
                key={period}
                onClick={() => setTimeframe(period)}
                className={`px-3 py-1.5 text-xs font-medium rounded-lg transition ${
                  timeframe === period
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {period}
              </button>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4 mb-6">
          <div className="bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg p-4 border border-blue-200">
            <p className="text-sm text-gray-600 mb-1">Current Portfolio Value</p>
            <p className="text-2xl font-bold text-gray-900">{stats.lastValue.toLocaleString()} SAR</p>
            <div className={`flex items-center space-x-1 mt-2 text-sm ${stats.changePercent >= 0 ? 'text-green-600' : 'text-red-600'}`}>
              {stats.changePercent >= 0 ? <TrendingUp className="w-4 h-4" /> : <TrendingDown className="w-4 h-4" />}
              <span className="font-semibold">
                {stats.changePercent >= 0 ? '+' : ''}{stats.changePercent.toFixed(2)}%
              </span>
              <span className="text-gray-500">({stats.changePercent >= 0 ? '+' : ''}{stats.valueChange.toLocaleString()} SAR)</span>
            </div>
          </div>

          <div className="bg-gray-50 rounded-lg p-4 border border-gray-200">
            <div className="grid grid-cols-2 gap-3">
              <div>
                <p className="text-xs text-gray-600 mb-1">High</p>
                <p className="text-lg font-bold text-green-600">{stats.maxPrice.toFixed(2)} SAR</p>
              </div>
              <div>
                <p className="text-xs text-gray-600 mb-1">Low</p>
                <p className="text-lg font-bold text-red-600">{stats.minPrice.toFixed(2)} SAR</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="p-6">
        <div className="relative">
          <svg
            viewBox={`0 0 ${chartWidth} ${chartHeight}`}
            className="w-full"
            style={{ minHeight: '250px' }}
          >
            <defs>
              <linearGradient id="areaGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#3b82f6" stopOpacity="0.3" />
                <stop offset="100%" stopColor="#3b82f6" stopOpacity="0.05" />
              </linearGradient>
            </defs>

            <path
              d={areaPathD}
              fill="url(#areaGradient)"
            />

            <path
              d={pathD}
              fill="none"
              stroke="#3b82f6"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />

            {historicalData.map((d, i) => {
              if (i % Math.ceil(historicalData.length / 8) === 0 || i === historicalData.length - 1) {
                return (
                  <g key={i}>
                    <circle
                      cx={xScale(i)}
                      cy={yScale(d.price)}
                      r="3"
                      fill="#3b82f6"
                      className="hover:r-5 transition-all cursor-pointer"
                    />
                  </g>
                );
              }
              return null;
            })}

            <line
              x1={padding.left}
              y1={chartHeight - padding.bottom}
              x2={chartWidth - padding.right}
              y2={chartHeight - padding.bottom}
              stroke="#d1d5db"
              strokeWidth="1"
            />

            <line
              x1={padding.left}
              y1={padding.top}
              x2={padding.left}
              y2={chartHeight - padding.bottom}
              stroke="#d1d5db"
              strokeWidth="1"
            />

            {[0, 0.25, 0.5, 0.75, 1].map((ratio) => {
              const price = stats.minPrice + (priceRange * ratio);
              const y = yScale(price);
              return (
                <g key={ratio}>
                  <line
                    x1={padding.left}
                    y1={y}
                    x2={chartWidth - padding.right}
                    y2={y}
                    stroke="#e5e7eb"
                    strokeWidth="1"
                    strokeDasharray="4 4"
                  />
                  <text
                    x={padding.left - 10}
                    y={y + 4}
                    textAnchor="end"
                    fontSize="10"
                    fill="#6b7280"
                  >
                    {price.toFixed(1)}
                  </text>
                </g>
              );
            })}

            {historicalData.map((d, i) => {
              if (i % Math.ceil(historicalData.length / 6) === 0) {
                const date = new Date(d.date);
                const label = date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
                return (
                  <text
                    key={i}
                    x={xScale(i)}
                    y={chartHeight - padding.bottom + 20}
                    textAnchor="middle"
                    fontSize="10"
                    fill="#6b7280"
                  >
                    {label}
                  </text>
                );
              }
              return null;
            })}
          </svg>
        </div>

        <div className="mt-6 grid grid-cols-3 gap-4 text-center">
          <div className="p-3 bg-gray-50 rounded-lg">
            <Calendar className="w-5 h-5 text-gray-400 mx-auto mb-2" />
            <p className="text-xs text-gray-600 mb-1">Period Start</p>
            <p className="text-sm font-semibold text-gray-900">
              {new Date(historicalData[0]?.date).toLocaleDateString()}
            </p>
          </div>
          <div className="p-3 bg-blue-50 rounded-lg border border-blue-200">
            <TrendingUp className="w-5 h-5 text-blue-600 mx-auto mb-2" />
            <p className="text-xs text-gray-600 mb-1">Total Gain/Loss</p>
            <p className={`text-sm font-semibold ${stats.valueChange >= 0 ? 'text-green-600' : 'text-red-600'}`}>
              {stats.valueChange >= 0 ? '+' : ''}{stats.valueChange.toLocaleString()} SAR
            </p>
          </div>
          <div className="p-3 bg-gray-50 rounded-lg">
            <Calendar className="w-5 h-5 text-gray-400 mx-auto mb-2" />
            <p className="text-xs text-gray-600 mb-1">Period End</p>
            <p className="text-sm font-semibold text-gray-900">
              {new Date(historicalData[historicalData.length - 1]?.date).toLocaleDateString()}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
