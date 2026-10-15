import UIKit

/// Centered “Session Expired” card matching the product design.
final class SessionExpiredPopupView: UIView {

    var onLoginAgain: (() -> Void)?

    private let dimView = UIView()
    private let cardView = UIView()
    private let mascotImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let loginButton = UIButton(type: .system)

    private let cardBackground = UIColor(red: 0.925, green: 0.910, blue: 0.988, alpha: 1) // #ECE8FC
    private let textColor = UIColor(red: 0.290, green: 0.165, blue: 0.420, alpha: 1) // deep purple
    private let buttonColor = UIColor(red: 0.420, green: 0.870, blue: 0.650, alpha: 1) // mint

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        addSubview(dimView)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = cardBackground
        cardView.layer.cornerRadius = 28
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.12
        cardView.layer.shadowRadius = 18
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        addSubview(cardView)

        mascotImageView.translatesAutoresizingMaskIntoConstraints = false
        mascotImageView.contentMode = .scaleAspectFit
        mascotImageView.image = UIImage(named: "session_mascot")
        cardView.addSubview(mascotImageView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Session Expired"
        titleLabel.textAlignment = .center
        titleLabel.textColor = textColor
        titleLabel.font = UIFont(name: "Poppins-Bold", size: 22) ?? .systemFont(ofSize: 22, weight: .bold)
        cardView.addSubview(titleLabel)

        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = "Your session has expired.\nPlease log in again to continue."
        messageLabel.textAlignment = .center
        messageLabel.textColor = textColor
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont(name: "Poppins-Regular", size: 14) ?? .systemFont(ofSize: 14)
        cardView.addSubview(messageLabel)

        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.setTitle("Login Again", for: .normal)
        loginButton.setTitleColor(textColor, for: .normal)
        loginButton.titleLabel?.font = UIFont(name: "Poppins-SemiBold", size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
        loginButton.backgroundColor = buttonColor
        loginButton.layer.cornerRadius = 26
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        cardView.addSubview(loginButton)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            cardView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 36),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -36),
            cardView.widthAnchor.constraint(equalToConstant: 300),

            mascotImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 28),
            mascotImageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            mascotImageView.widthAnchor.constraint(equalToConstant: 150),
            mascotImageView.heightAnchor.constraint(equalToConstant: 150),

            titleLabel.topAnchor.constraint(equalTo: mascotImageView.bottomAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            loginButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 22),
            loginButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 28),
            loginButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -28),
            loginButton.heightAnchor.constraint(equalToConstant: 52),
            loginButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -28)
        ])
    }

    @objc private func loginTapped() {
        onLoginAgain?()
    }

    func present(in host: UIView, animated: Bool = true) {
        translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: host.topAnchor),
            leadingAnchor.constraint(equalTo: host.leadingAnchor),
            trailingAnchor.constraint(equalTo: host.trailingAnchor),
            bottomAnchor.constraint(equalTo: host.bottomAnchor)
        ])

        alpha = 0
        cardView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        UIView.animate(withDuration: animated ? 0.28 : 0, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.6) {
            self.alpha = 1
            self.cardView.transform = .identity
        }
    }

    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: animated ? 0.2 : 0, animations: {
            self.alpha = 0
            self.cardView.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        }, completion: { _ in
            self.removeFromSuperview()
            completion?()
        })
    }
}
