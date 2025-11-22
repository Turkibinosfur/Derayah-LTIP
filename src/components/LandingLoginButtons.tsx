import { Link } from 'react-router-dom';
import { LogIn, Building2, Users, ShieldCheck } from 'lucide-react';

interface LandingLoginButtonsProps {
  variant?: 'light' | 'dark';
  align?: 'left' | 'center';
}

export default function LandingLoginButtons({ variant = 'light', align = 'left' }: LandingLoginButtonsProps) {
  const commonClasses =
    'px-4 py-2 rounded-lg text-sm font-semibold transition inline-flex items-center gap-2 focus:outline-none focus:ring-2 focus:ring-offset-2';

  const variantStyles =
    variant === 'dark'
      ? {
          primary: `${commonClasses} bg-white text-slate-900 hover:bg-slate-100 focus:ring-white focus:ring-offset-slate-900`,
          secondary: `${commonClasses} border border-white/40 text-white hover:border-white focus:ring-white focus:ring-offset-slate-900`
        }
      : {
          primary: `${commonClasses} bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 focus:ring-offset-white`,
          secondary: `${commonClasses} border border-slate-900/10 text-slate-900 hover:border-slate-900/40 focus:ring-blue-500 focus:ring-offset-white`
        };

  const alignment = align === 'center' ? 'justify-center' : 'justify-start';

  return (
    <div className={`flex flex-wrap ${alignment} gap-3`}>
      <Link to="/login" className={variantStyles.primary}>
        <ShieldCheck className="w-4 h-4" />
        SaaS Admin Login
      </Link>
      <Link to="/login" className={variantStyles.secondary}>
        <Building2 className="w-4 h-4" />
        Company Admin Login
      </Link>
      <Link to="/employee/login" className={variantStyles.secondary}>
        <Users className="w-4 h-4" />
        Employee Login
      </Link>
      <Link to="/login" className={`${variantStyles.secondary} bg-transparent`}>
        <LogIn className="w-4 h-4" />
        Partner Portal
      </Link>
    </div>
  );
}




