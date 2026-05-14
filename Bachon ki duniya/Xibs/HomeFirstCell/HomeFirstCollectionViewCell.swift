//
//  HomeFirstCollectionViewCell.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 13/04/2026.
//

import UIKit

class HomeFirstCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var bannerImageView: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var bgView: UIView!
    
    // Add this method
    func configureForBanner() {
        // Configure cell to look like a banner
        bannerImageView.image = UIImage(named: "banner_placeholder") // Set your banner image
        titleLbl.text = AppL10n.t(.specialOfferTitle)
        descriptionLbl.text = AppL10n.t(.specialOfferSubtitle)
        
        // Optional: Style the banner differently
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.layer.cornerRadius = 14
        
        bgView.layer.borderColor = UIColor.darkGray.cgColor //(named: "homeCellborderColor")?.cgColor
        bgView.layer.borderWidth = 1
        bgView.backgroundColor = .white
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
