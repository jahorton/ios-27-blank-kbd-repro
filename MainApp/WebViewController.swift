//
//  WebViewController.swift
//  KeyboardCalibrator
//
//  Created by Joshua Horton on 9/30/26.
//  Copyright © 2026 Joshua Horton. All rights reserved.
//

import UIKit
import WebKit
import OSLog

enum HostedPage: String {
  case cyanBack = "index.html"
  case redBack = "alt.html"
}

// We subclass for one critical reason - by default, WebViews may become first responder...
// a detail that is really, REALLY bad for a WebView in a keyboard.
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
  override func viewWillLayoutSubviews() {
    kbSize = view.bounds.size
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

    loadPage()
  }
  
  public var activePage: HostedPage? = nil

  public var selectedPage: HostedPage {
    get {
      // Retrieve kbd height from app group!
      let userDefaults = UserDefaults(suiteName: DummyInputViewController.appGroup)!
      
      let pageString = userDefaults.string(forKey: "hostedPage")
      
      if pageString != nil {
        return HostedPage(rawValue: pageString!)!
      } else {
        return HostedPage.cyanBack
      }
    }
  }
  
  // MARK: - Show/hide views
  func loadPage() {
    activePage = selectedPage
    
    let hostPageFileUrl = URL(fileURLWithPath: activePage!.rawValue, relativeTo: WebViewController.siteBundle.bundleURL)
    webView!.loadFileURL(hostPageFileUrl, allowingReadAccessTo: WebViewController.siteBundle.bundleURL)
  }

  // Very useful for immediately adjusting the WebView's properties upon loading.
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    kbSize = view.bounds.size
  }

  func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    os_log("Web content process terminated - reloading")
    webView.reload()
  }
}
