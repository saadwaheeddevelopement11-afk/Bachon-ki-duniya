import UIKit

class HomeListingColvCell: UICollectionViewCell {

    @IBOutlet weak var bannerImageView: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var bgImage: UIImageView!

    private let lockBadge = UIImageView()

    override func awakeFromNib() {
        super.awakeFromNib()
        setupLockBadge()
    }

    private func setupLockBadge() {
        guard lockBadge.superview == nil else { return }
        lockBadge.translatesAutoresizingMaskIntoConstraints = false
        lockBadge.contentMode = .scaleAspectFit
        lockBadge.image = UIImage(named: "parentalControlLockIcon")
            ?? UIImage(systemName: "lock.fill")
        lockBadge.tintColor = .white
        lockBadge.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        lockBadge.layer.cornerRadius = 14
        lockBadge.clipsToBounds = true
        lockBadge.isHidden = true
        // Slight padding so the icon sits inside the badge.
        lockBadge.contentMode = .center
        contentView.addSubview(lockBadge)
        NSLayoutConstraint.activate([
            lockBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            lockBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            lockBadge.widthAnchor.constraint(equalToConstant: 28),
            lockBadge.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    func setLocked(_ locked: Bool) {
        if lockBadge.superview == nil {
            setupLockBadge()
        }
        lockBadge.isHidden = !locked
        contentView.bringSubviewToFront(lockBadge)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setLocked(false)
    }

    func configureForBanner() {
        bannerImageView.image = UIImage(named: "banner_placeholder")
        titleLbl.text = AppL10n.t(.specialOfferTitle)
        descriptionLbl.text = AppL10n.t(.specialOfferSubtitle)
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.layer.cornerRadius = 14
        bgView.layer.borderColor = UIColor.black.cgColor
        bgView.layer.borderWidth = 1
        bgView.backgroundColor = .white
    }
}
