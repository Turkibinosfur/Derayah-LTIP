import { useTranslation } from 'react-i18next';
import NotificationPreferences from '../components/NotificationPreferences';

export default function EmployeeNotifications() {
  const { t } = useTranslation();
  
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">{t('employeeNotifications.title')}</h1>
        <p className="text-gray-600 mt-1">{t('employeeNotifications.description')}</p>
      </div>
      <NotificationPreferences />
    </div>
  );
}