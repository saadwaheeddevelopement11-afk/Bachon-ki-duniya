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
    
    static let reuseIdentifier = "KidsStoriesTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        languageLbl?.text = nil
        languageLbl?.superview?.isHidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        languageLbl?.text = nil
        languageLbl?.isHidden = true
        languageLbl?.superview?.isHidden = true
        titleLbl?.text = nil
        textLbl?.text = nil
        mainImageView?.image = nil
    }
}
