//
//  HTMLGameViewController.swift
//  Bachon ki duniya
//

import UIKit
import WebKit

/// Full-screen HTML game: compact header with back + title, WebKit fills the rest.
/// Scales the HTML document so the full game UI (including center buttons) fits on screen.
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
        // Guard localStorage before game scripts run (some WebViews block it and break renderGrid).
        let bootstrap = WKUserScript(
            source: HTMLGameViewController.bootstrapJavaScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(bootstrap)
        // Run fit script as soon as the document is ready, then again after load.
        let script = WKUserScript(
            source: HTMLGameViewController.fitToViewportJavaScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(script)
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Re-fit when the web view size is known / changes (after the page has loaded).
        if webView.bounds.height > 0, !webView.isLoading {
            applyFitToViewport()
        }
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
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.bounces = false
        webView.scrollView.minimumZoomScale = 1
        webView.scrollView.maximumZoomScale = 1

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
        webView.load(URLRequest(url: url))
    }

    private func applyFitToViewport() {
        webView.evaluateJavaScript(Self.fitToViewportJavaScript, completionHandler: nil)
    }

    /// Ensures game scripts can use localStorage (needed for level buttons on some WebViews).
    private static let bootstrapJavaScript = """
    (function() {
      try {
        localStorage.getItem('__bkd_probe');
      } catch (e) {
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

    /// Scales `.container` (or body content) so the entire game card fits in the WebView.
    /// Uses CSS `zoom` (WebKit) so layout size matches visual size and content is not clipped.
    private static let fitToViewportJavaScript = """
    (function() {
      if (window.__bkdFitInstalled) {
        window.__bkdFitNow && window.__bkdFitNow();
        return;
      }
      window.__bkdFitInstalled = true;

      function ensureStyle() {
        if (document.getElementById('bkd-fit-style')) return;
        var css = document.createElement('style');
        css.id = 'bkd-fit-style';
        css.textContent = [
          'html, body {',
          '  height: 100% !important;',
          '  min-height: 100% !important;',
          '  width: 100% !important;',
          '  margin: 0 !important;',
          '  padding: 0 !important;',
          '  overflow: hidden !important;',
          '}',
          'body {',
          '  display: flex !important;',
          '  align-items: center !important;',
          '  justify-content: center !important;',
          '  min-height: 100% !important;',
          '}',
          '.container, .bkd-fit-target {',
          '  transform: none !important;',
          '  flex-shrink: 0 !important;',
          '}',
          '.card-box { padding: 22px 18px !important; }',
          '.emoji-big { font-size: 48px !important; margin-bottom: 8px !important; }',
          'h1 { font-size: 1.6rem !important; margin-bottom: 4px !important; }',
          '.sub { margin-bottom: 14px !important; font-size: 0.9rem !important; }',
          '.level-grid {',
          '  display: grid !important;',
          '  grid-template-columns: repeat(3, 1fr) !important;',
          '  gap: 10px !important;',
          '  margin-bottom: 8px !important;',
          '  min-height: 0 !important;',
          '}',
          '.level-btn {',
          '  display: block !important;',
          '  padding: 12px 6px !important;',
          '  min-height: 56px !important;',
          '}'
        ].join('\\n');
        document.head.appendChild(css);
      }

      function measureTarget() {
        return document.querySelector('.container')
          || document.querySelector('.card-box')
          || document.body.firstElementChild;
      }

      function fitNow() {
        ensureStyle();

        // Level buttons are injected by the game script; re-render if the grid is still empty.
        var levelGrid = document.getElementById('levelGrid');
        if (levelGrid && !levelGrid.children.length && typeof renderGrid === 'function') {
          try { renderGrid(); } catch (e) {}
        }

        var target = measureTarget();
        if (!target) return;

        target.classList.add('bkd-fit-target');
        target.style.transform = 'none';
        target.style.zoom = '1';

        // Force layout so dynamically inserted level buttons are included.
        void target.offsetHeight;

        var contentH = Math.max(target.scrollHeight, target.offsetHeight, 1);
        var contentW = Math.max(target.scrollWidth, target.offsetWidth, 1);
        var availH = Math.max(window.innerHeight, 1);
        var availW = Math.max(window.innerWidth, 1);

        var scale = Math.min(availW / contentW, availH / contentH) * 0.95;
        scale = Math.max(0.35, Math.min(scale, 1));

        // `zoom` scales layout box too (unlike transform), preventing clipped buttons.
        target.style.zoom = String(scale);

        // Fallback for engines without zoom support.
        if (!target.style.zoom || target.style.zoom === 'normal') {
          target.style.transformOrigin = 'center center';
          target.style.transform = 'scale(' + scale + ')';
          target.style.marginTop = ((contentH * (1 - scale)) / -2) + 'px';
          target.style.marginBottom = ((contentH * (1 - scale)) / -2) + 'px';
        } else {
          target.style.transform = 'none';
          target.style.marginTop = '0';
          target.style.marginBottom = '0';
        }
      }

      window.__bkdFitNow = fitNow;
      fitNow();
      setTimeout(fitNow, 50);
      setTimeout(fitNow, 200);
      setTimeout(fitNow, 500);
      setTimeout(fitNow, 1000);
      window.addEventListener('resize', fitNow);
      window.addEventListener('orientationchange', fitNow);
      if (document.fonts && document.fonts.ready) {
        document.fonts.ready.then(fitNow).catch(function(){});
      }
      if (document.body) {
        new MutationObserver(function() { setTimeout(fitNow, 30); })
          .observe(document.body, {
            childList: true,
            subtree: true,
            attributes: true,
            attributeFilter: ['class', 'style']
          });
      } else {
        document.addEventListener('DOMContentLoaded', function() {
          new MutationObserver(function() { setTimeout(fitNow, 30); })
            .observe(document.body, {
              childList: true,
              subtree: true,
              attributes: true,
              attributeFilter: ['class', 'style']
            });
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
        applyFitToViewport()
        // Fonts / dynamic level buttons may land slightly later.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.applyFitToViewport()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.applyFitToViewport()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.applyFitToViewport()
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
