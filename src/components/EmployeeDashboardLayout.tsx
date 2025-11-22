import { ReactNode, useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate, Link, useLocation } from 'react-router-dom';
import {
  Award,
  TrendingUp,
  Calculator,
  DollarSign,
  FileText,
  Bell,
  LogOut,
  Menu,
  X,
  ArrowRightLeft,
  Briefcase,
} from 'lucide-react';

interface EmployeeDashboardLayoutProps {
  children: ReactNode;
}

export default function EmployeeDashboardLayout({ children }: EmployeeDashboardLayoutProps) {
  const { user, signOut } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(true);

  const handleSignOut = async () => {
    await signOut();
    navigate('/employee/login');
  };

  const navigation = [
    { name: 'Dashboard', href: '/employee/dashboard', icon: TrendingUp },
    { name: 'Vesting Timeline', href: '/employee/vesting', icon: Award },
    { name: 'Portfolio', href: '/employee/portfolio', icon: Briefcase },
    { name: 'Performance', href: '/employee/performance', icon: TrendingUp },
    { name: 'Tax Calculator', href: '/employee/tax-calculator', icon: Calculator },
    { name: 'Zakat Calculator', href: '/employee/zakat-calculator', icon: DollarSign },
    { name: 'Documents', href: '/employee/documents', icon: FileText },
    { name: 'Notifications', href: '/employee/notifications', icon: Bell },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      <div className={`fixed inset-y-0 left-0 z-50 w-64 bg-white border-r border-gray-200 transform transition-transform duration-200 ease-in-out ${
        sidebarOpen ? 'translate-x-0' : '-translate-x-full'
      } lg:translate-x-0`}>
        <div className="flex flex-col h-full">
          <div className="flex items-center justify-between p-6 border-b border-gray-200">
            <div className="flex items-center space-x-3">
              <div className="bg-gradient-to-br from-blue-600 to-blue-700 p-2 rounded-lg">
                <Award className="w-6 h-6 text-white" />
              </div>
              <div>
                <h2 className="text-sm font-bold text-gray-900">LTIP-CONNECT</h2>
                <p className="text-xs text-gray-500">Employee Portal</p>
              </div>
            </div>
            <button
              onClick={() => setSidebarOpen(false)}
              className="lg:hidden text-gray-500 hover:text-gray-700"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <nav className="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
            {navigation.map((item) => {
              const isActive = location.pathname === item.href;
              return (
                <Link
                  key={item.name}
                  to={item.href}
                  className={`flex items-center space-x-3 px-4 py-3 rounded-lg transition ${
                    isActive
                      ? 'bg-blue-50 text-blue-600 font-medium'
                      : 'text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  <item.icon className={`w-5 h-5 ${isActive ? 'text-blue-600' : 'text-gray-400'}`} />
                  <span>{item.name}</span>
                </Link>
              );
            })}
          </nav>

          <div className="p-4 border-t border-gray-200">
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg mb-3">
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center">
                  <span className="text-white text-sm font-medium">
                    {user?.email?.charAt(0).toUpperCase()}
                  </span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-900 truncate">
                    {user?.email?.split('@')[0]}
                  </p>
                  <p className="text-xs text-gray-500 truncate">Employee</p>
                </div>
              </div>
            </div>
            <button
              onClick={handleSignOut}
              className="flex items-center justify-center space-x-2 w-full px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-50 rounded-lg transition"
            >
              <LogOut className="w-4 h-4" />
              <span>Sign Out</span>
            </button>
          </div>
        </div>
      </div>

      <div className="lg:pl-64">
        <div className="sticky top-0 z-40 flex h-16 shrink-0 items-center gap-x-4 border-b border-gray-200 bg-white px-4 shadow-sm sm:gap-x-6 sm:px-6 lg:px-8">
          <button
            type="button"
            className="-m-2.5 p-2.5 text-gray-700 lg:hidden"
            onClick={() => setSidebarOpen(true)}
          >
            <span className="sr-only">Open sidebar</span>
            <Menu className="h-6 w-6" />
          </button>

          <div className="flex flex-1 gap-x-4 self-stretch lg:gap-x-6 items-center justify-end">
            <div className="flex items-center gap-x-4 lg:gap-x-6">
              <Link
                to="/login"
                className="flex items-center space-x-2 px-4 py-2 bg-gray-100 text-gray-700 hover:bg-gray-200 rounded-lg transition"
                title="Switch to Admin Portal"
              >
                <ArrowRightLeft className="w-4 h-4" />
                <span className="text-sm font-medium hidden sm:inline">Admin View</span>
              </Link>
              <Link
                to="/employee/notifications"
                className="relative -m-2.5 p-2.5 text-gray-400 hover:text-gray-500"
              >
                <span className="sr-only">View notifications</span>
                <Bell className="h-6 w-6" />
                <span className="absolute top-1 right-1 block h-2 w-2 rounded-full bg-red-500 ring-2 ring-white" />
              </Link>
            </div>
          </div>
        </div>

        <main className="py-8">
          <div className="px-4 sm:px-6 lg:px-8">
            {children}
          </div>
        </main>
      </div>

      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-gray-900 bg-opacity-50 z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}
    </div>
  );
}
