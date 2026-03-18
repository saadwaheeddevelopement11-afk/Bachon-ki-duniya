//
//  HomeCollectionViewCell.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 11/03/2026.
//

import UIKit

class HomeCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "HomeCollectionViewCell"
    
    @IBOutlet weak var imageView: UIImageView!
    
    // Remove the manual nib loading - it's causing the crash
    // The XIB loading is handled by the collection view registration
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCell()
    }
    
    private func setupCell() {
        // Ensure imageView content mode is set correctly
//        imageView?.contentMode = .scaleAspectFill
        imageView?.clipsToBounds = true
        
        // Optional: Add a subtle shadow to the cell
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.1
        self.layer.shadowRadius = 4
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.masksToBounds = false
        self.backgroundColor = .clear
    }
    
    func configure(with imageName: String) {
        imageView?.image = UIImage(named: imageName)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update shadow path for better performance
        let shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 0)
        self.layer.shadowPath = shadowPath.cgPath
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView?.image = nil
    }
}
