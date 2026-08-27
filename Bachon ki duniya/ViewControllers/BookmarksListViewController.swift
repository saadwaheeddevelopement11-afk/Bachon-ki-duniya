import UIKit
import SDWebImage

/// Lists bookmarked episodes (local cache + synced from GET /bookmarks/{msisdn}).
final class BookmarksListViewController: UIViewController {

    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    private var items: [BookmarkEpisode] = []
    private var changeObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "appBackground") ?? .white
        setupHeader()
        setupTable()
        setupEmpty()
        reload()
        changeObserver = NotificationCenter.default.addObserver(
            forName: .bookmarksDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reload(fromServer: false)
        }
        BookmarkStore.syncFromServer { [weak self] _ in
            self?.reload(fromServer: false)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload(fromServer: true)
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
        titleLabel.text = AppL10n.t(.profileBookmarks)
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
        tableView.rowHeight = 120
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        let nib = UINib(nibName: "KidsStoriesTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: KidsStoriesTableViewCell.reuseIdentifier)

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
        emptyLabel.text = AppL10n.t(.bookmarksEmpty)
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

    private func reload(fromServer: Bool = false) {
        if fromServer {
            BookmarkStore.syncFromServer { [weak self] _ in
                self?.applyLocalItems()
            }
        } else {
            applyLocalItems()
        }
    }

    private func applyLocalItems() {
        items = BookmarkStore.allBookmarks()
        emptyLabel.isHidden = !items.isEmpty
        tableView.reloadData()
    }

    @objc private func backTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func play(_ item: BookmarkEpisode) {
        guard let context = VideoPlaybackContext.from(bookmark: item) else { return }
        VideoPlaybackPresenter.play(urlString: context.videoURL, context: context, from: self)
    }

    private func toggleBookmark(_ item: BookmarkEpisode) {
        BookmarkStore.toggle(
            episodeId: item.id,
            title: item.title,
            description: item.description,
            thumbnailURL: item.thumbnailURL,
            videoURL: item.videoURL
        ) { [weak self] result in
            if case .failure(let error) = result {
                let alert = UIAlertController(
                    title: AppL10n.t(.errorTitle),
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: AppL10n.t(.ok), style: .default))
                self?.present(alert, animated: true)
            }
            self?.applyLocalItems()
        }
    }
}

extension BookmarksListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: KidsStoriesTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? KidsStoriesTableViewCell else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        cell.titleLbl.text = item.displayTitle
        cell.textLbl.text = item.displayDescription
        cell.titleLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        cell.textLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        cell.languageLbl?.superview?.isHidden = true
        cell.configureBookmark(isBookmarked: true)
        cell.onBookmarkTapped = { [weak self] in
            self?.toggleBookmark(item)
        }

        let placeholder = UIImage(named: "placeholder")
        if let urlString = item.thumbnailURL, let url = URL(string: urlString) {
            cell.mainImageView.sd_setImage(with: url, placeholderImage: placeholder)
        } else {
            cell.mainImageView.image = placeholder
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        play(items[indexPath.row])
    }
}
