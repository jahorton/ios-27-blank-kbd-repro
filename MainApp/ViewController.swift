//
//  ViewController.swift
//  DefaultKeyboardHost
//
//  Created by Joshua Horton on 1/10/20.
//  Copyright © 2020 SIL International. All rights reserved.
//

import UIKit
import OSLog
import WebKit

class ViewController: UIViewController, UITextFieldDelegate {
  @IBOutlet weak var systemInput: UITextField!
  @IBOutlet weak var inAppInput: UITextField!
  @IBOutlet weak var webViewVisible: UILabel!
  @IBOutlet weak var webViewIssueArmed: UILabel!

  var ivc: DummyInputViewController!

  var reproStateArmed: Bool = true

  override func viewDidLoad() {
    super.viewDidLoad()

    let assistant = systemInput.inputAssistantItem;
    assistant.leadingBarButtonGroups = [];
    assistant.trailingBarButtonGroups = [];

    ivc = DummyInputViewController()
    inAppInput.inputView = ivc.inputView

    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
      // Fires every 1/10 sec.
      self.updateStatusText()
    }

    systemInput.delegate = self
    inAppInput.delegate = self

    ivc.hostedPage = HostedPage.cyanBack
  }

  func updateStatusText() {
    guard let ivc = self.ivc else {
      return
    }

    guard let webView = ivc.webViewController.webView else {
      return
    }

    if ivc.inputView!.window == nil || ivc.inputView!.isHidden || webView.isHidden {
      self.webViewVisible.text = "App web view is not visible"
    } else {
      self.webViewVisible.text = "App web view is visible"
    }

    // If the web view has no title/URL but is supposed to be displaying content
    if reproStateArmed {
      self.webViewIssueArmed.text = "Web view repro is armed"
    } else {
      self.webViewIssueArmed.text = "Web view repro not armed"
    }
  }

  @IBAction func clearKeyboardPressed(_ sender: Any) {
    clearKeyboard()
    reproStateArmed = true

    updateStatusText()
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    reproStateArmed = false
  }

  @IBAction func replaceInputView(_ sender: Any) {
    os_log("replacing input view and input view controller")
    ivc = DummyInputViewController()

    // Does not appear to actually be "subbed in", based on polling results.
    // Seems to wait for a transition of UIResponder before actually replacing an old one.
    inAppInput.inputView = ivc.inputView
    updateStatusText()
  }

  func clearKeyboard() {
    self.view.endEditing(true)

    updateStatusText()
  }

  @IBAction func swapResponders(_ sender: Any) {
    // Seems to function the same as `endEditing` when
    // calling .become* on the current first responder.
    if systemInput.isFirstResponder {
      systemInput.resignFirstResponder()
      inAppInput.becomeFirstResponder()
    } else if inAppInput.isFirstResponder {
      inAppInput.resignFirstResponder()
      systemInput.becomeFirstResponder()
    }
    updateStatusText()
  }

  @IBAction func reloadInputView(_ sender: Any) {
    systemInput.reloadInputViews()
    inAppInput.reloadInputViews()

    updateStatusText()
  }

  @IBAction func tryContentNudge(_ sender: Any) {
    // AI suggestion, tidied up

    // 1. Tell UIKit the layout needs redrawing
    let webView = ivc.webViewController.webView!
    webView.setNeedsLayout()
    webView.layoutIfNeeded()

    // 2. Safely nudge the WebKit inner scrollView.
    // This forces the remote layer compositor to re-evaluate visible tiles.
    let currentOffset = webView.scrollView.contentOffset
    webView.scrollView.setContentOffset(CGPoint(x: currentOffset.x, y: currentOffset.y == 0 ? 0.5 : 0), animated: false)

    DispatchQueue.main.async {
      webView.scrollView.setContentOffset(currentOffset, animated: false)
    }

    updateStatusText()
  }

  @IBAction func swapHostedPage(_ sender: Any) {
    ivc.hostedPage = (ivc.hostedPage != HostedPage.redBack) ? HostedPage.redBack : HostedPage.cyanBack
    ivc.forceWebViewReload()
  }
}

