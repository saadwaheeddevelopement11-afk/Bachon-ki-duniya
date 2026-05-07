//
//  LanguagesTableViewCell.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 14/04/2026.
//

import UIKit

class LanguagesTableViewCell: UITableViewCell {
    
    @IBOutlet weak var languageName: UILabel!
    @IBOutlet weak var bgView: UIView!
    private let gradientLayer = CAGradientLayer()

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        bgView.layer.cornerRadius = 10
        bgView.layer.masksToBounds = false
        bgView.layer.borderWidth = 0
        
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 10
        bgView.layer.insertSublayer(gradientLayer, at: 0)
        
        languageName.textAlignment = .center
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bgView.bounds
    }
    
    func configure(backgroundColor: UIColor, isSelected: Bool, useDarkSelectedText: Bool) {
        let top = backgroundColor.adjustBrightness(by: 0.14)
        let mid = backgroundColor.adjustBrightness(by: 0.03)
        let bottom = backgroundColor.adjustBrightness(by: -0.12)
        gradientLayer.colors = [top.cgColor, mid.cgColor, bottom.cgColor]
        gradientLayer.locations = [0.0, 0.45, 1.0]
        bgView.backgroundColor = .clear
        configureSelection(isSelected: isSelected, useDarkSelectedText: useDarkSelectedText)
    }
    
    func configureSelection(isSelected: Bool, useDarkSelectedText: Bool) {
        if isSelected {
            languageName.textColor = useDarkSelectedText ? UIColor(white: 0.1, alpha: 1) : .white
            languageName.font = UIFont.boldSystemFont(ofSize: 18)
            bgView.layer.borderWidth = 2
            bgView.layer.borderColor = /*UIColor(named: "borderRed")?.cgColor ?? */ UIColor.lightGray.cgColor
            bgView.layer.shadowColor = UIColor.black.cgColor
            bgView.layer.shadowOpacity = 0.36
            bgView.layer.shadowRadius = 12
            bgView.layer.shadowOffset = CGSize(width: 0, height: 6)
            bgView.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        } else {
            languageName.textColor = UIColor(white: 0.35, alpha: 1)
            languageName.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            bgView.layer.borderWidth = 0
            bgView.layer.borderColor = UIColor.clear.cgColor
            bgView.layer.shadowOpacity = 0
            bgView.layer.shadowRadius = 0
            bgView.layer.shadowOffset = .zero
            bgView.transform = .identity
        }
    }
}

private extension UIColor {
    func adjustBrightness(by delta: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return self
        }
        let adjusted = max(0, min(1, brightness + delta))
        return UIColor(hue: hue, saturation: saturation, brightness: adjusted, alpha: alpha)
    }
}
