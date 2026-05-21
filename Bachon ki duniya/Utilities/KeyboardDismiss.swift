import UIKit
import ObjectiveC

/// Installs keyboard dismissal on every view controller: tap outside, drag on scroll views, and a Done bar for numeric keyboards.
enum KeyboardDismiss {

    static func installGlobally() {
        UIViewController.installKeyboardDismissSwizzle()
    }
}

// MARK: - UIViewController

private var keyboardDismissConfiguredKey: UInt8 = 0

extension UIViewController {

    static func installKeyboardDismissSwizzle() {
        guard self === UIViewController.self else { return }
        swizzle(#selector(viewDidLoad), #selector(kd_viewDidLoad))
        swizzle(#selector(viewWillAppear(_:)), #selector(kd_viewWillAppear(_:)))
    }

    private static func swizzle(_ original: Selector, _ swizzled: Selector) {
        guard
            let originalMethod = class_getInstanceMethod(UIViewController.self, original),
            let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled)
        else { return }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc func kd_viewDidLoad() {
        kd_viewDidLoad()
        enableKeyboardDismissOnTap()
    }

    @objc func kd_viewWillAppear(_ animated: Bool) {
        kd_viewWillAppear(animated)
        refreshKeyboardDismissConfiguration()
    }

    func enableKeyboardDismissOnTap() {
        guard objc_getAssociatedObject(self, &keyboardDismissConfiguredKey) == nil else { return }
        objc_setAssociatedObject(self, &keyboardDismissConfiguredKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let tap = UITapGestureRecognizer(target: self, action: #selector(kd_dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    func refreshKeyboardDismissConfiguration() {
        configureScrollViewsForKeyboardDismiss(in: view)
        configureTextInputsForKeyboardToolbar(in: view)
    }

    @objc private func kd_dismissKeyboard() {
        view.endEditing(true)
    }

    private func configureScrollViewsForKeyboardDismiss(in root: UIView) {
        for scrollView in root.kd_allSubviews(of: UIScrollView.self) {
            scrollView.keyboardDismissMode = .onDrag
        }
    }

    private func configureTextInputsForKeyboardToolbar(in root: UIView) {
        for textField in root.kd_allSubviews(of: UITextField.self) {
            textField.addKeyboardDoneToolbarIfNeeded()
        }
        for textView in root.kd_allSubviews(of: UITextView.self) {
            textView.addKeyboardDoneToolbarIfNeeded()
        }
    }
}

extension UIViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer.view === view else { return true }
        return touch.shouldDismissKeyboard
    }
}

// MARK: - Text inputs

private extension UITextInputTraits {
    var kd_needsDoneToolbar: Bool {
        switch keyboardType {
        case .numberPad, .phonePad, .decimalPad, .asciiCapableNumberPad:
            return true
        default:
            return false
        }
    }
}

extension UITextField {
    func addKeyboardDoneToolbarIfNeeded() {
        guard kd_needsDoneToolbar, inputAccessoryView == nil else { return }
        inputAccessoryView = makeKeyboardDoneToolbar(for: self)
    }
}

extension UITextView {
    func addKeyboardDoneToolbarIfNeeded() {
        guard kd_needsDoneToolbar, inputAccessoryView == nil else { return }
        inputAccessoryView = makeKeyboardDoneToolbar(for: self)
    }
}

private func makeKeyboardDoneToolbar(for responder: UIResponder) -> UIToolbar {
    let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
    toolbar.sizeToFit()
    let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let done = UIBarButtonItem(
        title: AppL10n.t(.ok),
        style: .done,
        target: responder,
        action: #selector(UIResponder.resignFirstResponder)
    )
    toolbar.items = [flex, done]
    return toolbar
}

// MARK: - Touch / view helpers

private extension UITouch {
    var shouldDismissKeyboard: Bool {
        var current: UIView? = view
        while let v = current {
            if v is UIControl || v is UITextField || v is UITextView {
                return false
            }
            current = v.superview
        }
        return true
    }
}

private extension UIView {
    func kd_allSubviews<T: UIView>(of type: T.Type) -> [T] {
        var result: [T] = []
        for sub in subviews {
            if let match = sub as? T { result.append(match) }
            result.append(contentsOf: sub.kd_allSubviews(of: type))
        }
        return result
    }
}
