//
//  LanguagesTableViewCell.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 14/04/2026.
//

import UIKit

class LanguagesTableViewCell: UITableViewCell {
    
    @IBOutlet weak var languageName: UILabel!
    @IBOutlet weak var bgImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        bgImage.layer.masksToBounds = true
        bgImage.layer.cornerRadius = 10
        bgImage.layer.borderWidth = 0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureSelection(isSelected: Bool) {
        if isSelected {
            bgImage.layer.borderWidth = 2
            bgImage.layer.borderColor = (UIColor(named: "borderRed") ?? UIColor.systemRed).cgColor
        } else {
            bgImage.layer.borderWidth = 0
            bgImage.layer.borderColor = UIColor.clear.cgColor
        }
    }
}
