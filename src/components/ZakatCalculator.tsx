import { useState } from 'react';
import { DollarSign, AlertCircle, Info, Download } from 'lucide-react';

interface ZakatCalculatorProps {
  vestedShares: number;
  currentPrice: number;
}

export default function ZakatCalculator({ vestedShares, currentPrice }: ZakatCalculatorProps) {
  const [otherAssets, setOtherAssets] = useState<number>(0);
  const [cashSavings, setCashSavings] = useState<number>(0);
  const [gold, setGold] = useState<number>(0);
  const [investments, setInvestments] = useState<number>(0);
  const [liabilities, setLiabilities] = useState<number>(0);

  const nisabThreshold = 85 * 595;
  const zakatRate = 0.025;

  const shareValue = vestedShares * currentPrice;
  const totalAssets = shareValue + otherAssets + cashSavings + gold + investments;
  const netAssets = totalAssets - liabilities;
  const zakatDue = netAssets >= nisabThreshold ? netAssets * zakatRate : 0;
  const isZakatPayable = netAssets >= nisabThreshold;

  const exportCalculation = () => {
    const report = `
ZAKAT CALCULATION REPORT
Generated: ${new Date().toLocaleString()}
Hijri Date: ${new Date().toLocaleDateString('ar-SA-u-ca-islamic')}

ASSETS BREAKDOWN
Vested Shares Value: ${shareValue.toLocaleString()} SAR
  - Shares: ${vestedShares.toLocaleString()}
  - Price: ${currentPrice.toFixed(2)} SAR
Cash & Savings: ${cashSavings.toLocaleString()} SAR
Gold & Precious Metals: ${gold.toLocaleString()} SAR
Other Investments: ${investments.toLocaleString()} SAR
Other Assets: ${otherAssets.toLocaleString()} SAR
Total Assets: ${totalAssets.toLocaleString()} SAR

LIABILITIES
Total Liabilities: ${liabilities.toLocaleString()} SAR

NET ZAKATABLE WEALTH
Net Assets: ${netAssets.toLocaleString()} SAR
Nisab Threshold: ${nisabThreshold.toLocaleString()} SAR (85g of gold)

ZAKAT CALCULATION
Zakat Rate: 2.5%
Zakat Payable: ${isZakatPayable ? 'YES' : 'NO'}
Zakat Due: ${zakatDue.toLocaleString()} SAR

NOTES
- This calculation uses the gold standard for Nisab (85 grams at ~595 SAR/gram)
- Zakat is calculated on net assets held for one lunar year
- Please consult with a qualified Islamic scholar for specific rulings

بسم الله الرحمن الرحيم
"And establish prayer and give zakah and bow with those who bow [in worship and obedience]." - Quran 2:43
    `;

    const blob = new Blob([report], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `zakat-calculation-${new Date().toISOString().split('T')[0]}.txt`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="bg-white rounded-xl border border-gray-200 shadow-sm">
      <div className="p-6 border-b border-gray-200 bg-gradient-to-r from-green-50 to-emerald-50">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-12 h-12 bg-green-600 rounded-lg flex items-center justify-center">
              <DollarSign className="w-6 h-6 text-white" />
            </div>
            <div>
              <h3 className="text-xl font-bold text-gray-900">Zakat Calculator</h3>
              <p className="text-sm text-gray-600">Calculate your Islamic wealth tax</p>
            </div>
          </div>
        </div>
      </div>

      <div className="p-6 space-y-6">
        <div className="bg-green-50 rounded-lg p-4 border border-green-200">
          <h4 className="font-semibold text-gray-900 mb-3">Share Portfolio Value</h4>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-600">Vested Shares</p>
              <p className="text-lg font-bold text-gray-900">{vestedShares.toLocaleString()}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Current Price</p>
              <p className="text-lg font-bold text-gray-900">{currentPrice.toFixed(2)} SAR</p>
            </div>
          </div>
          <div className="mt-3 pt-3 border-t border-green-200">
            <p className="text-sm text-gray-600">Total Share Value</p>
            <p className="text-2xl font-bold text-green-600">{shareValue.toLocaleString()} SAR</p>
          </div>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Cash & Savings - SAR
            </label>
            <input
              type="number"
              value={cashSavings || ''}
              onChange={(e) => setCashSavings(Number(e.target.value) || 0)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="Enter cash and savings"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Gold & Precious Metals - SAR
            </label>
            <input
              type="number"
              value={gold || ''}
              onChange={(e) => setGold(Number(e.target.value) || 0)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="Enter gold value"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Other Investments - SAR
            </label>
            <input
              type="number"
              value={investments || ''}
              onChange={(e) => setInvestments(Number(e.target.value) || 0)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="Enter other investments"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Other Assets - SAR
            </label>
            <input
              type="number"
              value={otherAssets || ''}
              onChange={(e) => setOtherAssets(Number(e.target.value) || 0)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="Enter other zakatable assets"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Liabilities (Debts) - SAR
            </label>
            <input
              type="number"
              value={liabilities || ''}
              onChange={(e) => setLiabilities(Number(e.target.value) || 0)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="Enter debts and liabilities"
            />
          </div>
        </div>

        <div className="bg-gradient-to-br from-green-50 to-emerald-50 rounded-lg p-6 border-2 border-green-200">
          <h4 className="font-semibold text-gray-900 mb-4">Zakat Calculation</h4>

          <div className="space-y-3">
            <div className="flex justify-between items-center pb-3 border-b border-green-200">
              <span className="text-sm text-gray-600">Total Assets</span>
              <span className="font-semibold text-gray-900">{totalAssets.toLocaleString()} SAR</span>
            </div>

            <div className="flex justify-between items-center pb-3 border-b border-green-200">
              <span className="text-sm text-gray-600">Less: Liabilities</span>
              <span className="font-semibold text-red-600">-{liabilities.toLocaleString()} SAR</span>
            </div>

            <div className="flex justify-between items-center pb-3 border-b border-green-200">
              <span className="text-sm font-medium text-gray-700">Net Zakatable Wealth</span>
              <span className="font-bold text-gray-900">{netAssets.toLocaleString()} SAR</span>
            </div>

            <div className="flex justify-between items-center pb-3 border-b border-green-200">
              <span className="text-sm text-gray-600">Nisab Threshold</span>
              <span className="font-semibold text-gray-900">{nisabThreshold.toLocaleString()} SAR</span>
            </div>

            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600">Zakat Payable</span>
              <span className={`font-bold ${isZakatPayable ? 'text-green-600' : 'text-gray-400'}`}>
                {isZakatPayable ? 'YES' : 'NO'}
              </span>
            </div>
          </div>

          <div className="mt-6 pt-4 border-t-2 border-green-300">
            <div className="flex justify-between items-center">
              <span className="text-base font-bold text-gray-900">Zakat Due (2.5%)</span>
              <span className="text-3xl font-bold text-green-600">{zakatDue.toLocaleString()} SAR</span>
            </div>
          </div>

          {!isZakatPayable && (
            <div className="mt-4 bg-blue-50 rounded-lg p-3 border border-blue-200">
              <div className="flex items-start space-x-2">
                <Info className="w-4 h-4 text-blue-600 mt-0.5 flex-shrink-0" />
                <p className="text-sm text-blue-800">
                  Your net zakatable wealth is below the Nisab threshold. Zakat is not obligatory at this time.
                </p>
              </div>
            </div>
          )}
        </div>

        <button
          onClick={exportCalculation}
          className="w-full flex items-center justify-center space-x-2 px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition font-medium"
        >
          <Download className="w-4 h-4" />
          <span>Export Calculation</span>
        </button>

        <div className="bg-yellow-50 rounded-lg p-4 border border-yellow-200">
          <div className="flex items-start space-x-3">
            <AlertCircle className="w-5 h-5 text-yellow-600 mt-0.5 flex-shrink-0" />
            <div>
              <p className="text-sm font-semibold text-yellow-900 mb-1">Important Notes</p>
              <ul className="text-sm text-yellow-800 space-y-1">
                <li>• Zakat is due on wealth held for one complete lunar year (Hawl)</li>
                <li>• The Nisab is based on 85 grams of gold (approximately {nisabThreshold.toLocaleString()} SAR)</li>
                <li>• Only include assets that are zakatable according to Islamic law</li>
                <li>• This calculator provides an estimate. Please consult a qualified Islamic scholar for specific rulings</li>
              </ul>
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-r from-green-600 to-emerald-600 rounded-lg p-4 text-white text-center">
          <p className="text-sm font-arabic mb-1">بسم الله الرحمن الرحيم</p>
          <p className="text-xs opacity-90">
            "And establish prayer and give zakah..." - Quran 2:43
          </p>
        </div>
      </div>
    </div>
  );
}
