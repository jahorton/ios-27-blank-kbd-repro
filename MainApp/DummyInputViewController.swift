//
//  DummyInputViewController.swift
//  DefaultKeyboardHost
//
//  Created by Joshua Horton on 1/13/20.
//  Copyright © 2020 SIL International. All rights reserved.
//

import Foundation
import UIKit

private class CustomInputView: UIInputView {
  var height: CGFloat
  var inset: CGFloat
  
  var innerView: UIView!
  var insetView: UIView!
  
  var webViewController: WebViewController!

  init(height: CGFloat, inset: CGFloat, wvc: WebViewController) {
    self.height = height
    self.inset = inset
    self.webViewController = wvc
    
    super.init(frame: CGRect.zero, inputViewStyle: .keyboard)
  }

  override var intrinsicContentSize: CGSize {
    get {
      return CGSize(width: UIScreen.main.bounds.width, height: height > 0 ? height + inset : 200)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setConstraints() {
    let guide = self.safeAreaLayoutGuide
    var constraints: [NSLayoutConstraint] = []
    
    if height != 0 {
      constraints.append(innerView.heightAnchor.constraint(equalToConstant: height))
    } else {
      constraints.append(innerView.heightAnchor.constraint(equalTo: guide.heightAnchor))
    }

    constraints.append(innerView.widthAnchor.constraint(equalTo: guide.widthAnchor))
    constraints.append(innerView.leftAnchor.constraint(equalTo: guide.leftAnchor))
    constraints.append(insetView.widthAnchor.constraint(equalTo: guide.widthAnchor))

    constraints.append(innerView.bottomAnchor.constraint(equalTo: insetView.topAnchor))

    constraints.append(insetView.heightAnchor.constraint(equalToConstant: inset))
    constraints.append(insetView.bottomAnchor.constraint(equalTo: guide.bottomAnchor))
    
    // Lower the priority slightly below 1000 to prevent layout engine deadlocks
    constraints.forEach { constraint in
      constraint.priority = UILayoutPriority(999)
      constraint.isActive = true
    }
  }

  func load() {
    innerView = webViewController.view
    innerView.translatesAutoresizingMaskIntoConstraints = false

    self.addSubview(innerView)

    insetView = UIView()
    insetView.backgroundColor = .green
    insetView.translatesAutoresizingMaskIntoConstraints = false

    self.addSubview(insetView)
  }
}

class DummyInputViewController: UIInputViewController {
  var kbdHeight: CGFloat
  var insetHeight: CGFloat

  // The app group used to access common UserDefaults settings.
  static let appGroup = "group.horton.kmtesting"

  @IBOutlet var nextKeyboardButton: UIButton!
  
  public var webViewController: WebViewController!

  convenience init() {
    self.init(height: CGFloat(200))
  }

  init(height: CGFloat, inset: CGFloat = 0) {
    kbdHeight = 160
    insetHeight = 40

    super.init(nibName: nil, bundle: nil)
    
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
      // Fires every 1/10 sec.
      if self.webViewController.activePage != self.webViewController.selectedPage {
        self.webViewController.loadPage()
      }
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public var hostedPage: HostedPage {
    get {
      return webViewController.activePage ?? webViewController.selectedPage
    }
    
    set(value) {
      let userDefaults = UserDefaults(suiteName: DummyInputViewController.appGroup)!
      
      userDefaults.set(value.rawValue, forKey: "hostedPage")
      webViewController.loadPage()
    }
  }

  open override func loadView() {
    let wvc = WebViewController()
    webViewController = wvc
    let baseView = CustomInputView(height: kbdHeight, inset: insetHeight, wvc: wvc)
    addChild(wvc)

    baseView.backgroundColor = .blue
    baseView.translatesAutoresizingMaskIntoConstraints = false

    self.inputView = baseView
  }
  
  func forceWebViewReload() {
    webViewController!.loadPage()
  }

  open override func viewDidLoad() {
    let baseView = self.inputView as! CustomInputView
    
    // Perform custom UI setup here
    baseView.load()
    baseView.setConstraints()
    
    if(self.needsInputModeSwitchKey) {
      addNextKeyboardButton(to: baseView)
    }
  }
  
  private func addNextKeyboardButton(to baseView: CustomInputView) {
    // Adds a very basic "Next keyboard" button to ensure we can always swap keyboards, even on iPhone SE.
    self.nextKeyboardButton = UIButton(type: .system)

    self.nextKeyboardButton.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), for: [])
    self.nextKeyboardButton.sizeToFit()
    self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false

    self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)

    baseView.insetView.addSubview(self.nextKeyboardButton)

    self.nextKeyboardButton.leftAnchor.constraint(equalTo: baseView.insetView.leftAnchor).isActive = true
    self.nextKeyboardButton.bottomAnchor.constraint(equalTo: baseView.insetView.bottomAnchor).isActive = true
  }
}
