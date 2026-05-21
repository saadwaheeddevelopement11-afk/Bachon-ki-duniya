import UIKit
import SDWebImage

final class ContinueWatchingColvCell: UICollectionViewCell {

    static let reuseIdentifier = "ContinueWatchingColvCell"

    private let thumbImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = UIColor(white: 0.92, alpha: 1)
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .center
        return label
    }()

    private let progressTrack: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(white: 1, alpha: 0.35)
        return v
    }()

    private let progressFill: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = ContinueWatchingStyle.purple
        return v
    }()

    private var progressWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.addSubview(thumbImageView)
        contentView.addSubview(titleLabel)
        thumbImageView.addSubview(progressTrack)
        progressTrack.addSubview(progressFill)

        progressWidthConstraint = progressFill.widthAnchor.constraint(equalTo: progressTrack.widthAnchor, multiplier: 0)

        NSLayoutConstraint.activate([
            thumbImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbImageView.heightAnchor.constraint(equalToConstant: 90),

            titleLabel.topAnchor.constraint(equalTo: thumbImageView.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            progressTrack.leadingAnchor.constraint(equalTo: thumbImageView.leadingAnchor),
            progressTrack.trailingAnchor.constraint(equalTo: thumbImageView.trailingAnchor),
            progressTrack.bottomAnchor.constraint(equalTo: thumbImageView.bottomAnchor),
            progressTrack.heightAnchor.constraint(equalToConstant: 4),

            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            progressWidthConstraint!
        ])
    }

    func configure(with record: ContinueWatchingRecord) {
        titleLabel.text = record.title
        let placeholder = UIImage(named: "placeholder")
        if let urlString = record.imageURL, !urlString.isEmpty, let url = URL(string: urlString) {
            thumbImageView.sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .continueInBackground, .highPriority])
        } else {
            thumbImageView.image = placeholder
        }
        setProgress(record.progress)
    }

    private func setProgress(_ value: Float) {
        progressWidthConstraint?.isActive = false
        let clamped = max(0.02, min(1, value))
        progressWidthConstraint = progressFill.widthAnchor.constraint(
            equalTo: progressTrack.widthAnchor,
            multiplier: CGFloat(clamped)
        )
        progressWidthConstraint?.isActive = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageView.sd_cancelCurrentImageLoad()
        thumbImageView.image = nil
        titleLabel.text = nil
        setProgress(0)
    }
}

enum ContinueWatchingStyle {
    static let purple = UIColor(red: 0.62, green: 0.52, blue: 0.98, alpha: 1)
}
