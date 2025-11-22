import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Bell, Mail, Calendar, DollarSign, FileText, AlertCircle, Save, CheckCircle } from 'lucide-react';

interface NotificationPreferences {
  id?: string;
  employee_id: string;
  email_notifications: boolean;
  vesting_reminders: boolean;
  document_alerts: boolean;
  price_alerts: boolean;
  tax_reminders: boolean;
  price_alert_threshold: number;
  reminder_days_before: number;
}

export default function NotificationPreferences() {
  const [preferences, setPreferences] = useState<NotificationPreferences>({
    employee_id: '',
    email_notifications: true,
    vesting_reminders: true,
    document_alerts: true,
    price_alerts: false,
    tax_reminders: true,
    price_alert_threshold: 0,
    reminder_days_before: 7
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [employeeId, setEmployeeId] = useState<string | null>(null);

  useEffect(() => {
    loadPreferences();
  }, []);

  const loadPreferences = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: employee } = await supabase
        .from('employees')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

      if (employee) {
        setEmployeeId(employee.id);

        const { data, error } = await supabase
          .from('employee_notification_preferences')
          .select('*')
          .eq('employee_id', employee.id)
          .maybeSingle();

        if (data) {
          setPreferences(data);
        } else {
          setPreferences(prev => ({ ...prev, employee_id: employee.id }));
        }
      }
    } catch (error) {
      console.error('Error loading preferences:', error);
    } finally {
      setLoading(false);
    }
  };

  const savePreferences = async () => {
    if (!employeeId) return;

    setSaving(true);
    setSaved(false);

    try {
      const preferencesData = {
        employee_id: employeeId,
        email_notifications: preferences.email_notifications,
        vesting_reminders: preferences.vesting_reminders,
        document_alerts: preferences.document_alerts,
        price_alerts: preferences.price_alerts,
        tax_reminders: preferences.tax_reminders,
        price_alert_threshold: preferences.price_alert_threshold,
        reminder_days_before: preferences.reminder_days_before,
        updated_at: new Date().toISOString()
      };

      const { error } = await supabase
        .from('employee_notification_preferences')
        .upsert(preferencesData, {
          onConflict: 'employee_id'
        });

      if (error) throw error;

      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    } catch (error) {
      console.error('Error saving preferences:', error);
    } finally {
      setSaving(false);
    }
  };

  const togglePreference = (key: keyof NotificationPreferences) => {
    setPreferences(prev => ({
      ...prev,
      [key]: !prev[key]
    }));
  };

  const updateValue = (key: keyof NotificationPreferences, value: number) => {
    setPreferences(prev => ({
      ...prev,
      [key]: value
    }));
  };

  if (loading) {
    return (
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-12 text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
        <p className="text-gray-500 mt-4">Loading preferences...</p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl border border-gray-200 shadow-sm">
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <Bell className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <h3 className="text-xl font-bold text-gray-900">Notification Preferences</h3>
              <p className="text-sm text-gray-600">Manage how you receive updates and alerts</p>
            </div>
          </div>
          {saved && (
            <div className="flex items-center space-x-2 text-green-600">
              <CheckCircle className="w-5 h-5" />
              <span className="text-sm font-medium">Saved</span>
            </div>
          )}
        </div>
      </div>

      <div className="p-6 space-y-6">
        <div className="space-y-4">
          <div className="flex items-start justify-between p-4 bg-gray-50 rounded-lg border border-gray-200 hover:border-blue-300 transition">
            <div className="flex items-start space-x-3 flex-1">
              <Mail className="w-5 h-5 text-gray-600 mt-1" />
              <div className="flex-1">
                <h4 className="font-semibold text-gray-900">Email Notifications</h4>
                <p className="text-sm text-gray-600 mt-1">
                  Receive general email notifications about your account and grants
                </p>
              </div>
            </div>
            <button
              onClick={() => togglePreference('email_notifications')}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                preferences.email_notifications ? 'bg-blue-600' : 'bg-gray-300'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  preferences.email_notifications ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </div>

          <div className="flex items-start justify-between p-4 bg-gray-50 rounded-lg border border-gray-200 hover:border-blue-300 transition">
            <div className="flex items-start space-x-3 flex-1">
              <Calendar className="w-5 h-5 text-gray-600 mt-1" />
              <div className="flex-1">
                <h4 className="font-semibold text-gray-900">Vesting Reminders</h4>
                <p className="text-sm text-gray-600 mt-1">
                  Get reminders before your shares vest
                </p>
                {preferences.vesting_reminders && (
                  <div className="mt-3">
                    <label className="block text-xs font-medium text-gray-600 mb-1">
                      Remind me (days before)
                    </label>
                    <input
                      type="number"
                      value={preferences.reminder_days_before}
                      onChange={(e) => updateValue('reminder_days_before', Number(e.target.value))}
                      className="w-32 px-3 py-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                      min="1"
                      max="30"
                    />
                  </div>
                )}
              </div>
            </div>
            <button
              onClick={() => togglePreference('vesting_reminders')}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                preferences.vesting_reminders ? 'bg-blue-600' : 'bg-gray-300'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  preferences.vesting_reminders ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </div>

          <div className="flex items-start justify-between p-4 bg-gray-50 rounded-lg border border-gray-200 hover:border-blue-300 transition">
            <div className="flex items-start space-x-3 flex-1">
              <FileText className="w-5 h-5 text-gray-600 mt-1" />
              <div className="flex-1">
                <h4 className="font-semibold text-gray-900">Document Alerts</h4>
                <p className="text-sm text-gray-600 mt-1">
                  Notify me when new documents are available or require signatures
                </p>
              </div>
            </div>
            <button
              onClick={() => togglePreference('document_alerts')}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                preferences.document_alerts ? 'bg-blue-600' : 'bg-gray-300'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  preferences.document_alerts ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </div>

          <div className="flex items-start justify-between p-4 bg-gray-50 rounded-lg border border-gray-200 hover:border-blue-300 transition">
            <div className="flex items-start space-x-3 flex-1">
              <DollarSign className="w-5 h-5 text-gray-600 mt-1" />
              <div className="flex-1">
                <h4 className="font-semibold text-gray-900">Price Alerts</h4>
                <p className="text-sm text-gray-600 mt-1">
                  Get alerts when stock price reaches a threshold
                </p>
                {preferences.price_alerts && (
                  <div className="mt-3">
                    <label className="block text-xs font-medium text-gray-600 mb-1">
                      Alert threshold (SAR)
                    </label>
                    <input
                      type="number"
                      value={preferences.price_alert_threshold}
                      onChange={(e) => updateValue('price_alert_threshold', Number(e.target.value))}
                      className="w-32 px-3 py-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                      min="0"
                      step="0.01"
                    />
                  </div>
                )}
              </div>
            </div>
            <button
              onClick={() => togglePreference('price_alerts')}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                preferences.price_alerts ? 'bg-blue-600' : 'bg-gray-300'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  preferences.price_alerts ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </div>

          <div className="flex items-start justify-between p-4 bg-gray-50 rounded-lg border border-gray-200 hover:border-blue-300 transition">
            <div className="flex items-start space-x-3 flex-1">
              <AlertCircle className="w-5 h-5 text-gray-600 mt-1" />
              <div className="flex-1">
                <h4 className="font-semibold text-gray-900">Tax Reminders</h4>
                <p className="text-sm text-gray-600 mt-1">
                  Remind me about tax obligations and deadlines
                </p>
              </div>
            </div>
            <button
              onClick={() => togglePreference('tax_reminders')}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                preferences.tax_reminders ? 'bg-blue-600' : 'bg-gray-300'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                  preferences.tax_reminders ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </div>
        </div>

        <div className="pt-6 border-t border-gray-200">
          <button
            onClick={savePreferences}
            disabled={saving}
            className="w-full flex items-center justify-center space-x-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Save className="w-5 h-5" />
            <span>{saving ? 'Saving...' : 'Save Preferences'}</span>
          </button>
        </div>

        <div className="bg-blue-50 rounded-lg p-4 border border-blue-200">
          <div className="flex items-start space-x-3">
            <AlertCircle className="w-5 h-5 text-blue-600 mt-0.5 flex-shrink-0" />
            <div className="text-sm text-blue-800">
              <p className="font-semibold mb-1">About Notifications</p>
              <p>
                You can manage your notification preferences at any time. Critical security
                and legal notifications will still be sent regardless of your preferences.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
