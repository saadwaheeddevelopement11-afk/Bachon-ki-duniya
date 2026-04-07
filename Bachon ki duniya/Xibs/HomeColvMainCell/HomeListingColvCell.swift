//
//  HomeListingColvCell.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 17/03/2026.
//

import UIKit

class HomeListingColvCell: UICollectionViewCell {
    
    @IBOutlet weak var bannerImageView: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var bgView: UIView!
    
    // Add this method
    func configureForBanner() {
        // Configure cell to look like a banner
        bannerImageView.image = UIImage(named: "banner_placeholder") // Set your banner image
        titleLbl.text = LanguageManager.shared.isRTL() ? "عرض خاص" : "Special Offer"
        descriptionLbl.text = LanguageManager.shared.isRTL() ? "اكتشف المزيد" : "Discover More"
        
        // Optional: Style the banner differently
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.layer.cornerRadius = 14
        
        bgView.layer.borderColor = UIColor.black.cgColor//(named: "homeCellborderColor")?.cgColor
        bgView.layer.borderWidth = 1
        bgView.backgroundColor = .clear
        
        self.contentView.layer.cornerRadius = 12
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = UIColor(named: "homeCellborderColor")?.cgColor
    }
}
