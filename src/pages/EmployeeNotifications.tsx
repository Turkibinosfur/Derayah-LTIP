import NotificationPreferences from '../components/NotificationPreferences';

export default function EmployeeNotifications() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Notification Preferences</h1>
        <p className="text-gray-600 mt-1">Manage how you receive updates and alerts</p>
      </div>
      <NotificationPreferences />
    </div>
  );
}