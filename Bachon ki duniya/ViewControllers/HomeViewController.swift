//
//  HomeViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 11/03/2026.
//

import UIKit

class HomeViewController: UIViewController {
    
    // Image names matching assets in HomeAssets (and root Assets)
    private let homeItemsList = ["kidsStories", "islamicKnowledge", "generalKnowledge", "kidsShows", "bedTime", "growWell", "Banner"]
    
    private let itemsPerRow: CGFloat = 2
    private let spacing: CGFloat = 10
    
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            HomeCollectionViewCell.self,
            forCellWithReuseIdentifier: HomeCollectionViewCell.reuseIdentifier
        )
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
            layout.sectionInset = .zero
        }
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        homeItemsList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HomeCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? HomeCollectionViewCell else {
            return UICollectionViewCell()
        }
        let imageName = homeItemsList[indexPath.item]
        cell.configure(with: imageName)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "KidsStoriesViewController") as? KidsStoriesViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case 1:
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "IslamicKnowledgeViewController") as? IslamicKnowledgeViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case 2:
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "GeneralKnowledgeViewController") as? GeneralKnowledgeViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case 3:
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "AhadeesViewController") as? AhadeesViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        default:
            print("Nothing here")
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HomeViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalWidth = collectionView.bounds.width
        let isLastItem = indexPath.item == homeItemsList.count - 1
        let isOddCount = homeItemsList.count % 2 != 0
        
        // Last item occupies full width when we have an odd number of items
        if isLastItem && isOddCount {
            let itemHeight: CGFloat = (totalWidth - spacing) / 2  // same height as one row
            return CGSize(width: totalWidth, height: itemHeight)
        }
        
        let availableWidth = totalWidth - (spacing * (itemsPerRow - 1))
        let itemWidth = availableWidth / itemsPerRow
        let itemHeight = itemWidth * 1.35
        return CGSize(width: itemWidth, height: itemHeight)
    }
}
