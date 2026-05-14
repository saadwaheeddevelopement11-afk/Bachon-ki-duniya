import Foundation

/// Keys for UI strings resolved from `LanguageManager.shared.currentLanguageCode` (no app restart).
enum AppStringKey: String {
    case homeGreeting
    case homeSubtitle
    case homeNavTitle
    case homeLanguagesButton
    case homeQuickAccess
    case homeCategories
    case tabHome
    case tabSearch
    case tabLibrary
    case tabProfile
    case searchTitle
    case searchPlaceholder
    case searchShortPlaceholder
    case libraryTitle
    case librarySubtitle
    case librarySearchPlaceholder
    case librarySearchShortPlaceholder
    case languageSheetTitle
    case languageSheetSubtitle
    case recentEpisodesSection
    case specialOfferTitle
    case specialOfferSubtitle
    case storiesDefaultTitle
    case subcategoriesFallbackTitle
    case errorTitle
    case successTitle
    case ok
    case retry
    case cancel
    case change
    case changeLanguageTitle
    case changeLanguageMessageFormat
    case languageChangedFormat
    case failedToLoadLanguagesFormat
    case failedToLoadCategoriesFormat
    case failedToLoadContentFormat
    case profileYourReport
    case profileTotalWatchTime
    case profileMostWatchedCategory
    case profileParentalControls
    case profileNotifications
    case profileSelectLanguage
    case profileFAQs
    case profileTermsOfService
    case profileSampleCategoryName
    case profileWatchTimeSample
    case ahadeesSampleTitle
    case ahadeesSampleSubtitle
    case profileLogoutTitle
    case profileLogoutMessage
    case profileLogoutAction
}

enum AppL10n {

    static func t(_ key: AppStringKey) -> String {
        let bucket = languageBucket()
        if let row = table[bucket], let s = row[key] { return s }
        return table["en"]![key]!
    }

    static func t(_ key: AppStringKey, _ arg1: CVarArg) -> String {
        String(format: t(key), arg1)
    }

    private static func languageBucket() -> String {
        let c = LanguageManager.shared.currentLanguageCode.lowercased()
        if c.hasPrefix("ur") { return "ur" }
        if c.hasPrefix("ar") { return "ar" }
        return "en"
    }

    private static let table: [String: [AppStringKey: String]] = [
        "en": [
            .homeGreeting: "Hey Champ 👋",
            .homeSubtitle: "Shall we learn something new today?",
            .homeNavTitle: "Home",
            .homeLanguagesButton: "🌐 Languages",
            .homeQuickAccess: "Quick access",
            .homeCategories: "Categories",
            .tabHome: "Home",
            .tabSearch: "Search",
            .tabLibrary: "Library",
            .tabProfile: "Profile",
            .searchTitle: "Search",
            .searchPlaceholder: "Search stories, poems, quizzes...",
            .searchShortPlaceholder: "Search",
            .libraryTitle: "Library",
            .librarySubtitle: "Pick up where you left off",
            .librarySearchPlaceholder: "Search from your saved library...",
            .librarySearchShortPlaceholder: "Search",
            .languageSheetTitle: "Select Language",
            .languageSheetSubtitle: "Please Select Preferred Language",
            .recentEpisodesSection: "Recent Episodes",
            .specialOfferTitle: "Special Offer",
            .specialOfferSubtitle: "Discover More",
            .storiesDefaultTitle: "Stories",
            .subcategoriesFallbackTitle: "Subcategories",
            .errorTitle: "Error",
            .successTitle: "Success",
            .ok: "OK",
            .retry: "Retry",
            .cancel: "Cancel",
            .change: "Change",
            .changeLanguageTitle: "Change Language",
            .changeLanguageMessageFormat: "Do you want to change the language to %@?",
            .languageChangedFormat: "Language changed to %@",
            .failedToLoadLanguagesFormat: "Failed to load languages: %@",
            .failedToLoadCategoriesFormat: "Failed to load categories: %@",
            .failedToLoadContentFormat: "Failed to load content: %@",
            .profileYourReport: "Your Report",
            .profileTotalWatchTime: "Total Watch Time",
            .profileMostWatchedCategory: "Most Watched Category",
            .profileParentalControls: "Parental Controls",
            .profileNotifications: "Notifications",
            .profileSelectLanguage: "Select Language",
            .profileFAQs: "FAQs",
            .profileTermsOfService: "Terms Of Service",
            .profileSampleCategoryName: "Kids Stories",
            .profileWatchTimeSample: "30min 15sec",
            .ahadeesSampleTitle: "Whoever believes in Allah and the last day should...",
            .ahadeesSampleSubtitle: "- Sahih Al Bukhari 6136",
            .profileLogoutTitle: "Log out?",
            .profileLogoutMessage: "You will need to sign in again to use your account.",
            .profileLogoutAction: "Log out"
        ],
        "ur": [
            .homeGreeting: "ارے چیمپ 👋",
            .homeSubtitle: "آج کچھ نیا سیکھیں؟",
            .homeNavTitle: "ہوم",
            .homeLanguagesButton: "🌐 زبانیں",
            .homeQuickAccess: "فوری رسائی",
            .homeCategories: "اقسام",
            .tabHome: "ہوم",
            .tabSearch: "تلاش",
            .tabLibrary: "لائبریری",
            .tabProfile: "پروفائل",
            .searchTitle: "تلاش",
            .searchPlaceholder: "کہانیاں، نظمیں، کوئز تلاش کریں...",
            .searchShortPlaceholder: "تلاش",
            .libraryTitle: "لائبریری",
            .librarySubtitle: "جہاں سے چھوڑا تھا وہیں سے شروع کریں",
            .librarySearchPlaceholder: "اپنی محفوظ کردہ لائبریری میں تلاش کریں...",
            .librarySearchShortPlaceholder: "تلاش",
            .languageSheetTitle: "زبان منتخب کریں",
            .languageSheetSubtitle: "براہ کرم اپنی پسندیدہ زبان منتخب کریں",
            .recentEpisodesSection: "حالیہ اقساط",
            .specialOfferTitle: "خصوصی پیشکش",
            .specialOfferSubtitle: "مزید دریافت کریں",
            .storiesDefaultTitle: "کہانیاں",
            .subcategoriesFallbackTitle: "ذیلی اقسام",
            .errorTitle: "خرابی",
            .successTitle: "کامیابی",
            .ok: "ٹھیک ہے",
            .retry: "دوبارہ کوشش",
            .cancel: "منسوخ",
            .change: "تبدیل کریں",
            .changeLanguageTitle: "زبان تبدیل کریں",
            .changeLanguageMessageFormat: "کیا آپ زبان %@ میں بدلنا چاہتے ہیں؟",
            .languageChangedFormat: "زبان %@ میں بدل دی گئی",
            .failedToLoadLanguagesFormat: "زبانیں لوڈ نہیں ہو سکیں: %@",
            .failedToLoadCategoriesFormat: "اقسام لوڈ نہیں ہو سکیں: %@",
            .failedToLoadContentFormat: "مواد لوڈ نہیں ہو سکا: %@",
            .profileYourReport: "آپ کی رپورٹ",
            .profileTotalWatchTime: "کل دیکھا گیا وقت",
            .profileMostWatchedCategory: "سب سے زیادہ دیکھی گئی قسم",
            .profileParentalControls: "والدین کا کنٹرول",
            .profileNotifications: "اطلاعات",
            .profileSelectLanguage: "زبان منتخب کریں",
            .profileFAQs: "اکثر پوچھے گئے سوالات",
            .profileTermsOfService: "سروس کی شرائط",
            .profileSampleCategoryName: "بچوں کی کہانیاں",
            .profileWatchTimeSample: "30 منٹ 15 سیکنڈ",
            .ahadeesSampleTitle: "جو اللہ اور آخرت پر ایمان رکھتا ہے وہ...",
            .ahadeesSampleSubtitle: "- صحیح بخاری ۶۱۳۶",
            .profileLogoutTitle: "لاگ آؤٹ؟",
            .profileLogoutMessage: "دوبارہ استعمال کے لیے آپ کو سائن ان کرنا ہوگا۔",
            .profileLogoutAction: "لاگ آؤٹ"
        ],
        "ar": [
            .homeGreeting: "مرحباً أيها البطل 👋",
            .homeSubtitle: "هل نتعلم شيئاً جديداً اليوم؟",
            .homeNavTitle: "الصفحة الرئيسية",
            .homeLanguagesButton: "🌐 لغات",
            .homeQuickAccess: "وصول سريع",
            .homeCategories: "الفئات",
            .tabHome: "الرئيسية",
            .tabSearch: "بحث",
            .tabLibrary: "المكتبة",
            .tabProfile: "الملف",
            .searchTitle: "بحث",
            .searchPlaceholder: "ابحث عن قصص وأشعار وألغاز...",
            .searchShortPlaceholder: "بحث",
            .libraryTitle: "المكتبة",
            .librarySubtitle: "تابع من حيث توقفت",
            .librarySearchPlaceholder: "ابحث في مكتبتك المحفوظة...",
            .librarySearchShortPlaceholder: "بحث",
            .languageSheetTitle: "اختر اللغة",
            .languageSheetSubtitle: "يرجى اختيار اللغة المفضلة",
            .recentEpisodesSection: "الحلقات الأخيرة",
            .specialOfferTitle: "عرض خاص",
            .specialOfferSubtitle: "اكتشف المزيد",
            .storiesDefaultTitle: "قصص",
            .subcategoriesFallbackTitle: "فئات فرعية",
            .errorTitle: "خطأ",
            .successTitle: "نجاح",
            .ok: "موافق",
            .retry: "إعادة المحاولة",
            .cancel: "إلغاء",
            .change: "تغيير",
            .changeLanguageTitle: "تغيير اللغة",
            .changeLanguageMessageFormat: "هل تريد تغيير اللغة إلى %@؟",
            .languageChangedFormat: "تم تغيير اللغة إلى %@",
            .failedToLoadLanguagesFormat: "تعذر تحميل اللغات: %@",
            .failedToLoadCategoriesFormat: "تعذر تحميل الفئات: %@",
            .failedToLoadContentFormat: "تعذر تحميل المحتوى: %@",
            .profileYourReport: "تقريرك",
            .profileTotalWatchTime: "إجمالي وقت المشاهدة",
            .profileMostWatchedCategory: "أكثر فئة مشاهدة",
            .profileParentalControls: "الرقابة الأبوية",
            .profileNotifications: "الإشعارات",
            .profileSelectLanguage: "اختر اللغة",
            .profileFAQs: "الأسئلة الشائعة",
            .profileTermsOfService: "شروط الخدمة",
            .profileSampleCategoryName: "قصص الأطفال",
            .profileWatchTimeSample: "30 دقيقة 15 ثانية",
            .ahadeesSampleTitle: "من آمن بالله واليوم الآخر فليقل خيراً أو ليصمت...",
            .ahadeesSampleSubtitle: "- صحيح البخاري 6136",
            .profileLogoutTitle: "تسجيل الخروج؟",
            .profileLogoutMessage: "ستحتاج إلى تسجيل الدخول مرة أخرى لاستخدام حسابك.",
            .profileLogoutAction: "تسجيل الخروج"
        ]
    ]
}
