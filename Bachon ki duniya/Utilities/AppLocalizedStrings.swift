import Foundation

/// Runtime UI copy for `LanguageManager` languages (no app restart). Add new keys here and provide `en` + `ur` (+ `ar` when needed).
enum AppStringKey: String, CaseIterable {
    case homeGreeting
    case homeSubtitle
    case homeNavTitle
    case homeLanguagesButton
    case homeQuickAccess
    case homeCategories
    case homeContinueWatching
    case quickAccessStories
    case quickAccessDiscover
    case quickAccessLearn
    case quickAccessQuizzes
    case quickAccessGames
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
    case tabHome
    case tabSearch
    case tabLibrary
    case tabProfile
    case ahadeesSampleTitle
    case ahadeesSampleSubtitle
    case profileLogoutTitle
    case profileLogoutMessage
    case profileLogoutAction
    case profileChangePhotoTitle
    case profileChooseFromLibrary
    case profileTakePhoto
    case profileRemovePhoto
    case profilePhotoSaveFailed
    case screenTimeTitle
    case screenTimeTotalLabel
    case screenTimeInfo
    case screenTimeEmpty
    case screenTimeEmptyHint
    case screenTimeToday
    case screenTimeYesterday
    case screenTimeOneSession
    case screenTimeSessionCount
    case parentalReportTitle
    case parentalWeeklyUsage
    case parentalUsageLegend
    case parentalTotalUsage
    case parentalTodayUsage
    case parentalDailyLimit
    case parentalEnterPIN
    case parentalUpdateLimit
    case parentalLimitUpdatedDemo
    case parentalSetupTitle
    case parentalVerifyTitle
    case parentalSetupHint
    case parentalVerifyHint
    case parentalCreatePIN
    case parentalConfirmPIN
    case parentalEnable
    case parentalUnlock
    case parentalForgotPIN
    case parentalDisable
    case parentalDisableConfirm
    case parentalEnterPINToDisable
    case parentalLockedCategories
    case parentalLockHint
    case parentalNoCategories
    case parentalPINInvalid
    case parentalPINMismatch
    case parentalPINWrong
    case parentalNeedPhone
    case parentalNoLimit
    case parentalMinutes
    case parentalNewPINOptional
    case parentalChangePIN
    case parentalChangePINHint
    case parentalCurrentPIN
    case parentalSaveNewPIN
    case parentalResetPINTitle
    case parentalResetHint
    case parentalSendOTP
    case parentalEnterOTP
    case parentalConfirmReset
    case parentalCategoryLockedTitle
    case parentalCategoryLockedMessage
    case continueWatchingEmpty
    case profileSeeAll
}

enum AppL10n {
    static func t(_ key: AppStringKey) -> String {
        AppLocalizedStrings.text(key)
    }

    static func t(_ key: AppStringKey, _ arg1: CVarArg) -> String {
        String(format: AppLocalizedStrings.text(key), arg1)
    }
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
        if raw.hasPrefix("ur") || raw == "urd" { return "ur" }
        if raw.hasPrefix("ar") { return "ar" }
        // Sindhi: API uses `sd` / `snd`
        if raw.hasPrefix("sd") || raw == "snd" { return "sd" }
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
            .homeContinueWatching: "Continue Watching",
            .quickAccessStories: "Stories",
            .quickAccessDiscover: "Discover",
            .quickAccessLearn: "Learn",
            .quickAccessQuizzes: "Quizzes",
            .quickAccessGames: "Games",
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
            .profileTotalWatchTime: "Total Screen Time",
            .profileMostWatchedCategory: "Most Watched Category",
            .profileParentalControls: "Parental Controls",
            .profileNotifications: "Notifications",
            .profileSelectLanguage: "Select Language",
            .profileFAQs: "FAQs",
            .profileTermsOfService: "Terms Of Service",
            .profileSampleCategoryName: "Kids Stories",
            .profileWatchTimeSample: "30min 15sec",
            .tabHome: "Home",
            .tabSearch: "Search",
            .tabLibrary: "Library",
            .tabProfile: "Profile",
            .ahadeesSampleTitle: "Whoever believes in Allah and the last day should...",
            .ahadeesSampleSubtitle: "- Sahih Al Bukhari 6136",
            .profileLogoutTitle: "Log out?",
            .profileLogoutMessage: "You will need to sign in again to use your account.",
            .profileLogoutAction: "Log out",
            .profileChangePhotoTitle: "Change profile photo",
            .profileChooseFromLibrary: "Choose from Library",
            .profileTakePhoto: "Take Photo",
            .profileRemovePhoto: "Remove Photo",
            .profilePhotoSaveFailed: "Could not save your photo. Please try again.",
            .screenTimeTitle: "Screen Time",
            .screenTimeTotalLabel: "Total Screen Time",
            .screenTimeInfo: "Track active usage sessions recorded each time this app is open in the foreground. Times are saved locally and update automatically when you switch apps.",
            .screenTimeEmpty: "No days tracked yet",
            .screenTimeEmptyHint: "Open the app to start tracking screen time by day.",
            .screenTimeToday: "Today",
            .screenTimeYesterday: "Yesterday",
            .screenTimeOneSession: "1 session",
            .screenTimeSessionCount: "%d sessions",
            .parentalReportTitle: "Your Report",
            .parentalWeeklyUsage: "Weekly Usage",
            .parentalUsageLegend: "Usage (min)",
            .parentalTotalUsage: "Total Usage",
            .parentalTodayUsage: "Today Usage",
            .parentalDailyLimit: "Daily Limit",
            .parentalEnterPIN: "Enter PIN",
            .parentalUpdateLimit: "Update Limit",
            .parentalLimitUpdatedDemo: "Daily limit updated (demo). Real PIN checks will be added later.",
            .parentalSetupTitle: "Set Parental PIN",
            .parentalVerifyTitle: "Enter Parental PIN",
            .parentalSetupHint: "Create a PIN to enable parental controls, set a daily limit, and lock categories.",
            .parentalVerifyHint: "Enter your parental PIN to manage limits and locked categories.",
            .parentalCreatePIN: "Create PIN (4–6 digits)",
            .parentalConfirmPIN: "Confirm PIN",
            .parentalEnable: "Enable Parental Controls",
            .parentalUnlock: "Unlock",
            .parentalForgotPIN: "Forgot PIN?",
            .parentalDisable: "Disable Parental Controls",
            .parentalDisableConfirm: "This will turn off parental controls and unlock all categories.",
            .parentalEnterPINToDisable: "Enter your current PIN above to disable parental controls.",
            .parentalLockedCategories: "Lock Categories",
            .parentalLockHint: "Locked categories need a PIN before a child can open them.",
            .parentalNoCategories: "No categories loaded yet.",
            .parentalPINInvalid: "Please enter a valid 4–6 digit PIN.",
            .parentalPINMismatch: "PIN and confirmation do not match.",
            .parentalPINWrong: "Incorrect PIN.",
            .parentalNeedPhone: "A phone number is required for parental controls. Please sign in again.",
            .parentalNoLimit: "No daily limit",
            .parentalMinutes: "minutes",
            .parentalNewPINOptional: "New PIN (optional)",
            .parentalChangePIN: "Change PIN",
            .parentalChangePINHint: "Enter your current PIN, then choose a new 4–6 digit PIN.",
            .parentalCurrentPIN: "Current PIN",
            .parentalSaveNewPIN: "Save New PIN",
            .parentalResetPINTitle: "Reset Parental PIN",
            .parentalResetHint: "We'll send an OTP to your registered phone number to reset the parental PIN.",
            .parentalSendOTP: "Send OTP",
            .parentalEnterOTP: "Enter OTP",
            .parentalConfirmReset: "Confirm New PIN",
            .parentalCategoryLockedTitle: "Category Locked",
            .parentalCategoryLockedMessage: "Enter the parental PIN to open this category.",
            .continueWatchingEmpty: "Nothing to continue yet. Start watching a video from Home.",
            .profileSeeAll: "See All"
        ],
        "ur": [
            .homeGreeting: "ارے چیمپ 👋",
            .homeSubtitle: "آج کچھ نیا سیکھیں؟",
            .homeNavTitle: "ہوم",
            .homeLanguagesButton: "🌐 زبانیں",
            .homeQuickAccess: "فوری رسائی",
            .homeCategories: "اقسام",
            .homeContinueWatching: "دیکھنا جاری رکھیں",
            .quickAccessStories: "کہانیاں",
            .quickAccessDiscover: "دریافت",
            .quickAccessLearn: "سیکھیں",
            .quickAccessQuizzes: "کوئز",
            .quickAccessGames: "کھیل",
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
            .profileTotalWatchTime: "کل اسکرین ٹائم",
            .profileMostWatchedCategory: "سب سے زیادہ دیکھی گئی قسم",
            .profileParentalControls: "والدین کا کنٹرول",
            .profileNotifications: "اطلاعات",
            .profileSelectLanguage: "زبان منتخب کریں",
            .profileFAQs: "اکثر پوچھے گئے سوالات",
            .profileTermsOfService: "سروس کی شرائط",
            .profileSampleCategoryName: "بچوں کی کہانیاں",
            .profileWatchTimeSample: "30 منٹ 15 سیکنڈ",
            .tabHome: "ہوم",
            .tabSearch: "تلاش",
            .tabLibrary: "لائبریری",
            .tabProfile: "پروفائل",
            .ahadeesSampleTitle: "جو اللہ اور آخرت پر ایمان رکھتا ہے وہ...",
            .ahadeesSampleSubtitle: "- صحیح بخاری ۶۱۳۶",
            .profileLogoutTitle: "لاگ آؤٹ؟",
            .profileLogoutMessage: "دوبارہ استعمال کے لیے آپ کو سائن ان کرنا ہوگا۔",
            .profileLogoutAction: "لاگ آؤٹ",
            .profileChangePhotoTitle: "پروفائل تصویر تبدیل کریں",
            .profileChooseFromLibrary: "گیلری سے منتخب کریں",
            .profileTakePhoto: "تصویر لیں",
            .profileRemovePhoto: "تصویر ہٹائیں",
            .profilePhotoSaveFailed: "تصویر محفوظ نہیں ہو سکی۔ دوبارہ کوشش کریں۔",
            .screenTimeTitle: "اسکرین ٹائم",
            .screenTimeTotalLabel: "کل اسکرین ٹائم",
            .screenTimeInfo: "جب بھی یہ ایپ کھلی ہو تو فعال استعمال ریکارڈ ہوتا ہے۔ اوقات مقامی طور پر محفوظ ہوتے ہیں اور ایپ بدلنے پر خود بخود اپڈیٹ ہوتے ہیں۔",
            .screenTimeEmpty: "ابھی کوئی دن نہیں",
            .screenTimeEmptyHint: "روزانہ اسکرین ٹائم شروع کرنے کے لیے ایپ کھولیں۔",
            .screenTimeToday: "آج",
            .screenTimeYesterday: "کل",
            .screenTimeOneSession: "1 سیشن",
            .screenTimeSessionCount: "%d سیشن",
            .parentalReportTitle: "آپ کی رپورٹ",
            .parentalWeeklyUsage: "ہفتہ وار استعمال",
            .parentalUsageLegend: "استعمال (منٹ)",
            .parentalTotalUsage: "کل استعمال",
            .parentalTodayUsage: "آج کا استعمال",
            .parentalDailyLimit: "یومیہ حد",
            .parentalEnterPIN: "PIN درج کریں",
            .parentalUpdateLimit: "حد اپڈیٹ کریں",
            .parentalLimitUpdatedDemo: "یومیہ حد اپڈیٹ ہو گئی (ڈیمو)۔ حقیقی PIN بعد میں شامل ہوگا۔",
            .continueWatchingEmpty: "ابھی جاری رکھنے کے لیے کچھ نہیں۔ ہوم سے ویڈیو دیکھنا شروع کریں۔",
            .profileSeeAll: "سب دیکھیں"
        ],
        "sd": [
            .homeGreeting: "ارے چيمپ 👋",
            .homeSubtitle: "اڄ ڪجھ نئون سکو؟",
            .homeNavTitle: "گهر",
            .homeLanguagesButton: "🌐 ٻوليون",
            .homeQuickAccess: "فوري رسائي",
            .homeCategories: "قسمون",
            .homeContinueWatching: "ڏسڻ جاري رکو",
            .quickAccessStories: "ڪهاڻيون",
            .quickAccessDiscover: "دريافت",
            .quickAccessLearn: "سکو",
            .quickAccessQuizzes: "ڪوئز",
            .quickAccessGames: "رانديون",
            .searchTitle: "ڳولا",
            .searchPlaceholder: "ڪهاڻيون، نظمون، ڪوئز ڳوليو...",
            .searchShortPlaceholder: "ڳولا",
            .libraryTitle: "لائبريري",
            .librarySubtitle: "جيڏهن ڇڏيو هو اتان شروع ڪريو",
            .librarySearchPlaceholder: "پنهنجي محفوظ لائبريري ۾ ڳوليو...",
            .librarySearchShortPlaceholder: "ڳولا",
            .languageSheetTitle: "ٻولي چونڊيو",
            .languageSheetSubtitle: "مهرباني ڪري پنهنجي پسنديده ٻولي چونڊيو",
            .categoryScreenSubtitle: "دلچسپ سبق ۽ ڪهاڻيون دريافت ڪريو",
            .recentEpisodesSection: "تازيون قسطون",
            .specialOfferTitle: "خاص پيشڪش",
            .specialOfferSubtitle: "وڌيڪ دريافت ڪريو",
            .storiesDefaultTitle: "ڪهاڻيون",
            .subcategoriesFallbackTitle: "ذيلي قسمون",
            .errorTitle: "غلطی",
            .successTitle: "ڪاميابي",
            .ok: "ٺيڪ آهي",
            .retry: "ٻيهر ڪوشش",
            .cancel: "منسوخ",
            .change: "تبديل ڪريو",
            .changeLanguageTitle: "ٻولي تبديل ڪريو",
            .changeLanguageMessageFormat: "ڇا توهان ٻولي %@ ۾ تبديل ڪرڻ چاهيو ٿا؟",
            .languageChangedFormat: "ٻولي %@ ۾ تبديل ٿي وئي",
            .failedToLoadLanguagesFormat: "ٻوليون لوڊ نه ٿي سگهيون: %@",
            .failedToLoadCategoriesFormat: "قسمون لوڊ نه ٿي سگهيون: %@",
            .failedToLoadContentFormat: "مواد لوڊ نه ٿي سگهيو: %@",
            .profileYourReport: "توهان جي رپورٽ",
            .profileTotalWatchTime: "ڪل اسڪرين ٽائيم",
            .profileMostWatchedCategory: "سڀ کان وڌيڪ ڏٺل قسم",
            .profileParentalControls: "والدين جو ڪنٽرول",
            .profileNotifications: "اطلاعات",
            .profileSelectLanguage: "ٻولي چونڊيو",
            .profileFAQs: "اڪثر پڇيا ويا سوال",
            .profileTermsOfService: "سروس جون شرطون",
            .profileSampleCategoryName: "ٻارن جون ڪهاڻيون",
            .profileWatchTimeSample: "30 منٽ 15 سيڪنڊ",
            .tabHome: "گهر",
            .tabSearch: "ڳولا",
            .tabLibrary: "لائبريري",
            .tabProfile: "پروفائل",
            .ahadeesSampleTitle: "جيڪو الله ۽ قيامت تي ايمان رکي ٿو اهو...",
            .ahadeesSampleSubtitle: "- صحيح بخاري ٦١٣٦",
            .profileLogoutTitle: "لاگ آئوٽ؟",
            .profileLogoutMessage: "ٻيهر استعمال لاءِ توهان کي سائن ان ڪرڻو پوندو.",
            .profileLogoutAction: "لاگ آئوٽ",
            .profileChangePhotoTitle: "پروفائل تصوير تبديل ڪريو",
            .profileChooseFromLibrary: "گيلري مان چونڊيو",
            .profileTakePhoto: "تصوير ڪڍو",
            .profileRemovePhoto: "تصوير هٽايو",
            .profilePhotoSaveFailed: "تصوير محفوظ نه ٿي سگهي. ٻيهر ڪوشش ڪريو.",
            .screenTimeTitle: "اسڪرين ٽائيم",
            .screenTimeTotalLabel: "ڪل اسڪرين ٽائيم",
            .screenTimeInfo: "جڏهن به هي ايپ کليل هجي ته فعال استعمال رڪارڊ ٿئي ٿو. وقت مقامي طور محفوظ ٿين ٿا ۽ ايپ مٽائڻ تي پاڻمرادو اپڊيٽ ٿين ٿا.",
            .screenTimeEmpty: "اڃا ڪو ڏينهن نه آهي",
            .screenTimeEmptyHint: "روزاني اسڪرين ٽائيم شروع ڪرڻ لاءِ ايپ کوليو.",
            .screenTimeToday: "اڄ",
            .screenTimeYesterday: "ڪالهه",
            .screenTimeOneSession: "1 سيشن",
            .screenTimeSessionCount: "%d سيشن",
            .parentalReportTitle: "توهان جي رپورٽ",
            .parentalWeeklyUsage: "هفتيوار استعمال",
            .parentalUsageLegend: "استعمال (منٽ)",
            .parentalTotalUsage: "ڪل استعمال",
            .parentalTodayUsage: "اڄ جو استعمال",
            .parentalDailyLimit: "روزاني حد",
            .parentalEnterPIN: "PIN داخل ڪريو",
            .parentalUpdateLimit: "حد اپڊيٽ ڪريو",
            .parentalLimitUpdatedDemo: "روزاني حد اپڊيٽ ٿي (ڊيمو). حقيقي PIN بعد ۾ شامل ٿيندو.",
            .continueWatchingEmpty: "اڃا جاري رکڻ لاءِ ڪجهه نه آهي. هوم کان وڊيو ڏسڻ شروع ڪريو.",
            .profileSeeAll: "سڀ ڏسو"
        ],
        "ar": [
            .homeGreeting: "مرحباً أيها البطل 👋",
            .homeSubtitle: "هل نتعلم شيئاً جديداً اليوم؟",
            .homeNavTitle: "الصفحة الرئيسية",
            .homeLanguagesButton: "🌐 لغات",
            .homeQuickAccess: "وصول سريع",
            .homeCategories: "الفئات",
            .homeContinueWatching: "متابعة المشاهدة",
            .quickAccessStories: "قصص",
            .quickAccessDiscover: "اكتشف",
            .quickAccessLearn: "تعلّم",
            .quickAccessQuizzes: "اختبارات",
            .quickAccessGames: "ألعاب",
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
            .profileTotalWatchTime: "إجمالي وقت الشاشة",
            .profileMostWatchedCategory: "أكثر فئة مشاهدة",
            .profileParentalControls: "الرقابة الأبوية",
            .profileNotifications: "الإشعارات",
            .profileSelectLanguage: "اختر اللغة",
            .profileFAQs: "الأسئلة الشائعة",
            .profileTermsOfService: "شروط الخدمة",
            .profileSampleCategoryName: "قصص الأطفال",
            .profileWatchTimeSample: "30 دقيقة 15 ثانية",
            .tabHome: "الرئيسية",
            .tabSearch: "بحث",
            .tabLibrary: "المكتبة",
            .tabProfile: "الملف",
            .ahadeesSampleTitle: "من آمن بالله واليوم الآخر فليقل خيراً أو ليصمت...",
            .ahadeesSampleSubtitle: "- صحيح البخاري 6136",
            .profileLogoutTitle: "تسجيل الخروج؟",
            .profileLogoutMessage: "ستحتاج إلى تسجيل الدخول مرة أخرى لاستخدام حسابك.",
            .profileLogoutAction: "تسجيل الخروج",
            .profileChangePhotoTitle: "تغيير صورة الملف",
            .profileChooseFromLibrary: "اختر من المعرض",
            .profileTakePhoto: "التقاط صورة",
            .profileRemovePhoto: "إزالة الصورة",
            .profilePhotoSaveFailed: "تعذر حفظ الصورة. حاول مرة أخرى.",
            .screenTimeTitle: "وقت الشاشة",
            .screenTimeTotalLabel: "إجمالي وقت الشاشة",
            .screenTimeInfo: "يتم تسجيل جلسات الاستخدام النشط كلما كان التطبيق مفتوحاً في المقدمة. تُحفظ الأوقات محلياً وتُحدَّث تلقائياً عند التبديل.",
            .screenTimeEmpty: "لا أيام مسجّلة بعد",
            .screenTimeEmptyHint: "افتح التطبيق لبدء تتبع وقت الشاشة يومياً.",
            .screenTimeToday: "اليوم",
            .screenTimeYesterday: "أمس",
            .screenTimeOneSession: "جلسة واحدة",
            .screenTimeSessionCount: "%d جلسات",
            .parentalReportTitle: "تقريرك",
            .parentalWeeklyUsage: "الاستخدام الأسبوعي",
            .parentalUsageLegend: "الاستخدام (دقيقة)",
            .parentalTotalUsage: "إجمالي الاستخدام",
            .parentalTodayUsage: "استخدام اليوم",
            .parentalDailyLimit: "الحد اليومي",
            .parentalEnterPIN: "أدخل الرمز",
            .parentalUpdateLimit: "تحديث الحد",
            .parentalLimitUpdatedDemo: "تم تحديث الحد اليومي (تجريبي). سيتم إضافة التحقق بالرمز لاحقاً.",
            .continueWatchingEmpty: "لا يوجد شيء للمتابعة بعد. ابدأ مشاهدة فيديو من الرئيسية.",
            .profileSeeAll: "عرض الكل"
        ]
    ]
}
