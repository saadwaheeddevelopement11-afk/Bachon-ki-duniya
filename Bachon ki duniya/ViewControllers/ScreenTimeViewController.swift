import UIKit

fileprivate enum ScreenTimePalette {
    static let purple = UIColor(red: 0.29, green: 0.17, blue: 0.46, alpha: 1)
    static let purpleMuted = UIColor(red: 0.55, green: 0.42, blue: 0.72, alpha: 1)
    static let cardFill = UIColor(red: 0.93, green: 0.90, blue: 0.98, alpha: 1)
    static let infoFill = UIColor(red: 0.91, green: 0.93, blue: 0.96, alpha: 1)
    static let border = UIColor(red: 0.86, green: 0.84, blue: 0.90, alpha: 1)
    static let headerTop = UIColor(red: 0.90, green: 0.86, blue: 0.97, alpha: 1)
    static let secondaryText = UIColor(red: 0.55, green: 0.55, blue: 0.60, alpha: 1)
}

/// App foreground usage history (not video watch time).
final class ScreenTimeViewController: UIViewController {

    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)

    private var daySummaries: [AppScreenTimeDaySummary] = []
    private var totalText = "0s"
    private var changeObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "appBackground") ?? .white
        setupHeader()
        setupTable()
        reloadData()
        changeObserver = NotificationCenter.default.addObserver(
            forName: .appScreenTimeDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    deinit {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = ScreenTimePalette.headerTop

        backButton.translatesAutoresizingMaskIntoConstraints = false
        if let img = UIImage(named: "backIcon") {
            backButton.setImage(img.withRenderingMode(.alwaysOriginal), for: .normal)
        } else {
            backButton.setTitle("‹", for: .normal)
            backButton.titleLabel?.font = .systemFont(ofSize: 28, weight: .medium)
            backButton.tintColor = ScreenTimePalette.purple
        }
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = AppL10n.t(.screenTimeTitle)
        titleLabel.font = UIFont(name: "Poppins-SemiBold", size: 20)
            ?? .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = ScreenTimePalette.purple
        titleLabel.textAlignment = .center

        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8)
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tableView.register(ScreenTimeDayCell.self, forCellReuseIdentifier: ScreenTimeDayCell.reuseId)
        tableView.register(ScreenTimeHeaderCell.self, forCellReuseIdentifier: ScreenTimeHeaderCell.reuseId)

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func reloadData() {
        daySummaries = AppScreenTimeTracker.shared.dailySummaries()
        totalText = AppScreenTimeTracker.shared.formattedTotal()
        tableView.reloadData()
    }

    @objc private func backTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}

extension ScreenTimeViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 1 : max(daySummaries.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ScreenTimeHeaderCell.reuseId,
                for: indexPath
            ) as! ScreenTimeHeaderCell
            cell.configure(total: totalText)
            return cell
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: ScreenTimeDayCell.reuseId,
            for: indexPath
        ) as! ScreenTimeDayCell

        if daySummaries.isEmpty {
            cell.configureEmpty()
        } else {
            cell.configure(day: daySummaries[indexPath.row])
        }
        return cell
    }
}

// MARK: - Header (total + info)

private final class ScreenTimeHeaderCell: UITableViewCell {
    static let reuseId = "ScreenTimeHeaderCell"

    private let totalCard = UIView()
    private let totalTitle = UILabel()
    private let totalValue = UILabel()
    private let infoCard = UIView()
    private let infoIcon = UILabel()
    private let infoLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        totalCard.translatesAutoresizingMaskIntoConstraints = false
        totalCard.backgroundColor = ScreenTimePalette.cardFill
        totalCard.layer.cornerRadius = 18

        totalTitle.translatesAutoresizingMaskIntoConstraints = false
        totalTitle.font = UIFont(name: "Poppins-Medium", size: 13) ?? .systemFont(ofSize: 13, weight: .medium)
        totalTitle.textColor = ScreenTimePalette.purpleMuted
        totalTitle.text = AppL10n.t(.screenTimeTotalLabel)

        totalValue.translatesAutoresizingMaskIntoConstraints = false
        totalValue.font = UIFont(name: "Poppins-SemiBold", size: 28) ?? .systemFont(ofSize: 28, weight: .semibold)
        totalValue.textColor = ScreenTimePalette.purple

        infoCard.translatesAutoresizingMaskIntoConstraints = false
        infoCard.backgroundColor = ScreenTimePalette.infoFill
        infoCard.layer.cornerRadius = 14

        infoIcon.translatesAutoresizingMaskIntoConstraints = false
        infoIcon.text = "ℹ︎"
        infoIcon.textAlignment = .center
        infoIcon.font = .systemFont(ofSize: 14, weight: .bold)
        infoIcon.textColor = .white
        infoIcon.backgroundColor = ScreenTimePalette.purpleMuted
        infoIcon.layer.cornerRadius = 11
        infoIcon.clipsToBounds = true

        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.font = UIFont(name: "Poppins-Regular", size: 12) ?? .systemFont(ofSize: 12)
        infoLabel.textColor = ScreenTimePalette.secondaryText
        infoLabel.numberOfLines = 0
        infoLabel.text = AppL10n.t(.screenTimeInfo)

        contentView.addSubview(totalCard)
        totalCard.addSubview(totalTitle)
        totalCard.addSubview(totalValue)
        contentView.addSubview(infoCard)
        infoCard.addSubview(infoIcon)
        infoCard.addSubview(infoLabel)

        NSLayoutConstraint.activate([
            totalCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            totalCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            totalCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            totalTitle.topAnchor.constraint(equalTo: totalCard.topAnchor, constant: 16),
            totalTitle.leadingAnchor.constraint(equalTo: totalCard.leadingAnchor, constant: 16),
            totalTitle.trailingAnchor.constraint(equalTo: totalCard.trailingAnchor, constant: -16),

            totalValue.topAnchor.constraint(equalTo: totalTitle.bottomAnchor, constant: 4),
            totalValue.leadingAnchor.constraint(equalTo: totalCard.leadingAnchor, constant: 16),
            totalValue.trailingAnchor.constraint(equalTo: totalCard.trailingAnchor, constant: -16),
            totalValue.bottomAnchor.constraint(equalTo: totalCard.bottomAnchor, constant: -16),

            infoCard.topAnchor.constraint(equalTo: totalCard.bottomAnchor, constant: 12),
            infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            infoIcon.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 12),
            infoIcon.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 12),
            infoIcon.widthAnchor.constraint(equalToConstant: 22),
            infoIcon.heightAnchor.constraint(equalToConstant: 22),

            infoLabel.leadingAnchor.constraint(equalTo: infoIcon.trailingAnchor, constant: 10),
            infoLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -12),
            infoLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 12),
            infoLabel.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(total: String) {
        totalValue.text = total
    }
}

// MARK: - Day row

private final class ScreenTimeDayCell: UITableViewCell {
    static let reuseId = "ScreenTimeDayCell"

    private let card = UIView()
    private let durationLabel = UILabel()
    private let dayLabel = UILabel()
    private let detailLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(red: 0.97, green: 0.96, blue: 0.99, alpha: 1)
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = ScreenTimePalette.border.cgColor

        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = UIFont(name: "Poppins-SemiBold", size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
        durationLabel.textColor = ScreenTimePalette.purple

        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.font = UIFont(name: "Poppins-Regular", size: 12) ?? .systemFont(ofSize: 12)
        dayLabel.textColor = ScreenTimePalette.secondaryText
        dayLabel.textAlignment = .right

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = UIFont(name: "Poppins-Regular", size: 12) ?? .systemFont(ofSize: 12)
        detailLabel.textColor = ScreenTimePalette.secondaryText

        contentView.addSubview(card)
        card.addSubview(durationLabel)
        card.addSubview(dayLabel)
        card.addSubview(detailLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            durationLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            durationLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),

            dayLabel.centerYAnchor.constraint(equalTo: durationLabel.centerYAnchor),
            dayLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            dayLabel.leadingAnchor.constraint(greaterThanOrEqualTo: durationLabel.trailingAnchor, constant: 8),

            detailLabel.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 6),
            detailLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            detailLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            detailLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(day: AppScreenTimeDaySummary) {
        durationLabel.text = day.formattedDuration
        dayLabel.text = AppScreenTimeTracker.formatDayTitle(day.dayStart)
        if day.sessionCount <= 1 {
            detailLabel.text = AppL10n.t(.screenTimeOneSession)
        } else {
            detailLabel.text = AppL10n.t(.screenTimeSessionCount, day.sessionCount)
        }
        durationLabel.textColor = ScreenTimePalette.purple
    }

    func configureEmpty() {
        durationLabel.text = AppL10n.t(.screenTimeEmpty)
        dayLabel.text = ""
        detailLabel.text = AppL10n.t(.screenTimeEmptyHint)
        durationLabel.textColor = ScreenTimePalette.secondaryText
    }
}
