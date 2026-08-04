//
//  OTPBoxesView.swift
//  Bachon ki duniya
//

import UIKit

/// 4-digit OTP entry as separate boxes with a single hidden text field driving input.
final class OTPBoxesView: UIView, UITextFieldDelegate {

    var digitCount: Int = 4 {
        didSet { rebuildBoxesIfNeeded() }
    }

    var onCodeChanged: ((String) -> Void)?
    var onCodeCompleted: ((String) -> Void)?

    private let stack = UIStackView()
    private let hiddenField = UITextField()
    private var digitLabels: [UILabel] = []
    private var boxViews: [UIView] = []

    var code: String {
        (hiddenField.text ?? "").filter(\.isNumber)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        hiddenField.keyboardType = .numberPad
        hiddenField.textContentType = .oneTimeCode
        hiddenField.tintColor = .clear
        hiddenField.textColor = .clear
        hiddenField.delegate = self
        hiddenField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        hiddenField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hiddenField)

        let tap = UITapGestureRecognizer(target: self, action: #selector(focusField))
        addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),

            hiddenField.leadingAnchor.constraint(equalTo: leadingAnchor),
            hiddenField.trailingAnchor.constraint(equalTo: trailingAnchor),
            hiddenField.topAnchor.constraint(equalTo: topAnchor),
            hiddenField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        rebuildBoxesIfNeeded()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            DispatchQueue.main.async { [weak self] in
                self?.focusField()
            }
        }
    }

    @objc func focusField() {
        hiddenField.becomeFirstResponder()
        updateBoxHighlight()
    }

    func clear() {
        hiddenField.text = ""
        refreshDigits()
        onCodeChanged?("")
    }

    private func rebuildBoxesIfNeeded() {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        digitLabels.removeAll()
        boxViews.removeAll()

        for _ in 0..<digitCount {
            let box = UIView()
            box.backgroundColor = UIColor.white.withAlphaComponent(0.92)
            box.layer.cornerRadius = 12
            box.layer.borderWidth = 1.5
            box.layer.borderColor = UIColor(red: 0.145, green: 0.082, blue: 0.016, alpha: 0.18).cgColor

            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.font = UIFont(name: "Poppins-Bold", size: 22) ?? .boldSystemFont(ofSize: 22)
            label.textColor = UIColor(red: 0.145, green: 0.082, blue: 0.016, alpha: 1)
            label.text = ""

            box.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: box.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: box.centerYAnchor)
            ])

            stack.addArrangedSubview(box)
            boxViews.append(box)
            digitLabels.append(label)
        }
        updateBoxHighlight()
    }

    @objc private func editingChanged() {
        let digits = code
        let clipped = String(digits.prefix(digitCount))
        if clipped != hiddenField.text {
            hiddenField.text = clipped
        }
        refreshDigits()
        onCodeChanged?(clipped)
        if clipped.count == digitCount {
            onCodeCompleted?(clipped)
        }
    }

    private func refreshDigits() {
        let chars = Array(code)
        for (index, label) in digitLabels.enumerated() {
            label.text = index < chars.count ? String(chars[index]) : ""
        }
        updateBoxHighlight()
    }

    private func updateBoxHighlight() {
        let activeIndex = min(code.count, digitCount - 1)
        let accent = UIColor(red: 0.62, green: 0.52, blue: 0.98, alpha: 1).cgColor
        let idle = UIColor(red: 0.145, green: 0.082, blue: 0.016, alpha: 0.18).cgColor
        for (index, box) in boxViews.enumerated() {
            let isActive = hiddenField.isFirstResponder && index == activeIndex && code.count < digitCount
                || (code.count == digitCount && index == digitCount - 1 && hiddenField.isFirstResponder)
            box.layer.borderColor = isActive ? accent : idle
            box.layer.borderWidth = isActive ? 2 : 1.5
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        let filtered = string.filter(\.isNumber)
        guard !filtered.isEmpty else { return false }
        let current = textField.text ?? ""
        guard let range = Range(range, in: current) else { return false }
        let next = current.replacingCharacters(in: range, with: filtered)
        return next.filter(\.isNumber).count <= digitCount
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateBoxHighlight()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateBoxHighlight()
    }
}
