//
//  KidsStoriesTableViewCell.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 11/03/2026.
//

import UIKit

class KidsStoriesTableViewCell: UITableViewCell {

    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var textLbl: UILabel!
    @IBOutlet weak var languageLbl: UILabel!
    @IBOutlet weak var bookmarkBtn: UIButton!

    static let reuseIdentifier = "KidsStoriesTableViewCell"

    var onBookmarkTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        languageLbl?.text = nil
        languageLbl?.superview?.isHidden = true
        bookmarkBtn?.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        configureBookmark(isBookmarked: false)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        languageLbl?.text = nil
        languageLbl?.isHidden = true
        languageLbl?.superview?.isHidden = true
        titleLbl?.text = nil
        textLbl?.text = nil
        mainImageView?.image = nil
        onBookmarkTapped = nil
        configureBookmark(isBookmarked: false)
    }

    func configureBookmark(isBookmarked: Bool) {
        bookmarkBtn?.isHidden = false
        // Hide the static addIcon under the hit-target button; we drive the icon from the button.
        bookmarkBtn?.superview?.subviews
            .compactMap { $0 as? UIImageView }
            .forEach { $0.isHidden = true }

        let color = isBookmarked
            ? UIColor(red: 0.95, green: 0.55, blue: 0.12, alpha: 1) // warm orange accent
            : UIColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1)
        bookmarkBtn?.tintColor = color

        let symbolName = isBookmarked ? "bookmark.fill" : "bookmark"
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let image = UIImage(systemName: symbolName, withConfiguration: config)?
            .withRenderingMode(.alwaysTemplate)
        bookmarkBtn?.setImage(image, for: .normal)
    }

    @objc private func bookmarkButtonTapped() {
        onBookmarkTapped?()
    }
}
