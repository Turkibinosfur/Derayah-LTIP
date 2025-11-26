import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../lib/supabase';
import PerformanceChart from '../components/PerformanceChart';

export default function EmployeePerformance() {
  const { t } = useTranslation();
  const [vestedShares, setVestedShares] = useState(0);
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
        .select('vested_shares')
        .eq('employee_id', employee.id)
        .eq('status', 'active')
        .maybeSingle();

      if (data) {
        setVestedShares(data.vested_shares);
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

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">{t('employeePerformance.title')}</h1>
        <p className="text-gray-600 mt-1">{t('employeePerformance.description')}</p>
      </div>
      <PerformanceChart currentPrice={85.50} vestedShares={vestedShares} />
    </div>
  );
}