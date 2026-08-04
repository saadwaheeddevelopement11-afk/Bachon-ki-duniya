//
//  LanguagesTableViewCell.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 14/04/2026.
//

import UIKit

class LanguagesTableViewCell: UITableViewCell {
    
    @IBOutlet weak var languageName: UILabel!
    @IBOutlet weak var bgView: UIView!

    private enum Style {
        static let lightPurple = UIColor(red: 0.82, green: 0.76, blue: 0.98, alpha: 1)
        static let darkPurple = UIColor(red: 0.45, green: 0.32, blue: 0.82, alpha: 1)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        bgView.layer.cornerRadius = 10
        bgView.layer.masksToBounds = true
        bgView.layer.borderWidth = 0
        
        languageName.textAlignment = .center
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(isSelected: Bool) {
        languageName.textAlignment = .center
        languageName.font = UIFont.systemFont(ofSize: isSelected ? 18 : 17, weight: isSelected ? .bold : .semibold)

        if isSelected {
            bgView.backgroundColor = Style.darkPurple
            languageName.textColor = .white
            bgView.layer.borderWidth = 0
            bgView.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        } else {
            bgView.backgroundColor = Style.lightPurple
            languageName.textColor = Style.darkPurple
            bgView.layer.borderWidth = 0
            bgView.transform = .identity
        }
    }
}
