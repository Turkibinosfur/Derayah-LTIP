import { useTranslation } from 'react-i18next';
import { Building2, UserPlus, Award, FileText, Calendar, ArrowRight, CheckCircle, Clock, TrendingUp, Users, Package, ArrowDown, ArrowUp, Database, Server, Globe, Wallet, Activity } from 'lucide-react';

interface JourneyStep {
  id: string;
  title: string;
  description: string;
  icon: React.ReactNode;
  color: string;
  bgColor: string;
  details: string[];
}

export default function CustomerJourney() {
  const { t } = useTranslation();

  const journeySteps: JourneyStep[] = [
    {
      id: '1',
      title: t('customerJourney.companyOnboarding'),
      description: t('customerJourney.companyOnboardingDesc'),
      icon: <Building2 className="w-8 h-8" />,
      color: 'text-blue-600',
      bgColor: 'bg-blue-50',
      details: [
        t('customerJourney.step1Detail1'),
        t('customerJourney.step1Detail2'),
        t('customerJourney.step1Detail3'),
        t('customerJourney.step1Detail4'),
        t('customerJourney.step1Detail5')
      ]
    },
    {
      id: '2',
      title: t('customerJourney.employeeSetup'),
      description: t('customerJourney.employeeSetupDesc'),
      icon: <UserPlus className="w-8 h-8" />,
      color: 'text-green-600',
      bgColor: 'bg-green-50',
      details: [
        t('customerJourney.step2Detail1'),
        t('customerJourney.step2Detail2'),
        t('customerJourney.step2Detail3'),
        t('customerJourney.step2Detail4'),
        t('customerJourney.step2Detail5')
      ]
    },
    {
      id: '3',
      title: t('customerJourney.ltipPoolCreation'),
      description: t('customerJourney.ltipPoolCreationDesc'),
      icon: <Award className="w-8 h-8" />,
      color: 'text-purple-600',
      bgColor: 'bg-purple-50',
      details: [
        t('customerJourney.step3Detail1'),
        t('customerJourney.step3Detail2'),
        t('customerJourney.step3Detail3'),
        t('customerJourney.step3Detail4'),
        t('customerJourney.step3Detail5')
      ]
    },
    {
      id: '4',
      title: t('customerJourney.incentivePlanCreation'),
      description: t('customerJourney.incentivePlanCreationDesc'),
      icon: <Award className="w-8 h-8" />,
      color: 'text-violet-600',
      bgColor: 'bg-violet-50',
      details: [
        t('customerJourney.step4Detail1'),
        t('customerJourney.step4Detail2'),
        t('customerJourney.step4Detail3'),
        t('customerJourney.step4Detail4'),
        t('customerJourney.step4Detail5')
      ]
    },
    {
      id: '5',
      title: t('customerJourney.grantCreation'),
      description: t('customerJourney.grantCreationDesc'),
      icon: <FileText className="w-8 h-8" />,
      color: 'text-orange-600',
      bgColor: 'bg-orange-50',
      details: [
        t('customerJourney.step5Detail1'),
        t('customerJourney.step5Detail2'),
        t('customerJourney.step5Detail3'),
        t('customerJourney.step5Detail4'),
        t('customerJourney.step5Detail5')
      ]
    },
    {
      id: '6',
      title: t('customerJourney.vestingScheduleGeneration'),
      description: t('customerJourney.vestingScheduleGenerationDesc'),
      icon: <Calendar className="w-8 h-8" />,
      color: 'text-indigo-600',
      bgColor: 'bg-indigo-50',
      details: [
        t('customerJourney.step6Detail1'),
        t('customerJourney.step6Detail2'),
        t('customerJourney.step6Detail3'),
        t('customerJourney.step6Detail4'),
        t('customerJourney.step6Detail5')
      ]
    },
    {
      id: '7',
      title: t('customerJourney.vestingDateArrival'),
      description: t('customerJourney.vestingDateArrivalDesc'),
      icon: <Clock className="w-8 h-8" />,
      color: 'text-yellow-600',
      bgColor: 'bg-yellow-50',
      details: [
        t('customerJourney.step7Detail1'),
        t('customerJourney.step7Detail2'),
        t('customerJourney.step7Detail3'),
        t('customerJourney.step7Detail4'),
        t('customerJourney.step7Detail5')
      ]
    },
    {
      id: '8',
      title: t('customerJourney.shareTransfer'),
      description: t('customerJourney.shareTransferDesc'),
      icon: <TrendingUp className="w-8 h-8" />,
      color: 'text-red-600',
      bgColor: 'bg-red-50',
      details: [
        t('customerJourney.step8Detail1'),
        t('customerJourney.step8Detail2'),
        t('customerJourney.step8Detail3'),
        t('customerJourney.step8Detail4'),
        t('customerJourney.step8Detail5')
      ]
    },
    {
      id: '9',
      title: t('customerJourney.employeePortfolio'),
      description: t('customerJourney.employeePortfolioDesc'),
      icon: <Package className="w-8 h-8" />,
      color: 'text-teal-600',
      bgColor: 'bg-teal-50',
      details: [
        t('customerJourney.step9Detail1'),
        t('customerJourney.step9Detail2'),
        t('customerJourney.step9Detail3'),
        t('customerJourney.step9Detail4'),
        t('customerJourney.step9Detail5')
      ]
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 p-4 sm:p-6 lg:p-8">
      <div className="w-full max-w-[98vw] xl:max-w-[96vw] 2xl:max-w-[95vw] mx-auto">
        {/* Header */}
        <div className="mb-8 text-center">
          <h1 className="text-4xl font-bold text-slate-900 mb-2">
            {t('customerJourney.title')}
          </h1>
          <p className="text-lg text-slate-600">
            {t('customerJourney.subtitle')}
          </p>
        </div>

        {/* Journey Diagram */}
        <div className="bg-white rounded-2xl shadow-xl p-8 mb-8">
          <div className="relative">
            {/* Desktop View - Horizontal Flow */}
            <div className="hidden lg:block">
              <div className="flex items-start justify-between relative">
                {/* Steps */}
                {journeySteps.map((step, index) => (
                  <div key={step.id} className="flex-1 relative z-10">
                    <div className="flex flex-col items-center">
                      {/* Step Circle */}
                      <div className={`relative ${step.bgColor} rounded-full p-6 mb-4 shadow-lg transform transition-all duration-300 hover:scale-110`}>
                        <div className={step.color}>
                          {step.icon}
                        </div>
                        {/* Step Number Badge */}
                        <div className="absolute -top-2 -right-2 bg-slate-900 text-white rounded-full w-8 h-8 flex items-center justify-center text-sm font-bold">
                          {step.id}
                        </div>
                      </div>

                      {/* Step Title */}
                      <h3 className="text-lg font-semibold text-slate-900 mb-2 text-center">
                        {step.title}
                      </h3>

                      {/* Step Description */}
                      <p className="text-sm text-slate-600 text-center mb-3">
                        {step.description}
                      </p>

                      {/* Step Details */}
                      <div className="w-full space-y-1">
                        {step.details.map((detail, detailIndex) => (
                          <div key={detailIndex} className="flex items-start text-xs text-slate-500">
                            <CheckCircle className="w-3 h-3 mt-0.5 mr-1 flex-shrink-0 text-green-500" />
                            <span className="text-left">{detail}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Mobile/Tablet View - Vertical Flow */}
            <div className="lg:hidden space-y-6">
              {journeySteps.map((step, index) => (
                <div key={step.id} className="relative">
                  {/* Connection Arrow */}
                  {index < journeySteps.length - 1 && (
                    <div className="flex justify-center mb-4">
                      <ArrowDown className="w-6 h-6 text-slate-300" />
                    </div>
                  )}

                  {/* Step Card */}
                  <div className={`${step.bgColor} rounded-xl p-6 shadow-lg transform transition-all duration-300 hover:scale-105`}>
                    <div className="flex items-start space-x-4">
                      {/* Step Icon */}
                      <div className={`${step.color} flex-shrink-0`}>
                        <div className="bg-white rounded-full p-3 shadow-md">
                          {step.icon}
                        </div>
                      </div>

                      {/* Step Content */}
                      <div className="flex-1">
                        <div className="flex items-center justify-between mb-2">
                          <h3 className="text-lg font-semibold text-slate-900">
                            {step.title}
                          </h3>
                          <div className="bg-slate-900 text-white rounded-full w-8 h-8 flex items-center justify-center text-sm font-bold">
                            {step.id}
                          </div>
                        </div>
                        <p className="text-sm text-slate-600 mb-3">
                          {step.description}
                        </p>

                        {/* Step Details */}
                        <div className="space-y-2">
                          {step.details.map((detail, detailIndex) => (
                            <div key={detailIndex} className="flex items-start text-xs text-slate-600">
                              <CheckCircle className="w-3 h-3 mt-0.5 mr-2 flex-shrink-0 text-green-500" />
                              <span>{detail}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Process Flow Summary */}
        <div className="bg-white rounded-2xl shadow-xl p-8">
          <h2 className="text-2xl font-bold text-slate-900 mb-6">
            {t('customerJourney.processFlowSummary')}
          </h2>
          
          <div className="grid md:grid-cols-2 gap-6">
            {/* Key Milestones */}
            <div>
              <h3 className="text-lg font-semibold text-slate-900 mb-4 flex items-center">
                <Clock className="w-5 h-5 mr-2 text-blue-600" />
                {t('customerJourney.keyMilestones')}
              </h3>
              <div className="space-y-3">
                <div className="flex items-start p-3 bg-blue-50 rounded-lg">
                  <div className="bg-blue-600 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs font-bold mr-3 flex-shrink-0">1</div>
                  <div>
                    <p className="font-medium text-slate-900">{t('customerJourney.milestone1Title')}</p>
                    <p className="text-sm text-slate-600">{t('customerJourney.milestone1Desc')}</p>
                  </div>
                </div>
                <div className="flex items-start p-3 bg-green-50 rounded-lg">
                  <div className="bg-green-600 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs font-bold mr-3 flex-shrink-0">2</div>
                  <div>
                    <p className="font-medium text-slate-900">{t('customerJourney.milestone2Title')}</p>
                    <p className="text-sm text-slate-600">{t('customerJourney.milestone2Desc')}</p>
                  </div>
                </div>
                <div className="flex items-start p-3 bg-purple-50 rounded-lg">
                  <div className="bg-purple-600 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs font-bold mr-3 flex-shrink-0">3</div>
                  <div>
                    <p className="font-medium text-slate-900">{t('customerJourney.milestone3Title')}</p>
                    <p className="text-sm text-slate-600">{t('customerJourney.milestone3Desc')}</p>
                  </div>
                </div>
                <div className="flex items-start p-3 bg-violet-50 rounded-lg">
                  <div className="bg-violet-600 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs font-bold mr-3 flex-shrink-0">4</div>
                  <div>
                    <p className="font-medium text-slate-900">{t('customerJourney.milestone4Title')}</p>
                    <p className="text-sm text-slate-600">{t('customerJourney.milestone4Desc')}</p>
                  </div>
                </div>
                <div className="flex items-start p-3 bg-orange-50 rounded-lg">
                  <div className="bg-orange-600 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs font-bold mr-3 flex-shrink-0">5</div>
                  <div>
                    <p className="font-medium text-slate-900">{t('customerJourney.milestone5Title')}</p>
                    <p className="text-sm text-slate-600">{t('customerJourney.milestone5Desc')}</p>
                  </div>
                </div>
                <div className="flex items-start p-3 bg-red-50 rounded-lg">
                  <div className="bg-red-600 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs font-bold mr-3 flex-shrink-0">6</div>
                  <div>
                    <p className="font-medium text-slate-900">{t('customerJourney.milestone6Title')}</p>
                    <p className="text-sm text-slate-600">{t('customerJourney.milestone6Desc')}</p>
                  </div>
                </div>
              </div>
            </div>

            {/* System Features */}
            <div>
              <h3 className="text-lg font-semibold text-slate-900 mb-4 flex items-center">
                <TrendingUp className="w-5 h-5 mr-2 text-green-600" />
                {t('customerJourney.systemFeatures')}
              </h3>
              <div className="space-y-3">
                <div className="p-3 bg-slate-50 rounded-lg">
                  <p className="font-medium text-slate-900 mb-1">{t('customerJourney.feature1Title')}</p>
                  <p className="text-sm text-slate-600">{t('customerJourney.feature1Desc')}</p>
                </div>
                <div className="p-3 bg-slate-50 rounded-lg">
                  <p className="font-medium text-slate-900 mb-1">{t('customerJourney.feature2Title')}</p>
                  <p className="text-sm text-slate-600">{t('customerJourney.feature2Desc')}</p>
                </div>
                <div className="p-3 bg-slate-50 rounded-lg">
                  <p className="font-medium text-slate-900 mb-1">{t('customerJourney.feature3Title')}</p>
                  <p className="text-sm text-slate-600">{t('customerJourney.feature3Desc')}</p>
                </div>
                <div className="p-3 bg-slate-50 rounded-lg">
                  <p className="font-medium text-slate-900 mb-1">{t('customerJourney.feature4Title')}</p>
                  <p className="text-sm text-slate-600">{t('customerJourney.feature4Desc')}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Timeline Visualization */}
        <div className="mt-8 bg-white rounded-2xl shadow-xl p-8">
          <h2 className="text-2xl font-bold text-slate-900 mb-6">
            {t('customerJourney.timeline')}
          </h2>
          <div className="relative">
            <div className="absolute left-8 top-0 bottom-0 w-0.5 bg-gradient-to-b from-blue-500 via-green-500 via-purple-500 via-violet-500 via-orange-500 via-indigo-500 via-yellow-500 via-red-500 to-teal-500"></div>
            <div className="space-y-8">
              {journeySteps.map((step, index) => (
                <div key={step.id} className="relative pl-20">
                  <div className={`absolute left-0 top-0 ${step.bgColor} rounded-full p-3 shadow-lg ${step.color}`}>
                    {step.icon}
                  </div>
                  <div className="bg-slate-50 rounded-lg p-4">
                    <div className="flex items-center justify-between mb-2">
                      <h3 className="text-lg font-semibold text-slate-900">{step.title}</h3>
                      <span className="text-xs font-medium text-slate-500">{t('customerJourney.step')} {step.id}</span>
                    </div>
                    <p className="text-sm text-slate-600 mb-2">{step.description}</p>
                    <div className="flex flex-wrap gap-2 mt-3">
                      {step.details.slice(0, 3).map((detail, detailIndex) => (
                        <span key={detailIndex} className="text-xs bg-white px-2 py-1 rounded text-slate-600">
                          {detail}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Rich Picture - Complete Process Flow Diagram */}
        <div className="mt-8 bg-white rounded-2xl shadow-xl p-8 overflow-hidden">
          <h2 className="text-2xl font-bold text-slate-900 mb-6">
            {t('customerJourney.richPicture')}
          </h2>
          <p className="text-sm text-slate-600 mb-6">
            {t('customerJourney.richPictureDesc')}
          </p>
          
          <div className="overflow-x-auto">
            <div className="min-w-[1200px] lg:min-w-full">
              <svg 
                viewBox="0 0 1200 1400" 
                className="w-full h-auto max-w-full"
                style={{ maxHeight: '1400px' }}
              >
                {/* Background Grid */}
                <defs>
                  <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
                    <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#e2e8f0" strokeWidth="0.5"/>
                  </pattern>
                  <marker id="arrowhead" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto">
                    <polygon points="0 0, 10 3, 0 6" fill="#64748b" />
                  </marker>
                  <marker id="arrowhead-blue" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto">
                    <polygon points="0 0, 10 3, 0 6" fill="#3b82f6" />
                  </marker>
                  <marker id="arrowhead-green" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto">
                    <polygon points="0 0, 10 3, 0 6" fill="#10b981" />
                  </marker>
                  <marker id="arrowhead-red" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto">
                    <polygon points="0 0, 10 3, 0 6" fill="#ef4444" />
                  </marker>
                </defs>
                <rect width="100%" height="100%" fill="url(#grid)" opacity="0.3"/>

                {/* Title */}
                <text x="600" y="30" textAnchor="middle" fontSize="24" fontWeight="bold" fill="#1e293b">
                  {t('customerJourney.completeProcessFlow')}
                </text>

                {/* External Systems */}
                <g id="external-systems">
                  {/* Tadawul Market Data */}
                  <rect x="50" y="80" width="180" height="100" rx="10" fill="#fef3c7" stroke="#f59e0b" strokeWidth="2"/>
                  <text x="140" y="110" textAnchor="middle" fontSize="14" fontWeight="bold" fill="#92400e">Tadawul Market</text>
                  <text x="140" y="130" textAnchor="middle" fontSize="12" fill="#78350f">Price Data</text>
                  <text x="140" y="150" textAnchor="middle" fontSize="12" fill="#78350f">API Integration</text>
                  <text x="140" y="170" textAnchor="middle" fontSize="12" fill="#78350f">Real-time Updates</text>
                </g>

                {/* Phase 1: Company Onboarding */}
                <g id="phase1-onboarding">
                  <rect x="300" y="80" width="200" height="120" rx="10" fill="#dbeafe" stroke="#3b82f6" strokeWidth="2"/>
                  <text x="400" y="105" textAnchor="middle" fontSize="16" fontWeight="bold" fill="#1e40af">1. Company Onboarding</text>
                  <text x="400" y="125" textAnchor="middle" fontSize="11" fill="#1e3a8a">• Company Registration</text>
                  <text x="400" y="140" textAnchor="middle" fontSize="11" fill="#1e3a8a">• Admin User Creation</text>
                  <text x="400" y="155" textAnchor="middle" fontSize="11" fill="#1e3a8a">• Portfolio Setup</text>
                  <text x="400" y="170" textAnchor="middle" fontSize="11" fill="#1e3a8a">• Reserved Shares</text>
                  <text x="400" y="185" textAnchor="middle" fontSize="11" fill="#1e3a8a">• Market Data Config</text>
                </g>

                {/* Company Database */}
                <rect x="320" y="220" width="160" height="80" rx="8" fill="#e0e7ff" stroke="#6366f1" strokeWidth="2"/>
                <text x="400" y="245" textAnchor="middle" fontSize="13" fontWeight="bold" fill="#3730a3">Company</text>
                <text x="400" y="265" textAnchor="middle" fontSize="11" fill="#4338ca">• Company Info</text>
                <text x="400" y="280" textAnchor="middle" fontSize="11" fill="#4338ca">• Portfolio</text>
                <text x="400" y="295" textAnchor="middle" fontSize="11" fill="#4338ca">• Market Symbol</text>

                {/* Phase 2: Employee Setup */}
                <g id="phase2-employees">
                  <rect x="600" y="80" width="200" height="120" rx="10" fill="#d1fae5" stroke="#10b981" strokeWidth="2"/>
                  <text x="700" y="105" textAnchor="middle" fontSize="16" fontWeight="bold" fill="#065f46">2. Employee Setup</text>
                  <text x="700" y="125" textAnchor="middle" fontSize="11" fill="#047857">• Employee Record</text>
                  <text x="700" y="140" textAnchor="middle" fontSize="11" fill="#047857">• Auth User Creation</text>
                  <text x="700" y="155" textAnchor="middle" fontSize="11" fill="#047857">• Employee Portfolio</text>
                  <text x="700" y="170" textAnchor="middle" fontSize="11" fill="#047857">• Portal Access</text>
                  <text x="700" y="185" textAnchor="middle" fontSize="11" fill="#047857">• Financial Info</text>
                </g>

                {/* Employees Database */}
                <rect x="620" y="220" width="160" height="80" rx="8" fill="#dcfce7" stroke="#22c55e" strokeWidth="2"/>
                <text x="700" y="245" textAnchor="middle" fontSize="13" fontWeight="bold" fill="#166534">Employees</text>
                <text x="700" y="265" textAnchor="middle" fontSize="11" fill="#15803d">• Employee Data</text>
                <text x="700" y="280" textAnchor="middle" fontSize="11" fill="#15803d">• Auth Users</text>
                <text x="700" y="295" textAnchor="middle" fontSize="11" fill="#15803d">• Portfolios</text>

                {/* Phase 3: LTIP Pool Creation */}
                <g id="phase3-ltip-pools">
                  <rect x="900" y="80" width="200" height="120" rx="10" fill="#f3e8ff" stroke="#a855f7" strokeWidth="2"/>
                  <text x="1000" y="105" textAnchor="middle" fontSize="16" fontWeight="bold" fill="#6b21a8">3. LTIP Pool Creation</text>
                  <text x="1000" y="125" textAnchor="middle" fontSize="11" fill="#7c3aed">• Create LTIP Pool</text>
                  <text x="1000" y="140" textAnchor="middle" fontSize="11" fill="#7c3aed">• Allocate Shares</text>
                  <text x="1000" y="155" textAnchor="middle" fontSize="11" fill="#7c3aed">• Reserve Shares</text>
                  <text x="1000" y="170" textAnchor="middle" fontSize="11" fill="#7c3aed">• Pool Activation</text>
                  <text x="1000" y="185" textAnchor="middle" fontSize="11" fill="#7c3aed">• Pool Management</text>
                </g>

                {/* LTIP Pools Database */}
                <rect x="920" y="220" width="160" height="80" rx="8" fill="#faf5ff" stroke="#c084fc" strokeWidth="2"/>
                <text x="1000" y="245" textAnchor="middle" fontSize="13" fontWeight="bold" fill="#7c3aed">LTIP Pools</text>
                <text x="1000" y="265" textAnchor="middle" fontSize="11" fill="#9333ea">• Pool Records</text>
                <text x="1000" y="280" textAnchor="middle" fontSize="11" fill="#9333ea">• Share Allocation</text>
                <text x="1000" y="295" textAnchor="middle" fontSize="11" fill="#9333ea">• Status</text>

                {/* Phase 4: Incentive Plan Creation */}
                <g id="phase4-plans">
                  <rect x="300" y="350" width="200" height="120" rx="10" fill="#ede9fe" stroke="#8b5cf6" strokeWidth="2"/>
                  <text x="400" y="375" textAnchor="middle" fontSize="16" fontWeight="bold" fill="#5b21b6">4. Incentive Plan</text>
                  <text x="400" y="395" textAnchor="middle" fontSize="11" fill="#6d28d9">• Plan Definition</text>
                  <text x="400" y="410" textAnchor="middle" fontSize="11" fill="#6d28d9">• Link to LTIP Pool</text>
                  <text x="400" y="425" textAnchor="middle" fontSize="11" fill="#6d28d9">• Vesting Templates</text>
                  <text x="400" y="440" textAnchor="middle" fontSize="11" fill="#6d28d9">• Terms & Conditions</text>
                  <text x="400" y="455" textAnchor="middle" fontSize="11" fill="#6d28d9">• Plan Activation</text>
                </g>

                {/* Plans Database */}
                <rect x="320" y="490" width="160" height="80" rx="8" fill="#f5f3ff" stroke="#a78bfa" strokeWidth="2"/>
                <text x="400" y="515" textAnchor="middle" fontSize="13" fontWeight="bold" fill="#6d28d9">Incentive Plans</text>
                <text x="400" y="535" textAnchor="middle" fontSize="11" fill="#7c3aed">• Plan Records</text>
                <text x="400" y="550" textAnchor="middle" fontSize="11" fill="#7c3aed">• Templates</text>
                <text x="400" y="565" textAnchor="middle" fontSize="11" fill="#7c3aed">• Pool Link</text>

                {/* Phase 5: Grant Creation */}
                <g id="phase5-grants">
                  <rect x="600" y="350" width="200" height="120" rx="10" fill="#fed7aa" stroke="#f97316" strokeWidth="2"/>
                  <text x="700" y="375" textAnchor="middle" fontSize="16" fontWeight="bold" fill="#9a3412">5. Grant Creation</text>
                  <text x="700" y="395" textAnchor="middle" fontSize="11" fill="#c2410c">• Grant Document</text>
                  <text x="700" y="410" textAnchor="middle" fontSize="11" fill="#c2410c">• Share Allocation</text>
                  <text x="700" y="425" textAnchor="middle" fontSize="11" fill="#c2410c">• Grant Terms</text>
                  <text x="700" y="440" textAnchor="middle" fontSize="11" fill="#c2410c">• Employee Acceptance</text>
                  <text x="700" y="455" textAnchor="middle" fontSize="11" fill="#c2410c">• Status Tracking</text>
                </g>

                {/* Grants Database */}
                <rect x="620" y="490" width="160" height="80" rx="8" fill="#fff7ed" stroke="#fb923c" strokeWidth="2"/>
                <text x="700" y="515" textAnchor="middle" fontSize="13" fontWeight="bold" fill="#c2410c">Grants</text>
                <text x="700" y="535" textAnchor="middle" fontSize="11" fill="#ea580c">• Grant Records</text>
                <text x="700" y="550" textAnchor="middle" fontSize="11" fill="#ea580c">• Total Shares</text>
                <text x="700" y="565" textAnchor="middle" fontSize="11" fill="#ea580c">• Status</text>

                {/* Phase 6: Vesting Schedule */}
                <g id="phase6-vesting-schedule">
                  <rect x="900" y="350" width="200" height="120" rx="10" fill="#e0e7ff" stroke="#6366f1" strokeWidth="2"/>
                  <text x="1000" y="375" textAnchor="middle" fontSize="16" fontWeight="bold" fill="#3730a3">6. Vesting Schedule</text>
                  <text x="1000" y="395" textAnchor="middle" fontSize="11" fill="#4338ca">• Template Application</text>
                  <text x="1000" y="410" textAnchor="middle" fontSize="11" fill="#4338ca">• Event Generation</text>
                  <text x="1000" y="425" textAnchor="middle" fontSize="11" fill="#4338ca">• Date Calculation</text>
                  <text x="1000" y="440" textAnchor="middle" fontSize="11" fill="#4338ca">• Shares per Event</text>
                  <text x="1000" y="455" textAnchor="middle" fontSize="11" fill="#4338ca">• Cliff Period</text>
                </g>

                {/* Vesting Events Database */}
                <rect x="920" y="490" width="160" height="80" rx="8" fill="#eef2ff" stroke="#818cf8" strokeWidth="2"/>
                <text x="1000" y="515" textAnchor="middle" fontSize="13" fontWeight="bold" fill="#4338ca">Vesting Events</text>
                <text x="1000" y="535" textAnchor="middle" fontSize="11" fill="#4f46e5">• Event Records</text>
                <text x="1000" y="550" textAnchor="middle" fontSize="11" fill="#4f46e5">• Vesting Dates</text>
                <text x="1000" y="565" textAnchor="middle" fontSize="11" fill="#4f46e5">• Status</text>

                {/* Phase 7: Automated Vesting Engine */}
                <g id="phase7-vesting-engine">
                  <rect x="300" y="650" width="200" height="120" rx="10" fill="#fef3c7" stroke="#f59e0b" strokeWidth="2"/>
                  <text x="400" y="675" textAnchor="middle" fontSize="16" fontWeight="bold" fill="#92400e">7. Vesting Engine</text>
                  <text x="400" y="695" textAnchor="middle" fontSize="11" fill="#b45309">• Daily Job (00:00)</text>
                  <text x="400" y="710" textAnchor="middle" fontSize="11" fill="#b45309">• Status Check</text>
                  <text x="400" y="725" textAnchor="middle" fontSize="11" fill="#b45309">• Performance Eval</text>
                  <text x="400" y="740" textAnchor="middle" fontSize="11" fill="#b45309">• Price Fetch</text>
                  <text x="400" y="755" textAnchor="middle" fontSize="11" fill="#b45309">• Event Update</text>
                </g>

                {/* Phase 8: Share Transfer */}
                <g id="phase8-transfer">
                  <rect x="600" y="650" width="200" height="120" rx="10" fill="#fee2e2" stroke="#ef4444" strokeWidth="2"/>
                  <text x="700" y="675" textAnchor="middle" fontSize="16" fontWeight="bold" fill="#991b1b">8. Share Transfer</text>
                  <text x="700" y="695" textAnchor="middle" fontSize="11" fill="#dc2626">• Balance Verify</text>
                  <text x="700" y="710" textAnchor="middle" fontSize="11" fill="#dc2626">• Transfer Execute</text>
                  <text x="700" y="725" textAnchor="middle" fontSize="11" fill="#dc2626">• Record Creation</text>
                  <text x="700" y="740" textAnchor="middle" fontSize="11" fill="#dc2626">• Portfolio Update</text>
                  <text x="700" y="755" textAnchor="middle" fontSize="11" fill="#dc2626">• Audit Log</text>
                </g>

                {/* Share Transfers Database */}
                <rect x="620" y="790" width="160" height="80" rx="8" fill="#fef2f2" stroke="#f87171" strokeWidth="2"/>
                <text x="700" y="815" textAnchor="middle" fontSize="13" fontWeight="bold" fill="#dc2626">Share Transfers</text>
                <text x="700" y="835" textAnchor="middle" fontSize="11" fill="#ef4444">• Transfer Records</text>
                <text x="700" y="850" textAnchor="middle" fontSize="11" fill="#ef4444">• Market Price</text>
                <text x="700" y="865" textAnchor="middle" fontSize="11" fill="#ef4444">• Timestamps</text>

                {/* Phase 9: Employee Portfolio */}
                <g id="phase9-portfolio">
                  <rect x="900" y="650" width="200" height="120" rx="10" fill="#ccfbf1" stroke="#14b8a6" strokeWidth="2"/>
                  <text x="1000" y="675" textAnchor="middle" fontSize="16" fontWeight="bold" fill="#134e4a">9. Employee Portfolio</text>
                  <text x="1000" y="695" textAnchor="middle" fontSize="11" fill="#0d9488">• Vested Shares</text>
                  <text x="1000" y="710" textAnchor="middle" fontSize="11" fill="#0d9488">• Market Value</text>
                  <text x="1000" y="725" textAnchor="middle" fontSize="11" fill="#0d9488">• Dashboard Update</text>
                  <text x="1000" y="740" textAnchor="middle" fontSize="11" fill="#0d9488">• Notification</text>
                  <text x="1000" y="755" textAnchor="middle" fontSize="11" fill="#0d9488">• Reporting</text>
                </g>

                {/* Employee Portfolio Database */}
                <rect x="920" y="790" width="160" height="80" rx="8" fill="#f0fdfa" stroke="#5eead4" strokeWidth="2"/>
                <text x="1000" y="815" textAnchor="middle" fontSize="13" fontWeight="bold" fill="#0d9488">Portfolios</text>
                <text x="1000" y="835" textAnchor="middle" fontSize="11" fill="#14b8a6">• Share Balance</text>
                <text x="1000" y="850" textAnchor="middle" fontSize="11" fill="#14b8a6">• Market Value</text>
                <text x="1000" y="865" textAnchor="middle" fontSize="11" fill="#14b8a6">• History</text>

                {/* Decision Points */}
                <g id="decision-points">
                  {/* Employment Status Check */}
                  <polygon points="500,650 550,680 500,710 450,680" fill="#fef3c7" stroke="#f59e0b" strokeWidth="2"/>
                  <text x="500" y="675" textAnchor="middle" fontSize="11" fontWeight="bold" fill="#92400e">Active?</text>
                  
                  {/* Performance Check */}
                  <polygon points="500,750 550,780 500,810 450,780" fill="#fef3c7" stroke="#f59e0b" strokeWidth="2"/>
                  <text x="500" y="775" textAnchor="middle" fontSize="11" fontWeight="bold" fill="#92400e">Met?</text>
                </g>

                {/* Flow Arrows */}
                {/* External to Company */}
                <line x1="230" y1="130" x2="300" y2="140" stroke="#64748b" strokeWidth="2" markerEnd="url(#arrowhead)"/>
                <text x="265" y="130" fontSize="10" fill="#64748b">Market Data</text>

                {/* Company to Employee */}
                <line x1="500" y1="140" x2="600" y2="140" stroke="#3b82f6" strokeWidth="2" markerEnd="url(#arrowhead-blue)"/>
                <text x="550" y="135" fontSize="10" fill="#3b82f6">Setup</text>

                {/* Employee to LTIP Pools */}
                <line x1="800" y1="140" x2="900" y2="140" stroke="#10b981" strokeWidth="2" markerEnd="url(#arrowhead-green)"/>
                <text x="850" y="135" fontSize="10" fill="#10b981">Create</text>

                {/* Company DB to Employee DB */}
                <line x1="400" y1="300" x2="700" y2="300" stroke="#6366f1" strokeWidth="2" markerEnd="url(#arrowhead)"/>
                <text x="550" y="295" fontSize="10" fill="#6366f1">Link</text>

                {/* LTIP Pools to Plans */}
                <line x1="1000" y1="300" x2="400" y2="350" stroke="#a855f7" strokeWidth="2" markerEnd="url(#arrowhead)"/>
                <text x="700" y="320" fontSize="10" fill="#a855f7">Link Pool</text>

                {/* Plans to Grants */}
                <line x1="500" y1="410" x2="600" y2="410" stroke="#8b5cf6" strokeWidth="2" markerEnd="url(#arrowhead)"/>
                <text x="550" y="405" fontSize="10" fill="#8b5cf6">Allocate</text>

                {/* Employee to Grants */}
                <line x1="700" y1="300" x2="700" y2="410" stroke="#10b981" strokeWidth="2" markerEnd="url(#arrowhead-green)"/>
                <text x="720" y="355" fontSize="10" fill="#10b981">Grant</text>

                {/* Grants to Vesting Schedule */}
                <line x1="800" y1="410" x2="900" y2="410" stroke="#f97316" strokeWidth="2" markerEnd="url(#arrowhead)"/>
                <text x="850" y="405" fontSize="10" fill="#f97316">Generate</text>

                {/* Vesting Schedule to Engine */}
                <line x1="1000" y1="470" x2="400" y2="650" stroke="#6366f1" strokeWidth="2" markerEnd="url(#arrowhead)"/>
                <text x="700" y="560" fontSize="10" fill="#6366f1">Process</text>

                {/* Engine to Decision */}
                <line x1="500" y1="710" x2="500" y2="650" stroke="#f59e0b" strokeWidth="2" markerEnd="url(#arrowhead)"/>
                <text x="480" y="680" fontSize="10" fill="#f59e0b">Check</text>

                {/* Decision to Transfer */}
                <line x1="550" y1="680" x2="600" y2="680" stroke="#ef4444" strokeWidth="2" markerEnd="url(#arrowhead-red)"/>
                <text x="575" y="675" fontSize="10" fill="#ef4444">Yes</text>

                {/* Decision to Performance Check */}
                <line x1="500" y1="710" x2="500" y2="750" stroke="#f59e0b" strokeWidth="2" markerEnd="url(#arrowhead)"/>

                {/* Performance Check to Transfer */}
                <line x1="550" y1="780" x2="600" y2="710" stroke="#ef4444" strokeWidth="2" markerEnd="url(#arrowhead-red)"/>
                <text x="575" y="745" fontSize="10" fill="#ef4444">Yes</text>

                {/* Transfer to Portfolio */}
                <line x1="800" y1="710" x2="900" y2="710" stroke="#ef4444" strokeWidth="2" markerEnd="url(#arrowhead-red)"/>
                <text x="850" y="705" fontSize="10" fill="#ef4444">Transfer</text>

                {/* Portfolio Update */}
                <line x1="1000" y1="790" x2="1000" y2="650" stroke="#14b8a6" strokeWidth="2" markerEnd="url(#arrowhead)"/>
                <text x="1020" y="720" fontSize="10" fill="#14b8a6">Update</text>

                {/* Market Data to Engine */}
                <line x1="140" y1="180" x2="1000" y2="410" stroke="#f59e0b" strokeWidth="2" strokeDasharray="5,5" markerEnd="url(#arrowhead)"/>
                <text x="570" y="290" fontSize="10" fill="#f59e0b">Price Fetch</text>

                {/* Market Data to Portfolio */}
                <line x1="140" y1="180" x2="700" y2="650" stroke="#f59e0b" strokeWidth="2" strokeDasharray="5,5" markerEnd="url(#arrowhead)"/>
                <text x="420" y="410" fontSize="10" fill="#f59e0b">Valuation</text>

                {/* Legend */}
                <g id="legend">
                  <rect x="50" y="1200" width="1100" height="180" rx="10" fill="#f8fafc" stroke="#cbd5e1" strokeWidth="2"/>
                  <text x="600" y="1230" textAnchor="middle" fontSize="16" fontWeight="bold" fill="#1e293b">Legend</text>
                  
                  {/* Process Boxes */}
                  <rect x="80" y="1250" width="120" height="40" rx="8" fill="#dbeafe" stroke="#3b82f6" strokeWidth="2"/>
                  <text x="140" y="1275" textAnchor="middle" fontSize="12" fill="#1e40af">Process Step</text>
                  
                  {/* Database Boxes */}
                  <rect x="220" y="1250" width="120" height="40" rx="8" fill="#e0e7ff" stroke="#6366f1" strokeWidth="2"/>
                  <text x="280" y="1275" textAnchor="middle" fontSize="12" fill="#3730a3">Database</text>
                  
                  {/* Decision Points */}
                  <polygon points="360,1250 410,1270 360,1290 310,1270" fill="#fef3c7" stroke="#f59e0b" strokeWidth="2"/>
                  <text x="360" y="1285" textAnchor="middle" fontSize="12" fill="#92400e">Decision</text>
                  
                  {/* Flow Arrows */}
                  <line x1="480" y1="1270" x2="550" y2="1270" stroke="#64748b" strokeWidth="2" markerEnd="url(#arrowhead)"/>
                  <text x="515" y="1265" fontSize="12" fill="#64748b">Data Flow</text>
                  
                  {/* External System */}
                  <rect x="580" y="1250" width="120" height="40" rx="8" fill="#fef3c7" stroke="#f59e0b" strokeWidth="2"/>
                  <text x="640" y="1275" textAnchor="middle" fontSize="12" fill="#92400e">External System</text>
                  
                  {/* Automated Process */}
                  <rect x="720" y="1250" width="120" height="40" rx="8" fill="#fee2e2" stroke="#ef4444" strokeWidth="2"/>
                  <text x="780" y="1275" textAnchor="middle" fontSize="12" fill="#991b1b">Automated</text>
                  
                  {/* Manual Process */}
                  <rect x="860" y="1250" width="120" height="40" rx="8" fill="#d1fae5" stroke="#10b981" strokeWidth="2"/>
                  <text x="920" y="1275" textAnchor="middle" fontSize="12" fill="#065f46">Manual</text>
                  
                  {/* System Components */}
                  <text x="80" y="1320" fontSize="12" fontWeight="bold" fill="#1e293b">System Components:</text>
                  <text x="80" y="1340" fontSize="11" fill="#475569">• Supabase Database (PostgreSQL)</text>
                  <text x="80" y="1355" fontSize="11" fill="#475569">• Supabase Auth (User Management)</text>
                  <text x="80" y="1370" fontSize="11" fill="#475569">• Edge Functions (Vesting Engine)</text>
                  
                  <text x="400" y="1320" fontSize="12" fontWeight="bold" fill="#1e293b">Key Features:</text>
                  <text x="400" y="1340" fontSize="11" fill="#475569">• Real-time Portfolio Updates</text>
                  <text x="400" y="1355" fontSize="11" fill="#475569">• Automated Daily Vesting Job</text>
                  <text x="400" y="1370" fontSize="11" fill="#475569">• Market Price Integration</text>
                  
                  <text x="700" y="1320" fontSize="12" fontWeight="bold" fill="#1e293b">Data Integrity:</text>
                  <text x="700" y="1340" fontSize="11" fill="#475569">• Transaction-based Transfers</text>
                  <text x="700" y="1355" fontSize="11" fill="#475569">• Complete Audit Trail</text>
                  <text x="700" y="1370" fontSize="11" fill="#475569">• Row Level Security (RLS)</text>
                </g>
              </svg>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

