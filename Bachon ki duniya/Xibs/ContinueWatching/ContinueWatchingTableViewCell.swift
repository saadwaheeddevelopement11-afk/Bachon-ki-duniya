import UIKit

final class ContinueWatchingTableViewCell: UITableViewCell {

    static let reuseIdentifier = "ContinueWatchingTableViewCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()
    
    private var records: [ContinueWatchingRecord] = []
    var onSelectRecord: ((ContinueWatchingRecord) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        clipsToBounds = false
        contentView.clipsToBounds = false

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            ContinueWatchingColvCell.self,
            forCellWithReuseIdentifier: ContinueWatchingColvCell.reuseIdentifier
        )

        contentView.addSubview(titleLabel)
        contentView.addSubview(collectionView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 126),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(title: String, records: [ContinueWatchingRecord], isRTL: Bool) {
        titleLabel.text = title
        titleLabel.textAlignment = isRTL ? .right : .left
        collectionView.semanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
        self.records = records
        collectionView.reloadData()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        records = []
        onSelectRecord = nil
    }
}

extension ContinueWatchingTableViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        records.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ContinueWatchingColvCell.reuseIdentifier,
            for: indexPath
        ) as? ContinueWatchingColvCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: records[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        onSelectRecord?(records[indexPath.item])
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: 148, height: 126)
    }
}
