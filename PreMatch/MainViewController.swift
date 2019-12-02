//
//  MainViewController.swift
//  PreMatch
//
//  Created by Michael Peng on 10/23/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import UIKit
import SevenPlusH

class MainViewController: UITabBarController {
    private weak static var instance: MainViewController?
    public weak static var welcomeScreen: UIViewController?
    
    override func viewDidLoad() {
        MainViewController.instance = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let welcome = storyboard!.instantiateViewController(withIdentifier: "WelcomeScreen")
        MainViewController.welcomeScreen = welcome
        if ResourceProvider.calendar() == nil {
            present(welcome, animated: true, completion: nil)
        }
    }
    
    class func refreshTabs() {
        for controller in (instance?.viewControllers ?? []) {
            if let resourceUser = controller as? ResourceUser {
                controller.loadViewIfNeeded()
                resourceUser.resourcesDidUpdate()
            }
        }
        
    }
}
