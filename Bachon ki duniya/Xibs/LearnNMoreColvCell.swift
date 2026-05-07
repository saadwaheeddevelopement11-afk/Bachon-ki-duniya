//
//  LearnNMoreColvCell.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 12/03/2026.
//

import UIKit
import SDWebImage

class LearnNMoreColvCell: UICollectionViewCell {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = 8
        titleLbl.numberOfLines = 2
        titleLbl.textAlignment = .center
    }

    func configure(with episode: LatestEpisode) {
        let placeholder = UIImage(named: "learnImage")
        if let urlString = episode.thumbnailURL, !urlString.isEmpty, let url = URL(string: urlString) {
            image.sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .continueInBackground, .highPriority])
        } else {
            image.image = placeholder
        }

        if let number = episode.episodeNumber {
            titleLbl.text = "Episode \(number)"
        } else {
            titleLbl.text = "Episode"
        }
    }

}
