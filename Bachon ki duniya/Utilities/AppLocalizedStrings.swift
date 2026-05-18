import Foundation

/// Runtime UI copy for `LanguageManager` languages (no app restart). Add new keys here and provide `en` + `ur` (+ `ar` when needed).
enum AppStringKey: String, CaseIterable {
    case homeGreeting
    case homeSubtitle
    case homeNavTitle
    case homeLanguagesButton
    case homeQuickAccess
    case homeCategories
    case searchTitle
    case searchPlaceholder
    case searchShortPlaceholder
    case libraryTitle
    case librarySubtitle
    case librarySearchPlaceholder
    case librarySearchShortPlaceholder
    case languageSheetTitle
    case languageSheetSubtitle
    case categoryScreenSubtitle
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
}

enum AppLocalizedStrings {

    static func text(_ key: AppStringKey) -> String {
        let lang = normalizedLanguageBucket()
        if let v = table[lang]?[key] { return v }
        return table["en"]![key]!
    }

    static func text(_ key: AppStringKey, _ args: CVarArg...) -> String {
        let format = text(key)
        return String(format: format, arguments: args)
    }

    private static func normalizedLanguageBucket() -> String {
        let raw = LanguageManager.shared.currentLanguageCode.lowercased()
        if raw.hasPrefix("ur") { return "ur" }
        if raw.hasPrefix("ar") { return "ar" }
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
            .searchTitle: "Search",
            .searchPlaceholder: "Search stories, poems, quizzes...",
            .searchShortPlaceholder: "Search",
            .libraryTitle: "Library",
            .librarySubtitle: "Pick up where you left off",
            .librarySearchPlaceholder: "Search from your saved library...",
            .librarySearchShortPlaceholder: "Search",
            .languageSheetTitle: "Select Language",
            .languageSheetSubtitle: "Please Select Preferred Language",
            .categoryScreenSubtitle: "Explore fun lessons and stories",
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
            .profileWatchTimeSample: "30min 15sec"
        ],
        "ur": [
            .homeGreeting: "ارے چیمپ 👋",
            .homeSubtitle: "آج کچھ نیا سیکھیں؟",
            .homeNavTitle: "ہوم",
            .homeLanguagesButton: "🌐 زبانیں",
            .homeQuickAccess: "فوری رسائی",
            .homeCategories: "اقسام",
            .searchTitle: "تلاش",
            .searchPlaceholder: "کہانیاں، نظمیں، کوئز تلاش کریں...",
            .searchShortPlaceholder: "تلاش",
            .libraryTitle: "لائبریری",
            .librarySubtitle: "جہاں سے چھوڑا تھا وہیں سے شروع کریں",
            .librarySearchPlaceholder: "اپنی محفوظ کردہ لائبریری میں تلاش کریں...",
            .librarySearchShortPlaceholder: "تلاش",
            .languageSheetTitle: "زبان منتخب کریں",
            .languageSheetSubtitle: "براہ کرم اپنی پسندیدہ زبان منتخب کریں",
            .categoryScreenSubtitle: "دلچسپ سبق اور کہانیاں دریافت کریں",
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
            .profileWatchTimeSample: "30 منٹ 15 سیکنڈ"
        ],
        "ar": [
            .homeGreeting: "مرحباً أيها البطل 👋",
            .homeSubtitle: "هل نتعلم شيئاً جديداً اليوم؟",
            .homeNavTitle: "الصفحة الرئيسية",
            .homeLanguagesButton: "🌐 لغات",
            .homeQuickAccess: "وصول سريع",
            .homeCategories: "الفئات",
            .searchTitle: "بحث",
            .searchPlaceholder: "ابحث عن قصص وأشعار وألغاز...",
            .searchShortPlaceholder: "بحث",
            .libraryTitle: "المكتبة",
            .librarySubtitle: "تابع من حيث توقفت",
            .librarySearchPlaceholder: "ابحث في مكتبتك المحفوظة...",
            .librarySearchShortPlaceholder: "بحث",
            .languageSheetTitle: "اختر اللغة",
            .languageSheetSubtitle: "يرجى اختيار اللغة المفضلة",
            .categoryScreenSubtitle: "استكشف دروساً وقصصاً ممتعة",
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
            .profileWatchTimeSample: "30 دقيقة 15 ثانية"
        ]
    ]
}
