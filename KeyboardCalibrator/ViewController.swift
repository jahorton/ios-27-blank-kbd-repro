//
//  ViewController.swift
//  DefaultKeyboardHost
//
//  Created by Joshua Horton on 1/10/20.
//  Copyright © 2020 SIL International. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  @IBOutlet weak var systemInput: UITextField!
  @IBOutlet weak var inAppInput: UITextField!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let screen = UIScreen.main.bounds
    
    let assistant = systemInput.inputAssistantItem;
    assistant.leadingBarButtonGroups = [];
    assistant.trailingBarButtonGroups = [];
    
    inAppInput.inputView = DummyInputViewController().inputView
  }

  @IBAction func clearKeybooardPressed(_ sender: Any) {
    clearKeyboard()
  }
  
  func clearKeyboard() {
    self.view.endEditing(true)
  }
}

