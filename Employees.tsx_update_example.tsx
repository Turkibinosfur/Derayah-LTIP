// Example update for Employees.tsx component
// This shows how to integrate automatic auth user creation

import { useState } from 'react';
import { supabase } from '../lib/supabase';

// Add this function to handle enabling portal access
const handleEnablePortalAccess = async (employeeId: string, portalUsername: string, portalPassword: string) => {
  try {
    setLoading(true);
    
    // Call the SQL function to enable portal access
    const { data, error } = await supabase.rpc('enable_employee_portal_access', {
      p_employee_id: employeeId,
      p_portal_username: portalUsername,
      p_portal_password: portalPassword
    });
    
    if (error) {
      console.error('Error enabling portal access:', error);
      setError('Failed to enable portal access');
      return;
    }
    
    if (data.success) {
      // Portal access enabled successfully
      setSuccess('Portal access enabled successfully');
      // Refresh the employees list
      await loadEmployees();
    } else {
      // Portal access enabled but auth user needs manual creation
      setError(`Portal access enabled but auth user needs manual creation. ${data.message}`);
      
      // Show instructions to the user
      if (data.instructions) {
        const instructions = data.instructions;
        const instructionText = `
Please create the auth user manually:
1. ${instructions.step1}
2. ${instructions.step2}
3. ${instructions.step3}
4. ${instructions.step4}
5. ${instructions.step5}
6. ${instructions.step6}
7. ${instructions.step7}
        `;
        
        // You could show this in a modal or alert
        alert(instructionText);
      }
    }
  } catch (error) {
    console.error('Error enabling portal access:', error);
    setError('Failed to enable portal access');
  } finally {
    setLoading(false);
  }
};

// Add this function to check portal status
const checkPortalStatus = async (employeeId: string) => {
  try {
    const { data, error } = await supabase.rpc('check_employee_portal_status', {
      p_employee_id: employeeId
    });
    
    if (error) {
      console.error('Error checking portal status:', error);
      return null;
    }
    
    return data;
  } catch (error) {
    console.error('Error checking portal status:', error);
    return null;
  }
};

// Add this function to disable portal access
const handleDisablePortalAccess = async (employeeId: string) => {
  try {
    setLoading(true);
    
    const { data, error } = await supabase.rpc('disable_employee_portal_access', {
      p_employee_id: employeeId
    });
    
    if (error) {
      console.error('Error disabling portal access:', error);
      setError('Failed to disable portal access');
      return;
    }
    
    if (data.success) {
      setSuccess('Portal access disabled successfully');
      await loadEmployees();
    } else {
      setError(`Failed to disable portal access: ${data.message}`);
    }
  } catch (error) {
    console.error('Error disabling portal access:', error);
    setError('Failed to disable portal access');
  } finally {
    setLoading(false);
  }
};

// Update the employee table to show portal status
const EmployeeTable = ({ employees, onEdit, onDelete, onEnablePortal, onDisablePortal }) => {
  return (
    <div className="bg-white shadow rounded-lg overflow-hidden">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Name
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Email
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Portal Access
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Auth Status
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {employees.map((employee) => (
            <tr key={employee.id}>
              <td className="px-6 py-4 whitespace-nowrap">
                <div className="text-sm font-medium text-gray-900">
                  {employee.first_name_en} {employee.last_name_en}
                </div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <div className="text-sm text-gray-900">{employee.email}</div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                  employee.portal_access_enabled 
                    ? 'bg-green-100 text-green-800' 
                    : 'bg-gray-100 text-gray-800'
                }`}>
                  {employee.portal_access_enabled ? 'Enabled' : 'Disabled'}
                </span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                  employee.user_id 
                    ? 'bg-green-100 text-green-800' 
                    : 'bg-red-100 text-red-800'
                }`}>
                  {employee.user_id ? 'Linked' : 'Not Linked'}
                </span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                <div className="flex space-x-2">
                  {employee.portal_access_enabled ? (
                    <button
                      onClick={() => onDisablePortal(employee.id)}
                      className="text-red-600 hover:text-red-900"
                    >
                      Disable Portal
                    </button>
                  ) : (
                    <button
                      onClick={() => onEnablePortal(employee.id)}
                      className="text-green-600 hover:text-green-900"
                    >
                      Enable Portal
                    </button>
                  )}
                  <button
                    onClick={() => onEdit(employee)}
                    className="text-blue-600 hover:text-blue-900"
                  >
                    Edit
                  </button>
                  <button
                    onClick={() => onDelete(employee.id)}
                    className="text-red-600 hover:text-red-900"
                  >
                    Delete
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

// Example usage in the main component
const Employees = () => {
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // ... existing code ...

  return (
    <div className="space-y-6">
      {/* Success/Error messages */}
      {success && (
        <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded">
          {success}
        </div>
      )}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* Employee table */}
      <EmployeeTable
        employees={employees}
        onEdit={handleEdit}
        onDelete={handleDelete}
        onEnablePortal={handleEnablePortalAccess}
        onDisablePortal={handleDisablePortalAccess}
      />
    </div>
  );
};

export default Employees;
