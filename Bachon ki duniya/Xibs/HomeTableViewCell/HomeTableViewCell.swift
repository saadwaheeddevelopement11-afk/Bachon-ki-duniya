//
//  HomeTableViewCell.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 04/05/2026.
//

import UIKit
import SDWebImage

enum HomeCategoryRowLayout {
    /// Horizontal strip using `QuickAccessColVCell` + local asset icons
    case horizontalQuickAccess
    /// Full category grid using `HomeListingColvCell`
    case verticalGrid
}

final class HomeTableViewCell: UITableViewCell {

    static let reuseIdentifier = "HomeTableViewCell"

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionHeightConstraint: NSLayoutConstraint!

    private var items: [HomeItem] = []
    private var quickAccessItems: [QuickAccessItem] = []
    private var layoutKind: HomeCategoryRowLayout = .verticalGrid
    private var contentWidthForLayout: CGFloat = UIScreen.main.bounds.width

    private let spacing: CGFloat = 16
    private let sectionInset: CGFloat = 16
    private let itemsPerRow: CGFloat = 2
    private let quickAccessItemsPerRow: CGFloat = 5
    private let quickAccessSpacing: CGFloat = 6
    /// Quick access horizontal row (image + title); must match `QuickAccessColVCell` height
    private let quickAccessCollectionHeight: CGFloat = 108

    var onSelectItem: ((HomeItem) -> Void)?
    var onSelectQuickAccess: ((QuickAccessItem) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false

        collectionView.register(
            UINib(nibName: "HomeListingColvCell", bundle: nil),
            forCellWithReuseIdentifier: "HomeListingColvCell"
        )
        collectionView.register(
            UINib(nibName: "QuickAccessColVCell", bundle: nil),
            forCellWithReuseIdentifier: QuickAccessColVCell.reuseIdentifier
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        items = []
        quickAccessItems = []
        onSelectItem = nil
        onSelectQuickAccess = nil
    }

    func configure(
        title: String,
        items: [HomeItem],
        layoutKind: HomeCategoryRowLayout,
        contentWidth: CGFloat,
        isRTL: Bool
    ) {
        self.items = items
        self.quickAccessItems = []
        configureChrome(title: title, layoutKind: layoutKind, contentWidth: contentWidth, isRTL: isRTL)
        collectionView.reloadData()
    }

    func configureQuickAccess(
        title: String,
        items: [QuickAccessItem],
        contentWidth: CGFloat,
        isRTL: Bool
    ) {
        self.quickAccessItems = items
        self.items = []
        configureChrome(title: title, layoutKind: .horizontalQuickAccess, contentWidth: contentWidth, isRTL: isRTL)
        collectionView.reloadData()
    }

    private func configureChrome(
        title: String,
        layoutKind: HomeCategoryRowLayout,
        contentWidth: CGFloat,
        isRTL: Bool
    ) {
        titleLbl.text = title
        titleLbl.textAlignment = isRTL ? .right : .left
        self.layoutKind = layoutKind
        self.contentWidthForLayout = max(contentWidth, 1)

        guard let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        switch layoutKind {
        case .horizontalQuickAccess:
            flow.scrollDirection = .horizontal
            flow.minimumLineSpacing = quickAccessSpacing
            flow.minimumInteritemSpacing = quickAccessSpacing
            flow.sectionInset = UIEdgeInsets(top: 0, left: sectionInset, bottom: 0, right: sectionInset)
            collectionView.isScrollEnabled = false
            collectionView.semanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
            collectionHeightConstraint.constant = quickAccessCollectionHeight

        case .verticalGrid:
            flow.scrollDirection = .vertical
            flow.minimumLineSpacing = spacing
            flow.minimumInteritemSpacing = spacing
            flow.sectionInset = UIEdgeInsets(top: 0, left: sectionInset, bottom: 0, right: sectionInset)
            collectionView.isScrollEnabled = false
            collectionView.semanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight

            let count = items.count
            let rows = count == 0 ? 0 : Int(ceil(CGFloat(count) / itemsPerRow))
            let available = contentWidthForLayout - (sectionInset * 2) - spacing * (itemsPerRow - 1)
            let w = max(0, available / itemsPerRow)
            let h = w * 1.1
            let gridHeight = CGFloat(rows) * h + CGFloat(max(0, rows - 1)) * spacing
            collectionHeightConstraint.constant = max(gridHeight, 0)
        }
    }

    private func loadImage(from urlString: String, into imageView: UIImageView) {
        let placeholder = UIImage(named: "placeholder")
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            imageView.image = placeholder
            return
        }
        imageView.sd_setImage(
            with: url,
            placeholderImage: placeholder,
            options: [.retryFailed, .continueInBackground, .highPriority]
        )
    }
}

// MARK: - UICollectionView
extension HomeTableViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch layoutKind {
        case .horizontalQuickAccess:
            return quickAccessItems.count
        case .verticalGrid:
            return items.count
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch layoutKind {
        case .horizontalQuickAccess:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: QuickAccessColVCell.reuseIdentifier,
                for: indexPath
            ) as? QuickAccessColVCell else {
                return UICollectionViewCell()
            }
            let item = quickAccessItems[indexPath.item]
            cell.thumbImageView.image = UIImage(named: item.iconName)
            cell.titleLbl.text = item.title
            cell.titleLbl.textAlignment = .center
            return cell

        case .verticalGrid:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "HomeListingColvCell",
                for: indexPath
            ) as? HomeListingColvCell else {
                return UICollectionViewCell()
            }
            let item = items[indexPath.item]
            loadImage(from: item.imageUrl, into: cell.bannerImageView)
            cell.bgImage.image = UIImage(named: item.backgroundImageName)
            cell.titleLbl.text = item.title
            cell.descriptionLbl.text = item.description
            cell.titleLbl.textAlignment = .center
            cell.descriptionLbl.textAlignment = .center
            let usesDarkText = (item.backgroundImageName == "bg2" || item.backgroundImageName == "bg8")
            let textColor: UIColor = usesDarkText ? .black : .white
            cell.titleLbl.textColor = textColor
            cell.descriptionLbl.textColor = textColor
            cell.setLocked(ParentalStatusStore.isCategoryLocked(item.id))
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        switch layoutKind {
        case .horizontalQuickAccess:
            let available = contentWidthForLayout - (sectionInset * 2) - quickAccessSpacing * (quickAccessItemsPerRow - 1)
            let width = max(46, floor(available / quickAccessItemsPerRow))
            return CGSize(width: width, height: quickAccessCollectionHeight)

        case .verticalGrid:
            let available = contentWidthForLayout - (sectionInset * 2) - spacing * (itemsPerRow - 1)
            let width = max(80, available / itemsPerRow)
            let height = width * 1.1
            return CGSize(width: width, height: height)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        switch layoutKind {
        case .horizontalQuickAccess:
            onSelectQuickAccess?(quickAccessItems[indexPath.item])
        case .verticalGrid:
            onSelectItem?(items[indexPath.item])
        }
    }
}
