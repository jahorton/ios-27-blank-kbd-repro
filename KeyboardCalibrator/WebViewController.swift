//
//  WebViewController.swift
//  KeyboardCalibrator
//
//  Created by Joshua Horton on 9/30/26.
//  Copyright © 2026 Joshua Horton. All rights reserved.
//

import UIKit
import WebKit

// We subclass for one critical reason - by default, WebViews may become first responder...
// a detail that is really, REALLY bad for a WebView in a keyboard.
//
// Minor reference here: https://stackoverflow.com/questions/39829863/can-a-uiwebview-handle-user-interaction-without-becoming-first-responder
//
// Confirmed issue existed within app during workaround for https://github.com/keymanapp/keyman/issues/2716
class WebView: WKWebView {
  override public var canBecomeFirstResponder: Bool {
    return false;
  }

  override public func becomeFirstResponder() -> Bool {
    return false;
  }
}

// MARK: - UIViewController
class WebViewController: UIViewController, WKNavigationDelegate {
  private let userContentController = WKUserContentController()
  
  public static let siteBundle: Bundle = {
    let mainBundle = Bundle(for: WebViewController.self)
    return Bundle(path: mainBundle.path(forResource: "Hosted", ofType: "bundle")!)!
  }()

  // Views
  var webView: WebView?

  /// Stores the keyboard view's current size.
  private var kbSize: CGSize = CGSize.zero

  init() {
    super.init(nibName: nil, bundle: nil)
    _ = view
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc func fixLayout() {
    view.setNeedsLayout()
    view.layoutIfNeeded()
  }

  override func viewWillLayoutSubviews() {
    kbSize = view.bounds.size
  }

  open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    coordinator.animateAlongsideTransition(in: nil, animation: {
      _ in
        self.fixLayout()
    }, completion: {
      _ in
      // When going from landscape to portrait, the value is often not properly set until the end of the call chain.
      // A simple, ultra-short timer allows us to quickly rectify the value in these cases to correct the keyboard.
      Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.fixLayout), userInfo: nil, repeats: false)
    })
  }

  override func loadView() {
    let config = WKWebViewConfiguration()
    let prefs = WKPreferences()

    let pagePrefs = WKWebpagePreferences()
    pagePrefs.allowsContentJavaScript = true

    // Explicitly grant universal context to custom scheme pipelines
    config.preferences = prefs
    config.defaultWebpagePreferences = pagePrefs

    config.suppressesIncrementalRendering = false
    config.userContentController = self.userContentController

    webView = WebView(frame: CGRect(origin: .zero, size: kbSize), configuration: config)

    // Keep this:  it's actually making a difference in background color visibility.
    webView!.isOpaque = true
    webView!.translatesAutoresizingMaskIntoConstraints = false
    webView!.backgroundColor = UIColor.clear
    webView!.navigationDelegate = self
    webView!.scrollView.isScrollEnabled = false

    // Disable WKWebView default layout-constraint manipulations. We ensure
    // safe-area boundaries are respected via InputView / InputViewController
    // constraints.
    //
    // Fixes #10859.
    // Ref: https://stackoverflow.com/a/63741514
    webView!.scrollView.contentInsetAdjustmentBehavior = .never
    
    if #available(iOS 16.4, *) {
      webView!.isInspectable = true
    } else {
      // Fallback on earlier versions
    }

    view = webView

    loadKeyboard()
  }
  
  // MARK: - Show/hide views
  func loadKeyboard() {
    let hostPageFileUrl = URL(fileURLWithPath: "index.html", relativeTo: WebViewController.siteBundle.bundleURL)
    webView!.loadFileURL(hostPageFileUrl, allowingReadAccessTo: WebViewController.siteBundle.bundleURL)
  }

  // Very useful for immediately adjusting the WebView's properties upon loading.
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    fixLayout()

    // Initialize the keyboard's size/scale.  In iOS 13 (at least), the system
    // keyboard's width will be set at this stage, but not in viewWillAppear.
    kbSize = view.bounds.size
  }
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    guard let url = webView.url else {
      return
    }
  }
  
  func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    webView.reload()
  }
}
