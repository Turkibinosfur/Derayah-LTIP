import { useState } from 'react';
import { Calculator, AlertCircle, FileText, Download } from 'lucide-react';

interface TaxCalculatorProps {
  vestedShares: number;
  currentPrice: number;
  exercisePrice?: number;
}

export default function TaxCalculator({
  vestedShares,
  currentPrice,
  exercisePrice = 0
}: TaxCalculatorProps) {
  const [annualIncome, setAnnualIncome] = useState<number>(0);
  const [otherCapitalGains, setOtherCapitalGains] = useState<number>(0);

  const shareGain = (currentPrice - exercisePrice) * vestedShares;
  const totalIncome = annualIncome + shareGain + otherCapitalGains;

  const calculateTax = (income: number): number => {
    if (income <= 0) return 0;

    let tax = 0;

    if (income > 1000000) {
      tax += (income - 1000000) * 0.25;
      income = 1000000;
    }
    if (income > 500000) {
      tax += (income - 500000) * 0.20;
      income = 500000;
    }
    if (income > 250000) {
      tax += (income - 250000) * 0.15;
      income = 250000;
    }
    if (income > 100000) {
      tax += (income - 100000) * 0.10;
      income = 100000;
    }
    if (income > 50000) {
      tax += (income - 50000) * 0.05;
    }

    return tax;
  };

  const incomeTaxOnSalary = calculateTax(annualIncome);
  const totalTax = calculateTax(totalIncome);
  const additionalTaxFromShares = totalTax - incomeTaxOnSalary;
  const netGainAfterTax = shareGain - additionalTaxFromShares;
  const effectiveTaxRate = shareGain > 0 ? (additionalTaxFromShares / shareGain) * 100 : 0;

  const exportCalculation = () => {
    const report = `
TAX CALCULATION REPORT
Generated: ${new Date().toLocaleString()}

INCOME BREAKDOWN
Annual Income: ${annualIncome.toLocaleString()} SAR
Share Capital Gain: ${shareGain.toLocaleString()} SAR
Other Capital Gains: ${otherCapitalGains.toLocaleString()} SAR
Total Taxable Income: ${totalIncome.toLocaleString()} SAR

SHARE DETAILS
Vested Shares: ${vestedShares.toLocaleString()}
Current Price: ${currentPrice.toFixed(2)} SAR
Exercise Price: ${exercisePrice.toFixed(2)} SAR
Gain per Share: ${(currentPrice - exercisePrice).toFixed(2)} SAR

TAX CALCULATION
Tax on Salary Only: ${incomeTaxOnSalary.toLocaleString()} SAR
Tax on Total Income: ${totalTax.toLocaleString()} SAR
Additional Tax from Shares: ${additionalTaxFromShares.toLocaleString()} SAR
Effective Tax Rate on Shares: ${effectiveTaxRate.toFixed(2)}%

NET RESULTS
Gross Share Gain: ${shareGain.toLocaleString()} SAR
Tax on Share Gain: ${additionalTaxFromShares.toLocaleString()} SAR
Net Gain After Tax: ${netGainAfterTax.toLocaleString()} SAR

DISCLAIMER
This calculation is for estimation purposes only. Please consult with a qualified tax advisor for accurate tax planning.
    `;

    const blob = new Blob([report], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `tax-calculation-${new Date().toISOString().split('T')[0]}.txt`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="bg-white rounded-xl border border-gray-200 shadow-sm">
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <Calculator className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <h3 className="text-xl font-bold text-gray-900">Tax Calculator</h3>
              <p className="text-sm text-gray-600">Estimate your tax liability on vested shares</p>
            </div>
          </div>
        </div>
      </div>

      <div className="p-6 space-y-6">
        <div className="bg-blue-50 rounded-lg p-4 border border-blue-200">
          <h4 className="font-semibold text-gray-900 mb-3">Share Capital Gain</h4>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-600">Vested Shares</p>
              <p className="text-lg font-bold text-gray-900">{vestedShares.toLocaleString()}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600">Gain per Share</p>
              <p className="text-lg font-bold text-gray-900">{(currentPrice - exercisePrice).toFixed(2)} SAR</p>
            </div>
          </div>
          <div className="mt-3 pt-3 border-t border-blue-200">
            <p className="text-sm text-gray-600">Total Capital Gain from Shares</p>
            <p className="text-2xl font-bold text-blue-600">{shareGain.toLocaleString()} SAR</p>
          </div>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Annual Income (Salary) - SAR
            </label>
            <input
              type="number"
              value={annualIncome || ''}
              onChange={(e) => setAnnualIncome(Number(e.target.value) || 0)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Enter your annual income"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Other Capital Gains - SAR
            </label>
            <input
              type="number"
              value={otherCapitalGains || ''}
              onChange={(e) => setOtherCapitalGains(Number(e.target.value) || 0)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Enter other capital gains"
            />
          </div>
        </div>

        <div className="bg-gradient-to-br from-gray-50 to-gray-100 rounded-lg p-6 border border-gray-200">
          <h4 className="font-semibold text-gray-900 mb-4">Tax Calculation Results</h4>

          <div className="space-y-3">
            <div className="flex justify-between items-center pb-3 border-b border-gray-300">
              <span className="text-sm text-gray-600">Total Taxable Income</span>
              <span className="font-semibold text-gray-900">{totalIncome.toLocaleString()} SAR</span>
            </div>

            <div className="flex justify-between items-center pb-3 border-b border-gray-300">
              <span className="text-sm text-gray-600">Tax on Salary Only</span>
              <span className="font-semibold text-gray-900">{incomeTaxOnSalary.toLocaleString()} SAR</span>
            </div>

            <div className="flex justify-between items-center pb-3 border-b border-gray-300">
              <span className="text-sm text-gray-600">Tax on Total Income</span>
              <span className="font-semibold text-gray-900">{totalTax.toLocaleString()} SAR</span>
            </div>

            <div className="flex justify-between items-center pb-3 border-b border-gray-300">
              <span className="text-sm font-medium text-gray-700">Additional Tax from Shares</span>
              <span className="font-bold text-red-600">{additionalTaxFromShares.toLocaleString()} SAR</span>
            </div>

            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600">Effective Tax Rate on Shares</span>
              <span className="font-semibold text-gray-900">{effectiveTaxRate.toFixed(2)}%</span>
            </div>
          </div>

          <div className="mt-4 pt-4 border-t-2 border-gray-300">
            <div className="flex justify-between items-center">
              <span className="text-base font-bold text-gray-900">Net Gain After Tax</span>
              <span className="text-2xl font-bold text-green-600">{netGainAfterTax.toLocaleString()} SAR</span>
            </div>
          </div>
        </div>

        <div className="flex items-center space-x-3">
          <button
            onClick={exportCalculation}
            className="flex-1 flex items-center justify-center space-x-2 px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium"
          >
            <Download className="w-4 h-4" />
            <span>Export Calculation</span>
          </button>
          <button className="px-4 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition">
            <FileText className="w-5 h-5" />
          </button>
        </div>

        <div className="bg-yellow-50 rounded-lg p-4 border border-yellow-200">
          <div className="flex items-start space-x-3">
            <AlertCircle className="w-5 h-5 text-yellow-600 mt-0.5 flex-shrink-0" />
            <div>
              <p className="text-sm font-semibold text-yellow-900 mb-1">Important Disclaimer</p>
              <p className="text-sm text-yellow-800">
                This calculation is for estimation purposes only and uses Saudi tax brackets.
                Actual tax liability may vary based on your specific circumstances.
                Please consult with a qualified tax advisor or accountant for accurate tax planning and filing.
              </p>
            </div>
          </div>
        </div>

        <div className="bg-gray-50 rounded-lg p-4">
          <h5 className="font-semibold text-gray-900 mb-2 text-sm">Saudi Tax Brackets (2024)</h5>
          <div className="space-y-1 text-xs text-gray-600">
            <p>• 0% on income up to 50,000 SAR</p>
            <p>• 5% on income from 50,001 to 100,000 SAR</p>
            <p>• 10% on income from 100,001 to 250,000 SAR</p>
            <p>• 15% on income from 250,001 to 500,000 SAR</p>
            <p>• 20% on income from 500,001 to 1,000,000 SAR</p>
            <p>• 25% on income above 1,000,000 SAR</p>
          </div>
        </div>
      </div>
    </div>
  );
}
