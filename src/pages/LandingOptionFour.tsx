import { Link } from 'react-router-dom';
import {
  ArrowRight,
  Star,
  Layers,
  PenSquare,
  ShieldCheck,
  LineChart,
  BarChart3,
  FileSignature,
  Users,
  ClipboardList,
  Mail,
  Phone,
  Building2,
  Sparkles
} from 'lucide-react';
import LandingLoginButtons from '../components/LandingLoginButtons';

const programOptions = [
  {
    title: 'Restricted Stock Awards',
    description:
      'Issue immediate equity ownership with tailored vesting conditions, lockups, and localization for Saudi governance requirements.',
    points: ['Hybrid service + performance triggers', 'Automated board packs', 'Clawback policies baked in'],
    color: 'from-sky-500/15 via-blue-500/10 to-transparent'
  },
  {
    title: 'Stock Appreciation Rights',
    description:
      'Deliver cash or stock-settled value without issuing shares. Configure valuation models, payout gates, and FAR-aligned accounting schedules.',
    points: ['FMV snapshots embedded', 'Expense automation', 'Liquidity-ready documentation'],
    color: 'from-purple-500/15 via-fuchsia-500/10 to-transparent'
  },
  {
    title: 'Employee Stock Options',
    description:
      'Launch ESOP plans with multi-trigger vesting, graded cliffs, and region-specific tax education. Deep analytics keep overhang in check.',
    points: ['Exercise windows & reminders', 'Tax + zakat guidance', 'Scenario planning toolkit'],
    color: 'from-emerald-500/15 via-teal-500/10 to-transparent'
  }
];

const workflowHighlights = [
  {
    title: 'Draft bilingual contracts',
    detail: 'Generate Arabic and English agreements with dynamic merge fields, approval routing, and e-signature.'
  },
  {
    title: 'Notify participants instantly',
    detail: 'SMS, email, and in-app alerts guide employees through grant acceptance with progress tracking.'
  },
  {
    title: 'Archive with confidence',
    detail: 'Immutable audit trails capture every amendment, reissue, cancellation, and acceptance timestamp.'
  }
];

const supportHighlights = [
  {
    title: 'Regulatory Alignment',
    description:
      'Derayah tracks CMA updates, IFRS 2 changes, and zakat implications so your plans stay compliant from launch to exit.',
    icon: ShieldCheck
  },
  {
    title: 'Specialized Legal Network',
    description:
      'Tap into our partner ecosystem for bespoke plan design, Sharia-compliant structures, and cross-border legal opinions.',
    icon: FileSignature
  },
  {
    title: 'Governance Controls',
    description:
      'Role-based approvals, segregation of duties, and configurable policies keep your stakeholders aligned and audit-ready.',
    icon: ClipboardList
  }
];

const transactionHistory = [
  { label: 'Grants issued', value: '1,248', meta: 'Across 6 entities • last 12 months' },
  { label: 'Vesting events processed', value: '4,612', meta: 'Performance + time-based mix' },
  { label: 'Liquidity actions', value: 'SAR 26.4M', meta: 'Buy-backs, secondary, SAR payouts' }
];

const consoleSnapshots = [
  {
    title: 'Admin Control Center',
    subtitle: 'Multi-plan overview',
    stats: [
      { label: 'Plans live', value: '18' },
      { label: 'Pending actions', value: '7' },
      { label: 'Audit score', value: '100%' }
    ],
    highlights: ['Real-time dilution monitor', 'Calendar of vesting events', 'Approval queue in focus']
  },
  {
    title: 'Finance Ops Workspace',
    subtitle: 'Expense & cap table sync',
    stats: [
      { label: 'Expense forecast', value: 'SAR 4.8M' },
      { label: 'Overhang', value: '7.2%' },
      { label: 'Scenario runs', value: '12' }
    ],
    highlights: ['IFRS 2 schedules auto-generated', 'Cap table entries reconciled', 'Cash vs stock payouts modeled']
  },
  {
    title: 'Employee Equity Portal',
    subtitle: 'Personal vesting timeline',
    stats: [
      { label: 'Next vest', value: '15 Feb 2026' },
      { label: 'Shares vesting', value: '4,200' },
      { label: 'Fair market value', value: 'SAR 186k' }
    ],
    highlights: ['Interactive vesting timeline', 'Tax & zakat estimators', 'Contract archive & learning hub']
  }
];

const shareMovementTimeline = [
  {
    stage: 'Plan creation',
    detail: 'SaaS operator and company admin configure plan rules, pools, and vesting logic.',
    actors: ['SaaS Admin', 'Company Admin'],
    timestamp: 'Week 0'
  },
  {
    stage: 'Grant issuance',
    detail: 'Contracts generated and routed for approval. Employees notified to accept digitally.',
    actors: ['Legal Counsel', 'HR', 'Employee'],
    timestamp: 'Week 2'
  },
  {
    stage: 'Vesting certification',
    detail: 'Performance committee certifies KPIs, finance signs off, shares move into vested status automatically.',
    actors: ['Performance Committee', 'Finance'],
    timestamp: 'Quarterly'
  },
  {
    stage: 'Payout or exercise',
    detail: 'Employees exercise, transfer, or receive SAR payouts. Liquidity exports land in finance dashboard.',
    actors: ['Employee', 'Finance', 'Board'],
    timestamp: 'Event-driven'
  }
];

export default function LandingOptionFour() {
  return (
    <div className="bg-gradient-to-b from-slate-50 to-white text-slate-900 min-h-screen">
      <header className="bg-white/80 backdrop-blur border-b border-slate-200 sticky top-0 z-30">
        <div className="max-w-6xl mx-auto px-6 py-5 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-6">
          <Link to="/concept4" className="inline-flex items-center gap-2 text-slate-900 hover:text-blue-600 transition">
            <Sparkles className="w-5 h-5 text-blue-600" />
            <span className="text-lg font-semibold tracking-tight">Derayah Equity Studio</span>
          </Link>
          <nav className="flex flex-wrap items-center gap-8 text-sm font-medium text-slate-600">
            <a href="#screens" className="hover:text-blue-600 transition">Platform Screens</a>
            <a href="#programs" className="hover:text-blue-600 transition">Program Options</a>
            <a href="#workflows" className="hover:text-blue-600 transition">Contract Workflow</a>
            <a href="#support" className="hover:text-blue-600 transition">Legal Support</a>
            <a href="#performance" className="hover:text-blue-600 transition">Performance Vesting</a>
            <a href="#movement" className="hover:text-blue-600 transition">Grant Lifecycle</a>
            <a href="#history" className="hover:text-blue-600 transition">Transaction History</a>
            <a href="#contact" className="hover:text-blue-600 transition">Contact</a>
          </nav>
          <LandingLoginButtons variant="light" />
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-6">
        <section className="py-16 md:py-20 grid lg:grid-cols-[1.1fr_0.9fr] gap-10 lg:gap-16 items-center">
          <div className="space-y-6">
            <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-700">
              <Star className="w-4 h-4" />
              Employee Share Ownership Program
            </span>
            <h1 className="text-4xl md:text-5xl font-semibold leading-tight tracking-tight">
              Elevate employee loyalty with flexible, compliant equity programs built for the GCC.
            </h1>
            <p className="text-lg text-slate-600 leading-relaxed">
              Inspired by leading experiences such as Ebana’s ESOP journey, Derayah Equity Studio streamlines program design, automates contracting, and delivers performance-driven vesting with real-time insight for every stakeholder.
            </p>
            <div className="flex flex-col sm:flex-row gap-4">
              <Link
                to="/login"
                className="inline-flex items-center justify-center gap-3 px-6 py-3 rounded-xl bg-blue-600 text-white font-semibold shadow-sm shadow-blue-600/20 hover:bg-blue-500 transition"
              >
                Get Started
                <ArrowRight className="w-4 h-4" />
              </Link>
              <Link
                to="/employee/login"
                className="inline-flex items-center justify-center gap-3 px-6 py-3 rounded-xl border border-blue-200 text-blue-700 hover:bg-blue-50 transition"
              >
                Employee Portal
              </Link>
            </div>
            <p className="text-xs uppercase tracking-[0.3em] text-slate-400">Trusted by leading Saudi enterprises</p>
          </div>

          <div className="relative">
            <div className="absolute inset-0 rounded-3xl bg-gradient-to-br from-blue-500/20 via-sky-400/10 to-transparent blur-3xl" />
            <div className="relative rounded-3xl border border-slate-200 bg-white shadow-xl shadow-slate-500/10 overflow-hidden">
              <div className="px-6 py-5 border-b border-slate-100 flex items-center justify-between">
                <div>
                  <p className="text-xs uppercase tracking-wide text-slate-500">Program Health Overview</p>
                  <h3 className="text-xl font-semibold text-slate-900 mt-1">Derayah Platform</h3>
                </div>
                <span className="inline-flex items-center gap-2 text-xs font-semibold text-emerald-600 bg-emerald-100 px-3 py-1 rounded-full">
                  Live Sync
                  <LineChart className="w-3 h-3" />
                </span>
              </div>
              <div className="p-6 space-y-6">
                <div className="grid sm:grid-cols-3 gap-4">
                  {[
                    { label: 'Active Programs', value: '18', meta: 'Across 4 entities' },
                    { label: 'Participants', value: '1,042', meta: '92% engaged' },
                    { label: 'Total Equity Granted', value: '6.2M shares', meta: 'SAR 134M FMV' }
                  ].map(stat => (
                    <div key={stat.label} className="rounded-2xl border border-slate-100 bg-slate-50 p-5">
                      <p className="text-xs font-medium text-slate-500 uppercase tracking-wide">{stat.label}</p>
                      <p className="text-2xl font-semibold text-slate-900 mt-2">{stat.value}</p>
                      <p className="text-xs text-slate-500 mt-1">{stat.meta}</p>
                    </div>
                  ))}
                </div>
                <div className="rounded-2xl border border-slate-100 bg-blue-50 p-5 space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-xs uppercase tracking-[0.3em] text-blue-500">Upcoming Vesting</p>
                      <h4 className="text-lg font-semibold text-blue-900">Next 30 days</h4>
                    </div>
                    <BarChart3 className="w-5 h-5 text-blue-600" />
                  </div>
                  <div className="space-y-3">
                    {[
                      { title: 'Leadership RSU 2024', date: '15 Jan', status: 'Performance KPI ready', tone: 'text-emerald-600' },
                      { title: 'Tech ESOP Refresh', date: '28 Jan', status: '36,200 shares vesting', tone: 'text-blue-700' },
                      { title: 'SAR Bonus Plan', date: '02 Feb', status: 'FMV certified • payout soon', tone: 'text-purple-600' }
                    ].map(item => (
                      <div key={item.title} className="bg-white rounded-xl border border-blue-100 px-4 py-3 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 shadow-sm">
                        <div>
                          <p className="text-sm font-semibold text-blue-900">{item.title}</p>
                          <p className={`text-xs font-medium ${item.tone}`}>{item.status}</p>
                        </div>
                        <span className="inline-flex items-center justify-center px-3 py-1 text-xs font-semibold text-blue-700 bg-blue-100 rounded-full">
                          {item.date}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="screens" className="py-16 border-t border-slate-200">
          <div className="text-center max-w-3xl mx-auto space-y-4">
            <h2 className="text-3xl font-semibold text-slate-900">See the platform in action</h2>
            <p className="text-slate-600">
              These live-rendered panels showcase real Derayah UI components—no mockups—illustrating how administrators, finance teams, and employees navigate the system.
            </p>
          </div>
          <div className="mt-10 grid lg:grid-cols-3 gap-6">
            {consoleSnapshots.map(snapshot => (
              <div key={snapshot.title} className="rounded-3xl border border-slate-200 bg-white shadow-md shadow-slate-900/5 overflow-hidden">
                <div className="px-5 py-4 border-b border-slate-100 bg-slate-50">
                  <p className="text-xs uppercase tracking-[0.3em] text-slate-500">{snapshot.title}</p>
                  <h3 className="text-lg font-semibold text-slate-900 mt-1">{snapshot.subtitle}</h3>
                </div>
                <div className="p-5 space-y-4">
                  <div className="grid grid-cols-3 gap-3">
                    {snapshot.stats.map(stat => (
                      <div key={stat.label} className="rounded-2xl bg-slate-900/5 border border-slate-100 p-3 text-center">
                        <p className="text-[11px] uppercase tracking-wide text-slate-500">{stat.label}</p>
                        <p className="text-lg font-semibold text-slate-900 mt-1">{stat.value}</p>
                      </div>
                    ))}
                  </div>
                  <div className="rounded-2xl border border-slate-100 bg-gradient-to-br from-blue-500/10 via-white to-white p-4 space-y-2">
                    {snapshot.highlights.map(highlight => (
                      <div key={highlight} className="flex items-start gap-2 text-sm text-slate-600">
                        <span className="mt-1 w-1.5 h-1.5 rounded-full bg-blue-500" />
                        <span>{highlight}</span>
                      </div>
                    ))}
                  </div>
                  <div className="rounded-2xl border border-slate-100 bg-white p-4">
                    <div className="flex items-center justify-between text-xs text-slate-500">
                      <span>Timeline preview</span>
                      <span>Live data feed</span>
                    </div>
                    <div className="mt-3 h-28 rounded-xl bg-slate-900/5 border border-slate-100 flex items-center justify-center text-xs text-slate-500">
                      Dynamic component renders inside app
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>

        <section id="programs" className="py-16">
          <div className="text-center max-w-3xl mx-auto space-y-4">
            <h2 className="text-3xl font-semibold text-slate-900">Multiple program options tailored to your workforce</h2>
            <p className="text-slate-600">
              Mix and match incentives to suit different roles and business units. Derayah keeps grant rules, vesting logic, and accounting synchronized.
            </p>
          </div>
          <div className="mt-10 grid md:grid-cols-3 gap-6">
            {programOptions.map(option => (
              <div
                key={option.title}
                className={`rounded-3xl border border-slate-200 bg-white shadow-sm shadow-slate-900/5 p-6 space-y-4 bg-gradient-to-br ${option.color}`}
              >
                <div className="flex items-center gap-3">
                  <Layers className="w-6 h-6 text-blue-600" />
                  <h3 className="text-xl font-semibold text-slate-900">{option.title}</h3>
                </div>
                <p className="text-sm text-slate-600 leading-relaxed">{option.description}</p>
                <ul className="space-y-2 text-sm text-slate-600">
                  {option.points.map(point => (
                    <li key={point} className="flex items-start gap-2">
                      <span className="mt-1 w-2 h-2 rounded-full bg-blue-500" />
                      <span>{point}</span>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </section>

        <section id="workflows" className="py-16 border-t border-slate-200">
          <div className="grid lg:grid-cols-[1.1fr_0.9fr] gap-10 lg:gap-16 items-center">
            <div className="space-y-6">
              <h2 className="text-3xl font-semibold text-slate-900">Create contracts in minutes with guided workflows</h2>
              <p className="text-slate-600 leading-relaxed">
                Our contract engine mirrors Ebana’s seamless experience: generate localized agreements, assign reviewers, and notify employees automatically—all without leaving the platform.
              </p>
              <ul className="space-y-4">
                {workflowHighlights.map(item => (
                  <li key={item.title} className="rounded-2xl border border-slate-200 bg-white p-4">
                    <div className="flex items-center gap-3">
                      <PenSquare className="w-5 h-5 text-blue-600" />
                      <h3 className="text-lg font-semibold text-slate-900">{item.title}</h3>
                    </div>
                    <p className="mt-2 text-sm text-slate-600 leading-relaxed">{item.detail}</p>
                  </li>
                ))}
              </ul>
              <div className="flex flex-wrap gap-3">
                <LandingLoginButtons variant="light" />
              </div>
            </div>
            <div className="rounded-3xl border border-slate-200 bg-white shadow-lg shadow-slate-900/10 p-6 space-y-5">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs uppercase tracking-[0.3em] text-slate-500">Contract Workflow</p>
                  <h4 className="text-lg font-semibold text-slate-900">Grant Acceptance Queue</h4>
                </div>
                <PenSquare className="w-5 h-5 text-blue-600" />
              </div>
              <div className="space-y-3">
                {[
                  { name: 'Aisha Al-Mutairi', plan: 'Leadership RSU 2024', stage: 'Awaiting legal review', tone: 'text-amber-600' },
                  { name: 'Hassan Al-Shehri', plan: 'Tech ESOP Refresh', stage: 'Employee signature pending', tone: 'text-blue-600' },
                  { name: 'Noura Al-Qahtani', plan: 'SAR Bonus Plan', stage: 'Fully executed • archived', tone: 'text-emerald-600' }
                ].map(row => (
                  <div key={row.name} className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm font-semibold text-slate-900">{row.name}</p>
                        <p className="text-xs text-slate-500">{row.plan}</p>
                      </div>
                      <span className={`text-xs font-semibold ${row.tone}`}>{row.stage}</span>
                    </div>
                  </div>
                ))}
              </div>
              <div className="rounded-2xl border border-blue-100 bg-blue-50 px-4 py-3">
                <p className="text-xs uppercase tracking-[0.3em] text-blue-500">Automations</p>
                <p className="text-sm text-blue-900 mt-2">
                  Reminder cadence, approver delegation, and document redlining are configurable per plan template.
                </p>
              </div>
            </div>
          </div>
        </section>

        <section id="support" className="py-16 border-t border-slate-200">
          <div className="text-center max-w-3xl mx-auto space-y-4">
            <h2 className="text-3xl font-semibold text-slate-900">Legal support every step of the way</h2>
            <p className="text-slate-600">
              Partner with our experts or bring your own counsel. Derayah centralizes templates, reviews, and approvals inside one source of truth.
            </p>
          </div>
          <div className="mt-10 grid md:grid-cols-3 gap-6">
            {supportHighlights.map(item => (
              <div key={item.title} className="rounded-3xl border border-slate-200 bg-white shadow-sm shadow-slate-900/5 p-6 space-y-4">
                <item.icon className="w-8 h-8 text-blue-600" />
                <h3 className="text-lg font-semibold text-slate-900">{item.title}</h3>
                <p className="text-sm text-slate-600 leading-relaxed">{item.description}</p>
              </div>
            ))}
          </div>
        </section>

        <section id="movement" className="py-16 border-t border-slate-200">
          <div className="grid lg:grid-cols-[1fr_1fr] gap-12 items-start">
            <div className="space-y-6">
              <h2 className="text-3xl font-semibold text-slate-900">End-to-end grant lifecycle captured in the platform</h2>
              <p className="text-slate-600 leading-relaxed">
                From plan creation to employee payout, Derayah records every decision, approval, and share movement. The timeline below maps the exact touchpoints stakeholders experience.
              </p>
              <div className="rounded-3xl border border-slate-200 bg-white shadow-sm shadow-slate-900/5 p-6 space-y-4">
                <p className="text-xs uppercase tracking-[0.3em] text-slate-500">Share movement timeline</p>
                <div className="relative">
                  <div className="absolute left-4 top-0 bottom-2 w-px bg-slate-200" />
                  <div className="space-y-6 pl-12">
                    {shareMovementTimeline.map(step => (
                      <div key={step.stage} className="relative">
                        <div className="absolute -left-12 top-1 w-8 h-8 rounded-full border-4 border-white bg-blue-500 shadow shadow-blue-200 flex items-center justify-center text-xs font-semibold text-white">
                          {step.timestamp}
                        </div>
                        <h3 className="text-lg font-semibold text-slate-900">{step.stage}</h3>
                        <p className="text-sm text-slate-600 mt-1 leading-relaxed">{step.detail}</p>
                        <p className="text-xs uppercase tracking-[0.3em] text-blue-500 mt-2">
                          {step.actors.join(' • ')}
                        </p>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
            <div className="rounded-3xl border border-slate-200 bg-white shadow-lg shadow-slate-900/10 p-6 space-y-5">
              <div>
                <p className="text-xs uppercase tracking-[0.3em] text-slate-500">Live vesting view</p>
                <h3 className="text-lg font-semibold text-slate-900 mt-1">Employee journey preview</h3>
              </div>
              <div className="rounded-2xl border border-blue-100 bg-blue-50 p-4 space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-semibold text-blue-900">Upcoming vesting event</span>
                  <span className="text-xs font-semibold text-blue-600 bg-white/70 px-3 py-1 rounded-full">Due in 6 days</span>
                </div>
                <p className="text-sm text-blue-800">
                  4,200 shares vest on 15 February 2026 for Growth RSU 2025. FMV SAR 44.3.
                </p>
                <div className="h-2 w-full bg-white rounded-full overflow-hidden">
                  <div className="h-full bg-gradient-to-r from-blue-500 to-blue-600" style={{ width: '68%' }} />
                </div>
                <p className="text-xs text-blue-700">68% of grant vested • performance certified</p>
              </div>
              <div className="rounded-2xl border border-slate-100 bg-slate-50 p-4 space-y-3">
                <div className="flex items-center justify-between text-xs text-slate-500">
                  <span>Timeline checkpoints</span>
                  <span>Auto reminders enabled</span>
                </div>
                <div className="space-y-2 text-sm text-slate-700">
                  <div className="flex items-center justify-between rounded-xl bg-white px-3 py-2">
                    <span>Grant accepted</span>
                    <span className="text-blue-600 font-semibold">✔</span>
                  </div>
                  <div className="flex items-center justify-between rounded-xl bg-white px-3 py-2">
                    <span>Performance KPI certified</span>
                    <span className="text-blue-600 font-semibold">✔</span>
                  </div>
                  <div className="flex items-center justify-between rounded-xl bg-white px-3 py-2">
                    <span>Finance approval</span>
                    <span className="text-amber-500 font-semibold">Pending</span>
                  </div>
                  <div className="flex items-center justify-between rounded-xl bg-white px-3 py-2">
                    <span>Employee payout</span>
                    <span className="text-slate-500 font-semibold">Scheduled</span>
                  </div>
                </div>
              </div>
              <div className="rounded-2xl border border-slate-100 bg-white p-4">
                <p className="text-xs uppercase tracking-[0.3em] text-slate-500">Notifications sent</p>
                <ul className="mt-3 space-y-2 text-xs text-slate-600">
                  <li>• Email + SMS reminder to employee with vesting summary</li>
                  <li>• Finance approval task assigned with due date</li>
                  <li>• Board observer notified about liquidity impact</li>
                </ul>
              </div>
            </div>
          </div>
        </section>

        <section id="performance" className="py-16 border-t border-slate-200">
          <div className="grid lg:grid-cols-[0.9fr_1.1fr] gap-10 lg:gap-16 items-center">
            <div className="space-y-6">
              <h2 className="text-3xl font-semibold text-slate-900">Performance-based vesting schedules made simple</h2>
              <p className="text-slate-600 leading-relaxed">
                Align vesting milestones with KPIs, OKRs, and qualitative milestones. Finance, HR, and leaders stay synchronized through shared dashboards and certification workflows.
              </p>
              <ul className="space-y-3 text-sm text-slate-600">
                <li className="flex items-start gap-3">
                  <span className="mt-1 w-2 h-2 rounded-full bg-blue-500" />
                  <span>Define single or double-trigger vesting without complex spreadsheets.</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="mt-1 w-2 h-2 rounded-full bg-blue-500" />
                  <span>Capture committee approvals with timestamps, commentary, and supporting documents.</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="mt-1 w-2 h-2 rounded-full bg-blue-500" />
                  <span>Trigger vesting updates automatically once performance thresholds are met.</span>
                </li>
              </ul>
            </div>
            <div className="rounded-3xl border border-slate-200 bg-white shadow-lg shadow-slate-900/10 p-6 space-y-5">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs uppercase tracking-[0.3em] text-slate-500">Performance Console</p>
                  <h4 className="text-lg font-semibold text-slate-900">KPIs driving vesting</h4>
                </div>
                <LineChart className="w-5 h-5 text-blue-600" />
              </div>
              <div className="grid sm:grid-cols-2 gap-4">
                {[
                  { label: 'Revenue CAGR', value: '118%', status: 'Ahead of plan' },
                  { label: 'Customer Retention', value: '96%', status: 'Met threshold' },
                  { label: 'EBITDA Margin', value: '22%', status: 'Pending finance review' },
                  { label: 'Product OKRs', value: '84%', status: 'Above target' }
                ].map(item => (
                  <div key={item.label} className="rounded-2xl border border-slate-200 bg-slate-50 p-4">
                    <p className="text-xs font-medium text-slate-500 uppercase tracking-wide">{item.label}</p>
                    <p className="text-xl font-semibold text-slate-900 mt-2">{item.value}</p>
                    <p className="text-xs text-blue-600 mt-1">{item.status}</p>
                  </div>
                ))}
              </div>
              <div className="rounded-2xl border border-blue-100 bg-blue-50 px-4 py-3">
                <p className="text-xs uppercase tracking-[0.3em] text-blue-500">Certification queue</p>
                <div className="mt-3 space-y-2">
                  {[
                    { plan: 'Series C RSU', status: 'Awaiting CFO sign-off' },
                    { plan: 'Corporate SAR', status: 'Legal review in progress' }
                  ].map(item => (
                    <div key={item.plan} className="flex items-center justify-between rounded-xl bg-white border border-blue-100 px-4 py-2 text-xs font-medium text-blue-700">
                      <span>{item.plan}</span>
                      <span>{item.status}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="history" className="py-16 border-t border-slate-200">
          <div className="grid lg:grid-cols-[1.1fr_0.9fr] gap-10 lg:gap-16 items-center">
            <div className="space-y-6">
              <h2 className="text-3xl font-semibold text-slate-900">Comprehensive transaction history at your fingertips</h2>
              <p className="text-slate-600 leading-relaxed">
                Track every grant, vesting event, exercise, and liquidity action with immutable logs. Export data for auditors or leadership in a single click.
              </p>
              <div className="grid sm:grid-cols-3 gap-4">
                {transactionHistory.map(item => (
                  <div key={item.label} className="rounded-2xl border border-slate-200 bg-white shadow-sm p-4">
                    <p className="text-xs font-medium text-slate-500 uppercase tracking-wide">{item.label}</p>
                    <p className="text-xl font-semibold text-slate-900 mt-2">{item.value}</p>
                    <p className="text-xs text-slate-500 mt-1">{item.meta}</p>
                  </div>
                ))}
              </div>
            </div>
            <div className="rounded-3xl border border-slate-200 bg-white shadow-lg shadow-slate-900/10 p-6 space-y-5">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs uppercase tracking-[0.3em] text-slate-500">Equity Ledger</p>
                  <h4 className="text-lg font-semibold text-slate-900">Recent activity</h4>
                </div>
                <Users className="w-5 h-5 text-blue-600" />
              </div>
              <div className="space-y-3 text-sm text-slate-600">
                {[
                  { actor: 'Finance Team', action: 'Exported IFRS 2 expense schedule for Q4 2025' },
                  { actor: 'Legal Counsel', action: 'Approved accelerated vesting for exit event' },
                  { actor: 'Employee (ID 2045)', action: 'Exercised 2,400 options • triggered tax calculator notification' }
                ].map(entry => (
                  <div key={entry.action} className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3">
                    <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">{entry.actor}</p>
                    <p className="mt-1 text-slate-700">{entry.action}</p>
                  </div>
                ))}
              </div>
              <div className="rounded-2xl border border-blue-100 bg-blue-50 px-4 py-3 text-xs text-blue-700">
                Download full history as CSV, Excel, or push to your data warehouse via secure API.
              </div>
            </div>
          </div>
        </section>

        <section id="contact" className="py-16 border-t border-slate-200">
          <div className="rounded-3xl border border-slate-200 bg-white shadow-sm shadow-slate-900/5 p-8 md:p-10 grid lg:grid-cols-[1fr_1fr] gap-10">
            <div className="space-y-6">
              <h2 className="text-3xl font-semibold text-slate-900">Speak with an equity specialist</h2>
              <p className="text-slate-600 leading-relaxed">
                We’ll walk you through program design, onboarding, and stakeholder training. Discover how Derayah aligns with your equity strategy and regulatory commitments.
              </p>
              <div className="space-y-4 text-sm text-slate-600">
                <div className="flex items-center gap-3">
                  <Phone className="w-5 h-5 text-blue-600" />
                  <span>+966 11 200 2054</span>
                </div>
                <div className="flex items-center gap-3">
                  <Mail className="w-5 h-5 text-blue-600" />
                  <span>support@derayah.com</span>
                </div>
                <div className="flex items-center gap-3">
                  <Building2 className="w-5 h-5 text-blue-600" />
                  <span>Riyadh • Saudi Arabia</span>
                </div>
              </div>
              <LandingLoginButtons variant="light" />
            </div>
            <div className="space-y-6">
              <div>
                <p className="text-xs uppercase tracking-[0.3em] text-slate-500">Contact form</p>
                <h3 className="text-lg font-semibold text-slate-900 mt-1">Request a tailored demo</h3>
              </div>
              <form className="space-y-4">
                <div className="grid sm:grid-cols-2 gap-4">
                  <input
                    type="text"
                    placeholder="Full name"
                    className="px-4 py-3 rounded-xl border border-slate-200 bg-slate-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white"
                  />
                  <input
                    type="email"
                    placeholder="Work email"
                    className="px-4 py-3 rounded-xl border border-slate-200 bg-slate-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white"
                  />
                </div>
                <input
                  type="text"
                  placeholder="Company name"
                  className="w-full px-4 py-3 rounded-xl border border-slate-200 bg-slate-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white"
                />
                <textarea
                  placeholder="Tell us about your equity program goals..."
                  rows={4}
                  className="w-full px-4 py-3 rounded-xl border border-slate-200 bg-slate-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white resize-none"
                ></textarea>
                <button
                  type="submit"
                  className="inline-flex items-center gap-3 px-6 py-3 rounded-xl bg-blue-600 text-white font-semibold hover:bg-blue-500 transition"
                >
                  Submit Request
                  <ArrowRight className="w-4 h-4" />
                </button>
              </form>
            </div>
          </div>
        </section>
      </main>

      <footer className="border-t border-slate-200 bg-slate-50">
        <div className="max-w-6xl mx-auto px-6 py-8 text-sm text-slate-600 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <p>© {new Date().getFullYear()} Derayah Equity Studio. All rights reserved.</p>
          <div className="flex items-center gap-6">
            <Link to="/concept1" className="hover:text-blue-600 transition">Concept 1</Link>
            <Link to="/concept2" className="hover:text-blue-600 transition">Concept 2</Link>
            <Link to="/concept3" className="hover:text-blue-600 transition">Concept 3</Link>
            <Link to="/login" className="hover:text-blue-600 transition">Admin Login</Link>
            <Link to="/employee/login" className="hover:text-blue-600 transition">Employee Login</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}

