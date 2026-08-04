//
//  SubCategoriesCell.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 07/04/2026.
//

import UIKit

class SubCategoriesCell: UITableViewCell {
    
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var exploreBtn: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
