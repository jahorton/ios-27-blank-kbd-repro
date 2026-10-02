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

class ViewController: UIViewController {
  @IBOutlet weak var systemInput: UITextField!
  @IBOutlet weak var inAppInput: UITextField!
  @IBOutlet weak var webViewVisible: UILabel!
  @IBOutlet weak var webViewProcess: UILabel!
  
  var ivc: DummyInputViewController!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let assistant = systemInput.inputAssistantItem;
    assistant.leadingBarButtonGroups = [];
    assistant.trailingBarButtonGroups = [];
    
    ivc = DummyInputViewController()
    inAppInput.inputView = ivc.inputView
    
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
      // Fires every 1/10 sec.
      //
      
      self.updateStatusText()
    }
  }
  
  func updateStatusText() {
    guard let ivc = self.ivc else {
      return
    }
    
    guard let webView = ivc.webViewController.webView else {
      return
    }
    
    if ivc.inputView!.window == nil || ivc.inputView!.isHidden || webView.isHidden {
      self.webViewVisible.text = "Web view is not visible"
    } else {
      self.webViewVisible.text = "Web view is visible"
    }
    
    // If the web view has no title/URL but is supposed to be displaying content
    if webView.title?.isEmpty ?? true && webView.url == nil {
      self.webViewProcess.text = "Web view process appears dead"
    } else {
      self.webViewProcess.text = "Web view process appears live"
    }
  }

  @IBAction func clearKeyboardPressed(_ sender: Any) {
    clearKeyboard()
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
    // Is what Keyman for iPhone / iOS calls to complete hiding the keyboard.
    // Well, that and resignFirstResponder.
    // Ah.  Its docs aim to resignFirstResponder on the view or a subview if applicable, so yeah, of course there's correlation
    self.view.endEditing(true)
    
    updateStatusText()
  }
  
  @IBAction func swapResponders(_ sender: Any) {
    // Seems to function the same as `endEditing`.
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
  
  // AI suggestion, tidied up
  func kickstartWebViewRendering() {
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
  
  @IBAction func tryContentNudge(_ sender: Any) {
    kickstartWebViewRendering()
    updateStatusText()
  }
  
  @IBAction func forceWebViewReload(_ sender: Any) {
    ivc.forceWebViewReload()
  }
}

