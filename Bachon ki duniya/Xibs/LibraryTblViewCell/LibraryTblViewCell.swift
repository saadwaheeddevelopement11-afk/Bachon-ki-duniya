//
//  LibraryTblViewCell.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 06/05/2026.
//

import UIKit

class LibraryTblViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var episodes: [LatestEpisode] = []
    var onSelectEpisode: ((LatestEpisode) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.register(UINib(nibName: "HomeCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: HomeCollectionViewCell.reuseIdentifier)

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 8
            layout.minimumInteritemSpacing = 8
            layout.sectionInset = .zero
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        episodes = []
        onSelectEpisode = nil
    }

    func configure(title: String, episodes: [LatestEpisode]) {
        titleLbl.text = title
        let rtl = LanguageManager.shared.isRTL()
        titleLbl.textAlignment = rtl ? .right : .left
        collectionView.semanticContentAttribute = rtl ? .forceRightToLeft : .forceLeftToRight
        self.episodes = episodes
        collectionView.reloadData()
    }
}

extension LibraryTblViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        episodes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeCollectionViewCell.reuseIdentifier, for: indexPath) as? HomeCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(withImageURL: episodes[indexPath.item].thumbnailURL, showPlayOverlay: true)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        onSelectEpisode?(episodes[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let colVHeight = collectionView.bounds.height
        return CGSize(width: colVHeight*1.5, height: colVHeight)
    }
}
