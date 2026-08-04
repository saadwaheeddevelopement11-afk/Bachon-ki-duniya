import Foundation

/// Hardcoded Home Quick Access tiles (Android parity).
struct QuickAccessItem {
    let id: Int
    let titleKey: AppStringKey
    let iconName: String

    var title: String { AppL10n.t(titleKey) }
}

enum QuickAccessCatalog {

    /// Stories → Bedtime Stories (9), Discover/Learn (5/15), Quizzes → Quiz For You (29), Games (49).
    static let items: [QuickAccessItem] = [
        QuickAccessItem(id: 9, titleKey: .quickAccessStories, iconName: "storiesIcon"),
        QuickAccessItem(id: 5, titleKey: .quickAccessDiscover, iconName: "discoverIcon"),
        QuickAccessItem(id: 15, titleKey: .quickAccessLearn, iconName: "learnIcon"),
        QuickAccessItem(id: 29, titleKey: .quickAccessQuizzes, iconName: "quizzesIcon"),
        QuickAccessItem(id: 49, titleKey: .quickAccessGames, iconName: "gamesIcon")
    ]

    /// Open full category / subcategory list screens.
    static let categoryDetailIds: Set<Int> = [5, 9, 15]
    /// Open leaf content for these subcategory ids (Quiz For You, Games).
    static let storiesSubcategoryIds: Set<Int> = [29, 49]
}
