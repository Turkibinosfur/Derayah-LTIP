import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../lib/supabase';
import TaxCalculator from '../components/TaxCalculator';

export default function EmployeeTaxCalculator() {
  const { t } = useTranslation();
  const [grantData, setGrantData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: employee } = await supabase
        .from('employees')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

      if (!employee) return;

      const { data } = await supabase
        .from('grants')
        .select(`
          vested_shares,
          incentive_plans (
            exercise_price
          )
        `)
        .eq('employee_id', employee.id)
        .eq('status', 'active')
        .maybeSingle();

      if (data) {
        setGrantData(data);
      }
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="flex items-center justify-center h-64"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div></div>;
  }

  if (!grantData) {
    return <div className="text-center py-12"><p className="text-gray-600">{t('employeeTaxCalculator.noGrantData')}</p></div>;
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">{t('employeeTaxCalculator.title')}</h1>
        <p className="text-gray-600 mt-1">{t('employeeTaxCalculator.description')}</p>
      </div>
      <TaxCalculator
        vestedShares={grantData.vested_shares}
        currentPrice={85.50}
        exercisePrice={grantData.incentive_plans?.exercise_price || 0}
      />
    </div>
  );
}