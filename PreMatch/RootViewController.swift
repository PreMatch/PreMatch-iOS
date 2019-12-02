//
//  RootViewController.swift
//  PreMatch
//
//  Created by Michael Peng on 10/5/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import UIKit
import GoogleSignIn
import SevenPlusH

class RootViewController: UIViewController, UIPageViewControllerDelegate {
    
    //MARK: Properties
    @IBOutlet weak var passPersonalization: UIButton!
    
    var pageViewController: UIPageViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // Configure the page view controller and add it as a child view controller.
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UIPageViewController delegate methods
    
    @IBAction func didTapContinueWithoutPersonalize() {
        func showMainScreen() {
            MainViewController.refreshTabs()
            self.dismiss(animated: true, completion: nil)
        }
        
        if ResourceProvider.calendar() == nil {
            Downloader().storeCalendar(onSuccess: { _ in showMainScreen() },
                                       onFailure: { err in
                self.present(UIAlertController(title: "Oops!", message: err.localizedDescription, preferredStyle: .alert), animated: true, completion: nil)
            })
        } else {
            showMainScreen()
        }
    }
}

