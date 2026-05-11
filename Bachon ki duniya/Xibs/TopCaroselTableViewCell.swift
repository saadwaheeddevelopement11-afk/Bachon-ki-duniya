//
//  TopCaroselTableViewCell.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 07/05/2026.
//

import UIKit

class TopCaroselTableViewCell: UITableViewCell {
    
    @IBOutlet weak var caroselColV: UICollectionView!
    @IBOutlet weak var carocelPageController: UIPageControl!
    
    private var items: [HomeItem] = []
    private var onSelectItem: ((HomeItem) -> Void)?
    private var lastWidth: CGFloat = 0
    private let sidePeek: CGFloat = 22
    private let interItemSpacing: CGFloat = 12

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        caroselColV.delegate = self
        caroselColV.dataSource = self
        caroselColV.backgroundColor = .clear
        caroselColV.showsHorizontalScrollIndicator = false
        caroselColV.decelerationRate = .fast
        caroselColV.isPagingEnabled = false
        caroselColV.register(UINib(nibName: "HomeCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: HomeCollectionViewCell.reuseIdentifier)
        
        if let flow = caroselColV.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.scrollDirection = .horizontal
            flow.minimumLineSpacing = interItemSpacing
            flow.minimumInteritemSpacing = 0
            flow.sectionInset = .zero
        }
        
        carocelPageController.hidesForSinglePage = true
        carocelPageController.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.35)
        carocelPageController.currentPageIndicatorTintColor = .white
        carocelPageController.addTarget(self, action: #selector(pageChanged(_:)), for: .valueChanged)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let w = caroselColV.bounds.width
        guard w > 0, abs(w - lastWidth) > 0.5 else { return }
        lastWidth = w
        caroselColV.collectionViewLayout.invalidateLayout()
        caroselColV.layoutIfNeeded()
        let page = min(carocelPageController.currentPage, max(0, items.count - 1))
        guard !items.isEmpty else { return }
        scrollToPage(page, animated: false)
        syncPageControl()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        items = []
        onSelectItem = nil
        carocelPageController.currentPage = 0
        carocelPageController.numberOfPages = 0
    }
    
    func configure(items: [HomeItem], isRTL: Bool, onSelectItem: @escaping (HomeItem) -> Void) {
        self.items = items
        self.onSelectItem = onSelectItem
        carocelPageController.numberOfPages = items.count
        carocelPageController.currentPage = 0
        caroselColV.semanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
        caroselColV.reloadData()
        caroselColV.layoutIfNeeded()
        if !items.isEmpty {
            scrollToPage(0, animated: false)
        }
        syncPageControl()
    }
    
    private func cellWidth(for collectionWidth: CGFloat) -> CGFloat {
        max(200, collectionWidth - (2 * sidePeek))
    }
    
    private func contentOffsetCentered(forPage index: Int) -> CGFloat {
        guard index >= 0, index < items.count else { return 0 }
        caroselColV.layoutIfNeeded()
        guard let attrs = caroselColV.layoutAttributesForItem(at: IndexPath(item: index, section: 0)) else { return 0 }
        let target = attrs.center.x - caroselColV.bounds.width / 2
        let maxOffset = max(0, caroselColV.contentSize.width - caroselColV.bounds.width)
        return min(max(0, target), maxOffset)
    }
    
    private func nearestPage(for proposedOffsetX: CGFloat) -> Int {
        guard !items.isEmpty, caroselColV.bounds.width > 0 else { return 0 }
        caroselColV.layoutIfNeeded()
        let visibleMidX = proposedOffsetX + caroselColV.bounds.width / 2
        var best = 0
        var bestDelta = CGFloat.greatestFiniteMagnitude
        for i in 0..<items.count {
            guard let attrs = caroselColV.layoutAttributesForItem(at: IndexPath(item: i, section: 0)) else { continue }
            let delta = abs(attrs.center.x - visibleMidX)
            if delta < bestDelta {
                bestDelta = delta
                best = i
            }
        }
        return best
    }
    
    private func syncPageControl() {
        guard caroselColV.bounds.width > 0, !items.isEmpty else { return }
        let page = nearestPage(for: caroselColV.contentOffset.x)
        if carocelPageController.currentPage != page {
            carocelPageController.currentPage = page
        }
    }
    
    private func scrollToPage(_ page: Int, animated: Bool) {
        let x = contentOffsetCentered(forPage: page)
        caroselColV.setContentOffset(CGPoint(x: x, y: 0), animated: animated)
    }
    
    @objc private func pageChanged(_ sender: UIPageControl) {
        scrollToPage(sender.currentPage, animated: true)
    }
}

extension TopCaroselTableViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeCollectionViewCell.reuseIdentifier, for: indexPath) as? HomeCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: items[indexPath.item], showPlayOverlay: true)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        onSelectItem?(items[indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = max(collectionView.bounds.width, 1)
        let h = collectionView.bounds.height
        return CGSize(width: cellWidth(for: w), height: max(h, 1))
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        syncPageControl()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard !items.isEmpty else { return }
        let page = nearestPage(for: targetContentOffset.pointee.x)
        targetContentOffset.pointee.x = contentOffsetCentered(forPage: page)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        syncPageControl()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        syncPageControl()
    }
}
