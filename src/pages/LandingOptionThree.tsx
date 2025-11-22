import { useState } from 'react';
import { Link } from 'react-router-dom';
import {
  ArrowRight,
  UserCog,
  Building2,
  Users,
  Globe,
  Shield,
  ClipboardCheck,
  Sparkles,
  BarChart4,
  BookOpen,
  Mail,
  LayoutList
} from 'lucide-react';
import LandingLoginButtons from '../components/LandingLoginButtons';

type SegmentKey = 'saas' | 'company' | 'employee';

const segmentContent: Record<
  SegmentKey,
  {
    title: string;
    description: string;
    bullets: { label: string; detail: string }[];
    panels: { heading: string; content: string; metric?: string }[];
    loginPath: string;
  }
> = {
  saas: {
    title: 'SaaS Operator Console',
    description:
      'Govern multi-tenant deployments, enforce compliance standards, and monitor platform health across every customer environment. Assign success managers, monitor API usage, and coordinate product releases.',
    bullets: [
      { label: 'Environment oversight', detail: 'Manage staging, production, and sandbox tenants with configurable SLAs.' },
      { label: 'Compliance enforcement', detail: 'Provision policies aligned to CMA guidance, IFRS 2, and zakat reporting.' },
      { label: 'Release orchestration', detail: 'Roll out features safely with change logs, beta channels, and rollback controls.' }
    ],
    panels: [
      { heading: 'Active Tenants', content: '28 enterprise accounts', metric: '99.98% uptime' },
      { heading: 'Audit Checks (30d)', content: '0 open issues • 126 automated reports generated' },
      { heading: 'API Throughput', content: '1.4M calls processed with auto-throttling and webhooks' }
    ],
    loginPath: '/login'
  },
  company: {
    title: 'Company Equity HQ',
    description:
      'Design plans, approve grants, and coordinate finance, HR, and legal activities from a single command center. Track performance indicators and prepare for committee reviews with built-in workflows.',
    bullets: [
      { label: 'Plan lifecycle', detail: 'Create, simulate, and publish ESOP, RSU, and SAR programs with one-click approvals.' },
      { label: 'Performance governance', detail: 'Align vesting triggers to OKRs, financial KPIs, and qualitative milestones.' },
      { label: 'Stakeholder alignment', detail: 'Finance, HR, and legal share one dataset with fine-grained permissions.' }
    ],
    panels: [
      { heading: 'Active Plans', content: '12 programs spanning 4 entities', metric: '68% performance attained' },
      { heading: 'Upcoming Vesting Events', content: '14 due this month • 3 awaiting KPI approval' },
      { heading: 'Equity Expense Forecast', content: 'SAR 4.8M next quarter with IFRS 2 schedules ready for auditors' }
    ],
    loginPath: '/login'
  },
  employee: {
    title: 'Employee Equity Portal',
    description:
      'Empower employees with a transparent view of their equity journey. They can accept grants, track vesting milestones, and understand tax and zakat implications with localized guidance.',
    bullets: [
      { label: 'Personalized timeline', detail: 'Visualize vesting milestones with real-time progress indicators.' },
      { label: 'Financial clarity', detail: 'Estimate tax, zakat, and potential proceeds based on current FMV.' },
      { label: 'Knowledge base', detail: 'Access bilingual education modules, FAQs, and contract archives.' }
    ],
    panels: [
      { heading: 'Next Vesting Event', content: '4,200 shares vesting on 15 February', metric: 'Ready to accept' },
      { heading: 'Performance KPIs', content: 'Product adoption 92% • Customer NPS 74 • OKR progress 88%' },
      { heading: 'Learning Center', content: '3 new guides: RSU lifecycle, zakat FAQ, liquidity planning' }
    ],
    loginPath: '/employee/login'
  }
};

const proofItems = [
  { icon: Shield, title: 'Built for Saudi governance', detail: 'CMA-compliant workflows, IFRS 2 automation, and zakat-ready exports.' },
  { icon: Globe, title: 'Bilingual immersion', detail: 'Arabic and English interfaces, notifications, and contract generation.' },
  { icon: ClipboardCheck, title: 'Audit-first design', detail: 'Immutable logs, approval trails, and SOC2-ready operational controls.' }
];

export default function LandingOptionThree() {
  const [segment, setSegment] = useState<SegmentKey>('company');

  const activeSegment = segmentContent[segment];

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 relative">
      <div className="absolute inset-0 -z-10">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_top,_rgba(56,189,248,0.12),_transparent_45%),radial-gradient(circle_at_bottom,_rgba(59,130,246,0.18),_transparent_55%)]" />
        <div className="absolute inset-0 bg-slate-950/50" />
      </div>

      <header className="px-6 md:px-10 lg:px-16 pt-8 pb-6 flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between">
        <Link to="/concept3" className="inline-flex items-center gap-2 text-white/90 hover:text-white transition">
          <Sparkles className="w-6 h-6 text-cyan-300" />
          <span className="text-lg font-semibold">Derayah Equity Studio</span>
        </Link>
        <nav className="flex flex-wrap items-center gap-6 text-sm text-white/70">
          <a href="#segments" className="hover:text-white transition">Segments</a>
          <a href="#spotlight" className="hover:text-white transition">Feature Spotlight</a>
          <a href="#resources" className="hover:text-white transition">Resources</a>
          <a href="#contact" className="hover:text-white transition">Contact</a>
        </nav>
        <LandingLoginButtons variant="dark" align="center" />
      </header>

      <main className="px-6 md:px-10 lg:px-16">
        <section className="py-12 md:py-16 grid lg:grid-cols-[1.1fr_0.9fr] gap-10 lg:gap-16 items-center">
          <div className="space-y-6">
            <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-slate-800 text-cyan-200">
              <Globe className="w-4 h-4" />
              Omni-stakeholder experience
            </span>
            <h1 className="text-4xl md:text-5xl font-semibold leading-tight">
              One landing, three journeys—tailored experiences for SaaS operators, company admins, and employees.
            </h1>
            <p className="text-lg text-white/70 leading-relaxed">
              Transform how your teams and partners engage with equity. Inspired by best-in-class platforms like Ebana and Xumane, Derayah centralizes every workflow while honoring local requirements and multilingual communication.
            </p>
            <div className="flex flex-col sm:flex-row gap-4">
              <Link
                to={activeSegment.loginPath}
                className="inline-flex items-center justify-center gap-3 px-6 py-3 rounded-2xl bg-cyan-400 text-slate-900 font-semibold hover:bg-cyan-300 transition"
              >
                Continue as {segment === 'saas' ? 'SaaS Operator' : segment === 'company' ? 'Company Admin' : 'Employee'}
                <ArrowRight className="w-4 h-4" />
              </Link>
              <Link
                to="/login"
                className="inline-flex items-center justify-center gap-3 px-6 py-3 rounded-2xl border border-white/30 text-white hover:bg-white/10 transition"
              >
                Request Full Demo
              </Link>
            </div>
          </div>

          <div className="bg-slate-800/50 border border-white/10 rounded-3xl p-6 md:p-8 space-y-6">
            <div className="flex items-center justify-between">
              <p className="text-xs uppercase tracking-[0.3em] text-white/60">Live Feature Montage</p>
              <span className="inline-flex items-center gap-2 px-3 py-1 text-xs font-semibold bg-slate-900 rounded-full">
                <LayoutList className="w-4 h-4 text-cyan-300" />
                Context-aware UI
              </span>
            </div>
            <div className="space-y-4">
              <div className="rounded-2xl bg-slate-900/70 border border-white/10 p-5">
                <p className="text-xs text-white/60 uppercase">Console Snapshot</p>
                <h3 className="text-lg font-semibold text-white mt-2">Role-based dashboards</h3>
                <p className="text-sm text-white/70 mt-3">
                  Each persona signs in to a tailored dashboard with actionable KPIs, approvals, and insights sourced from the same data foundation.
                </p>
              </div>
              <div className="grid sm:grid-cols-3 gap-3">
                {[
                  { label: 'SaaS Health', value: '99.98% uptime', accent: 'text-cyan-300' },
                  { label: 'Plan Performance', value: '68% KPI attainment', accent: 'text-green-300' },
                  { label: 'Employee Adoption', value: '92% acceptance', accent: 'text-blue-200' }
                ].map(item => (
                  <div key={item.label} className="rounded-2xl bg-slate-900/80 border border-white/10 p-4">
                    <p className="text-xs text-white/60 uppercase">{item.label}</p>
                    <p className={`text-lg font-semibold mt-2 ${item.accent}`}>{item.value}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        <section id="segments" className="py-12 md:py-16">
          <div className="bg-slate-900/60 border border-white/10 rounded-3xl p-6 md:p-8">
            <div className="flex flex-wrap items-center gap-3 mb-8">
              {([
                { key: 'saas', label: 'SaaS Operator', icon: UserCog },
                { key: 'company', label: 'Company Admin', icon: Building2 },
                { key: 'employee', label: 'Employee', icon: Users }
              ] as Array<{ key: SegmentKey; label: string; icon: typeof UserCog }>).map(tab => {
                const active = segment === tab.key;
                return (
                  <button
                    key={tab.key}
                    onClick={() => setSegment(tab.key)}
                    className={`inline-flex items-center gap-2 px-4 py-2 rounded-2xl border transition ${
                      active ? 'border-cyan-400 bg-cyan-400/20 text-white' : 'border-white/10 text-white/70 hover:border-cyan-300 hover:text-white'
                    }`}
                  >
                    <tab.icon className="w-4 h-4" />
                    {tab.label}
                  </button>
                );
              })}
            </div>

            <div className="grid lg:grid-cols-[1.1fr_0.9fr] gap-8 lg:gap-12 items-start">
              <div className="space-y-5">
                <h2 className="text-3xl font-semibold text-white">{activeSegment.title}</h2>
                <p className="text-sm text-white/70 leading-relaxed">{activeSegment.description}</p>
                <ul className="space-y-3 text-sm text-white/80">
                  {activeSegment.bullets.map(item => (
                    <li key={item.label} className="flex items-start gap-3">
                      <span className="mt-1 w-2 h-2 rounded-full bg-cyan-400"></span>
                      <div>
                        <p className="font-semibold text-white">{item.label}</p>
                        <p className="text-white/70">{item.detail}</p>
                      </div>
                    </li>
                  ))}
                </ul>
                <div className="flex flex-wrap gap-3">
                  <Link
                    to={activeSegment.loginPath}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-cyan-400 text-slate-900 font-semibold hover:bg-cyan-300 transition"
                  >
                    Log in as {segment === 'saas' ? 'SaaS Operator' : segment === 'company' ? 'Company Admin' : 'Employee'}
                    <ArrowRight className="w-4 h-4" />
                  </Link>
                  <Link
                    to="/login"
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-xl border border-white/20 text-white hover:bg-white/10 transition"
                  >
                    Switch persona
                  </Link>
                </div>
              </div>

              <div className="grid gap-4">
                {activeSegment.panels.map(panel => (
                  <div key={panel.heading} className="rounded-2xl bg-slate-900/70 border border-white/10 p-5">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm font-semibold text-white">{panel.heading}</p>
                        <p className="text-xs text-white/60 mt-1">{panel.content}</p>
                      </div>
                      {panel.metric && <span className="text-xs font-semibold text-cyan-300">{panel.metric}</span>}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        <section id="spotlight" className="py-12 md:py-18">
          <div className="grid lg:grid-cols-[1.2fr_0.8fr] gap-12 items-center">
            <div className="space-y-6">
              <h2 className="text-3xl font-semibold text-white">Feature spotlight driven by real workflows</h2>
              <p className="text-white/70">
                Live dashboards, approval queues, and analytics panels shown here are rendered using the same UI components in our production platform—providing an authentic preview of the experience stakeholders receive.
              </p>
              <div className="grid sm:grid-cols-2 gap-4">
                {proofItems.map(item => (
                  <div key={item.title} className="rounded-2xl bg-slate-900/70 border border-white/10 p-5">
                    <item.icon className="w-5 h-5 text-cyan-300" />
                    <h3 className="mt-3 text-sm font-semibold text-white">{item.title}</h3>
                    <p className="text-xs text-white/70 mt-2 leading-relaxed">{item.detail}</p>
                  </div>
                ))}
              </div>
            </div>

            <div className="bg-slate-900/70 border border-white/10 rounded-3xl p-6 space-y-6">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-2xl bg-slate-800 flex items-center justify-center text-cyan-300">
                  <BarChart4 className="w-6 h-6" />
                </div>
                <div>
                  <p className="text-xs uppercase tracking-[0.2em] text-white/60">Equity Health Monitor</p>
                  <h3 className="text-lg font-semibold text-white">Cross-tenant analytics</h3>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                {[
                  { label: 'Grant approvals', value: '96% within SLA' },
                  { label: 'Performance KPIs', value: '78% certified on time' },
                  { label: 'Liquidity requests', value: 'SAR 12.4M processed' },
                  { label: 'Employee training', value: '1,240 modules completed' }
                ].map(item => (
                  <div key={item.label} className="rounded-2xl bg-slate-900 border border-white/10 p-4">
                    <p className="text-xs text-white/60 uppercase">{item.label}</p>
                    <p className="text-lg font-semibold text-cyan-300 mt-2">{item.value}</p>
                  </div>
                ))}
              </div>
              <div className="rounded-2xl bg-slate-900 border border-white/10 p-5">
                <p className="text-xs uppercase tracking-[0.2em] text-white/60 mb-2">Approval queue</p>
                <div className="space-y-3">
                  {[
                    { item: 'Series C RSU • Wave 2', status: 'Awaiting CFO e-signature' },
                    { item: 'Employee liquidity request', status: 'Compliance review in progress' },
                    { item: 'New entity onboarding', status: 'Legal docs approved • awaiting HR data' }
                  ].map(row => (
                    <div key={row.item} className="flex items-center justify-between px-4 py-3 rounded-xl bg-slate-800/80 border border-white/5">
                      <span className="text-sm font-medium text-white">{row.item}</span>
                      <span className="text-xs font-semibold text-cyan-300">{row.status}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="resources" className="py-12 md:py-16">
          <div className="bg-cyan-500/10 border border-cyan-400/30 rounded-3xl p-8 md:p-12 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-10">
            <div className="space-y-5">
              <h2 className="text-3xl font-semibold text-cyan-100">Resources for every stakeholder</h2>
              <p className="text-sm text-cyan-100/80 leading-relaxed">
                Access localized playbooks, policy templates, and onboarding programs for SaaS operators, company teams, and employees. Everything you need to launch with confidence.
              </p>
              <ul className="space-y-3 text-sm text-cyan-100/80">
                <li>• SaaS Ops handbook with deployment best practices</li>
                <li>• Company admin implementation checklist with CMA controls</li>
                <li>• Employee education tracks covering ESOP, RSU, SAR, and liquidity</li>
              </ul>
            </div>
            <div className="bg-slate-900/70 border border-white/10 rounded-2xl p-6 space-y-4">
              <div className="flex items-center gap-3">
                <BookOpen className="w-5 h-5 text-cyan-300" />
                <span className="text-sm font-semibold text-white">Featured Playbooks</span>
              </div>
              <div className="space-y-3 text-xs text-white/70">
                <p>• Performance-based vesting committee guide (Arabic & English)</p>
                <p>• Liquidity event checklist for private companies</p>
                <p>• IFRS 2 expense recognition templates for finance teams</p>
              </div>
              <div className="pt-4 border-t border-white/10">
                <LandingLoginButtons variant="dark" align="center" />
              </div>
            </div>
          </div>
        </section>
      </main>

      <footer id="contact" className="px-6 md:px-10 lg:px-16 pb-10">
        <div className="border-t border-white/10 pt-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4 text-sm text-white/60">
          <p>© {new Date().getFullYear()} Derayah Equity Studio. All rights reserved.</p>
          <div className="flex flex-wrap items-center gap-6">
            <a href="mailto:support@derayah.com" className="inline-flex items-center gap-2 hover:text-white transition">
              <Mail className="w-4 h-4" />
              support@derayah.com
            </a>
            <Link to="/login" className="hover:text-white transition">Admin Login</Link>
            <Link to="/employee/login" className="hover:text-white transition">Employee Login</Link>
            <a href="https://maps.app.goo.gl/" className="inline-flex items-center gap-2 hover:text-white transition" rel="noreferrer">
              <Building2 className="w-4 h-4" />
              Riyadh • Saudi Arabia
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}




