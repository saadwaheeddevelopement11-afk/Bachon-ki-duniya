import Foundation

/// Runtime UI copy for `LanguageManager` languages (no app restart).
/// Urdu (`ur`) uses Roman Urdu (Latin script) — do not add Nastaliq/Arabic-script Urdu here.
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
    case profileBookmarks
    case profileSubscriptions
    case profileSubscriptionsUnavailable
    case bookmarksEmpty
    case profileFAQs
    case profileTermsOfService
    case profilePrivacyPolicy
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
            .profileBookmarks: "Bookmarks",
            .profileSubscriptions: "Subscriptions",
            .profileSubscriptionsUnavailable: "Subscriptions will be available soon.",
            .bookmarksEmpty: "No bookmarks yet. Tap the bookmark icon on a story to save it here.",
            .profileFAQs: "FAQs",
            .profileTermsOfService: "Terms & Conditions",
            .profilePrivacyPolicy: "Privacy Policy",
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
            .homeGreeting: "Aray Champ 👋",
            .homeSubtitle: "Aaj kuch naya seekhein?",
            .homeNavTitle: "Home",
            .homeLanguagesButton: "🌐 Zabanein",
            .homeQuickAccess: "Fori Rasai",
            .homeCategories: "Aqsaam",
            .homeContinueWatching: "Dekhna jari rakhein",
            .quickAccessStories: "Kahaniyan",
            .quickAccessDiscover: "Daryaft",
            .quickAccessLearn: "Seekhein",
            .quickAccessQuizzes: "Quiz",
            .quickAccessGames: "Khel",
            .searchTitle: "Talaash",
            .searchPlaceholder: "Kahaniyan, nazmein, quiz talaash karein...",
            .searchShortPlaceholder: "Talaash",
            .libraryTitle: "Library",
            .librarySubtitle: "Jahan se chhora tha wahan se shuru karein",
            .librarySearchPlaceholder: "Apni mehfooz library mein talaash karein...",
            .librarySearchShortPlaceholder: "Talaash",
            .languageSheetTitle: "Zaban muntakhib karein",
            .languageSheetSubtitle: "Barah-e-karam apni pasandeeda zaban muntakhib karein",
            .categoryScreenSubtitle: "Dilchasp sabaq aur kahaniyan daryaft karein",
            .recentEpisodesSection: "Haaliya aqsaat",
            .specialOfferTitle: "Khaas offer",
            .specialOfferSubtitle: "Mazeed daryaft karein",
            .storiesDefaultTitle: "Kahaniyan",
            .subcategoriesFallbackTitle: "Zaili aqsaam",
            .errorTitle: "Kharabi",
            .successTitle: "Kamiyabi",
            .ok: "Theek hai",
            .retry: "Dobara koshish",
            .cancel: "Mansookh",
            .change: "Tabdeel karein",
            .changeLanguageTitle: "Zaban tabdeel karein",
            .changeLanguageMessageFormat: "Kya aap zaban %@ mein badalna chahte hain?",
            .languageChangedFormat: "Zaban %@ mein badal di gai",
            .failedToLoadLanguagesFormat: "Zabanein load nahi ho sakein: %@",
            .failedToLoadCategoriesFormat: "Aqsaam load nahi ho sakein: %@",
            .failedToLoadContentFormat: "Mawaad load nahi ho saka: %@",
            .profileYourReport: "Aap ki report",
            .profileTotalWatchTime: "Kul screen time",
            .profileMostWatchedCategory: "Sab se zyada dekhi gai qism",
            .profileParentalControls: "Walidain ka control",
            .profileNotifications: "Ittelaaat",
            .profileSelectLanguage: "Zaban muntakhib karein",
            .profileBookmarks: "Bookmarks",
            .profileSubscriptions: "Subscriptions",
            .profileSubscriptionsUnavailable: "Subscriptions jald dastyab hongi.",
            .bookmarksEmpty: "Abhi koi bookmark nahi. Kahani par bookmark icon daba kar yahan mehfooz karein.",
            .profileFAQs: "FAQs",
            .profileTermsOfService: "Terms & Conditions",
            .profilePrivacyPolicy: "Privacy Policy",
            .profileSampleCategoryName: "Bachon ki kahaniyan",
            .profileWatchTimeSample: "30 min 15 sec",
            .tabHome: "Home",
            .tabSearch: "Talaash",
            .tabLibrary: "Library",
            .tabProfile: "Profile",
            .ahadeesSampleTitle: "Jo Allah aur aakhirat par imaan rakhta hai woh...",
            .ahadeesSampleSubtitle: "- Sahih Bukhari 6136",
            .profileLogoutTitle: "Log out?",
            .profileLogoutMessage: "Dobara istemaal ke liye aap ko sign in karna hoga.",
            .profileLogoutAction: "Log out",
            .profileChangePhotoTitle: "Profile tasveer tabdeel karein",
            .profileChooseFromLibrary: "Gallery se muntakhib karein",
            .profileTakePhoto: "Tasveer lein",
            .profileRemovePhoto: "Tasveer hataein",
            .profilePhotoSaveFailed: "Tasveer mehfooz nahi ho saki. Dobara koshish karein.",
            .screenTimeTitle: "Screen Time",
            .screenTimeTotalLabel: "Kul screen time",
            .screenTimeInfo: "Jab bhi yeh app khuli ho to faal istemaal record hota hai. Auqaat maqami tor par mehfooz hote hain aur app badalne par khud-ba-khud update hote hain.",
            .screenTimeEmpty: "Abhi koi din nahi",
            .screenTimeEmptyHint: "Rozana screen time shuru karne ke liye app kholein.",
            .screenTimeToday: "Aaj",
            .screenTimeYesterday: "Kal",
            .screenTimeOneSession: "1 session",
            .screenTimeSessionCount: "%d sessions",
            .parentalReportTitle: "Aap ki report",
            .parentalWeeklyUsage: "Hafta waar istemaal",
            .parentalUsageLegend: "Istemaal (min)",
            .parentalTotalUsage: "Kul istemaal",
            .parentalTodayUsage: "Aaj ka istemaal",
            .parentalDailyLimit: "Yomiya had",
            .parentalEnterPIN: "PIN darj karein",
            .parentalUpdateLimit: "Had update karein",
            .parentalLimitUpdatedDemo: "Yomiya had update ho gai (demo). Asli PIN baad mein shamil hoga.",
            .parentalSetupTitle: "Parental PIN set karein",
            .parentalVerifyTitle: "Parental PIN darj karein",
            .parentalSetupHint: "Parental controls enable karne, daily limit set karne, aur categories lock karne ke liye PIN banayein.",
            .parentalVerifyHint: "Limits aur locked categories manage karne ke liye apna parental PIN darj karein.",
            .parentalCreatePIN: "PIN banayein (4–6 digits)",
            .parentalConfirmPIN: "PIN confirm karein",
            .parentalEnable: "Parental Controls enable karein",
            .parentalUnlock: "Unlock",
            .parentalForgotPIN: "PIN bhool gaye?",
            .parentalDisable: "Parental Controls band karein",
            .parentalDisableConfirm: "Is se parental controls band ho jayenge aur tamam categories unlock ho jayengi.",
            .parentalEnterPINToDisable: "Parental controls band karne ke liye upar apna current PIN darj karein.",
            .parentalLockedCategories: "Categories lock karein",
            .parentalLockHint: "Locked categories kholne se pehle PIN chahiye.",
            .parentalNoCategories: "Abhi koi categories load nahi huin.",
            .parentalPINInvalid: "Barah-e-karam sahi 4–6 digit PIN darj karein.",
            .parentalPINMismatch: "PIN aur confirmation match nahi karte.",
            .parentalPINWrong: "Galat PIN.",
            .parentalNeedPhone: "Parental controls ke liye phone number zaroori hai. Dobara sign in karein.",
            .parentalNoLimit: "Koi daily limit nahi",
            .parentalMinutes: "minutes",
            .parentalNewPINOptional: "Naya PIN (optional)",
            .parentalChangePIN: "PIN badlein",
            .parentalChangePINHint: "Apna current PIN darj karein, phir naya 4–6 digit PIN choose karein.",
            .parentalCurrentPIN: "Current PIN",
            .parentalSaveNewPIN: "Naya PIN save karein",
            .parentalResetPINTitle: "Parental PIN reset karein",
            .parentalResetHint: "Parental PIN reset karne ke liye hum aap ke registered phone number par OTP bhejenge.",
            .parentalSendOTP: "OTP bhejein",
            .parentalEnterOTP: "OTP darj karein",
            .parentalConfirmReset: "Naya PIN confirm karein",
            .parentalCategoryLockedTitle: "Category locked",
            .parentalCategoryLockedMessage: "Is category ko kholne ke liye parental PIN darj karein.",
            .continueWatchingEmpty: "Abhi jari rakhne ke liye kuch nahi. Home se video dekhna shuru karein.",
            .profileSeeAll: "Sab dekhein"
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
            .profileBookmarks: "بڪ مارڪس",
            .profileSubscriptions: "سبسڪرپشنز",
            .profileSubscriptionsUnavailable: "سبسڪرپشنز جلد دستياب ٿينديون.",
            .bookmarksEmpty: "اڃا ڪو بڪ مارڪ ناهي. ڪهاڻي تي بڪ مارڪ آئيڪن دٻائي هتي محفوظ ڪريو.",
            .profileFAQs: "FAQs",
            .profileTermsOfService: "Terms & Conditions",
            .profilePrivacyPolicy: "Privacy Policy",
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
            .profileBookmarks: "الإشارات المرجعية",
            .profileSubscriptions: "الاشتراكات",
            .profileSubscriptionsUnavailable: "ستتوفر الاشتراكات قريباً.",
            .bookmarksEmpty: "لا توجد إشارات بعد. اضغط أيقونة الإشارة على قصة لحفظها هنا.",
            .profileFAQs: "FAQs",
            .profileTermsOfService: "Terms & Conditions",
            .profilePrivacyPolicy: "Privacy Policy",
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
