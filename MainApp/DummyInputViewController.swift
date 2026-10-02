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
//  var topGuardView: UIView!
  var innerView: UIView!
  var insetView: UIView!

  var insetHeightLabel: UILabel!
  
  var webViewController: WebViewController!

  init(height: CGFloat, inset: CGFloat, wvc: WebViewController) {
    self.height = height
    self.inset = inset
    self.webViewController = wvc
    
    super.init(frame: CGRect.zero, inputViewStyle: .keyboard)
  }

  override var intrinsicContentSize: CGSize {
    get {
      return CGSize(width: UIScreen.main.bounds.width, height: height > 0 ? height + inset : 100)
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
//    topGuardView = UIView()
//    topGuardView.backgroundColor = UIColor.systemBackground
//    topGuardView.translatesAutoresizingMaskIntoConstraints = false
//    self.addSubview(topGuardView)
    
    innerView = webViewController.view
    innerView.translatesAutoresizingMaskIntoConstraints = false

    self.addSubview(innerView)

    insetView = UIView()
    insetView.backgroundColor = .green
    insetView.translatesAutoresizingMaskIntoConstraints = false

    insetHeightLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    insetHeightLabel.text = "(0.0, \(inset))"

    insetView.addSubview(insetHeightLabel)

    self.addSubview(insetView)
  }
}

class DummyInputViewController: UIInputViewController {
  var kbdHeight: CGFloat
  var insetHeight: CGFloat

  // The app group used to access common UserDefaults settings.
  static let appGroup = "group.horton.kmtesting"

  static var keyboardHeightDefault: CGFloat {
    get {
      let userDefaults = UserDefaults(suiteName: DummyInputViewController.appGroup)!
      return (userDefaults.object(forKey: "height") as? CGFloat) ?? 0
    }

    set(value) {
      let userDefaults = UserDefaults(suiteName: DummyInputViewController.appGroup)!
      userDefaults.set(value, forKey: "height")
    }
  }

  @IBOutlet var nextKeyboardButton: UIButton!

  var asSystemKeyboard: Bool = false
  public var webViewController: WebViewController!

  // This is the one used to initialize the keyboard as the app extension, marking "system keyboard" mode.
  convenience init() {
    // Retrieve kbd height from app group!
    let userDefaults = UserDefaults(suiteName: DummyInputViewController.appGroup)!
    let height = userDefaults.float(forKey: "height")

    self.init(height: CGFloat(height))
    asSystemKeyboard = true
  }

  init(height: CGFloat, inset: CGFloat = 0) {
    kbdHeight = height
    insetHeight = inset

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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

  open override func viewDidLoad() {
    let baseView = self.inputView as! CustomInputView

    // Perform custom UI setup here
    baseView.load()

    // Nope, no dice when trying it later.
//  open override func viewDidAppear(_ animated: Bool) {
//    let baseView = self.inputView as! CustomInputView
//
//    super.viewDidAppear(animated)
    baseView.setConstraints()

    // Adds a very basic "Next keyboard" button to ensure we can always swap keyboards, even on iPhone SE.
    self.nextKeyboardButton = UIButton(type: .system)

    self.nextKeyboardButton.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), for: [])
    self.nextKeyboardButton.sizeToFit()
    self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false

    self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)

    self.view.addSubview(self.nextKeyboardButton)

    var guide: UILayoutGuide
    guide = self.view.safeAreaLayoutGuide
    self.nextKeyboardButton.isHidden = !self.needsInputModeSwitchKey || !asSystemKeyboard

    self.nextKeyboardButton.leftAnchor.constraint(equalTo: guide.leftAnchor).isActive = true
    self.nextKeyboardButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
  }
  
  func forceWebViewReload() {
    webViewController!.loadKeyboard()
  }
}
