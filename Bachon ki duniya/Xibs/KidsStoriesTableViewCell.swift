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
    
    static let reuseIdentifier = "KidsStoriesTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
