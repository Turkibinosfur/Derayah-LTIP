import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { FileText, Download, Eye, Search, Filter, CheckCircle, Clock, AlertCircle } from 'lucide-react';
import { formatDate } from '../lib/dateUtils';

interface Document {
  id: string;
  document_name: string;
  document_type: string;
  status: 'draft' | 'pending_signature' | 'signed' | 'executed';
  generated_at: string;
  document_content: string;
  grant_data?: {
    id: string;
    grant_number: string;
    status: string;
    employee_acceptance_at: string | null;
    total_shares: number;
    grant_date: string;
    vesting_start_date: string;
    vesting_end_date: string;
  };
}

export default function DocumentDownloadCenter() {
  const [documents, setDocuments] = useState<Document[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<string>('all');
  const [selectedDoc, setSelectedDoc] = useState<Document | null>(null);
  const [showPreview, setShowPreview] = useState(false);
  const [accepting, setAccepting] = useState(false);

  useEffect(() => {
    loadDocuments();
  }, []);

  const loadDocuments = async () => {
    try {
      // Get current user from Supabase auth
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        console.log('No authenticated user');
        return;
      }

      // Get employee data from database using user_id
      const { data: employee, error: employeeError } = await supabase
        .from('employees')
        .select('id, company_id, first_name_en, last_name_en, email, user_id')
        .eq('user_id', user.id)
        .maybeSingle();

      if (employeeError || !employee) {
        console.error('Error loading employee data:', employeeError);
        return;
      }

      console.log('Loading documents for employee:', employee);

      // Load documents from the generated_documents table (where contracts are stored)
      const { data, error } = await supabase
        .from('generated_documents')
        .select(`
          *,
          grants(
            id,
            grant_number,
            status,
            employee_acceptance_at,
            total_shares,
            grant_date,
            vesting_start_date,
            vesting_end_date
          )
        `)
        .eq('employee_id', employee.id)
        .order('generated_at', { ascending: false });

      if (error) {
        console.error('Error loading generated documents:', error);
        // Create sample documents as fallback
        await createSampleDocuments(employee);
        return;
      }

      // Transform documents to match expected format
      const transformedDocs = (data || []).map(doc => {
        const grant = doc.grants;
        let documentStatus = (doc.status as Document['status']) || 'draft';
        
        if (grant?.employee_acceptance_at) {
          documentStatus = 'signed';
        } else if (!documentStatus || documentStatus === 'draft') {
          if (grant?.status === 'pending_signature') {
            documentStatus = 'pending_signature';
          } else if (!documentStatus) {
            documentStatus = 'draft';
          }
        }
        
        return {
          id: doc.id,
          document_name: doc.document_name || 'Grant Agreement',
          document_type: doc.document_type || 'grant_agreement',
          status: documentStatus,
          generated_at: doc.generated_at,
          document_content: doc.document_content || generateContractContent(employee, { grants: grant }),
          grant_data: grant
        };
      });

      setDocuments(transformedDocs);
    } catch (error) {
      console.error('Error loading documents:', error);
      // Create sample documents as fallback
      const employeeData = sessionStorage.getItem('employee');
      if (employeeData) {
        const employee = JSON.parse(employeeData);
        await createSampleDocuments(employee);
      }
    } finally {
      setLoading(false);
    }
  };

  const createSampleDocuments = async (employee: any) => {
    try {
      // Get grants to determine document status
      const { data: grantsData } = await supabase
        .from('grants')
        .select('id, status, employee_acceptance_at')
        .eq('employee_id', employee.id)
        .in('status', ['active', 'pending_signature']);

      const hasActiveGrant = grantsData?.some(grant => grant.status === 'active');
      const documentStatus = hasActiveGrant ? 'signed' : 'pending_signature';
      const activeGrant = grantsData?.find(grant => grant.status === 'active');

      // Create document with grant data for signature details
      const docWithGrantData = {
        id: 'sample-grant-1',
        status: documentStatus,
        grant_data: activeGrant
      };

      const sampleDocs = [
        {
          id: 'sample-grant-1',
          document_name: 'Employee Stock Grant Agreement',
          document_type: 'grant_agreement',
          status: documentStatus,
          generated_at: new Date().toISOString(),
          document_content: generateContractContent(employee, docWithGrantData)
        }
      ];
      setDocuments(sampleDocs);
    } catch (error) {
      console.error('Error creating sample documents:', error);
      // Fallback to pending_signature if we can't check grant status
      const docWithGrantData = {
        id: 'sample-grant-1',
        status: 'pending_signature',
        grant_data: null
      };

      const sampleDocs = [
        {
          id: 'sample-grant-1',
          document_name: 'Employee Stock Grant Agreement',
          document_type: 'grant_agreement',
          status: 'pending_signature',
          generated_at: new Date().toISOString(),
          document_content: generateContractContent(employee, docWithGrantData)
        }
      ];
      setDocuments(sampleDocs);
    }
  };

  const generateVestingScheduleTable = (employee: any, doc: any) => {
    const totalShares = 50000; // Default total shares
    const cliffPercentage = 25; // 25% cliff
    const cliffShares = Math.floor(totalShares * (cliffPercentage / 100));
    const remainingShares = totalShares - cliffShares;
    
    // Determine cliff period and vesting schedule
    const cliffPeriodMonths = 12; // Default 1 year cliff
    const totalVestingPeriodMonths = 48; // 4 years total
    const postCliffMonths = totalVestingPeriodMonths - cliffPeriodMonths;
    
    const grantDate = new Date();
    const cliffDate = new Date(grantDate.getTime() + cliffPeriodMonths * 30 * 24 * 60 * 60 * 1000);
    
    const formatDate = (date: Date) => {
      const day = String(date.getDate()).padStart(2, '0');
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const year = date.getFullYear();
      return `${day}/${month}/${year}`;
    };

    // Determine vesting frequency based on cliff period
    let vestingFrequency, periodLabel, vestingPeriods, sharesPerPeriod;
    
    if (cliffPeriodMonths >= 12) {
      // Annual vesting
      vestingFrequency = 12; // months between vesting
      periodLabel = "Year";
      vestingPeriods = Math.floor(postCliffMonths / 12);
      sharesPerPeriod = Math.floor(remainingShares / vestingPeriods);
    } else if (cliffPeriodMonths >= 6) {
      // Semi-annual vesting
      vestingFrequency = 6; // months between vesting
      periodLabel = "Half Year";
      vestingPeriods = Math.floor(postCliffMonths / 6);
      sharesPerPeriod = Math.floor(remainingShares / vestingPeriods);
    } else if (cliffPeriodMonths >= 3) {
      // Quarterly vesting
      vestingFrequency = 3; // months between vesting
      periodLabel = "Quarter";
      vestingPeriods = Math.floor(postCliffMonths / 3);
      sharesPerPeriod = Math.floor(remainingShares / vestingPeriods);
    } else {
      // Monthly vesting
      vestingFrequency = 1; // months between vesting
      periodLabel = "Month";
      vestingPeriods = postCliffMonths;
      sharesPerPeriod = Math.floor(remainingShares / vestingPeriods);
    }

    let table = `
┌─────────────────┬──────────────┬─────────────┬─────────────────┬─────────────────┐
│ Vesting Period  │ Vesting Date │ Percentage  │ Shares Vesting │ Cumulative %    │
├─────────────────┼──────────────┼─────────────┼─────────────────┼─────────────────┤
│ Cliff Period    │ ${formatDate(cliffDate).padEnd(12)} │ ${cliffPercentage.toFixed(2)}%      │ ${cliffShares.toLocaleString().padEnd(15)} │ ${cliffPercentage.toFixed(2)}%          │`;

    // Add vesting periods
    for (let period = 1; period <= vestingPeriods; period++) {
      const vestingDate = new Date(cliffDate.getTime() + period * vestingFrequency * 30 * 24 * 60 * 60 * 1000);
      const periodPercentage = (remainingShares / vestingPeriods / totalShares * 100);
      const cumulativePercentage = (cliffPercentage + (period * periodPercentage)).toFixed(2);
      const cumulativeShares = cliffShares + (period * sharesPerPeriod);
      
      table += `
│ ${periodLabel} ${period.toString().padStart(2)}          │ ${formatDate(vestingDate).padEnd(12)} │ ${periodPercentage.toFixed(2)}%      │ ${sharesPerPeriod.toLocaleString().padEnd(15)} │ ${cumulativePercentage}%          │`;
    }

    table += `
├─────────────────┼──────────────┼─────────────┼─────────────────┼─────────────────┤
│ TOTAL           │              │ 100.00%     │ ${totalShares.toLocaleString().padEnd(15)} │ 100.00%         │
└─────────────────┴──────────────┴─────────────┴─────────────────┴─────────────────┘

VESTING SCHEDULE NOTES:
• Cliff Period: ${cliffPercentage}% of shares vest after ${cliffPeriodMonths} months of continuous employment
• Post-Cliff Vesting: Remaining ${100 - cliffPercentage}% vests in ${vestingFrequency === 12 ? 'annual' : vestingFrequency === 6 ? 'semi-annual' : vestingFrequency === 3 ? 'quarterly' : 'monthly'} installments over ${postCliffMonths} months
• Vesting is subject to continued employment with the company
• Shares may be subject to additional restrictions as per company policy
• Tax implications may apply upon vesting - consult with tax advisor`;

    return table;
  };

  const generateContractContent = (employee: any, doc: any) => {
    // Get grant data to show actual signature details
    const getSignatureDetails = () => {
      // Try to get grant data from the document or employee context
      const grantData = doc.grant_data || {};
      const isSigned = doc.status === 'signed' || grantData.status === 'active';
      
      if (isSigned && grantData.employee_acceptance_at) {
        const acceptanceDate = new Date(grantData.employee_acceptance_at);
        const formatDate = (date: Date) => {
          const day = String(date.getDate()).padStart(2, '0');
          const month = String(date.getMonth() + 1).padStart(2, '0');
          const year = date.getFullYear();
          return `${day}/${month}/${year}`;
        };
        return {
          employeeSignature: `${employee.first_name_en} ${employee.last_name_en}`,
          employeeDate: formatDate(acceptanceDate),
          employeeTime: acceptanceDate.toLocaleTimeString(),
          isSigned: true
        };
      }
      
      return {
        employeeSignature: '_________________',
        employeeDate: '________',
        employeeTime: '',
        isSigned: false
      };
    };

    const signatureDetails = getSignatureDetails();
    const currentDate = new Date();
    
    // Helper function to format dates as dd/mm/yyyy
    const formatDate = (date: Date) => {
      const day = String(date.getDate()).padStart(2, '0');
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const year = date.getFullYear();
      return `${day}/${month}/${year}`;
    };
    
    return `
${'='.repeat(80)}
                    EMPLOYEE STOCK GRANT AGREEMENT
${'='.repeat(80)}

Grant Number: GR-${new Date().getFullYear()}${String(new Date().getMonth() + 1).padStart(2, '0')}${String(new Date().getDate()).padStart(2, '0')}-001
Document Generated: ${formatDate(currentDate)} at ${currentDate.toLocaleTimeString()}

${'='.repeat(80)}

Dear ${employee.first_name_en} ${employee.last_name_en},

We are pleased to inform you that you have been granted an equity award under our Employee Stock Grant Program. This letter serves as your official grant agreement and outlines the terms and conditions of your equity award.

GRANT DETAILS:
• Employee Name: ${employee.first_name_en} ${employee.last_name_en}
• Employee Email: ${employee.email}
• Total Shares Granted: 50,000 shares
• Grant Date: ${formatDate(new Date())}
• Vesting Schedule: 4 years with 1-year cliff
• Vesting Start Date: ${formatDate(new Date())}
• Vesting End Date: ${formatDate(new Date(Date.now() + 4 * 365 * 24 * 60 * 60 * 1000))}

VESTING SCHEDULE OVERVIEW:
• Cliff Period: 25% of shares vest after 1 year of continuous employment
• Post-Cliff Vesting: Remaining 75% vests in annual installments over 3 years
• Total Vesting Period: 4 years from grant date

DETAILED VESTING SCHEDULE:
${generateVestingScheduleTable(employee, doc)}

TERMS AND CONDITIONS:
1. Employment Requirement: Shares will only vest if you remain employed with the company
2. Equity Plan: These shares are subject to the terms of our equity incentive plan
3. Tax Implications: You may be subject to tax obligations upon vesting - please consult with a tax advisor
4. Transfer Restrictions: Shares may be subject to transfer restrictions as per company policy
5. Plan Amendments: The company reserves the right to amend the equity plan with proper notice

ACCEPTANCE AND SIGNATURE:
By signing below, you acknowledge that you have read, understood, and agree to the terms and conditions of this grant agreement.

Employee Signature: ${signatureDetails.employeeSignature}
Employee Date: ${signatureDetails.employeeDate}${signatureDetails.employeeTime ? ` at ${signatureDetails.employeeTime}` : ''}

Company Representative: _________________ Date: _________

${signatureDetails.isSigned ? `
${'='.repeat(80)}
                    SIGNATURE VERIFICATION
${'='.repeat(80)}
✓ This contract has been electronically signed by the employee
✓ Signature Date: ${signatureDetails.employeeDate} at ${signatureDetails.employeeTime}
✓ Employee: ${employee.first_name_en} ${employee.last_name_en} (${employee.email})
✓ Contract Status: EXECUTED
✓ This agreement is now legally binding and effective
` : `
${'='.repeat(80)}
                    PENDING SIGNATURE
${'='.repeat(80)}
This contract is awaiting your signature and acceptance.
Please review the terms carefully before signing.
`}

${'='.repeat(80)}
                    DOCUMENT METADATA
${'='.repeat(80)}
• Document ID: ${doc.id || 'N/A'}
• Generated: ${formatDate(currentDate)} at ${currentDate.toLocaleTimeString()}
• Status: ${doc.status || 'pending_signature'}
• Employee ID: ${employee.id || 'N/A'}

This agreement is subject to the terms and conditions of the company's equity incentive plan.
For questions regarding this grant, please contact the Human Resources department.

${'='.repeat(80)}
    `.trim();
  };

  const filteredDocuments = documents.filter(doc => {
    const matchesSearch = doc.document_name.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesFilter = filterType === 'all' || doc.document_type === filterType;
    return matchesSearch && matchesFilter;
  });

  const downloadDocument = (doc: Document) => {
    const watermarkedContent = `
=====================================================
CONFIDENTIAL DOCUMENT
Generated: ${formatDate(doc.generated_at)}
Document ID: ${doc.id}
Status: ${doc.status.toUpperCase()}
=====================================================

${doc.document_content}

=====================================================
This document is confidential and intended solely
for the use of the individual to whom it is addressed.
Any dissemination, distribution, or copying of this
document is strictly prohibited.

Document authenticity can be verified at:
https://example.com/verify/${doc.id}
=====================================================
    `;

    const blob = new Blob([watermarkedContent], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${doc.document_name.replace(/[^a-z0-9]/gi, '_')}.txt`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleAcceptDocument = async (doc: Document) => {
    if (!doc?.grant_data || accepting) return;

    try {
      setAccepting(true);

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        alert('You need to be signed in to accept a contract.');
        return;
      }

      // Mark document as signed
      const { error: docError } = await supabase
        .from('generated_documents')
        .update({
          status: 'signed'
        })
        .eq('id', doc.id);

      if (docError) throw docError;

      // Update grant record to active + record acceptance timestamp
      const { error: grantError } = await supabase
        .from('grants')
        .update({
          status: 'active',
          employee_acceptance_at: new Date().toISOString()
        })
        .eq('id', doc.grant_data.id);

      if (grantError) throw grantError;

      alert('Thank you! Your contract has been accepted.');
      setShowPreview(false);
      await loadDocuments();
    } catch (error) {
      console.error('Error accepting document:', error);
      alert('Failed to accept the contract. Please try again.');
    } finally {
      setAccepting(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'signed':
      case 'executed':
        return <CheckCircle className="w-5 h-5 text-green-600" />;
      case 'pending_signature':
        return <Clock className="w-5 h-5 text-yellow-600" />;
      default:
        return <AlertCircle className="w-5 h-5 text-gray-400" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'signed':
      case 'executed':
        return 'bg-green-100 text-green-800';
      case 'pending_signature':
        return 'bg-yellow-100 text-yellow-800';
      case 'draft':
        return 'bg-gray-100 text-gray-600';
      default:
        return 'bg-gray-100 text-gray-600';
    }
  };

  const documentTypes = ['all', 'grant_agreement', 'exercise_notice', 'amendment', 'termination'];

  return (
    <div className="bg-white rounded-xl border border-gray-200 shadow-sm">
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="text-xl font-bold text-gray-900">Document Center</h3>
            <p className="text-sm text-gray-600 mt-1">Access and download your equity documents</p>
          </div>
          <div className="flex items-center space-x-2">
            <span className="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-sm font-medium">
              {filteredDocuments.length} documents
            </span>
          </div>
        </div>

        <div className="flex items-center space-x-3">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search documents..."
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
          <div className="relative">
            <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
            <select
              value={filterType}
              onChange={(e) => setFilterType(e.target.value)}
              className="pl-10 pr-8 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
            >
              {documentTypes.map(type => (
                <option key={type} value={type}>
                  {type === 'all' ? 'All Types' : type.replace('_', ' ')}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      <div className="p-6">
        {loading ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
            <p className="text-gray-500 mt-4">Loading documents...</p>
          </div>
        ) : filteredDocuments.length === 0 ? (
          <div className="text-center py-12">
            <FileText className="w-16 h-16 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500 font-medium">No documents found</p>
            <p className="text-sm text-gray-400 mt-1">Try adjusting your search or filters</p>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredDocuments.map((doc) => (
              <div
                key={doc.id}
                className="border border-gray-200 rounded-lg p-4 hover:border-blue-300 hover:shadow-md transition"
              >
                <div className="flex items-start justify-between">
                  <div className="flex items-start space-x-3 flex-1">
                    <div className="mt-1">
                      {getStatusIcon(doc.status)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <h4 className="font-semibold text-gray-900 truncate">{doc.document_name}</h4>
                      <div className="flex items-center space-x-3 mt-1">
                        <span className="text-xs text-gray-500">
                          Generated: {formatDate(doc.generated_at)}
                        </span>
                        <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${getStatusColor(doc.status)}`}>
                          {doc.status.replace('_', ' ')}
                        </span>
                        <span className="text-xs text-gray-500 capitalize">
                          {doc.document_type.replace('_', ' ')}
                        </span>
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2 ml-4">
                    <button
                      onClick={() => {
                        setSelectedDoc(doc);
                        setShowPreview(true);
                      }}
                      className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition"
                      title="Preview"
                    >
                      <Eye className="w-5 h-5" />
                    </button>
                    {doc.status === 'pending_signature' && doc.grant_data && (
                      <button
                        onClick={() => handleAcceptDocument(doc)}
                        className="px-3 py-1 text-sm bg-green-600 text-white rounded-lg hover:bg-green-700 transition"
                        title="Accept Contract"
                      >
                        Accept
                      </button>
                    )}
                    <button
                      onClick={() => downloadDocument(doc)}
                      className="p-2 text-gray-600 hover:text-green-600 hover:bg-green-50 rounded-lg transition"
                      title="Download"
                    >
                      <Download className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="p-6 bg-gray-50 border-t border-gray-200 rounded-b-xl">
        <div className="flex items-start space-x-3">
          <AlertCircle className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" />
          <div className="text-sm text-gray-600">
            <p className="font-semibold text-gray-900 mb-1">About Watermarking</p>
            <p>
              All downloaded documents are automatically watermarked with your information
              and a unique document ID for security and authenticity verification.
            </p>
          </div>
        </div>
      </div>

      {showPreview && selectedDoc && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl max-w-4xl w-full max-h-[90vh] flex flex-col">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h2 className="text-xl font-semibold text-gray-900">{selectedDoc.document_name}</h2>
              <button
                onClick={() => setShowPreview(false)}
                className="text-gray-400 hover:text-gray-600 transition"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
            <div className="p-6 overflow-y-auto" style={{ maxHeight: 'calc(90vh - 140px)' }}>
              <div className="bg-gray-50 rounded-lg p-4 mb-4 border border-gray-200">
                <p className="text-xs text-gray-500 mb-2">Document Preview - Watermark will be added on download</p>
                <pre className="text-sm text-gray-700 whitespace-pre-wrap font-mono">
                  {selectedDoc.document_content}
                </pre>
              </div>
            </div>
            <div className="sticky bottom-0 bg-white border-t border-gray-200 px-6 py-4 flex flex-col md:flex-row md:items-center md:justify-between gap-3">
              <div className="flex items-center gap-3 text-sm">
                <button
                  onClick={() => {
                    downloadDocument(selectedDoc);
                  }}
                  className="inline-flex items-center gap-2 px-4 py-2 bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200 transition"
                >
                  <Download className="w-4 h-4" />
                  Download with Watermark
                </button>
                <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                  selectedDoc.status === 'pending_signature'
                    ? 'bg-yellow-100 text-yellow-800'
                    : selectedDoc.status === 'signed'
                      ? 'bg-green-100 text-green-800'
                      : 'bg-gray-100 text-gray-600'
                }`}>
                  {selectedDoc.status.replace('_', ' ').toUpperCase()}
                </span>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setShowPreview(false)}
                  className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
                >
                  Close
                </button>
                {selectedDoc.status === 'pending_signature' && (
                  <button
                    onClick={() => handleAcceptDocument(selectedDoc)}
                    className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition disabled:opacity-50"
                    disabled={accepting}
                  >
                    {accepting ? 'Accepting...' : 'Accept Contract'}
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
