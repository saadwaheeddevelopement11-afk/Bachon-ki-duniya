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
    private let homeItems = ["Kids Stories", "Islamic Knowledge", "General knowledge", "Kids Shows", "Bed time Stories & Poems", "Grow Well"]
    private let homeDescriptions = [
        "Engaging and Character based children's stories",
        "Basic Islamic teachings in a child-friendly format",
        "Interesting facts and general information for kids",
        "Kids Podcast & Puppet Shows",
        "Engaging and Character based children's stories",
        "Emotional Intelligence & Well being Stories for kids"
    ]
    
    private let itemsPerRow: CGFloat = 2
    private let spacing: CGFloat = 16
    private let sectionInset: CGFloat = 6
    
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Register both cell types
        collectionView.register(
            UINib(nibName: "HomeListingColvCell", bundle: nil),
            forCellWithReuseIdentifier: "HomeListingColvCell"
        )
        
        collectionView.register(
            UINib(nibName: "HomeCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: HomeCollectionViewCell.reuseIdentifier
        )
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
            layout.sectionInset = UIEdgeInsets(top: 0, left: sectionInset, bottom: 0, right: sectionInset)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return homeItemsList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Use the full-bleed image cell for the last item (index 6)
        if indexPath.item == 6 { // 7th item (0-based index)
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HomeCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? HomeCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            let imageName = homeItemsList[indexPath.item]
            cell.configure(with: imageName)
            
            return cell
        } else {
            // Use regular cell for first 6 items
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "HomeListingColvCell",
                for: indexPath
            ) as? HomeListingColvCell else {
                return UICollectionViewCell()
            }
            
            let imageName = homeItemsList[indexPath.item]
            cell.bannerImageView.image = UIImage(named: imageName)
            
            cell.titleLbl.text = homeItems[indexPath.item]
            cell.descriptionLbl.text = homeDescriptions[indexPath.item]
            
            return cell
        }
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
        case 6: // Handle banner tap
            print("Banner tapped - navigate to banner content")
            // Navigate to banner view controller
//            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "BannerViewController") as? BannerViewController {
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
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
        
        // Different size for the last item (full-bleed banner)
        if isLastItem {
            let contentWidth = totalWidth - (sectionInset * 2)
            // Banner cell - adjust height as needed (maybe a specific aspect ratio)
            let bannerHeight: CGFloat = 200 // You can adjust this or make it dynamic based on image aspect ratio
            return CGSize(width: contentWidth, height: bannerHeight)
        }
        
        // Regular size for first 6 items
        let availableWidth = (totalWidth - (sectionInset * 2)) - (spacing * (itemsPerRow - 1))
        let itemWidth = availableWidth / itemsPerRow
        let itemHeight = itemWidth * 1.35 // This maintains the aspect ratio you had
        return CGSize(width: itemWidth, height: itemHeight)
    }
}

//class HomeViewController: UIViewController {
//    
//    // Image names matching assets in HomeAssets (and root Assets)
//    private let homeItemsList = ["kidsStories", "islamicKnowledge", "generalKnowledge", "kidsShows", "bedTime", "growWell", "Banner"]
//    private let homeItems = ["Kids Stories", "Islamic Knowledge", "General knowledge", "Kids Shows", "Bed time Stories & Poems", "Grow Well"]
//    private let homeDescriptions = [
//        "Fun, safe, and meaningful stories for kids.",
//        "Learn Islam in a simple and engaging way.",
//        "Boost your general knowledge every day.",
//        "Kids shows picked for young minds.",
//        "Bedtime stories & poems to sleep happy.",
//        "Healthy habits and growth for kids."
//    ]
//    
//    private let itemsPerRow: CGFloat = 2
//    private let spacing: CGFloat = 16
//    private let sectionInset: CGFloat = 6
//    
//    @IBOutlet weak var collectionView: UICollectionView!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupCollectionView()
//    }
//    
//    private func setupCollectionView() {
//        collectionView.delegate = self
//        collectionView.dataSource = self
//        // Cell UI is built in `HomeListingColvCell.xib`, so register the nib (not the class),
//        // otherwise outlets will be nil and cause a crash.
//        collectionView.register(
//            UINib(nibName: "HomeListingColvCell", bundle: nil),
//            forCellWithReuseIdentifier: "HomeListingColvCell"
//        )
//        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
//            layout.minimumInteritemSpacing = spacing
//            layout.minimumLineSpacing = spacing
//            layout.sectionInset = UIEdgeInsets(top: 0, left: sectionInset, bottom: 0, right: sectionInset)
//        }
//    }
//}
//
//// MARK: - UICollectionViewDataSource
//extension HomeViewController: UICollectionViewDataSource {
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        homeItemsList.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        guard let cell = collectionView.dequeueReusableCell(
//            withReuseIdentifier: "HomeListingColvCell",
//            for: indexPath
//        ) as? HomeListingColvCell else {
//            return UICollectionViewCell()
//        }
//        
//        let imageName = homeItemsList[indexPath.item]
//        cell.bannerImageView.image = UIImage(named: imageName)
//        
//        // The last item is a full-width banner image; it doesn't have a title/description entry.
//        if indexPath.item < homeItems.count {
//            cell.titleLbl.text = homeItems[indexPath.item]
//            cell.descriptionLbl.text = homeDescriptions[indexPath.item]
//        } else {
//            cell.titleLbl.text = nil
//            cell.descriptionLbl.text = nil
//        }
//        return cell
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        switch indexPath.row {
//        case 0:
//            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "KidsStoriesViewController") as? KidsStoriesViewController {
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        case 1:
//            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "IslamicKnowledgeViewController") as? IslamicKnowledgeViewController {
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        case 2:
//            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "GeneralKnowledgeViewController") as? GeneralKnowledgeViewController {
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        case 3:
//            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "AhadeesViewController") as? AhadeesViewController {
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        default:
//            print("Nothing here")
//        }
//    }
//}
//
//// MARK: - UICollectionViewDelegateFlowLayout
//extension HomeViewController: UICollectionViewDelegateFlowLayout {
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let totalWidth = collectionView.bounds.width
//        let isLastItem = indexPath.item == homeItemsList.count - 1
//        let isOddCount = homeItemsList.count % 2 != 0
//        
//        // Add horizontal inset to prevent shadows from touching edges
//        let horizontalInset: CGFloat = 8
//        
//        if isLastItem && isOddCount {
//            let contentWidth = totalWidth - (sectionInset * 2) - (horizontalInset * 2)
//            let itemHeight: CGFloat = (contentWidth - spacing) / 2
//            return CGSize(width: contentWidth, height: itemHeight)
//        }
//        
//        let availableWidth = (totalWidth - (sectionInset * 2)) - (spacing * (itemsPerRow - 1)) - (horizontalInset * 2)
//        let itemWidth = availableWidth / itemsPerRow
//        let itemHeight = itemWidth * 1.35
//        return CGSize(width: itemWidth, height: itemHeight)
//    }
//}
