import DocumentDownloadCenter from '../components/DocumentDownloadCenter';

export default function EmployeeDocuments() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Documents</h1>
        <p className="text-gray-600 mt-1">Access and download your equity documents</p>
      </div>
      <DocumentDownloadCenter />
    </div>
  );
}