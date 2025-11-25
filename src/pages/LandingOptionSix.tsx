import { Link } from 'react-router-dom';
import {
  ArrowRight,
  Building2,
  TrendingUp,
  Users,
  FileText,
  BarChart3,
  CheckCircle2,
  Sparkles,
  Shield,
  Calendar,
  DollarSign,
  PieChart,
  Target,
  Zap,
  Globe2,
  Award,
  RefreshCw
} from 'lucide-react';
import LandingLoginButtons from '../components/LandingLoginButtons';

const mainFeatures = [
  {
    icon: BarChart3,
    title: 'Empower Your Equity Management and Cap Table',
    description:
      'Leverage cutting-edge technology for a simplified governance process. Gain a bird\'s eye view of your ownership structure and streamline equity transactions. Simulate scenarios for informed decision-making in fundraising and equity financing rounds.',
    features: [
      'Cap Table and shareholder registry management',
      'Proof of shareholder ownership',
      'Organizing Exits and Stock Transfers',
      'User Identity Verification',
      'Data Room'
    ]
  },
  {
    icon: FileText,
    title: 'Transform Corporate Governance',
    description:
      'Revolutionize assemblies and resolutions with our fully digital solution. Streamline complex procedures, establish associations, collect signatures, and enhance transparency at an unparalleled pace.',
    features: [
      'Conducting Assemblies and Resolutions',
      'Meeting Invitation',
      'Online voting',
      'View documents',
      'Meeting Management',
      'Post-Meeting Report'
    ]
  },
  {
    icon: Users,
    title: 'Ignite Employee Engagement',
    description:
      'Weave flexible digital employee share programs into your company\'s fabric with our technology solutions. Catalyze a workspace where innovation thrives and simplicity is the standard.',
    features: [
      'Multiple program options',
      'Create contracts',
      'Legal support',
      'Performance-Based Vesting Schedules',
      'Transaction History'
    ]
  },
  {
    icon: Globe2,
    title: 'Elevate Investor Relations',
    description:
      'Experience the future of investor relations. Engage with a dedicated Investor Relations Officer and share sensitive documents via a secure portal.',
    features: [
      'Designate a Relationship Officer',
      'Communication portal',
      'News editing'
    ]
  },
  {
    icon: TrendingUp,
    title: 'Boost Investment Operations',
    description:
      'Maximize growth and financing opportunities with our efficient Investment Operations Support service. Connect with a vast network of qualified investors and ensure seamless transactions with legal support.',
    features: [
      'Investor network access',
      'Transaction support',
      'Legal documentation',
      'Due diligence facilitation'
    ]
  },
  {
    icon: RefreshCw,
    title: 'Simplify Share Buybacks',
    description:
      'Automate the process of buying back your company\'s shares with our legally-supported service. Allocate treasury shares effortlessly and enjoy a smoother experience with our legal partners\' support.',
    features: [
      'Automated buyback workflows',
      'Treasury share allocation',
      'Legal compliance support',
      'Transaction processing'
    ]
  }
];

const testimonials = [
  {
    quote: 'إبانه هي بيت المستثمرين لكل شركة، تدير العلاقات معهم بطريقة احترافية وتعاملهم بلغة الصديق',
    author: 'حمود الغصن',
    role: 'مؤسس تطبيق مستر مندوب'
  },
  {
    quote: 'سعداء بشراكتنا مع شركة إبانة وعلى الخدمات التي يقدمونها وفريق العمل الإحترافي، الأمر الذي جعل عملية التواصل مع المساهمين والإهتمام باستفساراتهم عمل متقن ويدار بكل مهنية واحترافية عالية',
    author: 'د.عبدالرحمن الشيخي',
    role: 'مؤسس تطبيق رحلة'
  }
];

export default function LandingOptionSix() {
  return (
    <div className="bg-white min-h-screen text-slate-900">
      <header className="bg-white border-b border-slate-200 sticky top-0 z-30">
        <div className="max-w-7xl mx-auto px-6 py-5 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-6">
          <Link to="/concept6" className="inline-flex items-center gap-2 text-slate-900 hover:text-blue-600 transition">
            <Sparkles className="w-5 h-5 text-blue-600" />
            <span className="text-lg font-semibold tracking-tight">Derayah Equity Studio</span>
          </Link>
          <nav className="flex flex-wrap items-center gap-8 text-sm font-medium text-slate-600">
            <a href="#features" className="hover:text-blue-600 transition">Features</a>
            <a href="#equity" className="hover:text-blue-600 transition">Equity Management</a>
            <a href="#esop" className="hover:text-blue-600 transition">ESOP</a>
            <a href="#testimonials" className="hover:text-blue-600 transition">Testimonials</a>
          </nav>
          <div className="flex items-center gap-4">
            <button className="text-sm text-slate-600 hover:text-blue-600">العربية</button>
            <LandingLoginButtons variant="light" />
          </div>
        </div>
      </header>

      <main>
        {/* Hero Section */}
        <section className="py-20 md:py-28 bg-gradient-to-b from-slate-50 to-white">
          <div className="max-w-7xl mx-auto px-6">
            <div className="grid lg:grid-cols-2 gap-16 items-center">
              <div className="space-y-6">
                <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold tracking-tight leading-tight">
                  Boosting private companies and investors with{' '}
                  <span className="text-blue-600">digital tools</span>
                </h1>
                <p className="text-xl text-slate-600 leading-relaxed">
                  Reshaping investments, governance, and equity management from inception to a thriving IPO
                </p>
                <div className="flex flex-col sm:flex-row gap-4 pt-4">
                  <Link
                    to="/login"
                    className="inline-flex items-center justify-center gap-3 px-8 py-4 rounded-xl bg-blue-600 text-white font-semibold shadow-sm hover:bg-blue-500 transition text-lg"
                  >
                    Create Account
                    <ArrowRight className="w-5 h-5" />
                  </Link>
                  <Link
                    to="/employee/login"
                    className="inline-flex items-center justify-center gap-3 px-8 py-4 rounded-xl border-2 border-slate-200 text-slate-700 hover:border-blue-200 hover:text-blue-600 transition text-lg"
                  >
                    Learn More
                  </Link>
                </div>
              </div>
              {/* Equity Management Dashboard Screenshot */}
              <div className="relative">
                <div className="absolute -inset-1 bg-gradient-to-r from-blue-500/20 to-purple-500/20 rounded-3xl blur-xl" />
                <div className="relative bg-white border border-slate-200 rounded-3xl overflow-hidden shadow-2xl">
                  {/* Browser Chrome */}
                  <div className="bg-slate-50 border-b border-slate-200 px-4 py-3 flex items-center gap-2">
                    <div className="flex gap-2">
                      <div className="w-3 h-3 rounded-full bg-red-500/50" />
                      <div className="w-3 h-3 rounded-full bg-yellow-500/50" />
                      <div className="w-3 h-3 rounded-full bg-green-500/50" />
                    </div>
                    <div className="flex-1 mx-4 bg-white rounded-lg px-4 py-1.5 text-xs text-slate-600 border border-slate-200">
                    </div>
                    <span className="text-xs text-blue-600 font-medium">Live</span>
                  </div>
                  
                  {/* Dashboard Content */}
                  <div className="p-6 space-y-6 bg-white">
                    <div className="text-center pb-4 border-b border-slate-200">
                      <p className="text-sm font-semibold text-slate-500 uppercase tracking-wide mb-2">Orchestrating Equity Prosperity</p>
                      <p className="text-4xl font-bold text-slate-900">3.1B+ SR</p>
                      <p className="text-sm text-slate-600 mt-2">Handled assets through the platform</p>
                    </div>

                    {/* Key Metrics */}
                    <div className="grid grid-cols-2 gap-4">
                      <div className="bg-blue-50 rounded-xl p-4 border border-blue-100">
                        <p className="text-xs text-blue-600 uppercase tracking-wide mb-1">Total Equity</p>
                        <p className="text-2xl font-bold text-blue-900">SAR 2.8B</p>
                        <p className="text-xs text-blue-600 mt-1">Under management</p>
                      </div>
                      <div className="bg-green-50 rounded-xl p-4 border border-green-100">
                        <p className="text-xs text-green-600 uppercase tracking-wide mb-1">Companies</p>
                        <p className="text-2xl font-bold text-green-900">200+</p>
                        <p className="text-xs text-green-600 mt-1">Active clients</p>
                      </div>
                    </div>

                    {/* Recent Transactions */}
                    <div className="bg-slate-50 rounded-xl p-4 border border-slate-100">
                      <p className="text-sm font-semibold text-slate-900 mb-3">Recent Activity</p>
                      <div className="space-y-2">
                        {[
                          { action: 'Equity transfer processed', amount: 'SAR 45M', time: '2h ago' },
                          { action: 'Cap table updated', amount: 'Company XYZ', time: '5h ago' },
                          { action: 'ESOP grant issued', amount: '1,200 shares', time: '1d ago' }
                        ].map((item, idx) => (
                          <div key={idx} className="flex items-center justify-between text-xs">
                            <div className="flex items-center gap-2">
                              <div className="w-2 h-2 rounded-full bg-blue-500" />
                              <span className="text-slate-700">{item.action}</span>
                            </div>
                            <div className="text-right">
                              <p className="text-slate-900 font-medium">{item.amount}</p>
                              <p className="text-slate-500">{item.time}</p>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Employee Portal Section - First */}
        <section className="py-20 md:py-28 bg-slate-50">
          <div className="max-w-7xl mx-auto px-6">
            <div className="text-center max-w-3xl mx-auto space-y-4 mb-16">
              <h2 className="text-4xl md:text-5xl font-bold">Employee Portal Experience</h2>
              <p className="text-lg text-slate-600">
                Empower employees with transparent access to their equity portfolio, vesting timeline, and real-time value tracking.
              </p>
            </div>
            
            <div className="grid lg:grid-cols-2 gap-12 items-center">
              {/* Employee Portfolio Screenshot */}
              <div className="relative">
                <div className="absolute -inset-1 bg-gradient-to-r from-blue-500/20 to-purple-500/20 rounded-3xl blur-xl" />
                <div className="relative bg-white border border-slate-200 rounded-3xl overflow-hidden shadow-2xl">
                  {/* Browser Chrome */}
                  <div className="bg-slate-50 border-b border-slate-200 px-4 py-3 flex items-center gap-2">
                    <div className="flex gap-2">
                      <div className="w-3 h-3 rounded-full bg-red-500/50" />
                      <div className="w-3 h-3 rounded-full bg-yellow-500/50" />
                      <div className="w-3 h-3 rounded-full bg-green-500/50" />
                    </div>
                    <div className="flex-1 mx-4 bg-white rounded-lg px-4 py-1.5 text-xs text-slate-600 border border-slate-200">
                    </div>
                    <span className="text-xs text-blue-600 font-medium">My Portfolio</span>
                  </div>
                  
                  {/* Employee Dashboard */}
                  <div className="p-6 space-y-6 bg-white">
                    <div className="flex items-center justify-between">
                      <div>
                        <h3 className="text-lg font-semibold text-slate-900">My Equity Portfolio</h3>
                        <p className="text-xs text-slate-500 mt-1">Personal equity overview</p>
                      </div>
                      <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center">
                        <Users className="w-5 h-5 text-blue-600" />
                      </div>
                    </div>

                    {/* Portfolio Value */}
                    <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-xl p-5 border border-blue-100">
                      <p className="text-xs text-slate-500 uppercase tracking-wide mb-2">Total Portfolio Value</p>
                      <p className="text-3xl font-bold text-slate-900">SAR 245,680</p>
                      <p className="text-xs text-green-600 mt-1">+18.2% from last quarter</p>
                    </div>

                    {/* Equity Breakdown Pie Chart */}
                    <div className="bg-slate-50 rounded-xl p-4 border border-slate-100">
                      <p className="text-sm font-semibold text-slate-900 mb-3">Equity Breakdown</p>
                      <div className="flex items-center gap-4">
                        <div className="relative w-32 h-32">
                          <svg viewBox="0 0 100 100" className="transform -rotate-90">
                            <circle cx="50" cy="50" r="40" fill="none" stroke="#e2e8f0" strokeWidth="16" />
                            <circle cx="50" cy="50" r="40" fill="none" stroke="#3b82f6" strokeWidth="16" strokeDasharray={`${2 * Math.PI * 40 * 0.50} ${2 * Math.PI * 40}`} />
                            <circle cx="50" cy="50" r="40" fill="none" stroke="#8b5cf6" strokeWidth="16" strokeDasharray={`${2 * Math.PI * 40 * 0.30} ${2 * Math.PI * 40}`} strokeDashoffset={`-${2 * Math.PI * 40 * 0.50}`} />
                            <circle cx="50" cy="50" r="40" fill="none" stroke="#10b981" strokeWidth="16" strokeDasharray={`${2 * Math.PI * 40 * 0.20} ${2 * Math.PI * 40}`} strokeDashoffset={`-${2 * Math.PI * 40 * 0.80}`} />
                          </svg>
                        </div>
                        <div className="flex-1 space-y-2">
                          {[
                            { label: 'ESOP 2025', value: '50%', shares: '2,100', color: 'bg-blue-500' },
                            { label: 'RSU Grant', value: '30%', shares: '1,260', color: 'bg-purple-500' },
                            { label: 'SAR Plan', value: '20%', shares: '840', color: 'bg-green-500' }
                          ].map((item, idx) => (
                            <div key={idx} className="flex items-center justify-between text-xs">
                              <div className="flex items-center gap-2">
                                <div className={`w-3 h-3 rounded-full ${item.color}`} />
                                <span className="text-slate-700 font-medium">{item.label}</span>
                              </div>
                              <div className="text-right">
                                <span className="text-slate-900 font-semibold">{item.shares}</span>
                                <span className="text-slate-500 ml-1">({item.value})</span>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>

                    {/* Quick Stats */}
                    <div className="grid grid-cols-3 gap-3">
                      <div className="bg-slate-50 rounded-lg p-3 border border-slate-100">
                        <p className="text-[10px] text-slate-500 mb-1">Total Shares</p>
                        <p className="text-lg font-bold text-slate-900">4,200</p>
                      </div>
                      <div className="bg-slate-50 rounded-lg p-3 border border-slate-100">
                        <p className="text-[10px] text-slate-500 mb-1">Vested</p>
                        <p className="text-lg font-bold text-green-600">72%</p>
                      </div>
                      <div className="bg-slate-50 rounded-lg p-3 border border-slate-100">
                        <p className="text-[10px] text-slate-500 mb-1">Pending</p>
                        <p className="text-lg font-bold text-orange-600">28%</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Vesting Timeline Screenshot */}
              <div className="relative">
                <div className="absolute -inset-1 bg-gradient-to-r from-purple-500/20 to-pink-500/20 rounded-3xl blur-xl" />
                <div className="relative bg-white border border-slate-200 rounded-3xl overflow-hidden shadow-2xl">
                  {/* Browser Chrome */}
                  <div className="bg-slate-50 border-b border-slate-200 px-4 py-3 flex items-center gap-2">
                    <div className="flex gap-2">
                      <div className="w-3 h-3 rounded-full bg-red-500/50" />
                      <div className="w-3 h-3 rounded-full bg-yellow-500/50" />
                      <div className="w-3 h-3 rounded-full bg-green-500/50" />
                    </div>
                    <div className="flex-1 mx-4 bg-white rounded-lg px-4 py-1.5 text-xs text-slate-600 border border-slate-200">
                    </div>
                    <span className="text-xs text-purple-600 font-medium">Vesting Timeline</span>
                  </div>
                  
                  {/* Vesting Timeline Content */}
                  <div className="p-6 space-y-6 bg-white">
                    <div className="flex items-center justify-between">
                      <div>
                        <h3 className="text-lg font-semibold text-slate-900">Vesting Schedule</h3>
                        <p className="text-xs text-slate-500 mt-1">Track your equity milestones</p>
                      </div>
                      <Calendar className="w-5 h-5 text-purple-600" />
                    </div>

                    {/* Vesting Timeline Chart */}
                    <div className="bg-slate-50 rounded-xl p-4 border border-slate-100">
                      <p className="text-sm font-semibold text-slate-900 mb-4">Vesting Progress</p>
                      <div className="space-y-4">
                        {[
                          { plan: 'ESOP 2025', vested: 72, total: 100, nextDate: 'Feb 15, 2026', shares: '2,100' },
                          { plan: 'RSU Grant', vested: 55, total: 100, nextDate: 'Mar 1, 2026', shares: '1,260' },
                          { plan: 'SAR Plan', vested: 35, total: 100, nextDate: 'Apr 10, 2026', shares: '840' }
                        ].map((item, idx) => (
                          <div key={idx} className="space-y-2">
                            <div className="flex items-center justify-between text-xs">
                              <span className="text-slate-700 font-medium">{item.plan}</span>
                              <span className="text-slate-500">{item.shares} shares</span>
                            </div>
                            <div className="h-3 bg-slate-200 rounded-full overflow-hidden">
                              <div 
                                className="h-full bg-gradient-to-r from-purple-500 to-pink-500"
                                style={{ width: `${item.vested}%` }}
                              />
                            </div>
                            <div className="flex items-center justify-between text-[10px]">
                              <span className="text-slate-500">{item.vested}% vested</span>
                              <span className="text-purple-600 font-medium">Next: {item.nextDate}</span>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Timeline Visualization */}
                    <div className="bg-slate-50 rounded-xl p-4 border border-slate-100">
                      <p className="text-sm font-semibold text-slate-900 mb-3">Vesting Timeline</p>
                      <div className="h-24 flex items-end gap-2">
                        {[
                          { month: 'Jan', height: 30, vested: true },
                          { month: 'Feb', height: 50, vested: true },
                          { month: 'Mar', height: 65, vested: true },
                          { month: 'Apr', height: 72, vested: true },
                          { month: 'May', height: 80, vested: false },
                          { month: 'Jun', height: 88, vested: false },
                          { month: 'Jul', height: 95, vested: false },
                          { month: 'Aug', height: 100, vested: false }
                        ].map((item, idx) => (
                          <div key={idx} className="flex-1 flex flex-col items-center">
                            <div
                              className={`w-full rounded-t ${
                                item.vested ? 'bg-gradient-to-t from-green-500 to-green-400' : 'bg-gradient-to-t from-slate-300 to-slate-200'
                              }`}
                              style={{ height: `${item.height}%` }}
                            />
                            <span className="text-[10px] text-slate-500 mt-1">{item.month}</span>
                          </div>
                        ))}
                      </div>
                      <div className="flex items-center gap-4 mt-3 text-xs">
                        <div className="flex items-center gap-2">
                          <div className="w-3 h-3 rounded-full bg-green-500" />
                          <span className="text-slate-600">Vested</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <div className="w-3 h-3 rounded-full bg-slate-300" />
                          <span className="text-slate-600">Pending</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Features Overview */}
        <section className="py-16 bg-white">
          <div className="max-w-7xl mx-auto px-6">
            <div className="text-center max-w-3xl mx-auto space-y-4 mb-12">
              <h2 className="text-4xl md:text-5xl font-bold">Derayah offers a range of features</h2>
              <p className="text-lg text-slate-600">
                Designed to save you hours of work in the long run
              </p>
            </div>
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
              {mainFeatures.map((feature, idx) => (
                <div key={feature.title} className="rounded-3xl border border-slate-200 bg-white p-8 space-y-6 hover:shadow-xl transition">
                  <div className="w-16 h-16 rounded-2xl bg-blue-100 flex items-center justify-center">
                    <feature.icon className="w-8 h-8 text-blue-600" />
                  </div>
                  <h3 className="text-xl font-semibold">{feature.title}</h3>
                  <p className="text-slate-600 leading-relaxed text-sm">{feature.description}</p>
                  <ul className="space-y-2 pt-2">
                    {feature.features.map((item, itemIdx) => (
                      <li key={itemIdx} className="flex items-start gap-2 text-sm text-slate-700">
                        <CheckCircle2 className="w-4 h-4 text-blue-600 shrink-0 mt-0.5" />
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Detailed Feature Sections */}
        <section id="equity" className="py-20 md:py-28">
          <div className="max-w-7xl mx-auto px-6">
            <div className="grid lg:grid-cols-2 gap-16 items-center">
              <div className="space-y-6">
                <h2 className="text-4xl md:text-5xl font-bold">Equity Management and Cap Table</h2>
                <p className="text-lg text-slate-600 leading-relaxed">
                  Our Equity Management and Cap Table services utilize innovative digital technologies to streamline your company's governance processes, 
                  providing a comprehensive view of your company's ownership structure and managing equity-related transactions. 
                  Discover how our Equity Management service can transform your company.
                </p>
                <ul className="space-y-3">
                  {mainFeatures[0].features.map((item, idx) => (
                    <li key={idx} className="flex items-start gap-3">
                      <CheckCircle2 className="w-5 h-5 text-blue-600 shrink-0 mt-0.5" />
                      <span className="text-slate-700">{item}</span>
                    </li>
                  ))}
                </ul>
              </div>
              {/* Cap Table Screenshot */}
              <div className="relative">
                <div className="absolute -inset-1 bg-gradient-to-r from-blue-500/20 to-cyan-500/20 rounded-3xl blur-xl" />
                <div className="relative bg-white border border-slate-200 rounded-3xl overflow-hidden shadow-2xl">
                  {/* Browser Chrome */}
                  <div className="bg-slate-50 border-b border-slate-200 px-4 py-2.5 flex items-center gap-2">
                    <div className="flex gap-2">
                      <div className="w-2.5 h-2.5 rounded-full bg-red-500/50" />
                      <div className="w-2.5 h-2.5 rounded-full bg-yellow-500/50" />
                      <div className="w-2.5 h-2.5 rounded-full bg-green-500/50" />
                    </div>
                    <div className="flex-1 mx-3 bg-white rounded-lg px-3 py-1 text-xs text-slate-600 border border-slate-200">
                    </div>
                  </div>
                  
                  {/* Cap Table Content */}
                  <div className="p-6 space-y-6 bg-white">
                    <div className="flex items-center gap-4">
                      <div className="w-16 h-16 rounded-2xl bg-blue-100 flex items-center justify-center">
                        <BarChart3 className="w-8 h-8 text-blue-600" />
                      </div>
                      <div>
                        <h3 className="text-xl font-semibold text-slate-900">Cap Table Overview</h3>
                        <p className="text-sm text-slate-600">Real-time ownership tracking</p>
                      </div>
                    </div>
                    
                    <div className="grid grid-cols-2 gap-4">
                      <div className="rounded-xl bg-slate-50 p-4 border border-slate-100">
                        <p className="text-xs text-slate-500 uppercase tracking-wide mb-2">Total Shares</p>
                        <p className="text-2xl font-bold text-slate-900">10.5M</p>
                        <p className="text-xs text-slate-500 mt-1">Fully diluted</p>
                      </div>
                      <div className="rounded-xl bg-slate-50 p-4 border border-slate-100">
                        <p className="text-xs text-slate-500 uppercase tracking-wide mb-2">Shareholders</p>
                        <p className="text-2xl font-bold text-slate-900">248</p>
                        <p className="text-xs text-slate-500 mt-1">Active holders</p>
                      </div>
                    </div>

                    {/* Ownership Breakdown with Pie Chart */}
                    <div className="bg-slate-50 rounded-xl p-4 border border-slate-100">
                      <p className="text-sm font-semibold text-slate-900 mb-3">Ownership Breakdown</p>
                      <div className="flex items-center gap-4 mb-4">
                        <div className="relative w-28 h-28">
                          <svg viewBox="0 0 100 100" className="transform -rotate-90">
                            <circle cx="50" cy="50" r="40" fill="none" stroke="#e2e8f0" strokeWidth="16" />
                            <circle cx="50" cy="50" r="40" fill="none" stroke="#3b82f6" strokeWidth="16" strokeDasharray={`${2 * Math.PI * 40 * 0.45} ${2 * Math.PI * 40}`} />
                            <circle cx="50" cy="50" r="40" fill="none" stroke="#8b5cf6" strokeWidth="16" strokeDasharray={`${2 * Math.PI * 40 * 0.30} ${2 * Math.PI * 40}`} strokeDashoffset={`-${2 * Math.PI * 40 * 0.45}`} />
                            <circle cx="50" cy="50" r="40" fill="none" stroke="#10b981" strokeWidth="16" strokeDasharray={`${2 * Math.PI * 40 * 0.18} ${2 * Math.PI * 40}`} strokeDashoffset={`-${2 * Math.PI * 40 * 0.75}`} />
                            <circle cx="50" cy="50" r="40" fill="none" stroke="#64748b" strokeWidth="16" strokeDasharray={`${2 * Math.PI * 40 * 0.07} ${2 * Math.PI * 40}`} strokeDashoffset={`-${2 * Math.PI * 40 * 0.93}`} />
                          </svg>
                        </div>
                        <div className="flex-1 space-y-2">
                          {[
                            { name: 'Founders', percentage: '45%', shares: '4.7M', color: 'bg-blue-500' },
                            { name: 'Investors', percentage: '30%', shares: '3.2M', color: 'bg-purple-500' },
                            { name: 'ESOP Pool', percentage: '18%', shares: '1.9M', color: 'bg-green-500' },
                            { name: 'Others', percentage: '7%', shares: '0.7M', color: 'bg-slate-400' }
                          ].map((item, idx) => (
                            <div key={idx} className="flex items-center gap-2 text-xs">
                              <div className={`w-3 h-3 rounded-full ${item.color}`} />
                              <span className="text-slate-700 font-medium">{item.name}</span>
                              <span className="text-slate-500 ml-auto">{item.percentage}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                      {/* Bar Chart for Shares */}
                      <div className="pt-3 border-t border-slate-200">
                        <p className="text-xs text-slate-500 mb-2">Share Distribution</p>
                        <div className="h-12 flex items-end gap-2">
                          {[
                            { label: 'Founders', height: 90, color: 'bg-blue-500' },
                            { label: 'Investors', height: 60, color: 'bg-purple-500' },
                            { label: 'ESOP', height: 36, color: 'bg-green-500' },
                            { label: 'Others', height: 14, color: 'bg-slate-400' }
                          ].map((item, idx) => (
                            <div key={idx} className="flex-1 flex flex-col items-center">
                              <div
                                className={`w-full ${item.color} rounded-t`}
                                style={{ height: `${item.height}%` }}
                              />
                              <span className="text-[10px] text-slate-500 mt-1">{item.label}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="esop" className="py-20 md:py-28 bg-slate-50">
          <div className="max-w-7xl mx-auto px-6">
            <div className="grid lg:grid-cols-2 gap-16 items-center">
              {/* ESOP Dashboard Screenshot */}
              <div className="relative order-2 lg:order-1">
                <div className="absolute -inset-1 bg-gradient-to-r from-purple-500/20 to-pink-500/20 rounded-3xl blur-xl" />
                <div className="relative bg-white border border-slate-200 rounded-3xl overflow-hidden shadow-2xl">
                  {/* Browser Chrome */}
                  <div className="bg-slate-50 border-b border-slate-200 px-4 py-2.5 flex items-center gap-2">
                    <div className="flex gap-2">
                      <div className="w-2.5 h-2.5 rounded-full bg-red-500/50" />
                      <div className="w-2.5 h-2.5 rounded-full bg-yellow-500/50" />
                      <div className="w-2.5 h-2.5 rounded-full bg-green-500/50" />
                    </div>
                    <div className="flex-1 mx-3 bg-white rounded-lg px-3 py-1 text-xs text-slate-600 border border-slate-200">
                    </div>
                  </div>
                  
                  {/* ESOP Dashboard Content */}
                  <div className="p-6 space-y-6 bg-white">
                    <div className="flex items-center gap-4">
                      <div className="w-16 h-16 rounded-2xl bg-purple-100 flex items-center justify-center">
                        <Users className="w-8 h-8 text-purple-600" />
                      </div>
                      <div>
                        <h3 className="text-xl font-semibold text-slate-900">Employee Stock Program</h3>
                        <p className="text-sm text-slate-600">Active programs</p>
                      </div>
                    </div>
                    
                    <div className="space-y-4">
                      <div className="rounded-xl bg-purple-50 p-4 border border-purple-100">
                        <div className="flex items-center justify-between mb-2">
                          <p className="text-sm font-semibold text-slate-900">ESOP 2025</p>
                          <span className="text-xs px-2 py-1 bg-green-100 text-green-700 rounded-full">Active</span>
                        </div>
                        <p className="text-xs text-slate-600 mb-3">1,240 participants</p>
                        <div className="mb-2">
                          <div className="h-2 bg-slate-200 rounded-full overflow-hidden">
                            <div className="h-full bg-purple-600" style={{ width: '68%' }} />
                          </div>
                        </div>
                        <div className="flex items-center justify-between text-xs">
                          <span className="text-slate-500">68% vested</span>
                          <span className="text-purple-600 font-medium">32% remaining</span>
                        </div>
                      </div>

                      {/* Program Stats with Chart */}
                      <div className="grid grid-cols-2 gap-3 mb-3">
                        <div className="bg-slate-50 rounded-lg p-3 border border-slate-100">
                          <p className="text-xs text-slate-500 mb-1">Total Grants</p>
                          <p className="text-lg font-bold text-slate-900">2,450</p>
                        </div>
                        <div className="bg-slate-50 rounded-lg p-3 border border-slate-100">
                          <p className="text-xs text-slate-500 mb-1">Next Vesting</p>
                          <p className="text-lg font-bold text-slate-900">Feb 15</p>
                        </div>
                      </div>
                      {/* Vesting Progress Chart */}
                      <div className="bg-slate-50 rounded-lg p-3 border border-slate-100">
                        <p className="text-xs text-slate-500 mb-2">Vesting Timeline</p>
                        <div className="h-16 flex items-end gap-1.5">
                          {[45, 52, 58, 65, 68, 72, 68, 75].map((height, idx) => (
                            <div key={idx} className="flex-1 flex flex-col items-center">
                              <div
                                className="w-full bg-gradient-to-t from-purple-500 to-purple-400 rounded-t"
                                style={{ height: `${height}%` }}
                              />
                            </div>
                          ))}
                        </div>
                        <div className="flex items-center justify-between mt-2 text-[10px] text-slate-500">
                          <span>Q1</span>
                          <span>Q2</span>
                          <span>Q3</span>
                          <span>Q4</span>
                        </div>
                      </div>

                      {/* Recent Grants */}
                      <div className="bg-slate-50 rounded-lg p-3 border border-slate-100">
                        <p className="text-xs font-semibold text-slate-900 mb-2">Recent Grants</p>
                        <div className="space-y-1.5">
                          {[
                            { employee: 'Ahmed Al-Mutairi', shares: '500', date: 'Jan 10' },
                            { employee: 'Sara Al-Qahtani', shares: '750', date: 'Jan 8' },
                            { employee: 'Mohammed Al-Shehri', shares: '1,000', date: 'Jan 5' }
                          ].map((item, idx) => (
                            <div key={idx} className="flex items-center justify-between text-xs">
                              <span className="text-slate-700">{item.employee}</span>
                              <div className="text-right">
                                <span className="text-slate-900 font-medium">{item.shares} shares</span>
                                <span className="text-slate-500 ml-2">• {item.date}</span>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div className="space-y-6 order-1 lg:order-2">
                <h2 className="text-4xl md:text-5xl font-bold">Employee Stock Program</h2>
                <p className="text-lg text-slate-600 leading-relaxed">
                  Enhance employee performance and loyalty with our seamless technology solutions. We simplify the creation of flexible digital employee share programs, 
                  making it effortless for your company.
                </p>
                <ul className="space-y-3">
                  {mainFeatures[2].features.map((item, idx) => (
                    <li key={idx} className="flex items-start gap-3">
                      <CheckCircle2 className="w-5 h-5 text-purple-600 shrink-0 mt-0.5" />
                      <span className="text-slate-700">{item}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        </section>

        {/* Testimonials */}
        <section id="testimonials" className="py-20 md:py-28">
          <div className="max-w-7xl mx-auto px-6">
            <div className="text-center max-w-3xl mx-auto space-y-4 mb-16">
              <h2 className="text-4xl md:text-5xl font-bold">What our clients say</h2>
            </div>
            <div className="grid md:grid-cols-2 gap-8">
              {testimonials.map((testimonial, idx) => (
                <div key={idx} className="rounded-3xl border border-slate-200 bg-white p-8 space-y-4">
                  <div className="flex items-center gap-2 text-blue-600 mb-4">
                    {[...Array(5)].map((_, i) => (
                      <Award key={i} className="w-5 h-5 fill-current" />
                    ))}
                  </div>
                  <p className="text-slate-700 leading-relaxed text-lg" dir="rtl">
                    "{testimonial.quote}"
                  </p>
                  <div className="pt-4 border-t border-slate-200">
                    <p className="font-semibold text-slate-900" dir="rtl">{testimonial.author}</p>
                    <p className="text-sm text-slate-600" dir="rtl">{testimonial.role}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Partners Section */}
        <section className="py-16 bg-slate-50">
          <div className="max-w-7xl mx-auto px-6">
            <div className="text-center mb-12">
              <p className="text-sm font-semibold text-slate-500 uppercase tracking-wide mb-4">
                Derayah, in collaboration with its partners, contributes to creating a digital environment to help your company prosper.
              </p>
            </div>
            <div className="flex items-center justify-center gap-12 flex-wrap">
              {['Partner 1', 'Partner 2', 'Partner 3', 'Partner 4', 'Partner 5'].map((partner, idx) => (
                <div key={idx} className="w-32 h-16 rounded-lg bg-slate-200 flex items-center justify-center text-slate-400 text-sm font-medium">
                  {partner}
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* CTA Section */}
        <section className="py-20 md:py-28 bg-gradient-to-r from-blue-600 to-purple-600 rounded-4xl text-white">
          <div className="max-w-4xl mx-auto px-6 text-center space-y-6">
            <h2 className="text-4xl md:text-5xl font-bold">Solutions Made Simple with the Derayah App!</h2>
            <p className="text-xl text-white/90">
              Get the full Derayah experience at your fingertips. Download it from the Apple App Store or Google Play Store today.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center pt-4">
              <Link
                to="/login"
                className="inline-flex items-center justify-center gap-3 px-8 py-4 rounded-xl bg-white text-blue-600 font-semibold hover:bg-blue-50 transition text-lg"
              >
                Create Account
                <ArrowRight className="w-5 h-5" />
              </Link>
              <Link
                to="/employee/login"
                className="inline-flex items-center justify-center gap-3 px-8 py-4 rounded-xl border-2 border-white/30 text-white hover:bg-white/10 transition text-lg"
              >
                Learn More
              </Link>
            </div>
          </div>
        </section>
      </main>

      <footer className="border-t border-slate-200 bg-slate-50">
        <div className="max-w-7xl mx-auto px-6 py-12">
          <div className="grid md:grid-cols-4 gap-8 mb-8">
            <div>
              <h3 className="font-semibold text-slate-900 mb-4">Companies</h3>
              <ul className="space-y-2 text-sm text-slate-600">
                <li><a href="#equity" className="hover:text-blue-600">Equity Management</a></li>
                <li><a href="#esop" className="hover:text-blue-600">ESOP</a></li>
                <li><a href="#" className="hover:text-blue-600">Buy-Back Shares</a></li>
                <li><a href="#" className="hover:text-blue-600">Investor Relations</a></li>
              </ul>
            </div>
            <div>
              <h3 className="font-semibold text-slate-900 mb-4">About Derayah</h3>
              <ul className="space-y-2 text-sm text-slate-600">
                <li><a href="#" className="hover:text-blue-600">About Us</a></li>
                <li><a href="#" className="hover:text-blue-600">Privacy Policy</a></li>
                <li><a href="#" className="hover:text-blue-600">Terms of Service</a></li>
                <li><a href="#" className="hover:text-blue-600">Knowledge Center</a></li>
              </ul>
            </div>
            <div>
              <h3 className="font-semibold text-slate-900 mb-4">Contact</h3>
              <ul className="space-y-2 text-sm text-slate-600">
                <li>contact@derayah.com</li>
                <li>+966 11 200 2054</li>
                <li>Anas Ibn Malik Rd, Al Malqa</li>
                <li>Riyadh 13524, Saudi Arabia</li>
              </ul>
            </div>
            <div>
              <h3 className="font-semibold text-slate-900 mb-4">Subscribe</h3>
              <p className="text-sm text-slate-600 mb-4">
                Join our newsletter to stay up to date on features and releases.
              </p>
              <div className="flex gap-2">
                <input
                  type="email"
                  placeholder="Your email"
                  className="flex-1 px-4 py-2 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-500 transition text-sm font-medium">
                  Subscribe
                </button>
              </div>
            </div>
          </div>
          <div className="border-t border-slate-200 pt-8 text-sm text-slate-600 text-center">
            <p>© Copyright Derayah. All rights reserved {new Date().getFullYear()}</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
