-- Complete Translations Insert Script
-- Run this script in Supabase SQL Editor to insert/update all translations
-- This uses ON CONFLICT to update existing translations safely

-- ============================================
-- 1. COMMON TRANSLATIONS
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('common.dashboard', 'en', 'Dashboard', 'translation'),
('common.employees', 'en', 'Employees', 'translation'),
('common.plans', 'en', 'Plans', 'translation'),
('common.grants', 'en', 'Grants', 'translation'),
('common.portfolio', 'en', 'Portfolio', 'translation'),
('common.settings', 'en', 'Settings', 'translation'),
('common.users', 'en', 'Users', 'translation'),
('common.capTable', 'en', 'Cap Table', 'translation'),
('common.ltipPools', 'en', 'LTIP Pools', 'translation'),
('common.vestingSchedules', 'en', 'Vesting Schedules', 'translation'),
('common.vestingEvents', 'en', 'Vesting Events', 'translation'),
('common.transfers', 'en', 'Transfers', 'translation'),
('common.performanceMetrics', 'en', 'Performance Metrics', 'translation'),
('common.documents', 'en', 'Documents', 'translation'),
('common.logout', 'en', 'Logout', 'translation'),
('common.login', 'en', 'Login', 'translation'),
('common.save', 'en', 'Save', 'translation'),
('common.cancel', 'en', 'Cancel', 'translation'),
('common.delete', 'en', 'Delete', 'translation'),
('common.edit', 'en', 'Edit', 'translation'),
('common.create', 'en', 'Create', 'translation'),
('common.search', 'en', 'Search', 'translation'),
('common.loading', 'en', 'Loading...', 'translation'),
('common.noData', 'en', 'No data available', 'translation'),
('common.tryAdjustingSearch', 'en', 'Try adjusting your search or filters', 'translation'),
('common.translations', 'en', 'Translations', 'translation'),
('common.operatorConsole', 'en', 'Operator Console', 'translation'),
('common.overview', 'en', 'Overview', 'translation'),
('common.incentivePlans', 'en', 'Incentive Plans', 'translation'),
('common.subscriptions', 'en', 'Subscriptions', 'translation'),
('common.buybackRequests', 'en', 'Buyback Requests', 'translation'),
('common.allPortfolios', 'en', 'All Portfolios', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('common.dashboard', 'ar', 'لوحة التحكم', 'translation'),
('common.employees', 'ar', 'الموظفون', 'translation'),
('common.plans', 'ar', 'الخطط', 'translation'),
('common.grants', 'ar', 'المنح', 'translation'),
('common.portfolio', 'ar', 'المحفظة', 'translation'),
('common.settings', 'ar', 'الإعدادات', 'translation'),
('common.users', 'ar', 'المستخدمون', 'translation'),
('common.capTable', 'ar', 'جدول رأس المال', 'translation'),
('common.ltipPools', 'ar', 'مجمعات LTIP', 'translation'),
('common.vestingSchedules', 'ar', 'جداول الاستحقاق', 'translation'),
('common.vestingEvents', 'ar', 'أحداث الاستحقاق', 'translation'),
('common.transfers', 'ar', 'التحويلات', 'translation'),
('common.performanceMetrics', 'ar', 'مقاييس الأداء', 'translation'),
('common.documents', 'ar', 'المستندات', 'translation'),
('common.logout', 'ar', 'تسجيل الخروج', 'translation'),
('common.login', 'ar', 'تسجيل الدخول', 'translation'),
('common.save', 'ar', 'حفظ', 'translation'),
('common.cancel', 'ar', 'إلغاء', 'translation'),
('common.delete', 'ar', 'حذف', 'translation'),
('common.edit', 'ar', 'تعديل', 'translation'),
('common.create', 'ar', 'إنشاء', 'translation'),
('common.search', 'ar', 'بحث', 'translation'),
('common.loading', 'ar', 'جاري التحميل...', 'translation'),
('common.noData', 'ar', 'لا توجد بيانات متاحة', 'translation'),
('common.tryAdjustingSearch', 'ar', 'حاول تعديل البحث أو المرشحات', 'translation'),
('common.translations', 'ar', 'الترجمات', 'translation'),
('common.operatorConsole', 'ar', 'لوحة المشغل', 'translation'),
('common.overview', 'ar', 'نظرة عامة', 'translation'),
('common.incentivePlans', 'ar', 'خطط الحوافز', 'translation'),
('common.subscriptions', 'ar', 'الاشتراكات', 'translation'),
('common.buybackRequests', 'ar', 'طلبات إعادة الشراء', 'translation'),
('common.allPortfolios', 'ar', 'جميع المحافظ', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- 2. DASHBOARD TRANSLATIONS (English)
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('dashboard.title', 'en', 'Dashboard Overview', 'translation'),
('dashboard.welcome', 'en', 'Welcome back! Here''s what''s happening with your LTIP/ESOP programs.', 'translation'),
('dashboard.verificationStatus', 'en', 'Verification Status', 'translation'),
('dashboard.tadawul', 'en', 'Tadawul', 'translation'),
('dashboard.equityPoolSize', 'en', 'Equity Pool Size', 'translation'),
('dashboard.equityPoolSizeTooltip', 'en', 'Total LTIP shares used across all pools compared to the overall LTIP allocation', 'translation'),
('dashboard.usedVsTotalPool', 'en', 'Used vs Total Pool', 'translation'),
('dashboard.used', 'en', 'used', 'translation'),
('dashboard.sharesUsed', 'en', 'shares used', 'translation'),
('dashboard.totalPool', 'en', 'total pool', 'translation'),
('dashboard.usedSharesBreakdown', 'en', 'Used Shares Breakdown', 'translation'),
('dashboard.usedSharesBreakdownTooltip', 'en', 'Breakdown of used shares showing granted vs ungranted, and vested vs unvested', 'translation'),
('dashboard.breakdownOfUsedShares', 'en', 'Breakdown of Used Shares', 'translation'),
('dashboard.granted', 'en', 'granted', 'translation'),
('dashboard.grantedLabel', 'en', 'Granted', 'translation'),
('dashboard.ungranted', 'en', 'Ungranted', 'translation'),
('dashboard.vested', 'en', 'Vested', 'translation'),
('dashboard.unvested', 'en', 'Unvested', 'translation'),
('dashboard.grantedVsUngranted', 'en', 'Granted vs Ungranted', 'translation'),
('dashboard.vestedVsUnvested', 'en', 'Vested vs Unvested (of Granted)', 'translation'),
('dashboard.optionsPoolUsed', 'en', 'Options Pool Used', 'translation'),
('dashboard.optionsPoolUsedTooltip', 'en', 'Total ESOP options used across the ESOP plan compared to the available pool', 'translation'),
('dashboard.usedVsAvailable', 'en', 'Used vs Available', 'translation'),
('dashboard.currentFMV', 'en', 'Current FMV', 'translation'),
('dashboard.currentFMVTooltip', 'en', 'Fair Market Value - The latest closing price from Tadawul stock exchange', 'translation'),
('dashboard.recentActivity', 'en', 'Recent Activity', 'translation'),
('dashboard.newGrantIssued', 'en', 'New grant issued', 'translation'),
('dashboard.employeesAdded', 'en', 'employees added', 'translation'),
('dashboard.newLTIPPlanCreated', 'en', 'New LTIP plan created', 'translation'),
('dashboard.hoursAgo', 'en', 'hours ago', 'translation'),
('dashboard.daysAgo', 'en', 'days ago', 'translation'),
('dashboard.upcomingVestingEvents', 'en', 'Upcoming Vesting Events', 'translation'),
('dashboard.nextOf', 'en', 'Next', 'translation'),
('dashboard.of', 'en', 'of', 'translation'),
('dashboard.more', 'en', 'More', 'translation'),
('dashboard.cliff', 'en', 'Cliff', 'translation'),
('dashboard.vesting', 'en', 'Vesting', 'translation'),
('dashboard.shares', 'en', 'shares', 'translation'),
('dashboard.exercisePrice', 'en', 'Exercise Price', 'translation'),
('dashboard.totalCost', 'en', 'Total Cost', 'translation'),
('dashboard.viewAllUpcomingEvents', 'en', 'View all', 'translation'),
('dashboard.upcomingEvents', 'en', 'upcoming events', 'translation'),
('dashboard.vestingEventsDue', 'en', 'Vesting Events Due', 'translation'),
('dashboard.dueNow', 'en', 'Due Now', 'translation'),
('dashboard.requiresImmediateAttention', 'en', 'Requires immediate attention', 'translation'),
('dashboard.noUpcomingVestingEvents', 'en', 'No upcoming vesting events', 'translation'),
('dashboard.noUpcomingVestingEventsDesc', 'en', 'All grants may be fully vested or no active grants found', 'translation'),
('dashboard.ltipPoolsSnapshot', 'en', 'LTIP Pools Snapshot', 'translation'),
('dashboard.ltipPoolsSnapshotDesc', 'en', 'Quick view of allocations and utilization across LTIP pools.', 'translation'),
('dashboard.incentivePlansSnapshot', 'en', 'Incentive Plans Snapshot', 'translation'),
('dashboard.incentivePlansSnapshotDesc', 'en', 'Overview of plan allocations and granted shares.', 'translation'),
('dashboard.available', 'en', 'Available', 'translation'),
('dashboard.sharesUsedLabel', 'en', 'Shares Used', 'translation'),
('dashboard.totalAllocated', 'en', 'Total Allocated', 'translation'),
('dashboard.totalPools', 'en', 'Total Pools', 'translation'),
('dashboard.usedShares', 'en', 'Used Shares', 'translation'),
('dashboard.availableShares', 'en', 'Available Shares', 'translation'),
('dashboard.sharesByStatus', 'en', 'Shares by Status', 'translation'),
('dashboard.sharesByPool', 'en', 'Shares by Pool', 'translation'),
('dashboard.usedLabel', 'en', 'Used', 'translation'),
('dashboard.allocatedNotGranted', 'en', 'Allocated (not granted)', 'translation'),
('dashboard.grantedNoVestingEvents', 'en', 'Granted (no vesting events)', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- 3. DASHBOARD TRANSLATIONS (Arabic)
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('dashboard.title', 'ar', 'نظرة عامة على لوحة التحكم', 'translation'),
('dashboard.welcome', 'ar', 'مرحباً بعودتك! إليك ما يحدث مع برامج LTIP/ESOP الخاصة بك.', 'translation'),
('dashboard.verificationStatus', 'ar', 'حالة التحقق', 'translation'),
('dashboard.tadawul', 'ar', 'تداول', 'translation'),
('dashboard.equityPoolSize', 'ar', 'حجم مجمع الأسهم', 'translation'),
('dashboard.equityPoolSizeTooltip', 'ar', 'إجمالي أسهم LTIP المستخدمة عبر جميع المجمعات مقارنة بالتخصيص الإجمالي لـ LTIP', 'translation'),
('dashboard.usedVsTotalPool', 'ar', 'المستخدم مقابل المجمع الإجمالي', 'translation'),
('dashboard.used', 'ar', 'مستخدم', 'translation'),
('dashboard.sharesUsed', 'ar', 'أسهم مستخدمة', 'translation'),
('dashboard.totalPool', 'ar', 'المجمع الإجمالي', 'translation'),
('dashboard.usedSharesBreakdown', 'ar', 'تفصيل الأسهم المستخدمة', 'translation'),
('dashboard.usedSharesBreakdownTooltip', 'ar', 'تفصيل الأسهم المستخدمة يوضح الممنوحة مقابل غير الممنوحة، والمستحقة مقابل غير المستحقة', 'translation'),
('dashboard.breakdownOfUsedShares', 'ar', 'تفصيل الأسهم المستخدمة', 'translation'),
('dashboard.granted', 'ar', 'ممنوحة', 'translation'),
('dashboard.grantedLabel', 'ar', 'ممنوحة', 'translation'),
('dashboard.ungranted', 'ar', 'غير ممنوحة', 'translation'),
('dashboard.vested', 'ar', 'مستحقة', 'translation'),
('dashboard.unvested', 'ar', 'غير مستحقة', 'translation'),
('dashboard.grantedVsUngranted', 'ar', 'ممنوحة مقابل غير ممنوحة', 'translation'),
('dashboard.vestedVsUnvested', 'ar', 'مستحقة مقابل غير مستحقة (من الممنوحة)', 'translation'),
('dashboard.optionsPoolUsed', 'ar', 'مجمع الخيارات المستخدم', 'translation'),
('dashboard.optionsPoolUsedTooltip', 'ar', 'إجمالي خيارات ESOP المستخدمة عبر خطة ESOP مقارنة بالمجمع المتاح', 'translation'),
('dashboard.usedVsAvailable', 'ar', 'المستخدم مقابل المتاح', 'translation'),
('dashboard.currentFMV', 'ar', 'القيمة السوقية العادلة الحالية', 'translation'),
('dashboard.currentFMVTooltip', 'ar', 'القيمة السوقية العادلة - آخر سعر إغلاق من سوق تداول', 'translation'),
('dashboard.recentActivity', 'ar', 'النشاط الأخير', 'translation'),
('dashboard.newGrantIssued', 'ar', 'تم إصدار منحة جديدة', 'translation'),
('dashboard.employeesAdded', 'ar', 'موظف تمت إضافتهم', 'translation'),
('dashboard.newLTIPPlanCreated', 'ar', 'تم إنشاء خطة LTIP جديدة', 'translation'),
('dashboard.hoursAgo', 'ar', 'ساعات مضت', 'translation'),
('dashboard.daysAgo', 'ar', 'أيام مضت', 'translation'),
('dashboard.upcomingVestingEvents', 'ar', 'أحداث الاستحقاق القادمة', 'translation'),
('dashboard.nextOf', 'ar', 'التالي', 'translation'),
('dashboard.of', 'ar', 'من', 'translation'),
('dashboard.more', 'ar', 'المزيد', 'translation'),
('dashboard.cliff', 'ar', 'منحدر', 'translation'),
('dashboard.vesting', 'ar', 'استحقاق', 'translation'),
('dashboard.shares', 'ar', 'أسهم', 'translation'),
('dashboard.exercisePrice', 'ar', 'سعر الممارسة', 'translation'),
('dashboard.totalCost', 'ar', 'التكلفة الإجمالية', 'translation'),
('dashboard.viewAllUpcomingEvents', 'ar', 'عرض جميع', 'translation'),
('dashboard.upcomingEvents', 'ar', 'الأحداث القادمة', 'translation'),
('dashboard.vestingEventsDue', 'ar', 'أحداث الاستحقاق المستحقة', 'translation'),
('dashboard.dueNow', 'ar', 'مستحقة الآن', 'translation'),
('dashboard.requiresImmediateAttention', 'ar', 'يتطلب اهتماماً فورياً', 'translation'),
('dashboard.noUpcomingVestingEvents', 'ar', 'لا توجد أحداث استحقاق قادمة', 'translation'),
('dashboard.noUpcomingVestingEventsDesc', 'ar', 'قد تكون جميع المنح مستحقة بالكامل أو لم يتم العثور على منح نشطة', 'translation'),
('dashboard.ltipPoolsSnapshot', 'ar', 'لقطة مجمعات LTIP', 'translation'),
('dashboard.ltipPoolsSnapshotDesc', 'ar', 'نظرة سريعة على التخصيصات والاستخدام عبر مجمعات LTIP.', 'translation'),
('dashboard.incentivePlansSnapshot', 'ar', 'لقطة خطط الحوافز', 'translation'),
('dashboard.incentivePlansSnapshotDesc', 'ar', 'نظرة عامة على تخصيصات الخطة والأسهم الممنوحة.', 'translation'),
('dashboard.available', 'ar', 'متاح', 'translation'),
('dashboard.sharesUsedLabel', 'ar', 'أسهم مستخدمة', 'translation'),
('dashboard.totalAllocated', 'ar', 'إجمالي المخصص', 'translation'),
('dashboard.totalPools', 'ar', 'إجمالي المجمعات', 'translation'),
('dashboard.usedShares', 'ar', 'أسهم مستخدمة', 'translation'),
('dashboard.availableShares', 'ar', 'أسهم متاحة', 'translation'),
('dashboard.sharesByStatus', 'ar', 'الأسهم حسب الحالة', 'translation'),
('dashboard.sharesByPool', 'ar', 'الأسهم حسب المجمع', 'translation'),
('dashboard.usedLabel', 'ar', 'مستخدم', 'translation'),
('dashboard.allocatedNotGranted', 'ar', 'مخصص (غير ممنوح)', 'translation'),
('dashboard.grantedNoVestingEvents', 'ar', 'ممنوحة (لا توجد أحداث استحقاق)', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- 4. INCENTIVE PLANS SUMMARY (English)
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('incentivePlans.title', 'en', 'Incentive Plans Snapshot', 'translation'),
('incentivePlans.description', 'en', 'Overview of plan allocations and granted shares.', 'translation'),
('incentivePlans.totalPlans', 'en', 'Total Plans', 'translation'),
('incentivePlans.active', 'en', 'Active', 'translation'),
('incentivePlans.activePercent', 'en', 'active', 'translation'),
('incentivePlans.ltipPool', 'en', 'LTIP Pool', 'translation'),
('incentivePlans.plannedShares', 'en', 'Planned Shares', 'translation'),
('incentivePlans.granted', 'en', 'Granted', 'translation'),
('incentivePlans.ungranted', 'en', 'Ungranted', 'translation'),
('incentivePlans.availableToPlan', 'en', 'Available to Plan', 'translation'),
('incentivePlans.ltipPoolVsPlanned', 'en', 'LTIP Pool vs Planned', 'translation'),
('incentivePlans.totalPool', 'en', 'Total Pool', 'translation'),
('incentivePlans.plannedSharesByPlan', 'en', 'Planned Shares by Plan', 'translation'),
('incentivePlans.unplannedShares', 'en', 'Unplanned Shares', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('incentivePlans.title', 'ar', 'لقطة خطط الحوافز', 'translation'),
('incentivePlans.description', 'ar', 'نظرة عامة على تخصيصات الخطة والأسهم الممنوحة.', 'translation'),
('incentivePlans.totalPlans', 'ar', 'إجمالي الخطط', 'translation'),
('incentivePlans.active', 'ar', 'نشط', 'translation'),
('incentivePlans.activePercent', 'ar', 'نشط', 'translation'),
('incentivePlans.ltipPool', 'ar', 'مجمع LTIP', 'translation'),
('incentivePlans.plannedShares', 'ar', 'الأسهم المخططة', 'translation'),
('incentivePlans.granted', 'ar', 'ممنوحة', 'translation'),
('incentivePlans.ungranted', 'ar', 'غير ممنوحة', 'translation'),
('incentivePlans.availableToPlan', 'ar', 'متاح للتخطيط', 'translation'),
('incentivePlans.ltipPoolVsPlanned', 'ar', 'مجمع LTIP مقابل المخطط', 'translation'),
('incentivePlans.totalPool', 'ar', 'المجمع الإجمالي', 'translation'),
('incentivePlans.plannedSharesByPlan', 'ar', 'الأسهم المخططة حسب الخطة', 'translation'),
('incentivePlans.unplannedShares', 'ar', 'أسهم غير مخططة', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- 5. VESTING EVENTS SUMMARY (English)
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('vestingEvents.title', 'en', 'Vesting Events Snapshot', 'translation'),
('vestingEvents.description', 'en', 'Monitor event statuses, shares, and urgent actions.', 'translation'),
('vestingEvents.totalEvents', 'en', 'Total Events', 'translation'),
('vestingEvents.dueNow', 'en', 'Due Now', 'translation'),
('vestingEvents.pending', 'en', 'Pending', 'translation'),
('vestingEvents.vested', 'en', 'Vested', 'translation'),
('vestingEvents.exercised', 'en', 'Exercised', 'translation'),
('vestingEvents.transferred', 'en', 'Transferred', 'translation'),
('vestingEvents.forfeitedCancelled', 'en', 'Forfeited/Cancelled', 'translation'),
('vestingEvents.eventsByStatus', 'en', 'Events by Status', 'translation'),
('vestingEvents.sharesByStatus', 'en', 'Shares by Status', 'translation'),
('vestingEvents.events', 'en', 'Events', 'translation'),
('vestingEvents.dueEvents', 'en', 'Due Events', 'translation'),
('vestingEvents.noDueEvents', 'en', 'No due events', 'translation'),
('vestingEvents.noEventsAvailable', 'en', 'No events available', 'translation'),
('vestingEvents.showAllDueEvents', 'en', 'Show all due events', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('vestingEvents.title', 'ar', 'لقطة أحداث الاستحقاق', 'translation'),
('vestingEvents.description', 'ar', 'مراقبة حالات الأحداث والأسهم والإجراءات العاجلة.', 'translation'),
('vestingEvents.totalEvents', 'ar', 'إجمالي الأحداث', 'translation'),
('vestingEvents.dueNow', 'ar', 'مستحقة الآن', 'translation'),
('vestingEvents.pending', 'ar', 'قيد الانتظار', 'translation'),
('vestingEvents.vested', 'ar', 'مستحقة', 'translation'),
('vestingEvents.exercised', 'ar', 'ممارسة', 'translation'),
('vestingEvents.transferred', 'ar', 'منقولة', 'translation'),
('vestingEvents.forfeitedCancelled', 'ar', 'مصادرة/ملغاة', 'translation'),
('vestingEvents.eventsByStatus', 'ar', 'الأحداث حسب الحالة', 'translation'),
('vestingEvents.sharesByStatus', 'ar', 'الأسهم حسب الحالة', 'translation'),
('vestingEvents.events', 'ar', 'أحداث', 'translation'),
('vestingEvents.dueEvents', 'ar', 'الأحداث المستحقة', 'translation'),
('vestingEvents.noDueEvents', 'ar', 'لا توجد أحداث مستحقة', 'translation'),
('vestingEvents.noEventsAvailable', 'ar', 'لا توجد أحداث متاحة', 'translation'),
('vestingEvents.showAllDueEvents', 'ar', 'عرض جميع الأحداث المستحقة', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- 6. EMPLOYEES TRANSLATIONS (English)
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('employees.title', 'en', 'Employee Management', 'translation'),
('employees.description', 'en', 'Manage employee records and grant eligibility', 'translation'),
('employees.importCSV', 'en', 'Import CSV', 'translation'),
('employees.addEmployee', 'en', 'Add Employee', 'translation'),
('employees.searchPlaceholder', 'en', 'Search employees by name, email, or employee number...', 'translation'),
('employees.allStatus', 'en', 'All Status', 'translation'),
('employees.active', 'en', 'Active', 'translation'),
('employees.terminated', 'en', 'Terminated', 'translation'),
('employees.resigned', 'en', 'Resigned', 'translation'),
('employees.retired', 'en', 'Retired', 'translation'),
('employees.employee', 'en', 'Employee', 'translation'),
('employees.employeeNumber', 'en', 'Employee #', 'translation'),
('employees.department', 'en', 'Department', 'translation'),
('employees.totalShares', 'en', 'Total Shares', 'translation'),
('employees.vested', 'en', 'Vested', 'translation'),
('employees.unvested', 'en', 'Unvested', 'translation'),
('employees.vestingProgress', 'en', 'Vesting Progress', 'translation'),
('employees.status', 'en', 'Status', 'translation'),
('employees.actions', 'en', 'Actions', 'translation'),
('employees.noEmployeesFound', 'en', 'No employees found', 'translation'),
('employees.noEmployeesDesc', 'en', 'Try adjusting your search or filter criteria', 'translation'),
('employees.view', 'en', 'View', 'translation'),
('employees.edit', 'en', 'Edit', 'translation'),
('employees.delete', 'en', 'Delete', 'translation'),
('employees.sendCredentials', 'en', 'Send Credentials', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('employees.title', 'ar', 'إدارة الموظفين', 'translation'),
('employees.description', 'ar', 'إدارة سجلات الموظفين وأهلية المنح', 'translation'),
('employees.importCSV', 'ar', 'استيراد CSV', 'translation'),
('employees.addEmployee', 'ar', 'إضافة موظف', 'translation'),
('employees.searchPlaceholder', 'ar', 'البحث عن الموظفين بالاسم أو البريد الإلكتروني أو رقم الموظف...', 'translation'),
('employees.allStatus', 'ar', 'جميع الحالات', 'translation'),
('employees.active', 'ar', 'نشط', 'translation'),
('employees.terminated', 'ar', 'منتهي', 'translation'),
('employees.resigned', 'ar', 'استقال', 'translation'),
('employees.retired', 'ar', 'متقاعد', 'translation'),
('employees.employee', 'ar', 'الموظف', 'translation'),
('employees.employeeNumber', 'ar', 'رقم الموظف', 'translation'),
('employees.department', 'ar', 'القسم', 'translation'),
('employees.totalShares', 'ar', 'إجمالي الأسهم', 'translation'),
('employees.vested', 'ar', 'مستحقة', 'translation'),
('employees.unvested', 'ar', 'غير مستحقة', 'translation'),
('employees.vestingProgress', 'ar', 'تقدم الاستحقاق', 'translation'),
('employees.status', 'ar', 'الحالة', 'translation'),
('employees.actions', 'ar', 'الإجراءات', 'translation'),
('employees.noEmployeesFound', 'ar', 'لم يتم العثور على موظفين', 'translation'),
('employees.noEmployeesDesc', 'ar', 'حاول تعديل معايير البحث أو التصفية', 'translation'),
('employees.view', 'ar', 'عرض', 'translation'),
('employees.edit', 'ar', 'تعديل', 'translation'),
('employees.delete', 'ar', 'حذف', 'translation'),
('employees.sendCredentials', 'ar', 'إرسال بيانات الاعتماد', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- 7. PLANS TRANSLATIONS (English)
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('plans.title', 'en', 'Incentive Plans', 'translation'),
('plans.description', 'en', 'Create and manage LTIP/ESOP programs', 'translation'),
('plans.createNewPlan', 'en', 'Create New Plan', 'translation'),
('plans.totalPlans', 'en', 'Total Plans', 'translation'),
('plans.active', 'en', 'Active', 'translation'),
('plans.activePercent', 'en', 'active', 'translation'),
('plans.ltipPool', 'en', 'LTIP Pool', 'translation'),
('plans.totalAllocated', 'en', 'Total Allocated', 'translation'),
('plans.plannedShares', 'en', 'Planned Shares', 'translation'),
('plans.granted', 'en', 'Granted', 'translation'),
('plans.ungranted', 'en', 'Ungranted', 'translation'),
('plans.availableToPlan', 'en', 'Available to Plan', 'translation'),
('plans.planName', 'en', 'Plan Name', 'translation'),
('plans.planCode', 'en', 'Plan Code', 'translation'),
('plans.planType', 'en', 'Plan Type', 'translation'),
('plans.type', 'en', 'Type', 'translation'),
('plans.status', 'en', 'Status', 'translation'),
('plans.actions', 'en', 'Actions', 'translation'),
('plans.createPlan', 'en', 'Create Plan', 'translation'),
('plans.planNameEnglish', 'en', 'Plan Name (English)', 'translation'),
('plans.planNameArabic', 'en', 'Plan Name (Arabic)', 'translation'),
('plans.descriptionEnglish', 'en', 'Description (English)', 'translation'),
('plans.descriptionArabic', 'en', 'Description (Arabic)', 'translation'),
('plans.vestingScheduleType', 'en', 'Vesting Schedule Type', 'translation'),
('plans.vestingType', 'en', 'Vesting Type', 'translation'),
('plans.vestingScheduleTemplate', 'en', 'Vesting Schedule Template', 'translation'),
('plans.startDate', 'en', 'Start Date', 'translation'),
('plans.endDate', 'en', 'End Date', 'translation'),
('plans.period', 'en', 'Period', 'translation'),
('plans.totalShares', 'en', 'Total Shares', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('plans.title', 'ar', 'خطط الحوافز', 'translation'),
('plans.description', 'ar', 'إنشاء وإدارة برامج LTIP/ESOP', 'translation'),
('plans.createNewPlan', 'ar', 'إنشاء خطة جديدة', 'translation'),
('plans.totalPlans', 'ar', 'إجمالي الخطط', 'translation'),
('plans.active', 'ar', 'نشط', 'translation'),
('plans.activePercent', 'ar', 'نشط', 'translation'),
('plans.ltipPool', 'ar', 'مجمع LTIP', 'translation'),
('plans.totalAllocated', 'ar', 'إجمالي المخصص', 'translation'),
('plans.plannedShares', 'ar', 'الأسهم المخططة', 'translation'),
('plans.granted', 'ar', 'ممنوحة', 'translation'),
('plans.ungranted', 'ar', 'غير ممنوحة', 'translation'),
('plans.availableToPlan', 'ar', 'متاح للتخطيط', 'translation'),
('plans.planName', 'ar', 'اسم الخطة', 'translation'),
('plans.planCode', 'ar', 'رمز الخطة', 'translation'),
('plans.planType', 'ar', 'نوع الخطة', 'translation'),
('plans.type', 'ar', 'النوع', 'translation'),
('plans.status', 'ar', 'الحالة', 'translation'),
('plans.actions', 'ar', 'الإجراءات', 'translation'),
('plans.createPlan', 'ar', 'إنشاء خطة', 'translation'),
('plans.planNameEnglish', 'ar', 'اسم الخطة (بالإنجليزية)', 'translation'),
('plans.planNameArabic', 'ar', 'اسم الخطة (بالعربية)', 'translation'),
('plans.descriptionEnglish', 'ar', 'الوصف (بالإنجليزية)', 'translation'),
('plans.descriptionArabic', 'ar', 'الوصف (بالعربية)', 'translation'),
('plans.vestingScheduleType', 'ar', 'نوع جدول الاستحقاق', 'translation'),
('plans.vestingType', 'ar', 'نوع الاستحقاق', 'translation'),
('plans.vestingScheduleTemplate', 'ar', 'قالب جدول الاستحقاق', 'translation'),
('plans.startDate', 'ar', 'تاريخ البدء', 'translation'),
('plans.endDate', 'ar', 'تاريخ الانتهاء', 'translation'),
('plans.period', 'ar', 'الفترة', 'translation'),
('plans.totalShares', 'ar', 'إجمالي الأسهم', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- 8. GRANTS TRANSLATIONS (English)
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('grants.title', 'en', 'Grants', 'translation'),
('grants.description', 'en', 'Manage employee grants and allocations', 'translation'),
('grants.createGrant', 'en', 'Create Grant', 'translation'),
('grants.grantNumber', 'en', 'Grant #', 'translation'),
('grants.employee', 'en', 'Employee', 'translation'),
('grants.plan', 'en', 'Plan', 'translation'),
('grants.totalShares', 'en', 'Total Shares', 'translation'),
('grants.grantDate', 'en', 'Grant Date', 'translation'),
('grants.status', 'en', 'Status', 'translation'),
('grants.actions', 'en', 'Actions', 'translation'),
('grants.totalGrants', 'en', 'Total Grants', 'translation'),
('grants.activeGrants', 'en', 'Active Grants', 'translation'),
('grants.pendingSignature', 'en', 'Pending Signature', 'translation'),
('grants.totalSharesGranted', 'en', 'Total Shares Granted', 'translation'),
('grants.planType', 'en', 'Plan Type', 'translation'),
('grants.vested', 'en', 'Vested', 'translation'),
('grants.unvested', 'en', 'Unvested', 'translation'),
('grants.vestingProgress', 'en', 'Vesting Progress', 'translation'),
('grants.noGrantsFound', 'en', 'No Grants Found', 'translation'),
('grants.issueFirstGrant', 'en', 'Issue First Grant', 'translation'),
('grants.allStatus', 'en', 'All Status', 'translation'),
('grants.filterByEmployee', 'en', 'Filter by Employee', 'translation'),
('grants.selected', 'en', 'selected', 'translation'),
('grants.deleteSelected', 'en', 'Delete Selected', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('grants.title', 'ar', 'المنح', 'translation'),
('grants.description', 'ar', 'إدارة منح الموظفين والتخصيصات', 'translation'),
('grants.createGrant', 'ar', 'إنشاء منحة', 'translation'),
('grants.grantNumber', 'ar', 'رقم المنحة', 'translation'),
('grants.employee', 'ar', 'الموظف', 'translation'),
('grants.plan', 'ar', 'الخطة', 'translation'),
('grants.totalShares', 'ar', 'إجمالي الأسهم', 'translation'),
('grants.grantDate', 'ar', 'تاريخ المنحة', 'translation'),
('grants.status', 'ar', 'الحالة', 'translation'),
('grants.actions', 'ar', 'الإجراءات', 'translation'),
('grants.totalGrants', 'ar', 'إجمالي المنح', 'translation'),
('grants.activeGrants', 'ar', 'المنح النشطة', 'translation'),
('grants.pendingSignature', 'ar', 'في انتظار التوقيع', 'translation'),
('grants.totalSharesGranted', 'ar', 'إجمالي الأسهم الممنوحة', 'translation'),
('grants.planType', 'ar', 'نوع الخطة', 'translation'),
('grants.vested', 'ar', 'مستحقة', 'translation'),
('grants.unvested', 'ar', 'غير مستحقة', 'translation'),
('grants.vestingProgress', 'ar', 'تقدم الاستحقاق', 'translation'),
('grants.noGrantsFound', 'ar', 'لم يتم العثور على منح', 'translation'),
('grants.issueFirstGrant', 'ar', 'إصدار أول منحة', 'translation'),
('grants.allStatus', 'ar', 'جميع الحالات', 'translation'),
('grants.filterByEmployee', 'ar', 'تصفية حسب الموظف', 'translation'),
('grants.selected', 'ar', 'محدد', 'translation'),
('grants.deleteSelected', 'ar', 'حذف المحدد', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- 9. TRANSLATIONS MANAGEMENT (English)
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('translations.title', 'en', 'Translation Management', 'translation'),
('translations.description', 'en', 'Manage all translations for English and Arabic', 'translation'),
('translations.key', 'en', 'Translation Key', 'translation'),
('translations.english', 'en', 'English', 'translation'),
('translations.arabic', 'en', 'Arabic', 'translation'),
('translations.save', 'en', 'Save Translation', 'translation'),
('translations.saved', 'en', 'Translation saved successfully', 'translation'),
('translations.error', 'en', 'Error saving translation', 'translation'),
('translations.search', 'en', 'Search translations...', 'translation'),
('translations.filter', 'en', 'Filter by language', 'translation'),
('translations.all', 'en', 'All Languages', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('translations.title', 'ar', 'إدارة الترجمات', 'translation'),
('translations.description', 'ar', 'إدارة جميع الترجمات للإنجليزية والعربية', 'translation'),
('translations.key', 'ar', 'مفتاح الترجمة', 'translation'),
('translations.english', 'ar', 'الإنجليزية', 'translation'),
('translations.arabic', 'ar', 'العربية', 'translation'),
('translations.save', 'ar', 'حفظ الترجمة', 'translation'),
('translations.saved', 'ar', 'تم حفظ الترجمة بنجاح', 'translation'),
('translations.error', 'ar', 'خطأ في حفظ الترجمة', 'translation'),
('translations.search', 'ar', 'البحث في الترجمات...', 'translation'),
('translations.filter', 'ar', 'تصفية حسب اللغة', 'translation'),
('translations.all', 'ar', 'جميع اللغات', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- 10. LTIP POOLS TRANSLATIONS (English)
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('ltipPools.title', 'en', 'LTIP Pool Management', 'translation'),
('ltipPools.description', 'en', 'Manage Long-Term Incentive Plan pools and allocations', 'translation'),
('ltipPools.createPool', 'en', 'Create LTIP Pool', 'translation'),
('ltipPools.totalPools', 'en', 'Total Pools', 'translation'),
('ltipPools.totalAllocated', 'en', 'Total Allocated', 'translation'),
('ltipPools.sharesUsed', 'en', 'Shares Used', 'translation'),
('ltipPools.sharesAvailable', 'en', 'Shares Available', 'translation'),
('ltipPools.sharesByStatus', 'en', 'Shares by Status', 'translation'),
('ltipPools.sharesByPool', 'en', 'Shares by Pool', 'translation'),
('ltipPools.noPoolsYet', 'en', 'No LTIP Pools Created Yet', 'translation'),
('ltipPools.createFirstPool', 'en', 'Create your first LTIP pool to start managing employee stock allocations', 'translation'),
('ltipPools.createFirstPoolButton', 'en', 'Create First Pool', 'translation'),
('ltipPools.poolName', 'en', 'Pool Name', 'translation'),
('ltipPools.poolCode', 'en', 'Code', 'translation'),
('ltipPools.poolType', 'en', 'Type', 'translation'),
('ltipPools.used', 'en', 'Used', 'translation'),
('ltipPools.available', 'en', 'Available', 'translation'),
('ltipPools.utilization', 'en', 'Utilization', 'translation'),
('ltipPools.granted', 'en', 'Granted', 'translation'),
('ltipPools.vested', 'en', 'Vested', 'translation'),
('ltipPools.unvested', 'en', 'Unvested', 'translation'),
('ltipPools.status', 'en', 'Status', 'translation'),
('ltipPools.actions', 'en', 'Actions', 'translation'),
('ltipPools.createNewPool', 'en', 'Create New LTIP Pool', 'translation'),
('ltipPools.definePoolParameters', 'en', 'Define pool parameters for employee stock allocations', 'translation'),
('ltipPools.poolNameEnglish', 'en', 'Pool Name (English)*', 'translation'),
('ltipPools.poolNameArabic', 'en', 'Pool Name (Arabic)', 'translation'),
('ltipPools.poolCodeLabel', 'en', 'Pool Code*', 'translation'),
('ltipPools.descriptionEnglish', 'en', 'Description (English)', 'translation'),
('ltipPools.descriptionArabic', 'en', 'Description (Arabic)', 'translation'),
('ltipPools.totalSharesAllocated', 'en', 'Total Shares Allocated*', 'translation'),
('ltipPools.poolTypeLabel', 'en', 'Pool Type*', 'translation'),
('ltipPools.poolStatus', 'en', 'Pool Status*', 'translation'),
('ltipPools.general', 'en', 'General', 'translation'),
('ltipPools.executive', 'en', 'Executive', 'translation'),
('ltipPools.employee', 'en', 'Employee', 'translation'),
('ltipPools.retention', 'en', 'Retention', 'translation'),
('ltipPools.performance', 'en', 'Performance', 'translation'),
('ltipPools.active', 'en', 'Active', 'translation'),
('ltipPools.inactive', 'en', 'Inactive', 'translation'),
('ltipPools.exhausted', 'en', 'Exhausted', 'translation'),
('ltipPools.viewDetails', 'en', 'View details', 'translation'),
('ltipPools.editPool', 'en', 'Edit pool', 'translation'),
('ltipPools.deletePool', 'en', 'Delete pool', 'translation'),
('ltipPools.updatePool', 'en', 'Update Pool', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('ltipPools.title', 'ar', 'إدارة مجمعات LTIP', 'translation'),
('ltipPools.description', 'ar', 'إدارة مجمعات خطط الحوافز طويلة الأجل والتخصيصات', 'translation'),
('ltipPools.createPool', 'ar', 'إنشاء مجمع LTIP', 'translation'),
('ltipPools.totalPools', 'ar', 'إجمالي المجمعات', 'translation'),
('ltipPools.totalAllocated', 'ar', 'إجمالي المخصص', 'translation'),
('ltipPools.sharesUsed', 'ar', 'الأسهم المستخدمة', 'translation'),
('ltipPools.sharesAvailable', 'ar', 'الأسهم المتاحة', 'translation'),
('ltipPools.sharesByStatus', 'ar', 'الأسهم حسب الحالة', 'translation'),
('ltipPools.sharesByPool', 'ar', 'الأسهم حسب المجمع', 'translation'),
('ltipPools.noPoolsYet', 'ar', 'لم يتم إنشاء مجمعات LTIP بعد', 'translation'),
('ltipPools.createFirstPool', 'ar', 'أنشئ أول مجمع LTIP للبدء في إدارة تخصيصات أسهم الموظفين', 'translation'),
('ltipPools.createFirstPoolButton', 'ar', 'إنشاء أول مجمع', 'translation'),
('ltipPools.poolName', 'ar', 'اسم المجمع', 'translation'),
('ltipPools.poolCode', 'ar', 'الرمز', 'translation'),
('ltipPools.poolType', 'ar', 'النوع', 'translation'),
('ltipPools.used', 'ar', 'مستخدم', 'translation'),
('ltipPools.available', 'ar', 'متاح', 'translation'),
('ltipPools.utilization', 'ar', 'الاستخدام', 'translation'),
('ltipPools.granted', 'ar', 'ممنوحة', 'translation'),
('ltipPools.vested', 'ar', 'مستحقة', 'translation'),
('ltipPools.unvested', 'ar', 'غير مستحقة', 'translation'),
('ltipPools.status', 'ar', 'الحالة', 'translation'),
('ltipPools.actions', 'ar', 'الإجراءات', 'translation'),
('ltipPools.createNewPool', 'ar', 'إنشاء مجمع LTIP جديد', 'translation'),
('ltipPools.definePoolParameters', 'ar', 'تحديد معاملات المجمع لتخصيصات أسهم الموظفين', 'translation'),
('ltipPools.poolNameEnglish', 'ar', 'اسم المجمع (بالإنجليزية)*', 'translation'),
('ltipPools.poolNameArabic', 'ar', 'اسم المجمع (بالعربية)', 'translation'),
('ltipPools.poolCodeLabel', 'ar', 'رمز المجمع*', 'translation'),
('ltipPools.descriptionEnglish', 'ar', 'الوصف (بالإنجليزية)', 'translation'),
('ltipPools.descriptionArabic', 'ar', 'الوصف (بالعربية)', 'translation'),
('ltipPools.totalSharesAllocated', 'ar', 'إجمالي الأسهم المخصصة*', 'translation'),
('ltipPools.poolTypeLabel', 'ar', 'نوع المجمع*', 'translation'),
('ltipPools.poolStatus', 'ar', 'حالة المجمع*', 'translation'),
('ltipPools.general', 'ar', 'عام', 'translation'),
('ltipPools.executive', 'ar', 'تنفيذي', 'translation'),
('ltipPools.employee', 'ar', 'موظف', 'translation'),
('ltipPools.retention', 'ar', 'الاحتفاظ', 'translation'),
('ltipPools.performance', 'ar', 'الأداء', 'translation'),
('ltipPools.active', 'ar', 'نشط', 'translation'),
('ltipPools.inactive', 'ar', 'غير نشط', 'translation'),
('ltipPools.exhausted', 'ar', 'منتهي', 'translation'),
('ltipPools.viewDetails', 'ar', 'عرض التفاصيل', 'translation'),
('ltipPools.editPool', 'ar', 'تعديل المجمع', 'translation'),
('ltipPools.deletePool', 'ar', 'حذف المجمع', 'translation'),
('ltipPools.updatePool', 'ar', 'تحديث المجمع', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- 11. OPERATOR CONSOLE TRANSLATIONS (English)
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('operatorConsole.title', 'en', 'Operator Console', 'translation'),
('operatorConsole.description', 'en', 'Manage all companies on the platform. View status, verify companies, and access company dashboards.', 'translation'),
('operatorConsole.totalCompanies', 'en', 'Total Companies', 'translation'),
('operatorConsole.verified', 'en', 'Verified', 'translation'),
('operatorConsole.pending', 'en', 'Pending', 'translation'),
('operatorConsole.active', 'en', 'Active', 'translation'),
('operatorConsole.allCompanies', 'en', 'All Companies', 'translation'),
('operatorConsole.manageCompanies', 'en', 'Manage platform companies and their verification status', 'translation'),
('operatorConsole.noCompanies', 'en', 'No companies found on the platform.', 'translation'),
('operatorConsole.loadingCompanies', 'en', 'Loading companies...', 'translation'),
('operatorConsole.company', 'en', 'Company', 'translation'),
('operatorConsole.tadawulSymbol', 'en', 'Tadawul Symbol', 'translation'),
('operatorConsole.verification', 'en', 'Verification', 'translation'),
('operatorConsole.status', 'en', 'Status', 'translation'),
('operatorConsole.statistics', 'en', 'Statistics', 'translation'),
('operatorConsole.shares', 'en', 'Shares', 'translation'),
('operatorConsole.created', 'en', 'Created', 'translation'),
('operatorConsole.actions', 'en', 'Actions', 'translation'),
('operatorConsole.editCompany', 'en', 'Edit Company', 'translation'),
('operatorConsole.verificationStatus', 'en', 'Verification Status', 'translation'),
('operatorConsole.companyStatus', 'en', 'Company Status', 'translation'),
('operatorConsole.viewDashboard', 'en', 'View Dashboard', 'translation'),
('operatorConsole.accessDenied', 'en', 'Access denied. Super admin privileges required.', 'translation'),
('operatorConsole.failedToLoad', 'en', 'Failed to load companies.', 'translation'),
('operatorConsole.saveChanges', 'en', 'Save Changes', 'translation'),
('operatorConsole.rejected', 'en', 'Rejected', 'translation'),
('operatorConsole.suspended', 'en', 'Suspended', 'translation'),
('operatorConsole.inactive', 'en', 'Inactive', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('operatorConsole.title', 'ar', 'لوحة المشغل', 'translation'),
('operatorConsole.description', 'ar', 'إدارة جميع الشركات على المنصة. عرض الحالة والتحقق من الشركات والوصول إلى لوحات التحكم الخاصة بالشركات.', 'translation'),
('operatorConsole.totalCompanies', 'ar', 'إجمالي الشركات', 'translation'),
('operatorConsole.verified', 'ar', 'متحقق', 'translation'),
('operatorConsole.pending', 'ar', 'قيد الانتظار', 'translation'),
('operatorConsole.active', 'ar', 'نشط', 'translation'),
('operatorConsole.allCompanies', 'ar', 'جميع الشركات', 'translation'),
('operatorConsole.manageCompanies', 'ar', 'إدارة شركات المنصة وحالة التحقق الخاصة بها', 'translation'),
('operatorConsole.noCompanies', 'ar', 'لم يتم العثور على شركات على المنصة.', 'translation'),
('operatorConsole.loadingCompanies', 'ar', 'جاري تحميل الشركات...', 'translation'),
('operatorConsole.company', 'ar', 'الشركة', 'translation'),
('operatorConsole.tadawulSymbol', 'ar', 'رمز تداول', 'translation'),
('operatorConsole.verification', 'ar', 'التحقق', 'translation'),
('operatorConsole.status', 'ar', 'الحالة', 'translation'),
('operatorConsole.statistics', 'ar', 'الإحصاءات', 'translation'),
('operatorConsole.shares', 'ar', 'الأسهم', 'translation'),
('operatorConsole.created', 'ar', 'تم الإنشاء', 'translation'),
('operatorConsole.actions', 'ar', 'الإجراءات', 'translation'),
('operatorConsole.editCompany', 'ar', 'تعديل الشركة', 'translation'),
('operatorConsole.verificationStatus', 'ar', 'حالة التحقق', 'translation'),
('operatorConsole.companyStatus', 'ar', 'حالة الشركة', 'translation'),
('operatorConsole.viewDashboard', 'ar', 'عرض لوحة التحكم', 'translation'),
('operatorConsole.accessDenied', 'ar', 'تم رفض الوصول. مطلوب صلاحيات المشرف الأعلى.', 'translation'),
('operatorConsole.failedToLoad', 'ar', 'فشل تحميل الشركات.', 'translation'),
('operatorConsole.saveChanges', 'ar', 'حفظ التغييرات', 'translation'),
('operatorConsole.rejected', 'ar', 'مرفوض', 'translation'),
('operatorConsole.suspended', 'ar', 'معلق', 'translation'),
('operatorConsole.inactive', 'ar', 'غير نشط', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- 12. VESTING SCHEDULES TRANSLATIONS (English)
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('vestingSchedules.title', 'en', 'Vesting Schedules', 'translation'),
('vestingSchedules.description', 'en', 'Create and manage vesting schedules for your equity plans', 'translation'),
('vestingSchedules.createSchedule', 'en', 'Create Schedule', 'translation'),
('vestingSchedules.scheduleName', 'en', 'Schedule Name', 'translation'),
('vestingSchedules.type', 'en', 'Type', 'translation'),
('vestingSchedules.duration', 'en', 'Duration', 'translation'),
('vestingSchedules.cliffPeriod', 'en', 'Cliff Period', 'translation'),
('vestingSchedules.frequency', 'en', 'Frequency', 'translation'),
('vestingSchedules.template', 'en', 'Template', 'translation'),
('vestingSchedules.actions', 'en', 'Actions', 'translation'),
('vestingSchedules.noSchedulesYet', 'en', 'No vesting schedules yet', 'translation'),
('vestingSchedules.createFirstSchedule', 'en', 'Create your first vesting schedule to get started', 'translation'),
('vestingSchedules.createVestingSchedule', 'en', 'Create Vesting Schedule', 'translation'),
('vestingSchedules.scheduleType', 'en', 'Schedule Type', 'translation'),
('vestingSchedules.totalDurationMonths', 'en', 'Total Duration (Months)', 'translation'),
('vestingSchedules.cliffPeriodMonths', 'en', 'Cliff Period (Months)', 'translation'),
('vestingSchedules.vestingFrequency', 'en', 'Vesting Frequency', 'translation'),
('vestingSchedules.descriptionOptional', 'en', 'Description (Optional)', 'translation'),
('vestingSchedules.months', 'en', 'months', 'translation'),
('vestingSchedules.years', 'en', 'years', 'translation'),
('vestingSchedules.yes', 'en', 'Yes', 'translation'),
('vestingSchedules.no', 'en', 'No', 'translation'),
('vestingSchedules.view', 'en', 'View', 'translation'),
('vestingSchedules.timeBased', 'en', 'Time Based', 'translation'),
('vestingSchedules.performanceBased', 'en', 'Performance Based', 'translation'),
('vestingSchedules.hybrid', 'en', 'Hybrid (Time + Performance)', 'translation'),
('vestingSchedules.monthly', 'en', 'Monthly', 'translation'),
('vestingSchedules.quarterly', 'en', 'Quarterly', 'translation'),
('vestingSchedules.annually', 'en', 'Annually', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('vestingSchedules.title', 'ar', 'جداول الاستحقاق', 'translation'),
('vestingSchedules.description', 'ar', 'إنشاء وإدارة جداول الاستحقاق لخطط الأسهم الخاصة بك', 'translation'),
('vestingSchedules.createSchedule', 'ar', 'إنشاء جدول', 'translation'),
('vestingSchedules.scheduleName', 'ar', 'اسم الجدول', 'translation'),
('vestingSchedules.type', 'ar', 'النوع', 'translation'),
('vestingSchedules.duration', 'ar', 'المدة', 'translation'),
('vestingSchedules.cliffPeriod', 'ar', 'فترة المنحدر', 'translation'),
('vestingSchedules.frequency', 'ar', 'التكرار', 'translation'),
('vestingSchedules.template', 'ar', 'القالب', 'translation'),
('vestingSchedules.actions', 'ar', 'الإجراءات', 'translation'),
('vestingSchedules.noSchedulesYet', 'ar', 'لا توجد جداول استحقاق بعد', 'translation'),
('vestingSchedules.createFirstSchedule', 'ar', 'أنشئ أول جدول استحقاق للبدء', 'translation'),
('vestingSchedules.createVestingSchedule', 'ar', 'إنشاء جدول الاستحقاق', 'translation'),
('vestingSchedules.scheduleType', 'ar', 'نوع الجدول', 'translation'),
('vestingSchedules.totalDurationMonths', 'ar', 'المدة الإجمالية (بالأشهر)', 'translation'),
('vestingSchedules.cliffPeriodMonths', 'ar', 'فترة المنحدر (بالأشهر)', 'translation'),
('vestingSchedules.vestingFrequency', 'ar', 'تكرار الاستحقاق', 'translation'),
('vestingSchedules.descriptionOptional', 'ar', 'الوصف (اختياري)', 'translation'),
('vestingSchedules.months', 'ar', 'أشهر', 'translation'),
('vestingSchedules.years', 'ar', 'سنوات', 'translation'),
('vestingSchedules.yes', 'ar', 'نعم', 'translation'),
('vestingSchedules.no', 'ar', 'لا', 'translation'),
('vestingSchedules.view', 'ar', 'عرض', 'translation'),
('vestingSchedules.timeBased', 'ar', 'قائم على الوقت', 'translation'),
('vestingSchedules.performanceBased', 'ar', 'قائم على الأداء', 'translation'),
('vestingSchedules.hybrid', 'ar', 'هجين (وقت + أداء)', 'translation'),
('vestingSchedules.monthly', 'ar', 'شهري', 'translation'),
('vestingSchedules.quarterly', 'ar', 'ربع سنوي', 'translation'),
('vestingSchedules.annually', 'ar', 'سنوي', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

