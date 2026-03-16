//
//  LearnNMoreColvCell.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 12/03/2026.
//

import UIKit

class LearnNMoreColvCell: UICollectionViewCell {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        image.image = UIImage(named: "learnImage")
        titleLbl.text = "Learning Games"
    }

}
