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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadContentViewFromNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadContentViewFromNib()
    }
    
    private func loadContentViewFromNib() {
        let nib = UINib(nibName: "HomeCollectionViewCell", bundle: nil)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with imageName: String) {
        imageView?.image = UIImage(named: imageName)
    }
}
