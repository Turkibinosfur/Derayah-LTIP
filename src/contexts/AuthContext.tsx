import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';

interface UserRole {
  user_id: string;
  email: string;
  company_id: string | null;
  role: string;
  is_active: boolean;
  permissions: Record<string, boolean> | null;
  user_type: 'super_admin' | 'company_admin' | 'employee' | 'unknown';
}

interface OnboardingProgress {
  company_id: string;
  has_pool: boolean;
  has_vesting_schedule: boolean;
  has_plan: boolean;
  has_employee: boolean;
  has_grant: boolean;
  completed_at: string | null;
}

interface SignUpInput {
  email: string;
  password: string;
  companyNameEn: string;
  companyNameAr?: string;
  phone?: string;
}

interface AuthContextType {
  user: User | null;
  session: Session | null;
  userRole: UserRole | null;
  loading: boolean;
  activeCompanyId: string | null;
  activeCompanyName: string | null;
  setActiveCompany: (companyId: string | null, companyName?: string | null) => void;
  clearActiveCompany: () => void;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (input: SignUpInput) => Promise<void>;
  signOut: () => Promise<void>;
  isSuperAdmin: () => boolean;
  isCompanyAdmin: (companyId?: string) => boolean;
  isEmployee: () => boolean;
  hasPermission: (permissionKey: string) => boolean;
  getCurrentCompanyId: () => string | null;
  onboardingProgress: OnboardingProgress | null;
  refreshOnboardingProgress: () => Promise<void>;
  isOnboardingComplete: () => boolean;
  onboardingLoaded: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [userRole, setUserRole] = useState<UserRole | null>(null);
  const [loading, setLoading] = useState(true);
  const [onboardingProgress, setOnboardingProgress] = useState<OnboardingProgress | null>(null);
  const [onboardingLoaded, setOnboardingLoaded] = useState(false);
  const [activeCompany, setActiveCompanyState] = useState<{ id: string | null; name: string | null }>({
    id: null,
    name: null,
  });
  const SUPER_ADMIN_COMPANY_STORAGE_KEY = 'saas_active_company';

  const loadOnboardingProgress = async (companyId: string | null, suppressErrors = false) => {
    if (!companyId) {
      setOnboardingProgress(null);
      setOnboardingLoaded(true);
      return;
    }

    const { data, error } = await supabase
      .from('company_onboarding_progress')
      .select('*')
      .eq('company_id', companyId)
      .maybeSingle();

    if (error) {
      if (!suppressErrors && error.code !== 'PGRST116') {
        console.error('Error loading onboarding progress:', error);
      }
      setOnboardingProgress(null);
      setOnboardingLoaded(true);
      return;
    }

    setOnboardingProgress(data);
    setOnboardingLoaded(true);
  };

  const loadUserRole = async (userId: string) => {
    try {
      // Increased timeout to 10 seconds to handle slower queries
      const timeoutPromise = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Timeout')), 10000)
      );

      const rolePromise = (async () => {
        console.log('🔍 loadUserRole: Starting to fetch user role for userId:', userId);
        
        // FIRST: Check company_users for company admin roles
        // Company admins should be identified before checking super admin memberships
        // This ensures company admins are treated as company admins even if they're
        // accidentally in company_super_admin_memberships
        const { data: companyUserRows, error: companyUserError } = await supabase
          .from('company_users')
          .select('user_id, company_id, role, is_active, permissions, created_at')
          .eq('user_id', userId)
          .eq('is_active', true)
          .neq('role', 'super_admin')  // Exclude super_admin role (shouldn't be here anyway)
          .order('created_at', { ascending: false })
          .limit(1);

        if (companyUserError) {
          console.warn('❌ Error fetching company user:', companyUserError);
        } else {
          console.log('✅ Fetched company user data:', companyUserRows?.[0]);
        }

        const companyUserData = companyUserRows?.[0] ?? null;
        
        if (companyUserData) {
          // User is a company admin - return immediately
          const userRoleResult = {
            user_id: companyUserData.user_id,
            email: user?.email || '',
            company_id: companyUserData.company_id,
            role: companyUserData.role,
            is_active: companyUserData.is_active,
            permissions: (companyUserData.permissions as Record<string, boolean> | null) ?? null,
            user_type: 'company_admin' as const
          };
          
          console.log('✅ loadUserRole: Created userRole object (company admin):', {
            role: userRoleResult.role,
            user_type: userRoleResult.user_type,
            company_id: userRoleResult.company_id,
            fullObject: userRoleResult
          });
          
          return userRoleResult;
        }
        
        // SECOND: Check employees table
        const { data: employeeData, error: employeeError } = await supabase
          .from('employees')
          .select('id, company_id')
          .eq('user_id', userId)
          .maybeSingle();

        if (employeeError) {
          console.warn('Error fetching employee data:', employeeError);
        }
          
        if (employeeData) {
          return {
            user_id: userId,
            email: user?.email || '',
            company_id: employeeData.company_id,
            role: 'employee',
            is_active: true,
            permissions: null,
            user_type: 'employee' as const
          };
        }
        
        // THIRD: Only if not a company admin or employee, check for super admin
        // Super admins are not tied to specific companies
        const { data: superAdminMemberships, error: superAdminError } = await supabase
          .from('company_super_admin_memberships')
          .select('user_id')
          .eq('user_id', userId)
          .limit(1);

        if (superAdminError) {
          console.warn('❌ Error checking super admin membership:', superAdminError);
        }

        if (superAdminMemberships && superAdminMemberships.length > 0) {
          // User is a super admin - not tied to any specific company
          const userRoleResult = {
            user_id: userId,
            email: user?.email || '',
            company_id: null,  // Super admins don't have a default company
            role: 'super_admin',
            is_active: true,
            permissions: null,
            user_type: 'super_admin' as const
          };
          
          console.log('✅ loadUserRole: User is super admin:', userRoleResult);
          return userRoleResult;
        }
        
        return null;
      })();

      const role = (await Promise.race([rolePromise, timeoutPromise])) as UserRole | null;
      console.log('✅ loadUserRole: Final role result:', role);
      setUserRole(role);

      if (role?.company_id) {
        setActiveCompanyState({ id: role.company_id, name: null });
        setOnboardingLoaded(false);
        await loadOnboardingProgress(role.company_id, true);
      } else {
        setOnboardingProgress(null);
        setOnboardingLoaded(true);
      }
    } catch (error) {
      console.error('Error loading user role:', error);
      // On timeout, don't clear the user role - keep existing state
      // Only clear on actual errors (not timeouts)
      if (error instanceof Error && error.message === 'Timeout') {
        console.warn('User role loading timed out, keeping existing state');
        // Still mark onboarding as loaded to prevent infinite loading
        setOnboardingLoaded(true);
      } else {
        setUserRole(null);
        setOnboardingProgress(null);
        setOnboardingLoaded(true);
      }
    }
  };

  useEffect(() => {
    let mounted = true;
    
    const initializeAuth = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        
        if (!mounted) return;
        
        setSession(session);
        setUser(session?.user ?? null);
        if (!session?.user) {
          setOnboardingProgress(null);
          setOnboardingLoaded(true);
        }
        
        if (session?.user) {
          await loadUserRole(session.user.id);
        }
      } catch (error) {
        console.error('Error initializing auth:', error);
      } finally {
        if (mounted) {
          setLoading(false);
        }
      }
    };
    
    initializeAuth();

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (_event, session) => {
      if (!mounted) return;
      
      setSession(session);
      setUser(session?.user ?? null);
      
      if (session?.user) {
        await loadUserRole(session.user.id);
      } else {
        setUserRole(null);
        setOnboardingProgress(null);
        setOnboardingLoaded(true);
      }
      
      setLoading(false);
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw error;
  };

  const signUp = async (input: SignUpInput) => {
    const { email, password, companyNameEn, companyNameAr, phone } = input;

    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    });
    if (error) throw error;

    let signedUpUser = data.user;

    if (!signedUpUser) {
      const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (signInError) {
        throw new Error('Account created. Please verify your email before continuing.');
      }

      signedUpUser = signInData.user;
    }

    if (!signedUpUser) {
      throw new Error('Unable to initialize user after sign-up.');
    }

    const { error: onboardingError } = await supabase.rpc('onboard_self_service_company', {
      p_company_name_en: companyNameEn,
      p_company_name_ar: companyNameAr ?? null,
      p_phone: phone ?? null,
      p_user_id: signedUpUser.id,
    });

    if (onboardingError) {
      throw onboardingError;
    }

    await loadUserRole(signedUpUser.id);
  };

  const signOut = async () => {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
    setUserRole(null);
    setOnboardingProgress(null);
    setOnboardingLoaded(false);
    setActiveCompanyState({ id: null, name: null });
    if (typeof window !== 'undefined') {
      localStorage.removeItem(SUPER_ADMIN_COMPANY_STORAGE_KEY);
    }
  };

  const isSuperAdmin = () => {
    // Only return true if user_type is explicitly 'super_admin'
    // This prevents company admins from being treated as super admins
    return userRole?.user_type === 'super_admin';
  };

  const isCompanyAdmin = (companyId?: string) => {
    if (!userRole) return false;
    if (userRole.role === 'super_admin') {
      if (!activeCompany.id) return false;
      if (companyId) {
        return activeCompany.id === companyId;
      }
      return true;
    }
    if (userRole.user_type === 'company_admin') {
      if (companyId) {
        return userRole.company_id === companyId;
      }
      return true;
    }
    return false;
  };

  const isEmployee = () => {
    return userRole?.user_type === 'employee';
  };

  const hasPermission = (permissionKey: string) => {
    if (userRole?.user_type === 'super_admin') {
      return true;
    }
    return Boolean(userRole?.permissions && userRole.permissions[permissionKey]);
  };

  const getCurrentCompanyId = () => {
    if (userRole?.role === 'super_admin') {
      return activeCompany.id;
    }
    if (userRole?.company_id) {
      return userRole.company_id;
    }
    return null;
  };

  const setActiveCompany = (companyId: string | null, companyName?: string | null) => {
    setActiveCompanyState({ id: companyId, name: companyName ?? null });
    if (userRole?.role === 'super_admin' && typeof window !== 'undefined') {
      if (companyId) {
        localStorage.setItem(
          SUPER_ADMIN_COMPANY_STORAGE_KEY,
          JSON.stringify({ id: companyId, name: companyName ?? null })
        );
      } else {
        localStorage.removeItem(SUPER_ADMIN_COMPANY_STORAGE_KEY);
      }
    }
  };

  const clearActiveCompany = () => {
    setActiveCompany(null);
  };

  useEffect(() => {
    if (userRole?.role === 'super_admin') {
      if (typeof window !== 'undefined') {
        const stored = localStorage.getItem(SUPER_ADMIN_COMPANY_STORAGE_KEY);
        if (stored) {
          try {
            const parsed = JSON.parse(stored) as { id: string | null; name: string | null };
            setActiveCompanyState(parsed);
          } catch (error) {
            console.warn('Failed to parse stored super admin company selection', error);
            localStorage.removeItem(SUPER_ADMIN_COMPANY_STORAGE_KEY);
          }
        } else {
          setActiveCompanyState({ id: null, name: null });
        }
      }
    } else if (userRole?.user_type === 'company_admin') {
      setActiveCompanyState({ id: userRole.company_id, name: null });
    } else {
      setActiveCompanyState({ id: null, name: null });
    }
  }, [userRole?.role, userRole?.company_id]);

  const value = {
    user,
    session,
    userRole,
    loading,
    activeCompanyId: activeCompany.id,
    activeCompanyName: activeCompany.name,
    setActiveCompany,
    clearActiveCompany,
    signIn,
    signUp,
    signOut,
    isSuperAdmin,
    isCompanyAdmin,
    isEmployee,
    hasPermission,
    getCurrentCompanyId,
    onboardingProgress,
    refreshOnboardingProgress: async () => {
      await loadOnboardingProgress(userRole?.company_id ?? null);
    },
    isOnboardingComplete: () => {
    if (!onboardingProgress) {
      return true;
    }

    return (
      onboardingProgress.has_pool &&
      onboardingProgress.has_vesting_schedule &&
      onboardingProgress.has_plan &&
      onboardingProgress.has_employee &&
      onboardingProgress.has_grant
    );
  },
    onboardingLoaded,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}