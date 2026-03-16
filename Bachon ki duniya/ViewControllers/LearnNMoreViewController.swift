//
//  LearnNMoreViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 12/03/2026.
//

import UIKit

class LearnNMoreViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private let itemsPerRow: CGFloat = 2
    private let spacing: CGFloat = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(LearnNMoreColvCell.self,forCellWithReuseIdentifier: "LearnNMoreColvCell")
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
            layout.sectionInset = .zero
        }
    }
}

// MARK: - UICollectionViewDataSource
extension LearnNMoreViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        4 //homeItemsList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LearnNMoreColvCell", for: indexPath) as? LearnNMoreColvCell else {
            return UICollectionViewCell()
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension LearnNMoreViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalWidth = collectionView.bounds.width
//        let isLastItem = indexPath.item == homeItemsList.count - 1
//        let isOddCount = homeItemsList.count % 2 != 0
//        
//        // Last item occupies full width when we have an odd number of items
//        if isLastItem && isOddCount {
//            let itemHeight: CGFloat = (totalWidth - spacing) / 2  // same height as one row
//            return CGSize(width: totalWidth, height: itemHeight)
//        }
        
        let availableWidth = totalWidth - (spacing * (itemsPerRow - 1))
        let itemWidth = availableWidth / itemsPerRow
        let itemHeight = itemWidth * 1.35
        return CGSize(width: itemWidth, height: itemHeight)
    }
}
