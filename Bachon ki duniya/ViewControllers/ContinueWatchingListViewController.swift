import UIKit
import SDWebImage

/// Full list of Continue Watching items (same store as Home).
final class ContinueWatchingListViewController: UIViewController {

    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    private var records: [ContinueWatchingRecord] = []
    private var changeObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "appBackground") ?? .white
        setupHeader()
        setupTable()
        setupEmpty()
        reload()
        changeObserver = NotificationCenter.default.addObserver(
            forName: .continueWatchingDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reload()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    deinit {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor(red: 1, green: 0.992, blue: 0.969, alpha: 1)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        if let img = UIImage(named: "backIcon") {
            backButton.setImage(img.withRenderingMode(.alwaysOriginal), for: .normal)
        } else {
            backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        }
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = AppL10n.t(.homeContinueWatching)
        titleLabel.font = UIFont(name: "Poppins-SemiBold", size: 18)
            ?? .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.145, green: 0.082, blue: 0.016, alpha: 1)
        titleLabel.textAlignment = .center

        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 52),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -48),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 100
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tableView.register(
            ContinueWatchingListCell.self,
            forCellReuseIdentifier: ContinueWatchingListCell.reuseId
        )

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmpty() {
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = AppL10n.t(.continueWatchingEmpty)
        emptyLabel.font = UIFont(name: "Poppins-Regular", size: 14) ?? .systemFont(ofSize: 14)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func reload() {
        ContinueWatchingStore.fetchForHome(limit: 50) { [weak self] records in
            guard let self else { return }
            self.records = records
            self.emptyLabel.isHidden = !records.isEmpty
            self.tableView.reloadData()
        }
    }

    @objc private func backTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func play(_ record: ContinueWatchingRecord) {
        guard let context = VideoPlaybackContext.from(record: record) else { return }
        VideoPlaybackPresenter.play(urlString: context.videoURL, context: context, from: self)
    }
}

extension ContinueWatchingListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ContinueWatchingListCell.reuseId,
            for: indexPath
        ) as! ContinueWatchingListCell
        cell.configure(with: records[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        play(records[indexPath.row])
    }
}

// MARK: - Row

private final class ContinueWatchingListCell: UITableViewCell {
    static let reuseId = "ContinueWatchingListCell"

    private let thumb = UIImageView()
    private let titleLabel = UILabel()
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private var progressWidth: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        thumb.translatesAutoresizingMaskIntoConstraints = false
        thumb.contentMode = .scaleAspectFill
        thumb.clipsToBounds = true
        thumb.layer.cornerRadius = 12
        thumb.backgroundColor = UIColor(white: 0.92, alpha: 1)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont(name: "Poppins-Medium", size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2

        progressTrack.translatesAutoresizingMaskIntoConstraints = false
        progressTrack.backgroundColor = UIColor(white: 0.9, alpha: 1)
        progressTrack.layer.cornerRadius = 2
        progressTrack.clipsToBounds = true

        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressFill.backgroundColor = ContinueWatchingStyle.purple
        progressFill.layer.cornerRadius = 2

        contentView.addSubview(thumb)
        contentView.addSubview(titleLabel)
        contentView.addSubview(progressTrack)
        progressTrack.addSubview(progressFill)

        progressWidth = progressFill.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            thumb.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumb.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumb.widthAnchor.constraint(equalToConstant: 120),
            thumb.heightAnchor.constraint(equalToConstant: 72),

            titleLabel.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: thumb.topAnchor, constant: 4),

            progressTrack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            progressTrack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            progressTrack.bottomAnchor.constraint(equalTo: thumb.bottomAnchor, constant: -4),
            progressTrack.heightAnchor.constraint(equalToConstant: 4),

            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            progressWidth!
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with record: ContinueWatchingRecord) {
        titleLabel.text = record.title
        let placeholder = UIImage(named: "placeholder")
        if let urlString = record.imageURL, !urlString.isEmpty, let url = URL(string: urlString) {
            thumb.sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .continueInBackground])
        } else {
            thumb.image = placeholder
        }
        progressWidth?.isActive = false
        let clamped = max(0.02, min(1, CGFloat(record.progress)))
        progressWidth = progressFill.widthAnchor.constraint(
            equalTo: progressTrack.widthAnchor,
            multiplier: clamped
        )
        progressWidth?.isActive = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumb.sd_cancelCurrentImageLoad()
        thumb.image = nil
        titleLabel.text = nil
    }
}
