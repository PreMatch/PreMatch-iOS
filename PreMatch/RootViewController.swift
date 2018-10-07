//
//  RootViewController.swift
//  PreMatch
//
//  Created by Michael Peng on 10/5/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import UIKit
import GoogleSignIn

class RootViewController: UIViewController, UIPageViewControllerDelegate, GIDSignInUIDelegate {

  var pageViewController: UIPageViewController?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    // Configure the page view controller and add it as a child view controller.
    
    GIDSignIn.sharedInstance().uiDelegate = self
    GIDSignIn.sharedInstance().signInSilently()
    
    // TODO(developer) Configure the sign-in button look/feel
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBAction func didTapSignOut(_ sender: AnyObject) {
    GIDSignIn.sharedInstance().signOut()
  }

  // MARK: - UIPageViewController delegate methods


}

