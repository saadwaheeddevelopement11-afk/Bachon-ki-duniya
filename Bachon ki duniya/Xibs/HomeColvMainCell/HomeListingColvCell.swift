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

    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update shadow path when bounds change
        updateShadow()
    }
    
    private func setupCell() {
        // Make sure bgView has a background color and corner radius
//        bgView.backgroundColor = .white
        bgView.layer.cornerRadius = 12
        bgView.layer.masksToBounds = true // This clips the content but NOT the shadow
        
        // Configure shadow on the cell itself (not bgView)
//        self.layer.shadowColor = UIColor.black.cgColor
//        self.layer.shadowOpacity = 0.1
//        self.layer.shadowRadius = 8
//        self.layer.shadowOffset = CGSize(width: 0, height: 2)
//        self.layer.masksToBounds = false // Important: allows shadow to show
        
        // Add a slight background to the cell to prevent shadow from showing through
        self.backgroundColor = .clear
    }
    
    private func updateShadow() {
        // Create a shadow path that matches the bgView's rounded rect
        // This improves performance and gives a cleaner shadow
        let shadowRect = bounds.insetBy(dx: 2, dy: 2) // Slight inset to prevent shadow merging
        let shadowPath = UIBezierPath(roundedRect: shadowRect, cornerRadius: bgView.layer.cornerRadius)
        self.layer.shadowPath = shadowPath.cgPath
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset any image to prevent flickering
        bannerImageView.image = nil
    }
}
