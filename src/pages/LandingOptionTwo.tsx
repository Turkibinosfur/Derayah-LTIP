import { Link } from 'react-router-dom';
import { useMemo } from 'react';
import {
  ArrowRight,
  LayoutDashboard,
  Layers,
  Activity,
  Users2,
  ShieldCheck,
  Building,
  LineChart,
  PlayCircle,
  Sparkle,
  PieChart
} from 'lucide-react';
import LandingLoginButtons from '../components/LandingLoginButtons';

const pillars = [
  {
    icon: LayoutDashboard,
    title: 'Unified Equity Cockpit',
    description:
      'Real-time dilution, expense, and vesting forecasts with drill downs by entity, plan, and grant. Export to IFRS 2 and zakat-ready formats instantly.'
  },
  {
    icon: Layers,
    title: 'Multi-Plan Engine',
    description:
      'Spin up ESOP, RSU, SAR, and phantom plans with configurable triggers, double-cliff vesting, and automated document packs in Arabic and English.'
  },
  {
    icon: Activity,
    title: 'Performance Automation',
    description:
      'Connect OKRs and KPIs, apply attainment weighting, and trigger partial or full vesting updates as performance committees approve metrics.'
  },
  {
    icon: Users2,
    title: 'Stakeholder Portals',
    description:
      'Dedicated experiences for SaaS operators, company admins, and employees with tailored dashboards, approvals, and messaging workflows.'
  }
];

const timelineSteps = [
  {
    title: 'Plan Design Studio',
    detail: 'Configure vesting logic, map eligibility, and preview expense forecasts before launch.',
    highlight: 'Visibility controls ensure governance teams approve every change.'
  },
  {
    title: 'Grant & Contract Automation',
    detail: 'Instant document generation, digital acceptance, and bilingual notifications with full audit trails.',
    highlight: 'Automated reminders keep employees on track for approvals.'
  },
  {
    title: 'Vesting Orchestration',
    detail: 'Time, performance, and manual vesting events sync across finance, HR, and cap table views.',
    highlight: 'Exception handling covers accelerations, forfeitures, and transfers.'
  },
  {
    title: 'Liquidity & Exit Support',
    detail: 'Manage buybacks, secondary events, and IPO readiness with scenario planning and record-keeping.',
    highlight: 'Single source of truth for compliance attestation.'
  }
];

const comparisonPoints = [
  {
    title: 'Why not spreadsheets?',
    bullets: [
      'Manual workflows risk data drift and missed vesting deadlines.',
      'No built-in audit history or approval routing for compliance.',
      'Employee communication is fragmented and difficult to track.'
    ]
  },
  {
    title: 'Why not generic equity tools?',
    bullets: [
      'Limited localization for Saudi governance and zakat treatment.',
      'No bi-lingual contract automation or CMA-aligned reporting.',
      'Performance vesting often requires custom development.'
    ]
  },
  {
    title: 'Why Derayah Equity Studio?',
    bullets: [
      'Purpose-built for GCC corporates and high-growth scaleups.',
      'SaaS operator console alongside company and employee portals.',
      'Embedded performance workflows and compliance frameworks.'
    ]
  }
];

const heroScreenshot = [
  {
    title: 'Plan Runway',
    metric: '36 active plans',
    delta: '+12% YoY',
    accent: 'bg-blue-500/10 text-blue-600'
  },
  {
    title: 'Employee Engagement',
    metric: '92% contracts signed',
    delta: '3 day avg.',
    accent: 'bg-emerald-500/10 text-emerald-600'
  },
  {
    title: 'Equity Expense',
    metric: 'SAR 18.6M',
    delta: 'Q4 forecast',
    accent: 'bg-purple-500/10 text-purple-600'
  }
];

const useLoopedGradientStyle = () =>
  useMemo(
    () => ({
      backgroundImage:
        'radial-gradient(circle at top left, rgba(59,130,246,0.08), transparent 40%), radial-gradient(circle at bottom right, rgba(14,165,233,0.08), transparent 35%)'
    }),
    []
  );

export default function LandingOptionTwo() {
  const heroBgStyle = useLoopedGradientStyle();

  return (
    <div className="bg-white min-h-screen text-slate-900">
      <header className="sticky top-0 z-30 backdrop-blur-lg bg-white/70 border-b border-slate-200">
        <div className="max-w-6xl mx-auto px-6 py-5 flex items-center justify-between gap-6">
          <Link to="/concept2" className="inline-flex items-center gap-2">
            <Sparkle className="w-5 h-5 text-blue-600" />
            <span className="text-lg font-semibold tracking-tight text-slate-900">Derayah Equity Studio</span>
          </Link>
          <nav className="hidden md:flex items-center gap-8 text-sm font-medium text-slate-600">
            <a href="#pillars" className="hover:text-blue-600 transition">Pillars</a>
            <a href="#tour" className="hover:text-blue-600 transition">Guided Tour</a>
            <a href="#comparison" className="hover:text-blue-600 transition">Why Derayah</a>
            <a href="#proof" className="hover:text-blue-600 transition">Proof</a>
          </nav>
          <LandingLoginButtons variant="light" align="center" />
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-6">
        <section className="py-16 md:py-20 flex flex-col-reverse lg:flex-row items-center gap-12 lg:gap-16">
          <div className="flex-1 space-y-6">
            <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-700">
              <ShieldCheck className="w-4 h-4" />
              CMA-aligned Equity Platform
            </span>
            <h1 className="text-4xl md:text-5xl font-semibold tracking-tight leading-tight">
              Orchestrate equity programs from plan design to liquidity in a single, compliant platform.
            </h1>
            <p className="text-lg text-slate-600 leading-relaxed">
              Inspired by leading ESOP platforms like Ebana and Xumane, Derayah Equity Studio layers local compliance controls, performance automation, and multi-tenant SaaS operations to deliver a truly end-to-end equity experience.
            </p>
            <div className="flex flex-col sm:flex-row gap-4">
              <Link
                to="/login"
                className="inline-flex items-center justify-center gap-3 px-6 py-3 rounded-xl bg-blue-600 text-white font-semibold shadow-sm shadow-blue-600/20 hover:bg-blue-500 transition"
              >
                Launch SaaS Console
                <ArrowRight className="w-4 h-4" />
              </Link>
              <Link
                to="/employee/login"
                className="inline-flex items-center justify-center gap-3 px-6 py-3 rounded-xl border border-slate-200 text-slate-700 hover:border-blue-200 hover:text-blue-600 transition"
              >
                Explore Employee Portal
              </Link>
            </div>
          </div>

          <div className="flex-1 w-full">
            <div className="rounded-3xl border border-slate-200 bg-white shadow-xl shadow-slate-900/[0.03] overflow-hidden" style={heroBgStyle}>
              <div className="px-6 py-5 border-b border-slate-200 flex items-center justify-between">
                <div>
                  <p className="text-xs uppercase tracking-wide text-slate-500">Operational Snapshot</p>
                  <h3 className="text-xl font-semibold text-slate-900 mt-1">Admin Control Center</h3>
                </div>
                <span className="inline-flex items-center gap-2 text-xs font-semibold text-emerald-600 bg-emerald-100 px-3 py-1 rounded-full">
                  Live Sync
                  <Activity className="w-3 h-3" />
                </span>
              </div>
              <div className="p-6 space-y-6">
                <div className="grid sm:grid-cols-3 gap-4">
                  {heroScreenshot.map(card => (
                    <div key={card.title} className={`rounded-2xl border border-slate-200 bg-white p-5 flex flex-col gap-2`}>
                      <p className="text-xs font-medium text-slate-500 uppercase tracking-wide">{card.title}</p>
                      <p className="text-2xl font-semibold text-slate-900">{card.metric}</p>
                      <span className={`inline-flex w-max items-center gap-2 text-xs font-semibold ${card.accent} px-2.5 py-1 rounded-full`}>
                        {card.delta}
                      </span>
                    </div>
                  ))}
                </div>

                <div className="rounded-2xl border border-slate-200 bg-slate-50 p-5">
                  <div className="flex items-center justify-between mb-3">
                    <div>
                      <p className="text-xs uppercase tracking-[0.3em] text-slate-500">Vesting Timeline</p>
                      <h4 className="text-lg font-semibold text-slate-900">Next 90 Days</h4>
                    </div>
                    <span className="inline-flex items-center gap-1 text-xs font-medium text-blue-600">
                      Auto reminders enabled
                      <ArrowRight className="w-3 h-3" />
                    </span>
                  </div>
                  <div className="space-y-3">
                    {[
                      { plan: 'Executive RSU 2025', date: 'Jan 24', status: 'Performance KPI certified', tone: 'text-emerald-600' },
                      { plan: 'Tech ESOP Refresh', date: 'Feb 08', status: 'Time-based milestone approaching', tone: 'text-blue-600' },
                      { plan: 'Saudi LTIP 2024', date: 'Mar 12', status: 'Legal review complete • ready to process', tone: 'text-purple-600' }
                    ].map(item => (
                      <div key={item.plan} className="bg-white border border-slate-200 rounded-xl px-4 py-3 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
                        <div>
                          <p className="text-sm font-semibold text-slate-900">{item.plan}</p>
                          <p className={`text-xs font-medium ${item.tone}`}>{item.status}</p>
                        </div>
                        <span className="inline-flex items-center justify-center px-3 py-1 text-xs font-semibold text-slate-700 bg-slate-100 rounded-full">
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

        <section id="pillars" className="py-16 border-t border-slate-200">
          <div className="max-w-4xl">
            <h2 className="text-3xl font-semibold text-slate-900">Four pillars inspired by modern equity leaders</h2>
            <p className="mt-4 text-slate-600">
              We studied platforms such as Ebana&apos;s ESOP solution and Xumane&apos;s RSU management to deliver a localized system with deeper performance automation, bilingual communication, and multi-tenant governance controls.
            </p>
          </div>

          <div className="mt-10 grid md:grid-cols-2 gap-6">
            {pillars.map(pillar => (
              <div key={pillar.title} className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm shadow-slate-900/[0.04]">
                <div className="w-12 h-12 rounded-2xl bg-blue-50 flex items-center justify-center text-blue-600 mb-4">
                  <pillar.icon className="w-6 h-6" />
                </div>
                <h3 className="text-xl font-semibold text-slate-900">{pillar.title}</h3>
                <p className="mt-3 text-sm text-slate-600 leading-relaxed">{pillar.description}</p>
              </div>
            ))}
          </div>
        </section>

        <section id="tour" className="py-16 border-t border-slate-200">
          <div className="flex flex-col lg:flex-row gap-10 lg:gap-16">
            <div className="flex-1 space-y-6">
              <h2 className="text-3xl font-semibold text-slate-900">A guided tour through your equity lifecycle</h2>
              <p className="text-slate-600">
                Follow the journey from plan ideation to liquidity. Each step combines automation with human approvals to keep governance tight while enabling speed.
              </p>
              <div className="space-y-5">
                {timelineSteps.map((step, idx) => (
                  <div key={step.title} className="rounded-3xl border border-slate-200 bg-gradient-to-r from-white to-slate-50 p-6 relative overflow-hidden">
                    <div className="absolute top-6 right-6 text-6xl font-bold text-slate-100">{idx + 1}</div>
                    <h3 className="text-lg font-semibold text-slate-900">{step.title}</h3>
                    <p className="mt-2 text-sm text-slate-600">{step.detail}</p>
                    <div className="mt-3 inline-flex items-center gap-2 text-xs font-semibold text-blue-600 bg-blue-100 px-3 py-1 rounded-full">
                      <PlayCircle className="w-4 h-4" />
                      {step.highlight}
                    </div>
                  </div>
                ))}
              </div>
            </div>
            <div className="flex-1">
              <div className="sticky top-24">
                <div className="rounded-3xl border border-blue-100 bg-blue-50 p-6 space-y-6">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-2xl bg-white flex items-center justify-center text-blue-600">
                      <LineChart className="w-6 h-6" />
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-[0.2em] text-blue-500">Live shot</p>
                      <h3 className="text-lg font-semibold text-blue-900">Performance KPI Console</h3>
                    </div>
                  </div>
                  <div className="rounded-2xl bg-white border border-blue-100 p-5 space-y-4 shadow-sm">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-semibold text-slate-900">Metric Attainment</span>
                      <span className="inline-flex items-center gap-2 text-xs font-semibold text-emerald-600 bg-emerald-100 px-2.5 py-1 rounded-full">
                        Real-time sync
                      </span>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      {[
                        { label: 'Revenue CAGR', value: '118%' },
                        { label: 'EBITDA Margin', value: '26%' },
                        { label: 'NPS', value: '72' },
                        { label: 'Product OKRs', value: '84%' }
                      ].map(item => (
                        <div key={item.label} className="rounded-xl border border-blue-100 bg-blue-50/60 p-4">
                          <p className="text-xs font-medium text-blue-500 uppercase tracking-wide">{item.label}</p>
                          <p className="text-xl font-semibold text-blue-900 mt-1">{item.value}</p>
                        </div>
                      ))}
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-[0.2em] text-blue-500 mb-2">Approval queue</p>
                      <div className="space-y-2">
                        {[
                          { plan: 'Series C RSU', status: 'Awaiting CFO sign-off' },
                          { plan: 'Corporate Bonus SAR', status: 'Performance met • releasing 40%' }
                        ].map(item => (
                          <div key={item.plan} className="flex items-center justify-between px-4 py-2 rounded-xl bg-blue-100">
                            <span className="text-sm font-medium text-blue-800">{item.plan}</span>
                            <span className="text-xs font-semibold text-blue-600">{item.status}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                  <p className="text-xs text-blue-700 leading-relaxed">
                    This is a rendered view from the actual performance metrics dashboard, showcasing how KPIs drive vesting decisions with audit-ready approvals.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="comparison" className="py-16 border-t border-slate-200">
          <div className="grid lg:grid-cols-3 gap-8">
            {comparisonPoints.map(block => (
              <div key={block.title} className="rounded-3xl border border-slate-200 bg-white p-7 shadow-sm">
                <h3 className="text-lg font-semibold text-slate-900">{block.title}</h3>
                <ul className="mt-4 space-y-3 text-sm text-slate-600">
                  {block.bullets.map(point => (
                    <li key={point} className="flex items-start gap-3">
                      <span className="w-1.5 h-1.5 rounded-full bg-blue-500 mt-2"></span>
                      <span>{point}</span>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </section>

        <section id="proof" className="py-16 border-t border-slate-200">
          <div className="bg-gradient-to-r from-blue-600 to-sky-500 rounded-4xl text-white px-8 py-10 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-10">
            <div className="space-y-5 max-w-xl">
              <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-white/10">
                <PieChart className="w-4 h-4" />
                Trusted across GCC enterprises
              </span>
              <h2 className="text-3xl font-semibold leading-tight">
                Drive higher employee engagement and reduce equity administration effort by 60%.
              </h2>
              <p className="text-sm text-white/80">
                Companies leverage Derayah to automate vesting events, orchestrate performance committees, and keep finance, HR, and legal perfectly aligned.
              </p>
              <div className="grid sm:grid-cols-3 gap-4 text-left">
                {[
                  { label: 'Employee adoption', value: '96%' },
                  { label: 'Audit readiness', value: '100%' },
                  { label: 'Time saved monthly', value: '42 hrs' }
                ].map(item => (
                  <div key={item.label} className="rounded-2xl bg-white/10 border border-white/20 px-4 py-5">
                    <p className="text-xs uppercase text-white/70">{item.label}</p>
                    <p className="text-2xl font-semibold text-white mt-1">{item.value}</p>
                  </div>
                ))}
              </div>
            </div>
            <div className="space-y-5">
              <LandingLoginButtons variant="dark" align="center" />
              <p className="text-xs text-white/80">
                Instant demo access available for SaaS operators, company admins, and employee champions. No credit card required.
              </p>
            </div>
          </div>
        </section>
      </main>

      <footer className="border-t border-slate-200 bg-slate-50">
        <div className="max-w-6xl mx-auto px-6 py-8 text-sm text-slate-600 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <p>© {new Date().getFullYear()} Derayah Equity Studio. Crafted in Riyadh.</p>
          <div className="flex items-center gap-6">
            <Link to="/login" className="hover:text-blue-600 transition">SaaS Login</Link>
            <Link to="/login" className="hover:text-blue-600 transition">Company Login</Link>
            <Link to="/employee/login" className="hover:text-blue-600 transition">Employee Login</Link>
            <a href="mailto:support@derayah.com" className="hover:text-blue-600 transition">Contact Support</a>
          </div>
        </div>
      </footer>
    </div>
  );
}

