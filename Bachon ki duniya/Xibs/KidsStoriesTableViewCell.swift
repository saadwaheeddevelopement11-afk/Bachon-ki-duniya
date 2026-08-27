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
            ? UIColor(red: 0.83, green: 0.18, blue: 0.18, alpha: 1)
            : UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)
        bookmarkBtn?.tintColor = color

        if isBookmarked, let asset = UIImage(named: "Bookmark") {
            bookmarkBtn?.setImage(asset.withRenderingMode(.alwaysTemplate), for: .normal)
        } else {
            let name = isBookmarked ? "bookmark.fill" : "bookmark"
            bookmarkBtn?.setImage(UIImage(systemName: name), for: .normal)
        }
    }

    @objc private func bookmarkButtonTapped() {
        onBookmarkTapped?()
    }
}
