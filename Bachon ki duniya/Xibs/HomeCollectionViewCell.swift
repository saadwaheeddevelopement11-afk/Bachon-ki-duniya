//
//  HomeCollectionViewCell.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 11/03/2026.
//

import UIKit
import SDWebImage

class HomeCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "HomeCollectionViewCell"

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var playOverlayImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }

    private func setupCell() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true

        layer.shadowOpacity = 0.1
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.masksToBounds = false
        backgroundColor = .clear
    }

    func configure(with imageName: String) {
        imageView?.image = UIImage(named: imageName)
        playOverlayImageView?.isHidden = false
    }

    /// Category / banner row from `/categories` (swap model when API changes).
    func configure(with item: HomeItem, showPlayOverlay: Bool = false) {
        playOverlayImageView?.isHidden = !showPlayOverlay
        let placeholder = UIImage(named: "placeholder")
        guard !item.imageUrl.isEmpty, let url = URL(string: item.imageUrl) else {
            imageView?.image = placeholder
            return
        }
        imageView?.sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .continueInBackground, .highPriority])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 12)
        layer.shadowPath = shadowPath.cgPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView?.sd_cancelCurrentImageLoad()
        imageView?.image = nil
        playOverlayImageView?.isHidden = false
    }
}
