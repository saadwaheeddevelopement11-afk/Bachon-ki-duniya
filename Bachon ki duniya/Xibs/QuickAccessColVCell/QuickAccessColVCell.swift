//
//  QuickAccessColVCell.swift
//  Bachon ki duniya
//

import UIKit

final class QuickAccessColVCell: UICollectionViewCell {

    static let reuseIdentifier = "QuickAccessColVCell"

    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .clear
        backgroundColor = .clear

        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.masksToBounds = true

        titleLbl.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLbl.textColor = .label
        titleLbl.numberOfLines = 2
        titleLbl.textAlignment = .center
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let side = min(thumbImageView.bounds.width, thumbImageView.bounds.height)
        guard side > 0 else { return }
        thumbImageView.layer.cornerRadius = side / 2
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageView.image = nil
        titleLbl.text = nil
    }
}
