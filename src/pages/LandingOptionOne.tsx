import { Link } from 'react-router-dom';
import { ArrowRight, CheckCircle2, Shield, BarChart3, Users, Sparkles, FileText, Timer, Globe2 } from 'lucide-react';
import LandingLoginButtons from '../components/LandingLoginButtons';

const heroHighlights = [
  'End-to-end equity administration across ESOP, RSU, SAR, and LTIP plans',
  'Automated contract workflows with audit-grade approvals',
  'Performance-based vesting and KPI tracking built-in'
];

const featureCards = [
  {
    title: 'Flexible Plan Builder',
    description:
      'Launch time-based, performance-based, or hybrid vesting plans in minutes. Configure grant rules, cliffs, and custom events with full governance.',
    metrics: [
      { label: 'Plan Templates', value: '12+' },
      { label: 'Localized Parameters', value: 'KSA-ready' }
    ]
  },
  {
    title: 'Automated Contracting',
    description:
      'Generate bilingual contracts, route approvals, and collect signatures digitally. Every acceptance is versioned and discoverable.',
    metrics: [
      { label: 'Avg. Cycle Time', value: '4x faster' },
      { label: 'Audit Logs', value: 'Immutable' }
    ]
  },
  {
    title: 'Performance Intelligence',
    description:
      'Tie vesting to OKRs and financial KPIs. Monitor attainment in real time and trigger vesting updates when metrics are certified.',
    metrics: [
      { label: 'Live KPIs', value: '22 tracked' },
      { label: 'Scenario Models', value: 'Instant' }
    ]
  }
];

const proofPoints = [
  { icon: Shield, title: 'SOC2-ready Security', description: 'Role-based access, encrypted records, continuous monitoring.' },
  { icon: Globe2, title: 'Regulatory Alignment', description: 'Supports CMA governance, IFRS 2 expense tracking, and zakat-ready data.' },
  { icon: Users, title: 'Stakeholder Visibility', description: 'Portals for SaaS admins, company teams, and employees—all in one platform.' }
];

const heroScreenshot = (
  <div className="bg-white/5 backdrop-blur-xl border border-white/10 rounded-3xl p-6 md:p-8 shadow-2xl">
    <div className="flex items-center justify-between mb-4">
      <div>
        <p className="text-xs uppercase tracking-[0.3em] text-blue-200">Company Overview</p>
        <h3 className="text-2xl font-semibold text-white">Vesting & Dilution Control</h3>
      </div>
      <span className="inline-flex items-center gap-1 px-3 py-1 text-xs font-medium bg-blue-500/20 text-blue-100 rounded-full">
        Live Sync
        <ArrowRight className="w-3 h-3" />
      </span>
    </div>

    <div className="grid md:grid-cols-2 gap-6">
      <div className="space-y-4">
        <div className="bg-white/5 border border-white/10 rounded-xl p-4">
          <p className="text-sm text-blue-100 mb-1">Total Granted Equity</p>
          <p className="text-3xl font-bold text-white">4,285,340</p>
          <p className="text-xs text-slate-300 mt-2">Across 36 active plans</p>
        </div>
        <div className="bg-white/5 border border-white/10 rounded-xl p-4">
          <p className="text-sm text-blue-100 mb-1">Performance Vesting</p>
          <div className="flex items-center justify-between">
            <p className="text-3xl font-bold text-green-300">68%</p>
            <span className="text-xs text-slate-300">KPI attainment YTD</span>
          </div>
          <div className="mt-3 space-y-2">
            {[
              { label: 'Revenue Growth', value: '104%', status: 'text-green-300' },
              { label: 'Customer Retention', value: '96%', status: 'text-green-200' },
              { label: 'Product OKRs', value: '82%', status: 'text-blue-200' }
            ].map(metric => (
              <div key={metric.label} className="flex items-center justify-between text-sm text-slate-200">
                <span>{metric.label}</span>
                <span className={`font-semibold ${metric.status}`}>{metric.value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="bg-slate-900/60 border border-white/10 rounded-2xl p-5 space-y-4">
        <div className="flex items-center justify-between">
          <p className="text-sm font-medium text-white">Upcoming Vesting Events</p>
          <span className="text-xs text-slate-300">Automated reminders active</span>
        </div>
        <div className="space-y-3">
          {[
            { name: 'Series B RSU Pool', date: '15 Jan 2026', shares: '48,000 shares', status: 'Due in 7 days' },
            { name: 'Saudi LTIP - Leadership', date: '30 Jan 2026', shares: '21,350 shares', status: 'KPI pending approval' },
            { name: 'Tech ESOP 2024', date: '01 Feb 2026', shares: '13,900 shares', status: 'Ready to process' }
          ].map(event => (
            <div key={event.name} className="rounded-xl bg-white/5 border border-white/10 p-4">
              <div className="flex items-center justify-between">
                <h4 className="text-sm font-semibold text-white">{event.name}</h4>
                <span className="text-xs text-slate-200">{event.date}</span>
              </div>
              <p className="text-sm text-blue-100 mt-2">{event.shares}</p>
              <p className="text-xs text-slate-300 mt-1">{event.status}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  </div>
);

export default function LandingOptionOne() {
  return (
    <div className="bg-slate-950 text-white min-h-screen">
      <div className="absolute inset-0 overflow-hidden -z-10">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-600/20 via-slate-950 to-slate-950" />
        <div className="absolute top-20 -left-10 w-96 h-96 bg-blue-500/20 blur-3xl rounded-full" />
        <div className="absolute bottom-10 right-0 w-[32rem] h-[32rem] bg-cyan-500/20 blur-3xl rounded-full" />
      </div>

      <header className="px-6 md:px-10 lg:px-16 pt-8 pb-4">
        <div className="flex items-center justify-between">
          <Link to="/" className="inline-flex items-center gap-2 text-white/90 hover:text-white transition">
            <Sparkles className="w-6 h-6 text-blue-300" />
            <span className="text-lg font-semibold tracking-tight">Derayah Equity Studio</span>
          </Link>
          <nav className="hidden md:flex items-center gap-8 text-sm text-white/70">
            <a href="#platform" className="hover:text-white transition">Platform</a>
            <a href="#features" className="hover:text-white transition">Capabilities</a>
            <a href="#compliance" className="hover:text-white transition">Governance</a>
            <a href="#resources" className="hover:text-white transition">Resources</a>
          </nav>
          <LandingLoginButtons variant="dark" />
        </div>
      </header>

      <main className="px-6 md:px-10 lg:px-16">
        <section className="py-12 md:py-20 grid lg:grid-cols-[1.1fr_1fr] gap-10 lg:gap-16 items-center">
          <div className="space-y-8">
            <div>
              <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-blue-500/20 text-blue-100">
                <Sparkles className="w-3 h-3" />
                Saudi-built, CMA-aligned
              </span>
              <h1 className="mt-6 text-4xl md:text-5xl font-bold tracking-tight">
                Modern equity infrastructure for performance-driven teams
              </h1>
              <p className="mt-6 text-lg text-white/70 leading-relaxed">
                Centralize grants, automate vesting events, and empower every stakeholder—from SaaS administrators to company teams and employees—with a single, intelligent equity platform.
              </p>
            </div>

            <ul className="space-y-3 text-white/80">
              {heroHighlights.map(item => (
                <li key={item} className="flex items-center gap-3">
                  <CheckCircle2 className="w-5 h-5 text-blue-300 shrink-0" />
                  <span>{item}</span>
                </li>
              ))}
            </ul>

            <div className="flex flex-col sm:flex-row gap-4">
              <Link
                to="/login"
                className="inline-flex items-center justify-center gap-3 px-6 py-3 rounded-2xl bg-blue-500 text-white font-semibold shadow-lg shadow-blue-500/30 hover:bg-blue-400 transition"
              >
                Launch Admin Console
                <ArrowRight className="w-4 h-4" />
              </Link>
              <Link
                to="/employee/login"
                className="inline-flex items-center justify-center gap-3 px-6 py-3 rounded-2xl border border-white/30 text-white hover:bg-white/10 transition"
              >
                Enter Employee Portal
              </Link>
            </div>
          </div>

          {heroScreenshot}
        </section>

        <section id="features" className="py-12 md:py-20">
          <div className="grid lg:grid-cols-3 gap-8">
            {featureCards.map(card => (
              <div key={card.title} className="bg-white/5 border border-white/10 rounded-3xl p-8 space-y-6">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-blue-500/20 flex items-center justify-center">
                    <Sparkles className="w-5 h-5 text-blue-200" />
                  </div>
                  <h3 className="text-xl font-semibold">{card.title}</h3>
                </div>
                <p className="text-sm text-white/70 leading-relaxed">{card.description}</p>
                <div className="grid grid-cols-2 gap-3">
                  {card.metrics.map(metric => (
                    <div key={metric.label} className="rounded-xl bg-slate-900/60 border border-white/10 p-4">
                      <p className="text-xs text-blue-100 uppercase tracking-wide">{metric.label}</p>
                      <p className="text-lg font-bold text-white mt-1">{metric.value}</p>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </section>

        <section id="platform" className="py-12 md:py-20">
          <div className="bg-white/5 border border-white/10 rounded-3xl p-8 md:p-12">
            <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-8">
              <div className="max-w-xl space-y-6">
                <h2 className="text-3xl font-semibold">Everything you need for compliant equity programs</h2>
                <p className="text-white/70 leading-relaxed">
                  From plan design to liquidity events, Derayah gives you automation, transparency, and controls to run equity with confidence. Performance triggers, service milestones, and manual adjustments stay synchronized across stakeholders.
                </p>
                <div className="grid sm:grid-cols-2 gap-4">
                  {[
                    { title: 'Role-based workspaces', detail: 'Dedicated consoles for SaaS ops, company admins, and employees.' },
                    { title: 'Real-time analytics', detail: 'Monitor dilution, overhang, and spend with dynamic dashboards.' },
                    { title: 'Embedded approvals', detail: 'Policy enforcement and audit log retention across every workflow.' },
                    { title: 'Localization controls', detail: 'Arabic & English communication, zakat exports, IFRS reports.' }
                  ].map(item => (
                    <div key={item.title} className="rounded-2xl bg-slate-900/60 border border-white/5 p-5">
                      <h4 className="text-sm font-semibold text-white">{item.title}</h4>
                      <p className="text-xs text-white/70 mt-2 leading-relaxed">{item.detail}</p>
                    </div>
                  ))}
                </div>
              </div>

              <div className="flex-1 min-w-[320px]">
                <div className="bg-slate-900/70 border border-white/10 rounded-3xl p-6 space-y-6">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-blue-500/20 flex items-center justify-center">
                      <BarChart3 className="w-5 h-5 text-blue-200" />
                    </div>
                    <div>
                      <p className="text-xs uppercase text-blue-200">Employee Equity Snapshot</p>
                      <p className="text-lg font-semibold">Interactive analytics</p>
                    </div>
                  </div>

                  <div className="space-y-4">
                    <div className="bg-white/5 rounded-2xl p-4 border border-white/10">
                      <div className="flex items-center justify-between mb-3">
                        <span className="text-sm font-semibold text-white">Employees by vesting status</span>
                        <span className="text-xs text-slate-300">Updated 2 min ago</span>
                      </div>
                      <div className="grid grid-cols-3 gap-3">
                        {[
                          { label: 'Fully Vested', value: '128' },
                          { label: 'In Progress', value: '502' },
                          { label: 'Pending KPI', value: '89' }
                        ].map(stat => (
                          <div key={stat.label} className="rounded-xl bg-slate-900/60 border border-white/5 p-3">
                            <p className="text-xs text-blue-100 uppercase">{stat.label}</p>
                            <p className="text-lg font-semibold text-white mt-1">{stat.value}</p>
                          </div>
                        ))}
                      </div>
                    </div>

                    <div className="bg-white/5 rounded-2xl p-4 border border-white/10">
                      <div className="flex items-center justify-between mb-4">
                        <span className="text-sm font-semibold text-white">Vesting velocity</span>
                        <Timer className="w-4 h-4 text-blue-200" />
                      </div>
                      <div className="space-y-3">
                        {[
                          { plan: 'Growth RSU 2025', progress: 72 },
                          { plan: 'Saudi LTIP 2024', progress: 58 },
                          { plan: 'Founders ESOP Refresh', progress: 84 }
                        ].map(item => (
                          <div key={item.plan}>
                            <div className="flex items-center justify-between text-xs text-white/70 mb-1">
                              <span>{item.plan}</span>
                              <span>{item.progress}%</span>
                            </div>
                            <div className="h-2 w-full bg-white/10 rounded-full overflow-hidden">
                              <div className="h-full bg-gradient-to-r from-blue-400 via-blue-500 to-cyan-400" style={{ width: `${item.progress}%` }} />
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

        <section id="compliance" className="py-12 md:py-20">
          <div className="grid md:grid-cols-3 gap-8">
            {proofPoints.map(point => (
              <div key={point.title} className="bg-white/5 border border-white/10 rounded-3xl p-8">
                <point.icon className="w-8 h-8 text-blue-200" />
                <h3 className="mt-4 text-lg font-semibold">{point.title}</h3>
                <p className="mt-2 text-sm text-white/70 leading-relaxed">{point.description}</p>
              </div>
            ))}
          </div>
        </section>

        <section id="resources" className="py-12 md:py-20">
          <div className="bg-blue-500/10 border border-blue-400/30 rounded-3xl p-8 md:p-12 flex flex-col md:flex-row md:items-center md:justify-between gap-8">
            <div className="space-y-4">
              <h2 className="text-3xl font-semibold text-white">Ready to experience the full platform?</h2>
              <p className="text-sm text-blue-100 leading-relaxed">
                Spin up a demo environment, invite internal stakeholders, and explore the admin, company, and employee perspectives side by side. We provide localized templates and ready-to-import data models.
              </p>
              <div className="flex items-center gap-4">
                <LandingLoginButtons variant="dark" />
              </div>
            </div>
            <div className="bg-slate-950/60 border border-white/10 rounded-2xl p-6 space-y-4">
              <div className="flex items-center gap-3">
                <FileText className="w-5 h-5 text-blue-200" />
                <span className="text-sm font-semibold text-white">Resource Library</span>
              </div>
              <ul className="space-y-3 text-sm text-blue-100">
                <li>• CMA Compliance Checklist</li>
                <li>• IFRS 2 Expense Modeling Workbook</li>
                <li>• Employee equity education guides (Arabic & English)</li>
                <li>• ESOP communication templates</li>
              </ul>
            </div>
          </div>
        </section>
      </main>

      <footer className="px-6 md:px-10 lg:px-16 pb-12 text-sm text-white/50">
        <div className="border-t border-white/10 pt-6 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <p>© {new Date().getFullYear()} Derayah Equity Studio. All rights reserved.</p>
          <div className="flex items-center gap-6">
            <Link to="/login" className="hover:text-white transition">Admin Login</Link>
            <Link to="/employee/login" className="hover:text-white transition">Employee Login</Link>
            <a href="#compliance" className="hover:text-white transition">Compliance</a>
            <a href="mailto:support@derayah.com" className="hover:text-white transition">Contact</a>
          </div>
        </div>
      </footer>
    </div>
  );
}





