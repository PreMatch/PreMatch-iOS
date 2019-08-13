//
//  NotificationViewController.swift
//  PreMatch
//
//  Created by Michael Peng on 5/7/19.
//  Copyright © 2019 PreMatch. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

protocol NotificationHubTransition {
    func transitionTo(identifier: Character)
}

class NotificationViewController: UIViewController, NotificationHubTransition {
    
    @IBOutlet var didNotAllowLabels: UIView!
    @IBOutlet weak var tableView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.childViewControllers[0] as? NOSelectionController)?.hubDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationPreferences.updatePermissionGranted()
        didUpdateNotifyPermission(allowed: NotificationPreferences.permissionGranted())
    }
    
    func transitionTo(identifier: Character) {
        switch identifier {
            
        case NODayBriefing.id:
            performSegue(withIdentifier: "showNODayBriefing", sender: nil)
            
        default: break
        }
    }
    
    func didUpdateNotifyPermission(allowed: Bool) {
        // didNotAllowLabels.isHidden = allowed
        tableView.isHidden = !allowed
    }
    
    @IBAction func didRequestRemoveAllPending() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            AppDelegate.showAlert(title: "Removed Notifications", message: "Removed \(requests.count) notifications.", actions: [], controller: self)
            NotificationPreferences.didClearNotifications()
            print(requests.map { $0.identifier })
        }
    }
}
