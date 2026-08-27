//
//  HTMLGameViewController.swift
//  Bachon ki duniya
//

import UIKit
import WebKit

/// Full-screen HTML game: compact header with back + title, WebKit fills the rest.
/// Fetches remote HTML, patches in level buttons + layout fixes, then loads via loadHTMLString
/// so WKWebView renders the full game UI (CDN serves `content-disposition: attachment`).
final class HTMLGameViewController: UIViewController {

    var gameTitleText: String = ""
    var htmlURLString: String = ""

    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let webView: WKWebView
    private let spinner = UIActivityIndicatorView(style: .large)

    init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        if #available(iOS 14.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            config.preferences.javaScriptEnabled = true
        }

        let bootstrap = WKUserScript(
            source: HTMLGameViewController.bootstrapJavaScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(bootstrap)

        webView = WKWebView(frame: .zero, configuration: config)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "appBackground") ?? .systemBackground
        setupHeader()
        setupWebView()
        loadGame()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed || isMovingFromParent {
            webView.stopLoading()
        }
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor(red: 1, green: 0.992, blue: 0.969, alpha: 1)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(named: "backIcon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.accessibilityLabel = "Back"

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = gameTitleText
        titleLabel.font = UIFont(name: "Acme-Regular", size: 18) ?? .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.145, green: 0.082, blue: 0.016, alpha: 1)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

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

    private func setupWebView() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.backgroundColor = .white
        webView.isOpaque = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.contentInset = .zero
        webView.scrollView.scrollIndicatorInsets = .zero
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.alwaysBounceVertical = true

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true

        view.addSubview(webView)
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: webView.centerYAnchor)
        ])
    }

    private func loadGame() {
        let trimmed = htmlURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else {
            presentLoadError(message: "Invalid game URL.")
            return
        }

        spinner.startAnimating()
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    self.spinner.stopAnimating()
                    self.presentLoadError(message: error.localizedDescription)
                    return
                }
                guard let data, let html = String(data: data, encoding: .utf8) else {
                    self.spinner.stopAnimating()
                    self.presentLoadError(message: "Could not read game content.")
                    return
                }

                let patched = Self.patchGameHTML(html)
                let baseURL = url.deletingLastPathComponent()
                self.webView.loadHTMLString(patched, baseURL: baseURL)
            }
        }.resume()
    }

    /// Patches CDN HTML so level buttons exist in markup and the card is not clipped.
    private static func patchGameHTML(_ html: String) -> String {
        var patched = html

        let headFix = """
        <style id="bkd-game-fix">
        html, body {
          overflow-x: hidden !important;
          overflow-y: auto !important;
          overflow: auto !important;
          height: auto !important;
          min-height: 100% !important;
          -webkit-text-size-adjust: 100% !important;
        }
        body {
          display: block !important;
          padding: 16px 0 32px !important;
          box-sizing: border-box !important;
        }
        .container {
          width: 90% !important;
          max-width: 520px !important;
          margin: 0 auto !important;
          height: auto !important;
          overflow: visible !important;
        }
        .card-box {
          overflow: visible !important;
          height: auto !important;
        }
        .screen.active {
          display: block !important;
          overflow: visible !important;
        }
        .level-grid {
          display: grid !important;
          grid-template-columns: repeat(3, minmax(0, 1fr)) !important;
          gap: 14px !important;
          margin: 16px 0 10px !important;
          min-height: 168px !important;
          overflow: visible !important;
        }
        .level-btn {
          min-height: 72px !important;
          cursor: pointer !important;
          visibility: visible !important;
          opacity: 1 !important;
        }
        </style>
        """

        if let headClose = patched.range(of: "</head>", options: .caseInsensitive) {
            patched.insert(contentsOf: headFix, at: headClose.lowerBound)
        }

        let staticGrid = """
        <div class="level-grid" id="levelGrid">
          <div class="level-btn" data-level="0"><div class="lvl-num">1</div><div class="lvl-label">Tiny Sums</div><div class="lvl-time">⏱ 45s</div></div>
          <div class="level-btn locked" data-level="1"><div class="lvl-num">🔒</div><div class="lvl-label">Take Away</div><div class="lvl-time">⏱ 50s</div></div>
          <div class="level-btn locked" data-level="2"><div class="lvl-num">🔒</div><div class="lvl-label">Times Fun</div><div class="lvl-time">⏱ 60s</div></div>
          <div class="level-btn locked" data-level="3"><div class="lvl-num">🔒</div><div class="lvl-label">Big Multiply</div><div class="lvl-time">⏱ 70s</div></div>
          <div class="level-btn locked" data-level="4"><div class="lvl-num">🔒</div><div class="lvl-label">Mix It Up</div><div class="lvl-time">⏱ 75s</div></div>
          <div class="level-btn locked" data-level="5"><div class="lvl-num">🔒</div><div class="lvl-label">Division Quest</div><div class="lvl-time">⏱ 80s</div></div>
        </div>
        """

        if patched.contains("id=\"levelGrid\"") {
            patched = patched.replacingOccurrences(
                of: "<div class=\"level-grid\" id=\"levelGrid\"></div>",
                with: staticGrid
            )
            patched = patched.replacingOccurrences(
                of: "<div class=\"level-grid\" id=\"levelGrid\"/>",
                with: staticGrid
            )
        }

        let wireScript = """
        <script id="bkd-wire-levels">
        (function() {
          function populateFallback() {
            var grid = document.getElementById('levelGrid');
            if (!grid || grid.children.length > 0 || typeof LEVELS === 'undefined') return;
            LEVELS.forEach(function(lv, i) {
              var ok = i === 0;
              var el = document.createElement('div');
              el.className = 'level-btn' + (ok ? '' : ' locked');
              el.setAttribute('data-level', String(i));
              el.innerHTML = '<div class="lvl-num">' + (ok ? String(i + 1) : '🔒') + '</div>'
                + '<div class="lvl-label">' + lv.name + '</div>'
                + '<div class="lvl-time">⏱ ' + lv.time + 's</div>';
              if (ok) el.onclick = function() { if (typeof startLevel === 'function') startLevel(i); };
              grid.appendChild(el);
            });
          }

          function wireLevels() {
            if (typeof renderGrid === 'function' && typeof LEVELS !== 'undefined') {
              try { renderGrid(); } catch (e) { populateFallback(); }
            } else {
              populateFallback();
            }

            var grid = document.getElementById('levelGrid');
            if (!grid) return;

            grid.querySelectorAll('.level-btn[data-level]').forEach(function(el) {
              if (el.classList.contains('locked')) return;
              var idx = parseInt(el.getAttribute('data-level'), 10);
              el.onclick = function() {
                if (typeof startLevel === 'function') startLevel(idx);
              };
            });
          }

          document.addEventListener('DOMContentLoaded', wireLevels);
          window.addEventListener('load', function() {
            wireLevels();
            setTimeout(wireLevels, 150);
            setTimeout(wireLevels, 500);
          });
        })();
        </script>
        """

        if let bodyClose = patched.range(of: "</body>", options: .caseInsensitive) {
            patched.insert(contentsOf: wireScript, at: bodyClose.lowerBound)
        }

        // Don't let a failing inline script wipe the static buttons we injected.
        patched = patched.replacingOccurrences(
            of: "const g=document.getElementById('levelGrid');g.innerHTML='';",
            with: "const g=document.getElementById('levelGrid');if(!g)return;g.innerHTML='';"
        )
        patched = patched.replacingOccurrences(
            of: "renderGrid();",
            with: "try { if (typeof LEVELS !== 'undefined') renderGrid(); } catch (e) {}"
        )

        return patched
    }

    private static let ensureLevelGridJavaScript = """
    (function() {
      var grid = document.getElementById('levelGrid');
      if (!grid || grid.children.length >= 6) return;
      if (typeof renderGrid === 'function' && typeof LEVELS !== 'undefined') {
        try { renderGrid(); } catch (e) {}
      }
      if (grid.children.length > 0 || typeof LEVELS === 'undefined') return;
      LEVELS.forEach(function(lv, i) {
        var ok = i === 0;
        var el = document.createElement('div');
        el.className = 'level-btn' + (ok ? '' : ' locked');
        el.setAttribute('data-level', String(i));
        el.innerHTML = '<div class="lvl-num">' + (ok ? String(i + 1) : '🔒') + '</div>'
          + '<div class="lvl-label">' + lv.name + '</div>'
          + '<div class="lvl-time">⏱ ' + lv.time + 's</div>';
        if (ok) el.onclick = function() { if (typeof startLevel === 'function') startLevel(i); };
        grid.appendChild(el);
      });
    })();
    """

    private static let bootstrapJavaScript = """
    (function() {
      try { localStorage.getItem('__bkd_probe'); }
      catch (e) {
        var mem = {};
        Object.defineProperty(window, 'localStorage', {
          configurable: true,
          value: {
            getItem: function(k) { return Object.prototype.hasOwnProperty.call(mem, k) ? mem[k] : null; },
            setItem: function(k, v) { mem[k] = String(v); },
            removeItem: function(k) { delete mem[k]; },
            clear: function() { mem = {}; },
            key: function(i) { return Object.keys(mem)[i] || null; },
            get length() { return Object.keys(mem).length; }
          }
        });
      }
    })();
    """

    @objc private func backTapped() {
        if presentingViewController != nil {
            dismiss(animated: true)
        } else if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func presentLoadError(message: String) {
        let alert = UIAlertController(
            title: AppL10n.t(.errorTitle),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: AppL10n.t(.ok), style: .default) { [weak self] _ in
            self?.backTapped()
        })
        present(alert, animated: true)
    }
}

// MARK: - WKNavigationDelegate

extension HTMLGameViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimating()

        if #available(iOS 14.0, *) {
            webView.pageZoom = 1.0
        }

        webView.evaluateJavaScript(Self.ensureLevelGridJavaScript)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.webView.evaluateJavaScript(Self.ensureLevelGridJavaScript)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating()
        presentLoadError(message: error.localizedDescription)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating()
        presentLoadError(message: error.localizedDescription)
    }
}
