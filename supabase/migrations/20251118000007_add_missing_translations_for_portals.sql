-- Add missing translations for company portal and employee portal
-- This migration adds translations that are currently hardcoded in the application

-- ============================================
-- TRANSLATIONS PAGE TRANSLATIONS
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('translations.title', 'en', 'Translations Management', 'translation'),
('translations.description', 'en', 'Manage all translations for the application', 'translation'),
('translations.search', 'en', 'Search translations...', 'translation'),
('translations.all', 'en', 'All Languages', 'translation'),
('translations.english', 'en', 'English', 'translation'),
('translations.arabic', 'en', 'Arabic', 'translation'),
('translations.allPages', 'en', 'All Pages/Modules', 'translation'),
('translations.saved', 'en', 'Translation saved successfully', 'translation'),
('translations.error', 'en', 'An error occurred while saving the translation', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('translations.title', 'ar', 'إدارة الترجمات', 'translation'),
('translations.description', 'ar', 'إدارة جميع ترجمات التطبيق', 'translation'),
('translations.search', 'ar', 'البحث في الترجمات...', 'translation'),
('translations.all', 'ar', 'جميع اللغات', 'translation'),
('translations.english', 'ar', 'الإنجليزية', 'translation'),
('translations.arabic', 'ar', 'العربية', 'translation'),
('translations.allPages', 'ar', 'جميع الصفحات/الوحدات', 'translation'),
('translations.saved', 'ar', 'تم حفظ الترجمة بنجاح', 'translation'),
('translations.error', 'ar', 'حدث خطأ أثناء حفظ الترجمة', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- EMPLOYEE PORTAL NAVIGATION
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('employee.dashboard', 'en', 'Dashboard', 'translation'),
('employee.vestingTimeline', 'en', 'Vesting Timeline', 'translation'),
('employee.portfolio', 'en', 'Portfolio', 'translation'),
('employee.performance', 'en', 'Performance', 'translation'),
('employee.taxCalculator', 'en', 'Tax Calculator', 'translation'),
('employee.zakatCalculator', 'en', 'Zakat Calculator', 'translation'),
('employee.documents', 'en', 'Documents', 'translation'),
('employee.notifications', 'en', 'Notifications', 'translation'),
('employee.employeePortal', 'en', 'Employee Portal', 'translation'),
('employee.signOut', 'en', 'Sign Out', 'translation'),
('employee.adminView', 'en', 'Admin View', 'translation'),
('employee.employee', 'en', 'Employee', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('employee.dashboard', 'ar', 'لوحة التحكم', 'translation'),
('employee.vestingTimeline', 'ar', 'الجدول الزمني للاستحقاق', 'translation'),
('employee.portfolio', 'ar', 'المحفظة', 'translation'),
('employee.performance', 'ar', 'الأداء', 'translation'),
('employee.taxCalculator', 'ar', 'حاسبة الضرائب', 'translation'),
('employee.zakatCalculator', 'ar', 'حاسبة الزكاة', 'translation'),
('employee.documents', 'ar', 'المستندات', 'translation'),
('employee.notifications', 'ar', 'الإشعارات', 'translation'),
('employee.employeePortal', 'ar', 'بوابة الموظف', 'translation'),
('employee.signOut', 'ar', 'تسجيل الخروج', 'translation'),
('employee.adminView', 'ar', 'عرض المسؤول', 'translation'),
('employee.employee', 'ar', 'الموظف', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- EMPLOYEE DASHBOARD
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('employeeDashboard.title', 'en', 'Employee Dashboard', 'translation'),
('employeeDashboard.description', 'en', 'Track and manage your equity compensation', 'translation'),
('employeeDashboard.totalSharesGranted', 'en', 'Total Shares Granted', 'translation'),
('employeeDashboard.vestedShares', 'en', 'Vested Shares', 'translation'),
('employeeDashboard.unvestedShares', 'en', 'Unvested Shares', 'translation'),
('employeeDashboard.grant', 'en', 'Grant', 'translation'),
('employeeDashboard.grants', 'en', 'Grants', 'translation'),
('employeeDashboard.percentOfTotal', 'en', '% of total', 'translation'),
('employeeDashboard.percentRemaining', 'en', '% remaining', 'translation'),
('employeeDashboard.status', 'en', 'Status', 'translation'),
('employeeDashboard.number', 'en', 'Number', 'translation'),
('employeeDashboard.valuation', 'en', 'Valuation', 'translation'),
('employeeDashboard.vested', 'en', 'Vested', 'translation'),
('employeeDashboard.unvested', 'en', 'Unvested', 'translation'),
('employeeDashboard.lapsed', 'en', 'Lapsed', 'translation'),
('employeeDashboard.active', 'en', 'Active', 'translation'),
('employeeDashboard.exercised', 'en', 'Exercised', 'translation'),
('employeeDashboard.buyBack', 'en', 'Buy-Back', 'translation'),
('employeeDashboard.whenIsNextVesting', 'en', 'When is my next vesting due?', 'translation'),
('employeeDashboard.options', 'en', 'Options', 'translation'),
('employeeDashboard.cumulativeVestedOptions', 'en', 'Cumulative Vested Options', 'translation'),
('employeeDashboard.noUpcomingVestingDates', 'en', 'No upcoming vesting dates', 'translation'),
('employeeDashboard.exercisePricePayable', 'en', 'Exercise Price Payable for Vested Qty.', 'translation'),
('employeeDashboard.sharesRoadmap', 'en', 'Shares Roadmap', 'translation'),
('employeeDashboard.vestedSharesSAR', 'en', 'Vested Shares (SAR)', 'translation'),
('employeeDashboard.unvestedSharesSAR', 'en', 'Unvested Shares (SAR)', 'translation'),
('employeeDashboard.vestedValuation', 'en', 'Vested Valuation', 'translation'),
('employeeDashboard.vestedSharesLabel', 'en', 'Vested Shares', 'translation'),
('employeeDashboard.unvestedValuation', 'en', 'Unvested Valuation', 'translation'),
('employeeDashboard.unvestedSharesLabel', 'en', 'Unvested Shares', 'translation'),
('employeeDashboard.noDataAvailable', 'en', 'No data available', 'translation'),
('employeeDashboard.totalShares', 'en', 'Total shares', 'translation'),
('employeeDashboard.shares', 'en', 'shares', 'translation'),
('employeeDashboard.actionRequired', 'en', 'Action Required', 'translation'),
('employeeDashboard.yourGrants', 'en', 'Your Grants', 'translation'),
('employeeDashboard.noActiveGrants', 'en', 'No Active Grants', 'translation'),
('employeeDashboard.quickStats', 'en', 'Quick Stats', 'translation'),
('employeeDashboard.reviewGrantAgreement', 'en', 'Review Grant Agreement', 'translation'),
('employeeDashboard.vestingEventDetails', 'en', 'Vesting Event Details', 'translation'),
('employeeDashboard.sharesToVest', 'en', 'Shares To Vest', 'translation'),
('employeeDashboard.eventType', 'en', 'Event Type', 'translation'),
('employeeDashboard.daysRemaining', 'en', 'Days Remaining', 'translation'),
('employeeDashboard.performanceNotes', 'en', 'Performance Notes', 'translation'),
('employeeDashboard.pendingSignature', 'en', 'Pending Signature', 'translation'),
('employeeDashboard.draft', 'en', 'Draft', 'translation'),
('employeeDashboard.failedToAcceptContract', 'en', 'Failed to accept contract. Please try again.', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('employeeDashboard.title', 'ar', 'لوحة تحكم الموظف', 'translation'),
('employeeDashboard.description', 'ar', 'تتبع وإدارة تعويضات حقوق الملكية', 'translation'),
('employeeDashboard.totalSharesGranted', 'ar', 'إجمالي الأسهم الممنوحة', 'translation'),
('employeeDashboard.vestedShares', 'ar', 'الأسهم المستحقة', 'translation'),
('employeeDashboard.unvestedShares', 'ar', 'الأسهم غير المستحقة', 'translation'),
('employeeDashboard.grant', 'ar', 'منحة', 'translation'),
('employeeDashboard.grants', 'ar', 'منح', 'translation'),
('employeeDashboard.percentOfTotal', 'ar', '% من الإجمالي', 'translation'),
('employeeDashboard.percentRemaining', 'ar', '% المتبقي', 'translation'),
('employeeDashboard.status', 'ar', 'الحالة', 'translation'),
('employeeDashboard.number', 'ar', 'رقم', 'translation'),
('employeeDashboard.valuation', 'ar', 'التقييم', 'translation'),
('employeeDashboard.vested', 'ar', 'مستحقة', 'translation'),
('employeeDashboard.unvested', 'ar', 'غير مستحقة', 'translation'),
('employeeDashboard.lapsed', 'ar', 'منتهية الصلاحية', 'translation'),
('employeeDashboard.active', 'ar', 'نشط', 'translation'),
('employeeDashboard.exercised', 'ar', 'ممارسة', 'translation'),
('employeeDashboard.buyBack', 'ar', 'إعادة الشراء', 'translation'),
('employeeDashboard.whenIsNextVesting', 'ar', 'متى يكون الاستحقاق القادم؟', 'translation'),
('employeeDashboard.options', 'ar', 'خيارات', 'translation'),
('employeeDashboard.cumulativeVestedOptions', 'ar', 'الخيارات المستحقة التراكمية', 'translation'),
('employeeDashboard.noUpcomingVestingDates', 'ar', 'لا توجد تواريخ استحقاق قادمة', 'translation'),
('employeeDashboard.exercisePricePayable', 'ar', 'سعر الممارسة المستحقة للكمية المستحقة', 'translation'),
('employeeDashboard.sharesRoadmap', 'ar', 'خارطة طريق الأسهم', 'translation'),
('employeeDashboard.vestedSharesSAR', 'ar', 'الأسهم المستحقة (ريال)', 'translation'),
('employeeDashboard.unvestedSharesSAR', 'ar', 'الأسهم غير المستحقة (ريال)', 'translation'),
('employeeDashboard.vestedValuation', 'ar', 'التقييم المستحق', 'translation'),
('employeeDashboard.vestedSharesLabel', 'ar', 'الأسهم المستحقة', 'translation'),
('employeeDashboard.unvestedValuation', 'ar', 'التقييم غير المستحق', 'translation'),
('employeeDashboard.unvestedSharesLabel', 'ar', 'الأسهم غير المستحقة', 'translation'),
('employeeDashboard.noDataAvailable', 'ar', 'لا توجد بيانات متاحة', 'translation'),
('employeeDashboard.totalShares', 'ar', 'إجمالي الأسهم', 'translation'),
('employeeDashboard.shares', 'ar', 'أسهم', 'translation'),
('employeeDashboard.actionRequired', 'ar', 'إجراء مطلوب', 'translation'),
('employeeDashboard.yourGrants', 'ar', 'منحك', 'translation'),
('employeeDashboard.noActiveGrants', 'ar', 'لا توجد منح نشطة', 'translation'),
('employeeDashboard.quickStats', 'ar', 'إحصائيات سريعة', 'translation'),
('employeeDashboard.reviewGrantAgreement', 'ar', 'مراجعة اتفاقية المنحة', 'translation'),
('employeeDashboard.vestingEventDetails', 'ar', 'تفاصيل حدث الاستحقاق', 'translation'),
('employeeDashboard.sharesToVest', 'ar', 'الأسهم المستحقة', 'translation'),
('employeeDashboard.eventType', 'ar', 'نوع الحدث', 'translation'),
('employeeDashboard.daysRemaining', 'ar', 'الأيام المتبقية', 'translation'),
('employeeDashboard.performanceNotes', 'ar', 'ملاحظات الأداء', 'translation'),
('employeeDashboard.pendingSignature', 'ar', 'في انتظار التوقيع', 'translation'),
('employeeDashboard.draft', 'ar', 'مسودة', 'translation'),
('employeeDashboard.failedToAcceptContract', 'ar', 'فشل قبول العقد. يرجى المحاولة مرة أخرى.', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- EMPLOYEE DOCUMENTS
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('employeeDocuments.title', 'en', 'Documents', 'translation'),
('employeeDocuments.description', 'en', 'Access and download your equity documents', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('employeeDocuments.title', 'ar', 'المستندات', 'translation'),
('employeeDocuments.description', 'ar', 'الوصول وتنزيل مستندات حقوق الملكية الخاصة بك', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- ACCESS DENIED
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('common.accessDenied', 'en', 'Access Denied', 'translation'),
('common.accessDeniedDescription', 'en', 'Only super administrators can access this page.', 'translation'),
('common.customerJourney', 'en', 'Customer Journey', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('common.accessDenied', 'ar', 'الوصول مرفوض', 'translation'),
('common.accessDeniedDescription', 'ar', 'يمكن فقط للمسؤولين المتفوقين الوصول إلى هذه الصفحة.', 'translation'),
('common.customerJourney', 'ar', 'رحلة العميل', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- TRANSFERS TRANSLATIONS
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('transfers.title', 'en', 'Share Transfers', 'translation'),
('transfers.description', 'en', 'Manage and process share transfer requests', 'translation'),
('transfers.searchPlaceholder', 'en', 'Search by transfer number, grant, employee...', 'translation'),
('transfers.all', 'en', 'All Status', 'translation'),
('transfers.pending', 'en', 'Pending', 'translation'),
('transfers.transferred', 'en', 'Transferred', 'translation'),
('transfers.cancelled', 'en', 'Cancelled', 'translation'),
('transfers.noTransfersFound', 'en', 'No transfers found', 'translation'),
('transfers.viewDetails', 'en', 'View Details', 'translation'),
('transfers.processTransfer', 'en', 'Process Transfer', 'translation'),
('transfers.processing', 'en', 'Processing...', 'translation'),
('transfers.deleteTransfer', 'en', 'Delete Transfer', 'translation'),
('transfers.transferDetails', 'en', 'Transfer Details', 'translation'),
('transfers.transferInformation', 'en', 'Transfer Information', 'translation'),
('transfers.employee', 'en', 'Employee', 'translation'),
('transfers.portfolioDetails', 'en', 'Portfolio Details', 'translation'),
('transfers.notes', 'en', 'Notes', 'translation'),
('transfers.failedToLoad', 'en', 'Failed to load transfers', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('transfers.title', 'ar', 'تحويلات الأسهم', 'translation'),
('transfers.description', 'ar', 'إدارة ومعالجة طلبات تحويل الأسهم', 'translation'),
('transfers.searchPlaceholder', 'ar', 'البحث برقم التحويل أو المنحة أو الموظف...', 'translation'),
('transfers.all', 'ar', 'جميع الحالات', 'translation'),
('transfers.pending', 'ar', 'قيد الانتظار', 'translation'),
('transfers.transferred', 'ar', 'منقول', 'translation'),
('transfers.cancelled', 'ar', 'ملغي', 'translation'),
('transfers.noTransfersFound', 'ar', 'لم يتم العثور على تحويلات', 'translation'),
('transfers.viewDetails', 'ar', 'عرض التفاصيل', 'translation'),
('transfers.processTransfer', 'ar', 'معالجة التحويل', 'translation'),
('transfers.processing', 'ar', 'جاري المعالجة...', 'translation'),
('transfers.deleteTransfer', 'ar', 'حذف التحويل', 'translation'),
('transfers.transferDetails', 'ar', 'تفاصيل التحويل', 'translation'),
('transfers.transferInformation', 'ar', 'معلومات التحويل', 'translation'),
('transfers.employee', 'ar', 'الموظف', 'translation'),
('transfers.portfolioDetails', 'ar', 'تفاصيل المحفظة', 'translation'),
('transfers.notes', 'ar', 'ملاحظات', 'translation'),
('transfers.failedToLoad', 'ar', 'فشل تحميل التحويلات', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- PERFORMANCE METRICS TRANSLATIONS
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('performanceMetrics.title', 'en', 'Performance Metrics', 'translation'),
('performanceMetrics.description', 'en', 'Track and manage performance metrics for grants', 'translation'),
('performanceMetrics.addMetric', 'en', 'Add Metric', 'translation'),
('performanceMetrics.noMetricsYet', 'en', 'No performance metrics yet', 'translation'),
('performanceMetrics.createFirstMetric', 'en', 'Create your first performance metric to get started', 'translation'),
('performanceMetrics.metric', 'en', 'Metric', 'translation'),
('performanceMetrics.type', 'en', 'Type', 'translation'),
('performanceMetrics.unit', 'en', 'Unit', 'translation'),
('performanceMetrics.descriptionLabel', 'en', 'Description', 'translation'),
('performanceMetrics.linkedGrants', 'en', 'Linked Grants', 'translation'),
('performanceMetrics.created', 'en', 'Created', 'translation'),
('performanceMetrics.actions', 'en', 'Actions', 'translation'),
('performanceMetrics.noDescription', 'en', 'No description', 'translation'),
('performanceMetrics.none', 'en', 'None', 'translation'),
('performanceMetrics.addPerformanceMetric', 'en', 'Add Performance Metric', 'translation'),
('performanceMetrics.editPerformanceMetric', 'en', 'Edit Performance Metric', 'translation'),
('performanceMetrics.name', 'en', 'Name', 'translation'),
('performanceMetrics.descriptionPlaceholder', 'en', 'Brief description of this metric', 'translation'),
('performanceMetrics.financial', 'en', 'Financial', 'translation'),
('performanceMetrics.operational', 'en', 'Operational', 'translation'),
('performanceMetrics.personal', 'en', 'Personal', 'translation'),
('performanceMetrics.saveChanges', 'en', 'Save Changes', 'translation'),
('performanceMetrics.deletePerformanceMetric', 'en', 'Delete Performance Metric', 'translation'),
('performanceMetrics.failedToSave', 'en', 'Failed to save performance metric', 'translation'),
('performanceMetrics.failedToDelete', 'en', 'Failed to delete performance metric', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('performanceMetrics.title', 'ar', 'مقاييس الأداء', 'translation'),
('performanceMetrics.description', 'ar', 'تتبع وإدارة مقاييس الأداء للمنح', 'translation'),
('performanceMetrics.addMetric', 'ar', 'إضافة مقياس', 'translation'),
('performanceMetrics.noMetricsYet', 'ar', 'لا توجد مقاييس أداء بعد', 'translation'),
('performanceMetrics.createFirstMetric', 'ar', 'أنشئ أول مقياس أداء للبدء', 'translation'),
('performanceMetrics.metric', 'ar', 'المقياس', 'translation'),
('performanceMetrics.type', 'ar', 'النوع', 'translation'),
('performanceMetrics.unit', 'ar', 'الوحدة', 'translation'),
('performanceMetrics.descriptionLabel', 'ar', 'الوصف', 'translation'),
('performanceMetrics.linkedGrants', 'ar', 'المنح المرتبطة', 'translation'),
('performanceMetrics.created', 'ar', 'تاريخ الإنشاء', 'translation'),
('performanceMetrics.actions', 'ar', 'الإجراءات', 'translation'),
('performanceMetrics.noDescription', 'ar', 'لا يوجد وصف', 'translation'),
('performanceMetrics.none', 'ar', 'لا شيء', 'translation'),
('performanceMetrics.addPerformanceMetric', 'ar', 'إضافة مقياس أداء', 'translation'),
('performanceMetrics.editPerformanceMetric', 'ar', 'تعديل مقياس الأداء', 'translation'),
('performanceMetrics.name', 'ar', 'الاسم', 'translation'),
('performanceMetrics.descriptionPlaceholder', 'ar', 'وصف موجز لهذا المقياس', 'translation'),
('performanceMetrics.financial', 'ar', 'مالي', 'translation'),
('performanceMetrics.operational', 'ar', 'تشغيلي', 'translation'),
('performanceMetrics.personal', 'ar', 'شخصي', 'translation'),
('performanceMetrics.saveChanges', 'ar', 'حفظ التغييرات', 'translation'),
('performanceMetrics.deletePerformanceMetric', 'ar', 'حذف مقياس الأداء', 'translation'),
('performanceMetrics.failedToSave', 'ar', 'فشل حفظ مقياس الأداء', 'translation'),
('performanceMetrics.failedToDelete', 'ar', 'فشل حذف مقياس الأداء', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- DOCUMENTS (DOCUMENT MANAGEMENT) TRANSLATIONS
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('documents.title', 'en', 'Document Management', 'translation'),
('documents.description', 'en', 'Create, manage, and track document templates and generated documents', 'translation'),
('documents.templates', 'en', 'Templates', 'translation'),
('documents.generated', 'en', 'Generated', 'translation'),
('documents.signatures', 'en', 'Signatures', 'translation'),
('documents.newTemplate', 'en', 'New Template', 'translation'),
('documents.generateDocument', 'en', 'Generate Document', 'translation'),
('documents.active', 'en', 'Active', 'translation'),
('documents.noTemplatesYet', 'en', 'No templates yet', 'translation'),
('documents.createFirstTemplate', 'en', 'Create your first document template', 'translation'),
('documents.createTemplate', 'en', 'Create Template', 'translation'),
('documents.document', 'en', 'Document', 'translation'),
('documents.employee', 'en', 'Employee', 'translation'),
('documents.type', 'en', 'Type', 'translation'),
('documents.status', 'en', 'Status', 'translation'),
('documents.generatedAt', 'en', 'Generated', 'translation'),
('documents.actions', 'en', 'Actions', 'translation'),
('documents.approveForSignature', 'en', 'Approve for Signature', 'translation'),
('documents.moreActions', 'en', 'More actions', 'translation'),
('documents.noDocumentsGeneratedYet', 'en', 'No documents generated yet', 'translation'),
('documents.noSignatureRequestsYet', 'en', 'No signature requests yet', 'translation'),
('documents.createDocumentTemplate', 'en', 'Create Document Template', 'translation'),
('documents.templateName', 'en', 'Template Name', 'translation'),
('documents.templateType', 'en', 'Template Type', 'translation'),
('documents.pendingSignature', 'en', 'Pending Signature', 'translation'),
('documents.signed', 'en', 'Signed', 'translation'),
('documents.archived', 'en', 'Archived', 'translation'),
('documents.pending', 'en', 'Pending', 'translation'),
('documents.declined', 'en', 'Declined', 'translation'),
('documents.failedToCreateTemplate', 'en', 'Failed to create template', 'translation'),
('documents.failedToGenerateDocument', 'en', 'Failed to generate document', 'translation'),
('documents.failedToDeleteTemplate', 'en', 'Failed to delete template', 'translation'),
('documents.failedToSendSignatureRequest', 'en', 'Failed to send signature request', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('documents.title', 'ar', 'إدارة المستندات', 'translation'),
('documents.description', 'ar', 'إنشاء وإدارة وتتبع قوالب المستندات والمستندات المُنشأة', 'translation'),
('documents.templates', 'ar', 'القوالب', 'translation'),
('documents.generated', 'ar', 'المُنشأة', 'translation'),
('documents.signatures', 'ar', 'التوقيعات', 'translation'),
('documents.newTemplate', 'ar', 'قالب جديد', 'translation'),
('documents.generateDocument', 'ar', 'إنشاء مستند', 'translation'),
('documents.active', 'ar', 'نشط', 'translation'),
('documents.noTemplatesYet', 'ar', 'لا توجد قوالب بعد', 'translation'),
('documents.createFirstTemplate', 'ar', 'أنشئ أول قالب مستند', 'translation'),
('documents.createTemplate', 'ar', 'إنشاء قالب', 'translation'),
('documents.document', 'ar', 'المستند', 'translation'),
('documents.employee', 'ar', 'الموظف', 'translation'),
('documents.type', 'ar', 'النوع', 'translation'),
('documents.status', 'ar', 'الحالة', 'translation'),
('documents.generatedAt', 'ar', 'تاريخ الإنشاء', 'translation'),
('documents.actions', 'ar', 'الإجراءات', 'translation'),
('documents.approveForSignature', 'ar', 'الموافقة للتوقيع', 'translation'),
('documents.moreActions', 'ar', 'المزيد من الإجراءات', 'translation'),
('documents.noDocumentsGeneratedYet', 'ar', 'لم يتم إنشاء مستندات بعد', 'translation'),
('documents.noSignatureRequestsYet', 'ar', 'لا توجد طلبات توقيع بعد', 'translation'),
('documents.createDocumentTemplate', 'ar', 'إنشاء قالب مستند', 'translation'),
('documents.templateName', 'ar', 'اسم القالب', 'translation'),
('documents.templateType', 'ar', 'نوع القالب', 'translation'),
('documents.pendingSignature', 'ar', 'في انتظار التوقيع', 'translation'),
('documents.signed', 'ar', 'موقّع', 'translation'),
('documents.archived', 'ar', 'مؤرشف', 'translation'),
('documents.pending', 'ar', 'قيد الانتظار', 'translation'),
('documents.declined', 'ar', 'مرفوض', 'translation'),
('documents.failedToCreateTemplate', 'ar', 'فشل إنشاء القالب', 'translation'),
('documents.failedToGenerateDocument', 'ar', 'فشل إنشاء المستند', 'translation'),
('documents.failedToDeleteTemplate', 'ar', 'فشل حذف القالب', 'translation'),
('documents.failedToSendSignatureRequest', 'ar', 'فشل إرسال طلب التوقيع', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- CAP TABLE TRANSLATIONS
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('capTable.title', 'en', 'Cap Table', 'translation'),
('capTable.description', 'en', 'Manage shareholders, funding rounds, and dilution scenarios', 'translation'),
('capTable.shareholders', 'en', 'Shareholders', 'translation'),
('capTable.totalShares', 'en', 'Total Shares', 'translation'),
('capTable.investment', 'en', 'Investment', 'translation'),
('capTable.fundingRounds', 'en', 'Funding Rounds', 'translation'),
('capTable.ownershipDistribution', 'en', 'Ownership Distribution', 'translation'),
('capTable.breakdownByType', 'en', 'Breakdown by Type', 'translation'),
('capTable.fullyDilutedShares', 'en', 'Fully Diluted Shares', 'translation'),
('capTable.recentDilutionScenarios', 'en', 'Recent Dilution Scenarios', 'translation'),
('capTable.fundingHistory', 'en', 'Funding History', 'translation'),
('capTable.round', 'en', 'Round', 'translation'),
('capTable.amountRaised', 'en', 'Amount Raised', 'translation'),
('capTable.valuation', 'en', 'Valuation', 'translation'),
('capTable.date', 'en', 'Date', 'translation'),
('capTable.addShareholder', 'en', 'Add Shareholder', 'translation'),
('capTable.newInvestor', 'en', 'New Investor', 'translation'),
('capTable.common', 'en', 'Common', 'translation'),
('capTable.preferred', 'en', 'Preferred', 'translation'),
('capTable.failedToDeleteShareholder', 'en', 'Failed to delete shareholder', 'translation'),
('capTable.failedToUpdateShareholder', 'en', 'Failed to update shareholder', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('capTable.title', 'ar', 'جدول رأس المال', 'translation'),
('capTable.description', 'ar', 'إدارة المساهمين وجولات التمويل وسيناريوهات التخفيف', 'translation'),
('capTable.shareholders', 'ar', 'المساهمون', 'translation'),
('capTable.totalShares', 'ar', 'إجمالي الأسهم', 'translation'),
('capTable.investment', 'ar', 'الاستثمار', 'translation'),
('capTable.fundingRounds', 'ar', 'جولات التمويل', 'translation'),
('capTable.ownershipDistribution', 'ar', 'توزيع الملكية', 'translation'),
('capTable.breakdownByType', 'ar', 'التفصيل حسب النوع', 'translation'),
('capTable.fullyDilutedShares', 'ar', 'الأسهم المخففة بالكامل', 'translation'),
('capTable.recentDilutionScenarios', 'ar', 'سيناريوهات التخفيف الأخيرة', 'translation'),
('capTable.fundingHistory', 'ar', 'تاريخ التمويل', 'translation'),
('capTable.round', 'ar', 'الجولة', 'translation'),
('capTable.amountRaised', 'ar', 'المبلغ المُجمع', 'translation'),
('capTable.valuation', 'ar', 'التقييم', 'translation'),
('capTable.date', 'ar', 'التاريخ', 'translation'),
('capTable.addShareholder', 'ar', 'إضافة مساهم', 'translation'),
('capTable.newInvestor', 'ar', 'مستثمر جديد', 'translation'),
('capTable.common', 'ar', 'عادي', 'translation'),
('capTable.preferred', 'ar', 'مفضّل', 'translation'),
('capTable.failedToDeleteShareholder', 'ar', 'فشل حذف المساهم', 'translation'),
('capTable.failedToUpdateShareholder', 'ar', 'فشل تحديث المساهم', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- PORTFOLIO TRANSLATIONS
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('portfolio.title', 'en', 'Portfolio Management', 'translation'),
('portfolio.description', 'en', 'Track and manage share portfolios', 'translation'),
('portfolio.ltipPoolAllocated', 'en', 'LTIP Pool Allocated', 'translation'),
('portfolio.grantedShares', 'en', 'Granted Shares', 'translation'),
('portfolio.vestedShares', 'en', 'Vested Shares', 'translation'),
('portfolio.unvestedShares', 'en', 'Unvested Shares', 'translation'),
('portfolio.grantSummary', 'en', 'Grant Summary', 'translation'),
('portfolio.totalGrantsIssued', 'en', 'Total Grants Issued', 'translation'),
('portfolio.totalSharesGranted', 'en', 'Total Shares Granted', 'translation'),
('portfolio.vestedSharesLabel', 'en', 'Vested Shares', 'translation'),
('portfolio.unvestedSharesLabel', 'en', 'Unvested Shares', 'translation'),
('portfolio.active', 'en', 'Active', 'translation'),
('portfolio.fullyAllocated', 'en', 'Fully Allocated', 'translation'),
('portfolio.totalShares', 'en', 'Total Shares', 'translation'),
('portfolio.available', 'en', 'Available', 'translation'),
('portfolio.locked', 'en', 'Locked', 'translation'),
('portfolio.noSharesAllocated', 'en', 'No shares allocated', 'translation'),
('portfolio.noSharesAvailable', 'en', 'No shares available', 'translation'),
('portfolio.noSharesLocked', 'en', 'No shares locked', 'translation'),
('portfolio.portfolioAllocation', 'en', 'Portfolio Allocation', 'translation'),
('portfolio.ltipPools', 'en', 'LTIP Pools', 'translation'),
('portfolio.companyPortfolio', 'en', 'Company Portfolio', 'translation'),
('portfolio.employeeGrants', 'en', 'Employee Grants', 'translation'),
('portfolio.recentTransfers', 'en', 'Recent Transfers', 'translation'),
('portfolio.latestShareMovements', 'en', 'Latest share movements from company portfolio', 'translation'),
('portfolio.portfolioOverview', 'en', 'Portfolio Overview', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('portfolio.title', 'ar', 'إدارة المحفظة', 'translation'),
('portfolio.description', 'ar', 'تتبع وإدارة محافظ الأسهم', 'translation'),
('portfolio.ltipPoolAllocated', 'ar', 'تخصيص مجمع LTIP', 'translation'),
('portfolio.grantedShares', 'ar', 'الأسهم الممنوحة', 'translation'),
('portfolio.vestedShares', 'ar', 'الأسهم المستحقة', 'translation'),
('portfolio.unvestedShares', 'ar', 'الأسهم غير المستحقة', 'translation'),
('portfolio.grantSummary', 'ar', 'ملخص المنح', 'translation'),
('portfolio.totalGrantsIssued', 'ar', 'إجمالي المنح المُصدرة', 'translation'),
('portfolio.totalSharesGranted', 'ar', 'إجمالي الأسهم الممنوحة', 'translation'),
('portfolio.vestedSharesLabel', 'ar', 'الأسهم المستحقة', 'translation'),
('portfolio.unvestedSharesLabel', 'ar', 'الأسهم غير المستحقة', 'translation'),
('portfolio.active', 'ar', 'نشط', 'translation'),
('portfolio.fullyAllocated', 'ar', 'مخصص بالكامل', 'translation'),
('portfolio.totalShares', 'ar', 'إجمالي الأسهم', 'translation'),
('portfolio.available', 'ar', 'متاح', 'translation'),
('portfolio.locked', 'ar', 'مقفل', 'translation'),
('portfolio.noSharesAllocated', 'ar', 'لا توجد أسهم مخصصة', 'translation'),
('portfolio.noSharesAvailable', 'ar', 'لا توجد أسهم متاحة', 'translation'),
('portfolio.noSharesLocked', 'ar', 'لا توجد أسهم مقفلة', 'translation'),
('portfolio.portfolioAllocation', 'ar', 'تخصيص المحفظة', 'translation'),
('portfolio.ltipPools', 'ar', 'مجمعات LTIP', 'translation'),
('portfolio.companyPortfolio', 'ar', 'محفظة الشركة', 'translation'),
('portfolio.employeeGrants', 'ar', 'منح الموظفين', 'translation'),
('portfolio.recentTransfers', 'ar', 'التحويلات الأخيرة', 'translation'),
('portfolio.latestShareMovements', 'ar', 'أحدث حركات الأسهم من محفظة الشركة', 'translation'),
('portfolio.portfolioOverview', 'ar', 'نظرة عامة على المحفظة', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- CUSTOMER JOURNEY TRANSLATIONS
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('customerJourney.title', 'en', 'Customer Journey', 'translation'),
('customerJourney.subtitle', 'en', 'From Company Onboarding to Share Transfer at Vesting Date', 'translation'),
('customerJourney.processFlowSummary', 'en', 'Process Flow Summary', 'translation'),
('customerJourney.keyMilestones', 'en', 'Key Milestones', 'translation'),
('customerJourney.systemFeatures', 'en', 'System Features', 'translation'),
('customerJourney.richPicture', 'en', 'Rich Picture - Complete Process Flow', 'translation'),
('customerJourney.companyOnboarding', 'en', 'Company Onboarding', 'translation'),
('customerJourney.companyOnboardingDesc', 'en', 'Company registration and initial setup', 'translation'),
('customerJourney.employeeSetup', 'en', 'Employee Setup', 'translation'),
('customerJourney.employeeSetupDesc', 'en', 'Add employees and enable portal access', 'translation'),
('customerJourney.ltipPoolCreation', 'en', 'LTIP Pool Creation', 'translation'),
('customerJourney.ltipPoolCreationDesc', 'en', 'Create LTIP pools and allocate shares', 'translation'),
('customerJourney.incentivePlanCreation', 'en', 'Incentive Plan Creation', 'translation'),
('customerJourney.incentivePlanCreationDesc', 'en', 'Create incentive plans linked to LTIP pools', 'translation'),
('customerJourney.grantCreation', 'en', 'Grant Creation', 'translation'),
('customerJourney.grantCreationDesc', 'en', 'Grant shares to employees', 'translation'),
('customerJourney.vestingScheduleGeneration', 'en', 'Vesting Schedule Generation', 'translation'),
('customerJourney.vestingScheduleGenerationDesc', 'en', 'Generate individual vesting events', 'translation'),
('customerJourney.vestingDateArrival', 'en', 'Vesting Date Arrival', 'translation'),
('customerJourney.vestingDateArrivalDesc', 'en', 'Automated vesting event processing', 'translation'),
('customerJourney.shareTransfer', 'en', 'Share Transfer', 'translation'),
('customerJourney.shareTransferDesc', 'en', 'Transfer vested shares to employee portfolio', 'translation'),
('customerJourney.employeePortfolio', 'en', 'Employee Portfolio', 'translation'),
('customerJourney.employeePortfolioDesc', 'en', 'Employee views and manages their equity', 'translation'),
-- Step 1 Details
('customerJourney.step1Detail1', 'en', 'Company registration with commercial details', 'translation'),
('customerJourney.step1Detail2', 'en', 'Tadawul symbol and market data setup', 'translation'),
('customerJourney.step1Detail3', 'en', 'Admin user account creation', 'translation'),
('customerJourney.step1Detail4', 'en', 'Company portfolio initialization', 'translation'),
('customerJourney.step1Detail5', 'en', 'Reserved shares allocation', 'translation'),
-- Step 2 Details
('customerJourney.step2Detail1', 'en', 'Employee record creation', 'translation'),
('customerJourney.step2Detail2', 'en', 'Authentication user setup', 'translation'),
('customerJourney.step2Detail3', 'en', 'Employee portfolio creation', 'translation'),
('customerJourney.step2Detail4', 'en', 'Portal access enablement', 'translation'),
('customerJourney.step2Detail5', 'en', 'Financial information collection', 'translation'),
-- Step 3 Details
('customerJourney.step3Detail1', 'en', 'LTIP pool creation', 'translation'),
('customerJourney.step3Detail2', 'en', 'Total shares allocation to pool', 'translation'),
('customerJourney.step3Detail3', 'en', 'Pool activation', 'translation'),
('customerJourney.step3Detail4', 'en', 'Share reservation', 'translation'),
('customerJourney.step3Detail5', 'en', 'Pool management setup', 'translation'),
-- Step 4 Details
('customerJourney.step4Detail1', 'en', 'Incentive plan definition', 'translation'),
('customerJourney.step4Detail2', 'en', 'Link to LTIP pool', 'translation'),
('customerJourney.step4Detail3', 'en', 'Vesting schedule template setup', 'translation'),
('customerJourney.step4Detail4', 'en', 'Plan terms and conditions', 'translation'),
('customerJourney.step4Detail5', 'en', 'Plan activation', 'translation'),
-- Step 5 Details
('customerJourney.step5Detail1', 'en', 'Grant document creation', 'translation'),
('customerJourney.step5Detail2', 'en', 'Total shares allocation per employee', 'translation'),
('customerJourney.step5Detail3', 'en', 'Grant date and terms setup', 'translation'),
('customerJourney.step5Detail4', 'en', 'Employee grant acceptance', 'translation'),
('customerJourney.step5Detail5', 'en', 'Grant status tracking', 'translation'),
-- Step 6 Details
('customerJourney.step6Detail1', 'en', 'Vesting schedule template application', 'translation'),
('customerJourney.step6Detail2', 'en', 'Individual vesting events creation', 'translation'),
('customerJourney.step6Detail3', 'en', 'Vesting dates calculation', 'translation'),
('customerJourney.step6Detail4', 'en', 'Shares per event calculation', 'translation'),
('customerJourney.step6Detail5', 'en', 'Cliff period application', 'translation'),
-- Step 7 Details
('customerJourney.step7Detail1', 'en', 'Daily vesting job execution', 'translation'),
('customerJourney.step7Detail2', 'en', 'Employment status verification', 'translation'),
('customerJourney.step7Detail3', 'en', 'Performance condition evaluation', 'translation'),
('customerJourney.step7Detail4', 'en', 'Market price fetch', 'translation'),
('customerJourney.step7Detail5', 'en', 'Vesting event status update', 'translation'),
-- Step 8 Details
('customerJourney.step8Detail1', 'en', 'Portfolio balance verification', 'translation'),
('customerJourney.step8Detail2', 'en', 'Share transfer execution', 'translation'),
('customerJourney.step8Detail3', 'en', 'Transfer record creation', 'translation'),
('customerJourney.step8Detail4', 'en', 'Portfolio balance update', 'translation'),
('customerJourney.step8Detail5', 'en', 'Audit trail logging', 'translation'),
-- Step 9 Details
('customerJourney.step9Detail1', 'en', 'Vested shares in portfolio', 'translation'),
('customerJourney.step9Detail2', 'en', 'Market value calculation', 'translation'),
('customerJourney.step9Detail3', 'en', 'Employee dashboard update', 'translation'),
('customerJourney.step9Detail4', 'en', 'Notification sent to employee', 'translation'),
('customerJourney.step9Detail5', 'en', 'Portfolio tracking and reporting', 'translation'),
-- Key Milestones
('customerJourney.milestone1Title', 'en', 'Company Registration', 'translation'),
('customerJourney.milestone1Desc', 'en', 'Initial setup and admin user creation', 'translation'),
('customerJourney.milestone2Title', 'en', 'Employee Onboarding', 'translation'),
('customerJourney.milestone2Desc', 'en', 'Add employees and enable portal access', 'translation'),
('customerJourney.milestone3Title', 'en', 'LTIP Pool Creation', 'translation'),
('customerJourney.milestone3Desc', 'en', 'Create pools and allocate shares', 'translation'),
('customerJourney.milestone4Title', 'en', 'Incentive Plan Creation', 'translation'),
('customerJourney.milestone4Desc', 'en', 'Create plans linked to LTIP pools', 'translation'),
('customerJourney.milestone5Title', 'en', 'Grant Creation', 'translation'),
('customerJourney.milestone5Desc', 'en', 'Allocate shares to employees', 'translation'),
('customerJourney.milestone6Title', 'en', 'Vesting & Transfer', 'translation'),
('customerJourney.milestone6Desc', 'en', 'Automated share transfer on vesting date', 'translation'),
-- System Features
('customerJourney.feature1Title', 'en', 'Automated Vesting Engine', 'translation'),
('customerJourney.feature1Desc', 'en', 'Daily job processes vesting events automatically', 'translation'),
('customerJourney.feature2Title', 'en', 'Portfolio Management', 'translation'),
('customerJourney.feature2Desc', 'en', 'Real-time tracking of company and employee portfolios', 'translation'),
('customerJourney.feature3Title', 'en', 'Market Price Integration', 'translation'),
('customerJourney.feature3Desc', 'en', 'Automatic Tadawul price fetching for valuations', 'translation'),
('customerJourney.feature4Title', 'en', 'Audit Trail', 'translation'),
('customerJourney.feature4Desc', 'en', 'Complete transaction history and compliance tracking', 'translation'),
-- Other
('customerJourney.timeline', 'en', 'Timeline', 'translation'),
('customerJourney.richPictureDesc', 'en', 'A comprehensive view of the complete process from onboarding to share transfer', 'translation'),
('customerJourney.step', 'en', 'Step', 'translation'),
('customerJourney.completeProcessFlow', 'en', 'Complete ESOP Process Flow', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('customerJourney.title', 'ar', 'رحلة العميل', 'translation'),
('customerJourney.subtitle', 'ar', 'من إعداد الشركة إلى تحويل الأسهم في تاريخ الاستحقاق', 'translation'),
('customerJourney.processFlowSummary', 'ar', 'ملخص عملية التدفق', 'translation'),
('customerJourney.keyMilestones', 'ar', 'المعالم الرئيسية', 'translation'),
('customerJourney.systemFeatures', 'ar', 'ميزات النظام', 'translation'),
('customerJourney.richPicture', 'ar', 'صورة شاملة لعملية التدفق', 'translation'),
('customerJourney.companyOnboarding', 'ar', 'إعداد الشركة', 'translation'),
('customerJourney.companyOnboardingDesc', 'ar', 'تسجيل الشركة والإعداد الأولي', 'translation'),
('customerJourney.employeeSetup', 'ar', 'إعداد الموظف', 'translation'),
('customerJourney.employeeSetupDesc', 'ar', 'إضافة الموظفين وتمكين الوصول للبوابة', 'translation'),
('customerJourney.ltipPoolCreation', 'ar', 'إنشاء مجمع LTIP', 'translation'),
('customerJourney.ltipPoolCreationDesc', 'ar', 'إنشاء مجمعات LTIP وتخصيص الأسهم', 'translation'),
('customerJourney.incentivePlanCreation', 'ar', 'إنشاء خطة الحوافز', 'translation'),
('customerJourney.incentivePlanCreationDesc', 'ar', 'إنشاء خطط الحوافز المرتبطة بمجمعات LTIP', 'translation'),
('customerJourney.grantCreation', 'ar', 'إنشاء المنحة', 'translation'),
('customerJourney.grantCreationDesc', 'ar', 'منح الأسهم للموظفين', 'translation'),
('customerJourney.vestingScheduleGeneration', 'ar', 'إنشاء جدول الاستحقاق', 'translation'),
('customerJourney.vestingScheduleGenerationDesc', 'ar', 'إنشاء أحداث الاستحقاق الفردية', 'translation'),
('customerJourney.vestingDateArrival', 'ar', 'وصول تاريخ الاستحقاق', 'translation'),
('customerJourney.vestingDateArrivalDesc', 'ar', 'معالجة حدث الاستحقاق الآلية', 'translation'),
('customerJourney.shareTransfer', 'ar', 'تحويل الأسهم', 'translation'),
('customerJourney.shareTransferDesc', 'ar', 'تحويل الأسهم المستحقة إلى محفظة الموظف', 'translation'),
('customerJourney.employeePortfolio', 'ar', 'محفظة الموظف', 'translation'),
('customerJourney.employeePortfolioDesc', 'ar', 'يعرض الموظف ويدير حقوق ملكيته', 'translation'),
-- Step 1 Details
('customerJourney.step1Detail1', 'ar', 'تسجيل الشركة بالتفاصيل التجارية', 'translation'),
('customerJourney.step1Detail2', 'ar', 'إعداد رمز تداول وبيانات السوق', 'translation'),
('customerJourney.step1Detail3', 'ar', 'إنشاء حساب مستخدم المسؤول', 'translation'),
('customerJourney.step1Detail4', 'ar', 'تهيئة محفظة الشركة', 'translation'),
('customerJourney.step1Detail5', 'ar', 'تخصيص الأسهم المحجوزة', 'translation'),
-- Step 2 Details
('customerJourney.step2Detail1', 'ar', 'إنشاء سجل الموظف', 'translation'),
('customerJourney.step2Detail2', 'ar', 'إعداد مستخدم المصادقة', 'translation'),
('customerJourney.step2Detail3', 'ar', 'إنشاء محفظة الموظف', 'translation'),
('customerJourney.step2Detail4', 'ar', 'تمكين الوصول للبوابة', 'translation'),
('customerJourney.step2Detail5', 'ar', 'جمع المعلومات المالية', 'translation'),
-- Step 3 Details
('customerJourney.step3Detail1', 'ar', 'إنشاء مجمع LTIP', 'translation'),
('customerJourney.step3Detail2', 'ar', 'تخصيص إجمالي الأسهم للمجمع', 'translation'),
('customerJourney.step3Detail3', 'ar', 'تفعيل المجمع', 'translation'),
('customerJourney.step3Detail4', 'ar', 'حجز الأسهم', 'translation'),
('customerJourney.step3Detail5', 'ar', 'إعداد إدارة المجمع', 'translation'),
-- Step 4 Details
('customerJourney.step4Detail1', 'ar', 'تعريف خطة الحوافز', 'translation'),
('customerJourney.step4Detail2', 'ar', 'ربط بمجمع LTIP', 'translation'),
('customerJourney.step4Detail3', 'ar', 'إعداد قالب جدول الاستحقاق', 'translation'),
('customerJourney.step4Detail4', 'ar', 'شروط وأحكام الخطة', 'translation'),
('customerJourney.step4Detail5', 'ar', 'تفعيل الخطة', 'translation'),
-- Step 5 Details
('customerJourney.step5Detail1', 'ar', 'إنشاء وثيقة المنحة', 'translation'),
('customerJourney.step5Detail2', 'ar', 'تخصيص إجمالي الأسهم لكل موظف', 'translation'),
('customerJourney.step5Detail3', 'ar', 'إعداد تاريخ المنحة والشروط', 'translation'),
('customerJourney.step5Detail4', 'ar', 'قبول الموظف للمنحة', 'translation'),
('customerJourney.step5Detail5', 'ar', 'تتبع حالة المنحة', 'translation'),
-- Step 6 Details
('customerJourney.step6Detail1', 'ar', 'تطبيق قالب جدول الاستحقاق', 'translation'),
('customerJourney.step6Detail2', 'ar', 'إنشاء أحداث الاستحقاق الفردية', 'translation'),
('customerJourney.step6Detail3', 'ar', 'حساب تواريخ الاستحقاق', 'translation'),
('customerJourney.step6Detail4', 'ar', 'حساب الأسهم لكل حدث', 'translation'),
('customerJourney.step6Detail5', 'ar', 'تطبيق فترة الهاوية', 'translation'),
-- Step 7 Details
('customerJourney.step7Detail1', 'ar', 'تنفيذ مهمة الاستحقاق اليومية', 'translation'),
('customerJourney.step7Detail2', 'ar', 'التحقق من حالة التوظيف', 'translation'),
('customerJourney.step7Detail3', 'ar', 'تقييم شرط الأداء', 'translation'),
('customerJourney.step7Detail4', 'ar', 'جلب سعر السوق', 'translation'),
('customerJourney.step7Detail5', 'ar', 'تحديث حالة حدث الاستحقاق', 'translation'),
-- Step 8 Details
('customerJourney.step8Detail1', 'ar', 'التحقق من رصيد المحفظة', 'translation'),
('customerJourney.step8Detail2', 'ar', 'تنفيذ تحويل الأسهم', 'translation'),
('customerJourney.step8Detail3', 'ar', 'إنشاء سجل التحويل', 'translation'),
('customerJourney.step8Detail4', 'ar', 'تحديث رصيد المحفظة', 'translation'),
('customerJourney.step8Detail5', 'ar', 'تسجيل سجل التدقيق', 'translation'),
-- Step 9 Details
('customerJourney.step9Detail1', 'ar', 'الأسهم المستحقة في المحفظة', 'translation'),
('customerJourney.step9Detail2', 'ar', 'حساب القيمة السوقية', 'translation'),
('customerJourney.step9Detail3', 'ar', 'تحديث لوحة تحكم الموظف', 'translation'),
('customerJourney.step9Detail4', 'ar', 'إرسال إشعار للموظف', 'translation'),
('customerJourney.step9Detail5', 'ar', 'تتبع المحفظة والتقارير', 'translation'),
-- Key Milestones
('customerJourney.milestone1Title', 'ar', 'تسجيل الشركة', 'translation'),
('customerJourney.milestone1Desc', 'ar', 'الإعداد الأولي وإنشاء مستخدم المسؤول', 'translation'),
('customerJourney.milestone2Title', 'ar', 'إعداد الموظف', 'translation'),
('customerJourney.milestone2Desc', 'ar', 'إضافة الموظفين وتمكين الوصول للبوابة', 'translation'),
('customerJourney.milestone3Title', 'ar', 'إنشاء مجمع LTIP', 'translation'),
('customerJourney.milestone3Desc', 'ar', 'إنشاء المجمعات وتخصيص الأسهم', 'translation'),
('customerJourney.milestone4Title', 'ar', 'إنشاء خطة الحوافز', 'translation'),
('customerJourney.milestone4Desc', 'ar', 'إنشاء خطط مرتبطة بمجمعات LTIP', 'translation'),
('customerJourney.milestone5Title', 'ar', 'إنشاء المنحة', 'translation'),
('customerJourney.milestone5Desc', 'ar', 'تخصيص الأسهم للموظفين', 'translation'),
('customerJourney.milestone6Title', 'ar', 'الاستحقاق والتحويل', 'translation'),
('customerJourney.milestone6Desc', 'ar', 'تحويل الأسهم التلقائي في تاريخ الاستحقاق', 'translation'),
-- System Features
('customerJourney.feature1Title', 'ar', 'محرك الاستحقاق الآلي', 'translation'),
('customerJourney.feature1Desc', 'ar', 'تعالج المهمة اليومية أحداث الاستحقاق تلقائياً', 'translation'),
('customerJourney.feature2Title', 'ar', 'إدارة المحفظة', 'translation'),
('customerJourney.feature2Desc', 'ar', 'تتبع محافظ الشركة والموظفين في الوقت الفعلي', 'translation'),
('customerJourney.feature3Title', 'ar', 'تكامل سعر السوق', 'translation'),
('customerJourney.feature3Desc', 'ar', 'جلب أسعار تداول تلقائي للتقييمات', 'translation'),
('customerJourney.feature4Title', 'ar', 'سجل التدقيق', 'translation'),
('customerJourney.feature4Desc', 'ar', 'تاريخ المعاملات الكامل وتتبع الامتثال', 'translation'),
-- Other
('customerJourney.timeline', 'ar', 'الجدول الزمني', 'translation'),
('customerJourney.richPictureDesc', 'ar', 'نظرة شاملة على العملية الكاملة من التسجيل حتى نقل الأسهم', 'translation'),
('customerJourney.step', 'ar', 'الخطوة', 'translation'),
('customerJourney.completeProcessFlow', 'ar', 'تدفق عملية ESOP الكاملة', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- SETTINGS TRANSLATIONS
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('settings.title', 'en', 'Settings', 'translation'),
('settings.description', 'en', 'Manage your company configuration and preferences', 'translation'),
('settings.noCompanyFound', 'en', 'No Company Found', 'translation'),
('settings.unableToLoadSettings', 'en', 'Unable to load company settings', 'translation'),
('settings.companyInformation', 'en', 'Company Information', 'translation'),
('settings.cannotBeChanged', 'en', 'Cannot be changed', 'translation'),
('settings.tadawulSymbol', 'en', 'Tadawul Symbol', 'translation'),
('settings.fetchPrice', 'en', 'Fetch', 'translation'),
('settings.notSet', 'en', 'Not set', 'translation'),
('settings.currentSharePrice', 'en', 'Current Share Price', 'translation'),
('settings.optionalOverride', 'en', 'Optional override', 'translation'),
('settings.sharePoolConfiguration', 'en', 'Share Pool Configuration', 'translation'),
('settings.totalReserved', 'en', 'Total Reserved', 'translation'),
('settings.available', 'en', 'Available', 'translation'),
('settings.granted', 'en', 'Granted', 'translation'),
('settings.vested', 'en', 'Vested', 'translation'),
('settings.saveChanges', 'en', 'Save Changes', 'translation'),
('settings.saving', 'en', 'Saving...', 'translation'),
('settings.settingsSavedSuccessfully', 'en', 'Settings saved successfully', 'translation'),
('settings.failedToSaveSettings', 'en', 'Failed to save settings', 'translation'),
('settings.failedToFetchPrice', 'en', 'Failed to fetch price from Tadawul', 'translation'),
('settings.pleaseSelectTadawulSymbol', 'en', 'Please select a Tadawul symbol first.', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('settings.title', 'ar', 'الإعدادات', 'translation'),
('settings.description', 'ar', 'إدارة إعدادات الشركة وتفضيلاتها', 'translation'),
('settings.noCompanyFound', 'ar', 'لم يتم العثور على شركة', 'translation'),
('settings.unableToLoadSettings', 'ar', 'تعذر تحميل إعدادات الشركة', 'translation'),
('settings.companyInformation', 'ar', 'معلومات الشركة', 'translation'),
('settings.cannotBeChanged', 'ar', 'لا يمكن تغييره', 'translation'),
('settings.tadawulSymbol', 'ar', 'رمز تداول', 'translation'),
('settings.fetchPrice', 'ar', 'جلب', 'translation'),
('settings.notSet', 'ar', 'غير مضبوط', 'translation'),
('settings.currentSharePrice', 'ar', 'سعر السهم الحالي', 'translation'),
('settings.optionalOverride', 'ar', 'تجاوز اختياري', 'translation'),
('settings.sharePoolConfiguration', 'ar', 'تكوين مجمع الأسهم', 'translation'),
('settings.totalReserved', 'ar', 'إجمالي المحجوز', 'translation'),
('settings.available', 'ar', 'متاح', 'translation'),
('settings.granted', 'ar', 'ممنوح', 'translation'),
('settings.vested', 'ar', 'مستحق', 'translation'),
('settings.saveChanges', 'ar', 'حفظ التغييرات', 'translation'),
('settings.saving', 'ar', 'جاري الحفظ...', 'translation'),
('settings.settingsSavedSuccessfully', 'ar', 'تم حفظ الإعدادات بنجاح', 'translation'),
('settings.failedToSaveSettings', 'ar', 'فشل حفظ الإعدادات', 'translation'),
('settings.failedToFetchPrice', 'ar', 'فشل جلب السعر من تداول', 'translation'),
('settings.pleaseSelectTadawulSymbol', 'ar', 'يرجى اختيار رمز تداول أولاً.', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- VESTING EVENTS TRANSLATIONS
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('vestingEvents.title', 'en', 'Vesting Events', 'translation'),
('vestingEvents.description', 'en', 'Manage and process vesting events for all grants', 'translation'),
('vestingEvents.generateEvents', 'en', 'Generate Events', 'translation'),
('vestingEvents.export', 'en', 'Export', 'translation'),
('vestingEvents.summary', 'en', 'Summary', 'translation'),
('vestingEvents.expand', 'en', 'Expand', 'translation'),
('vestingEvents.collapse', 'en', 'Collapse', 'translation'),
('vestingEvents.showAllEvents', 'en', 'Show all events', 'translation'),
('vestingEvents.totalEvents', 'en', 'Total Events', 'translation'),
('vestingEvents.dueNow', 'en', 'Due Now', 'translation'),
('vestingEvents.pending', 'en', 'Pending', 'translation'),
('vestingEvents.transferred', 'en', 'Transferred', 'translation'),
('vestingEvents.exercised', 'en', 'Exercised', 'translation'),
('vestingEvents.vested', 'en', 'Vested', 'translation'),
('vestingEvents.eventsByStatus', 'en', 'Events by Status', 'translation'),
('vestingEvents.expandLegend', 'en', 'Expand legend', 'translation'),
('vestingEvents.collapseLegend', 'en', 'Collapse legend', 'translation'),
('vestingEvents.failedToGenerateEvents', 'en', 'Failed to generate vesting events', 'translation'),
('vestingEvents.failedToLoadTransferData', 'en', 'Failed to load transfer confirmation data', 'translation'),
('vestingEvents.failedToTransferEvent', 'en', 'Failed to transfer vesting event', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('vestingEvents.title', 'ar', 'أحداث الاستحقاق', 'translation'),
('vestingEvents.description', 'ar', 'إدارة ومعالجة أحداث الاستحقاق لجميع المنح', 'translation'),
('vestingEvents.generateEvents', 'ar', 'إنشاء الأحداث', 'translation'),
('vestingEvents.export', 'ar', 'تصدير', 'translation'),
('vestingEvents.summary', 'ar', 'الملخص', 'translation'),
('vestingEvents.expand', 'ar', 'توسيع', 'translation'),
('vestingEvents.collapse', 'ar', 'طي', 'translation'),
('vestingEvents.showAllEvents', 'ar', 'عرض جميع الأحداث', 'translation'),
('vestingEvents.totalEvents', 'ar', 'إجمالي الأحداث', 'translation'),
('vestingEvents.dueNow', 'ar', 'مستحقة الآن', 'translation'),
('vestingEvents.pending', 'ar', 'قيد الانتظار', 'translation'),
('vestingEvents.transferred', 'ar', 'منقول', 'translation'),
('vestingEvents.exercised', 'ar', 'ممارسة', 'translation'),
('vestingEvents.vested', 'ar', 'مستحق', 'translation'),
('vestingEvents.eventsByStatus', 'ar', 'الأحداث حسب الحالة', 'translation'),
('vestingEvents.expandLegend', 'ar', 'توسيع الأسطورة', 'translation'),
('vestingEvents.collapseLegend', 'ar', 'طي الأسطورة', 'translation'),
('vestingEvents.failedToGenerateEvents', 'ar', 'فشل إنشاء أحداث الاستحقاق', 'translation'),
('vestingEvents.failedToLoadTransferData', 'ar', 'فشل تحميل بيانات تأكيد التحويل', 'translation'),
('vestingEvents.failedToTransferEvent', 'ar', 'فشل تحويل حدث الاستحقاق', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

-- ============================================
-- CHARTS AND COMPONENTS TRANSLATIONS
-- ============================================
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('charts.portfolioValue', 'en', 'Portfolio Value', 'translation'),
('charts.realTimeTadawulPricing', 'en', 'Real-time Tadawul pricing', 'translation'),
('charts.autoRefreshON', 'en', 'Auto-refresh ON', 'translation'),
('charts.autoRefreshOFF', 'en', 'Auto-refresh OFF', 'translation'),
('charts.stockSymbol', 'en', 'Stock Symbol:', 'translation'),
('charts.vestedValue', 'en', 'Vested Value', 'translation'),
('charts.unvestedValue', 'en', 'Unvested Value', 'translation'),
('charts.totalValue', 'en', 'Total Value', 'translation'),
('charts.vestedShares', 'en', 'Vested Shares', 'translation'),
('charts.unvestedShares', 'en', 'Unvested Shares', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('charts.portfolioValue', 'ar', 'قيمة المحفظة', 'translation'),
('charts.realTimeTadawulPricing', 'ar', 'أسعار تداول في الوقت الفعلي', 'translation'),
('charts.autoRefreshON', 'ar', 'التحديث التلقائي مفعّل', 'translation'),
('charts.autoRefreshOFF', 'ar', 'التحديث التلقائي معطّل', 'translation'),
('charts.stockSymbol', 'ar', 'رمز السهم:', 'translation'),
('charts.vestedValue', 'ar', 'القيمة المستحقة', 'translation'),
('charts.unvestedValue', 'ar', 'القيمة غير المستحقة', 'translation'),
('charts.totalValue', 'ar', 'القيمة الإجمالية', 'translation'),
('charts.vestedShares', 'ar', 'الأسهم المستحقة', 'translation'),
('charts.unvestedShares', 'ar', 'الأسهم غير المستحقة', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO UPDATE SET translation_value = EXCLUDED.translation_value;

