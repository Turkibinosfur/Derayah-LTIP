import { useTranslation } from 'react-i18next';
import DocumentDownloadCenter from '../components/DocumentDownloadCenter';

export default function EmployeeDocuments() {
  const { t } = useTranslation();
  
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">{t('employeeDocuments.title')}</h1>
        <p className="text-gray-600 mt-1">{t('employeeDocuments.description')}</p>
      </div>
      <DocumentDownloadCenter />
    </div>
  );
}