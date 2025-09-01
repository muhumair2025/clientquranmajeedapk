import 'app_localizations.dart';

class AppLocalizationsAr extends AppLocalizations {
  // App Information
  @override
  String get appTitle => 'القرآن المجيد';
  @override
  String get appDescription => 'القرآن الكريم كاملاً مع التفسير والترجمة';

  // Navigation & Menu Items
  @override
  String get home => 'الرئيسية';
  @override
  String get quranNavigation => 'تصفح القرآن';
  @override
  String get search => 'البحث';
  @override
  String get settings => 'الإعدادات';
  @override
  String get aboutUs => 'من نحن';
  @override
  String get helpSupport => 'المساعدة والدعم';
  @override
  String get feedback => 'الملاحظات';

  // Main Screen Titles
  @override
  String get otherTools => 'أدوات أخرى';
  @override
  String get documents => 'المستندات';
  @override
  String get audioDownloads => 'تحميل الصوتيات';
  @override
  String get videoDownloads => 'تحميل الفيديو';
  @override
  String get quranMajeed => 'القرآن المجيد';

  // Home Page Cards (in Arabic)
  @override
  String get aqeedah => 'العقيدة';
  @override
  String get aqeedahSubtitle => 'أسس الإسلام';
  @override
  String get tafseerTranslation => 'التفسير والترجمة';
  @override
  String get tafseerSubtitle => 'شرح القرآن';
  @override
  String get fiqh => 'الفقه';
  @override
  String get fiqhSubtitle => 'الشريعة الإسلامية';
  @override
  String get hadith => 'الحديث';
  @override
  String get hadithSubtitle => 'أحاديث النبي';
  @override
  String get questionAnswer => 'أسئلة وأجوبة';
  @override
  String get questionAnswerSubtitle => 'أسئلتكم';
  @override
  String get books => 'الكتب';
  @override
  String get booksSubtitle => 'الكتب الإسلامية';

  // Quran Navigation
  @override
  String get quranKareem => 'القرآن الكريم';
  @override
  String get surahs => 'السور';
  @override
  String get paras => 'الأجزاء';
  @override
  String get searchSurahPara => 'البحث في السور أو الأجزاء';
  @override
  String get searchHint => 'ابحث هنا...';

  // Quran Search
  @override
  String get quranSearch => 'البحث في القرآن';
  @override
  String get textSearch => 'البحث في النص';
  @override
  String get directNavigation => 'التنقل المباشر';
  @override
  String get searchInArabicText => 'البحث في النص العربي';
  @override
  String get searchPlaceholder => 'أدخل نص الآية أو كلمة';
  @override
  String get smartSearchSystem => 'نظام البحث الذكي';
  @override
  String get searchFeatures => 'ميزات البحث';
  @override
  String get noResultsFound => 'لم يتم العثور على نتائج';
  @override
  String get tryDifferentText => 'جرب نصاً مختلفاً';
  @override
  String get selectSurahFirst => 'اختر السورة أولاً';
  @override
  String get enterAyahNumber => 'أدخل رقم الآية';
  @override
  String get navigate => 'انتقل';
  @override
  String get ayahNumberRange => 'رقم الآية (1-{max})';
  @override
  String get selectSurah => 'اختر السورة';

  // Quran Reader
  @override
  String get loading => 'جارٍ التحميل...';
  @override
  String get ayah => 'آية';
  @override
  String get page => 'صفحة';
  @override
  String get surah => 'سورة';
  @override
  String get para => 'جزء';
  @override
  String get fontSize => 'حجم الخط';
  @override
  String get fontFamily => 'عائلة الخط';
  @override
  String get lineSpacing => 'تباعد الأسطر';
  @override
  String get wordSpacing => 'تباعد الكلمات';

  // Additional Methods (not in base class)
  String get backgroundColor => 'لون الخلفية';
  String get textColor => 'لون النص';
  String get showTranslation => 'إظهار الترجمة';
  String get hideTranslation => 'إخفاء الترجمة';
  String get goToPage => 'انتقل إلى الصفحة';
  String get pageNumber => 'رقم الصفحة';
  String get totalPages => 'إجمالي الصفحات: {total}';
  String get pageOf => 'صفحة {current} من {total}';

  // Theme & Settings
  @override
  String get darkMode => 'الوضع المظلم';
  @override
  String get lightMode => 'الوضع المضيء';
  String get systemMode => 'وضع النظام';
  String get fontSize16 => '16';
  String get fontSize18 => '18';
  String get fontSize20 => '20';
  String get fontSize22 => '22';
  String get fontSize24 => '24';
  String get fontSize26 => '26';
  String get fontSize28 => '28';
  String get fontSize30 => '30';
  String get fontArabic => 'خط عربي';
  String get fontUrdu => 'خط أردو';
  String get fontPashto => 'خط بشتو';
  String get fontEnglish => 'خط إنجليزي';
  String get lineHeight => 'ارتفاع الخط';
  String get wordGap => 'فجوة الكلمات';

  // Actions & Buttons
  @override
  String get previous => 'السابق';
  @override
  String get next => 'التالي';
  @override
  String get close => 'إغلاق';
  @override
  String get back => 'رجوع';
  @override
  String get save => 'حفظ';
  @override
  String get edit => 'تحرير';
  @override
  String get update => 'تحديث';
  @override
  String get refresh => 'تحديث';
  @override
  String get reset => 'إعادة تعيين';
  @override
  String get clear => 'مسح';
  @override
  String get select => 'اختيار';
  @override
  String get deselect => 'إلغاء الاختيار';
  @override
  String get selectAll => 'تحديد الكل';
  @override
  String get deselectAll => 'إلغاء تحديد الكل';

  // Download Screens
  @override
  String get downloadAudio => 'تحميل الصوت';
  @override
  String get downloadVideo => 'تحميل الفيديو';
  @override
  String get downloaded => 'تم التحميل';
  @override
  String get notDownloaded => 'لم يتم التحميل';
  @override
  String get downloading => 'جارٍ التحميل...';
  @override
  String get downloadFailed => 'فشل التحميل';
  @override
  String get downloadSuccess => 'تم التحميل بنجاح';
  @override
  String get downloadCancelled => 'تم إلغاء التحميل';
  @override
  String get retry => 'إعادة المحاولة';
  @override
  String get cancel => 'إلغاء';
  @override
  String get delete => 'حذف';
  @override
  String get play => 'تشغيل';
  @override
  String get pause => 'إيقاف مؤقت';
  @override
  String get stop => 'توقف';

  // Error Messages & Dialogs
  @override
  String get error => 'خطأ';
  @override
  String get warning => 'تحذير';
  @override
  String get information => 'معلومات';
  @override
  String get success => 'نجح';
  @override
  String get ok => 'موافق';
  @override
  String get cancelButton => 'إلغاء';
  @override
  String get yes => 'نعم';
  @override
  String get no => 'لا';
  @override
  String get confirm => 'تأكيد';
  @override
  String get dismiss => 'إغلاق';

  // Status Messages
  @override
  String get dataLoading => 'جارٍ تحميل البيانات...';
  @override
  String get dataLoaded => 'تم تحميل البيانات';
  @override
  String get dataError => 'خطأ في البيانات';
  @override
  String get noDataFound => 'لم يتم العثور على بيانات';
  @override
  String get networkError => 'خطأ في الشبكة';
  @override
  String get connectionError => 'خطأ في الاتصال';
  @override
  String get serverError => 'خطأ في الخادم';
  @override
  String get unknownError => 'خطأ غير معروف';

  // Settings
  @override
  String get language => 'اللغة';
  @override
  String get theme => 'المظهر';
  @override
  String get systemTheme => 'مظهر النظام';
  @override
  String get notifications => 'الإشعارات';
  @override
  String get privacy => 'الخصوصية';
  @override
  String get termsConditions => 'الشروط والأحكام';
  @override
  String get version => 'الإصدار';

  // Quran Specific
  @override
  String get bismillah => 'بسم الله الرحمن الرحيم';
  @override
  String get verse => 'آية';
  @override
  String get verses => 'آيات';
  @override
  String get chapter => 'سورة';
  @override
  String get chapters => 'سور';
  @override
  String get juz => 'جزء';
  @override
  String get hizb => 'حزب';
  @override
  String get ruku => 'ركوع';
  @override
  String get sajda => 'سجدة';
  @override
  String get makki => 'مكي';
  @override
  String get madani => 'مدني';

  // Media Options
  @override
  String get lughatText => 'المفردات - نص';
  @override
  String get lughatAudio => 'المفردات - صوت';
  @override
  String get lughatVideo => 'المفردات - فيديو';
  @override
  String get tafseerText => 'التفسير - نص';
  @override
  String get tafseerAudio => 'التفسير - صوت';
  @override
  String get tafseerVideo => 'التفسير - فيديو';
  @override
  String get faidiText => 'الفوائد - نص';
  @override
  String get faidiAudio => 'الفوائد - صوت';
  @override
  String get faidiVideo => 'الفوائد - فيديو';
  @override
  String get comingSoon => 'قريباً';
  @override
  String get notAvailable => 'غير متاح';

  // Time & Date
  @override
  String get today => 'اليوم';
  @override
  String get yesterday => 'أمس';
  @override
  String get tomorrow => 'غداً';
  @override
  String get thisWeek => 'هذا الأسبوع';
  @override
  String get thisMonth => 'هذا الشهر';
  @override
  String get thisYear => 'هذا العام';

  // General Messages
  @override
  String get underDevelopment => 'تحت التطوير';
  @override
  String get featureNotAvailable => 'الميزة غير متاحة';
  @override
  String get pleaseWait => 'يرجى الانتظار';
  @override
  String get tryAgain => 'حاول مرة أخرى';
  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  // Language Switcher
  @override
  String get selectLanguage => 'اختر اللغة';
  @override
  String get languageChanged => 'تم تغيير اللغة';
  @override
  String get restartRequired => 'إعادة التشغيل مطلوبة';
  @override
  String get changeLanguage => 'تغيير اللغة';
  @override
  String get currentLanguage => 'اللغة الحالية';

  // Search Related
  @override
  String get searchResults => 'نتائج البحث';
  @override
  String get searchTerm => 'مصطلح البحث';
  @override
  String get searchEmpty => 'البحث فارغ';
  @override
  String get searchLoading => 'جارٍ البحث...';
  @override
  String get searchCompleted => 'تم البحث';
  @override
  String get matchFound => 'تطابق واحد';
  @override
  String get matchesFound => 'تطابقات موجودة';
  @override
  String get relevanceScore => 'درجة الصلة';

  // File Operations
  @override
  String get fileNotFound => 'الملف غير موجود';
  @override
  String get fileCorrupted => 'الملف تالف';
  @override
  String get fileSize => 'حجم الملف';
  @override
  String get downloadProgress => 'تقدم التحميل';
  @override
  String get downloadCompleted => 'اكتمل التحميل';
  @override
  String get storagePermission => 'إذن التخزين';
  @override
  String get insufficientStorage => 'مساحة تخزين غير كافية';

  // Accessibility
  @override
  String get accessibilityLabel => 'تسمية إمكانية الوصول';
  @override
  String get semanticLabel => 'التسمية الدلالية';
  @override
  String get hint => 'تلميح';
  @override
  String get tooltip => 'نصيحة الأداة';

  // Modal and Dialog Content
  @override
  String get verseOptions => 'خيارات الآية';
  @override
  String get verseVocabulary => 'مفردات الآية';
  @override
  String get verseCommentary => 'تفسير الآية';
  @override
  String get verseBenefits => 'فوائد الآية';
  @override
  String get text => 'نص';
  @override
  String get audio => 'صوت';
  @override
  String get video => 'فيديو';
  @override
  String get fontSettings => 'إعدادات الخط';
  @override
  String get arabicTextFont => 'خط النص العربي';
  @override
  String get downloadIssue => 'مشكلة في التحميل';
  @override
  String get downloadedFileDeleted => 'تم حذف الملف المحمل';

  // Error messages for media viewers
  @override
  String get audioPlaybackError => 'خطأ في تشغيل الصوت';
  @override
  String get videoPlaybackError => 'خطأ في تشغيل الفيديو';
  @override
  String get downloadError => 'خطأ في التحميل';
  @override
  String get networkConnectionError => 'خطأ في اتصال الشبكة';
  @override
  String get filePermissionError => 'خطأ في صلاحية الملف';
  @override
  String get insufficientSpaceError => 'خطأ مساحة غير كافية';
  @override
  String get unsupportedFormatError => 'خطأ تنسيق غير مدعوم';
  @override
  String get fileNotFoundError => 'خطأ الملف غير موجود';

  // Success messages
  @override
  String get audioDownloadSuccess => 'تم تحميل الصوت بنجاح';
  @override
  String get videoDownloadSuccess => 'تم تحميل الفيديو بنجاح';
  @override
  String get fileDeletedSuccess => 'تم حذف الملف بنجاح';

  // Download status messages
  @override
  String get audioNotDownloaded => 'الصوت غير محمل';
  @override
  String get videoNotDownloaded => 'الفيديو غير محمل';
  @override
  String get downloadInProgress => 'التحميل جارٍ';
  @override
  String get downloadCancelledStatus => 'تم إلغاء التحميل';
  @override
  String get audioDownloaded => 'تم تحميل الصوت';
  @override
  String get videoDownloaded => 'تم تحميل الفيديو';

  // Empty state messages
  @override
  String get noAudioDownloads => 'لا توجد تحميلات صوتية';
  @override
  String get noVideoDownloads => 'لا توجد تحميلات فيديو';
  @override
  String get downloadAudiosFromVerses => 'حمل الصوتيات من الآيات';
  @override
  String get downloadVideosFromVerses => 'حمل الفيديوهات من الآيات';

  // Verse-specific messages
  @override
  String get verseVocabularyTitle => 'مفردات الآية';
  @override
  String get vocabularyTextNotAvailable => 'نص المفردات غير متاح';
  @override
  String get vocabularyAudioNotAvailable => 'صوت المفردات غير متاح';
  @override
  String get vocabularyVideoNotAvailable => 'فيديو المفردات غير متاح';

  // Para-related
  @override
  String get paraNumber => 'رقم الجزء';
  @override
  String get paraLabel => 'جزء';
  @override
  String get videosCount => 'عدد الفيديوهات';
  @override
  String get audiosCount => 'عدد الملفات الصوتية';
  @override
  String get ayahsCount => '{count} آية';

  // Font settings specific
  @override
  String get textSizeLabel => 'حجم النص';
  @override
  String get fontTypeLabel => 'نوع الخط';
  @override
  String get fontSizeSmall => 'صغير';
  @override
  String get fontSizeMedium => 'متوسط';
  @override
  String get fontSizeLarge => 'كبير';
  @override
  String get fontSizeXLarge => 'كبير جداً';

  // Media type labels
  @override
  String get vocabularyVideo => 'فيديو المفردات';

  // Additional Methods (not in base class) - keeping them without @override
  String get done => 'تم';
  String get apply => 'تطبيق';
  String get share => 'مشاركة';
  String get copy => 'نسخ';
  String get paste => 'لصق';
  String get download => 'تحميل';
  String get forward => 'للأمام';
  String get downloadStarted => 'بدأ التحميل';
  String get downloadPaused => 'تم إيقاف التحميل مؤقتاً';
  String get resumeDownload => 'استكمال التحميل';
  String get pauseDownload => 'إيقاف التحميل مؤقتاً';
  String get cancelDownload => 'إلغاء التحميل';
  
  // Surah Modal
  @override
  String get searchByAyahNumber => 'البحث برقم الآية أو النص...';
  @override
  String get totalAyahsInfo => 'إجمالي الآيات';
  @override
  String get noAyahsFound => 'لم يتم العثور على آيات';
  
  // Bulk Audio Player
  @override
  String get bulkAudioPlayer => 'مشغل الصوت المتعدد';
  @override
  String get playbackSettings => 'إعدادات التشغيل';
  @override
  String get fromAyah => 'من الآية';
  @override
  String get toAyah => 'إلى الآية';
  @override
  String get playbackMode => 'وضع التشغيل';
  @override
  String get single => 'واحد';
  @override
  String get sequential => 'متسلسل';
  @override
  String get repeat => 'إعادة';
  @override
  String get autoPlayNext => 'تشغيل التالي تلقائياً';
  @override
  String get playingRange => 'نطاق التشغيل';
  @override
  String get number => 'رقم';
} 