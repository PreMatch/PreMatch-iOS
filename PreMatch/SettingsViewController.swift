//
//  SettingsViewController.swift
//  PreMatch
//
//  Created by Michael Peng on 10/29/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import UIKit
import SevenPlusH
import GoogleSignIn

extension UIButton {
    func reenableAfter(minutes: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(minutes*60)) {
            self.isEnabled = true
        }
    }
}

class SettingsViewController: UIViewController, GIDSignInUIDelegate, ResourceUser {

    private let dangerButtonColor = UIColor(red: 255, green: 59, blue: 48, alpha: 1)
    private let normalButtonColor = UIColor(red: 0, green: 122, blue: 255, alpha: 1)
    
    //MARK: Properties
    @IBOutlet weak var updateCalendar: UIButton!
    @IBOutlet weak var refreshSchedule: UIButton!
    @IBOutlet weak var toggleAccountLink: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewDidAppear(true)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isScheduleLinked() {
            refreshSchedule.isEnabled = true
            configure(
                button: toggleAccountLink,
                title: "Unlink Account",
                addAction: #selector(unlinkAccount))
        } else {
            refreshSchedule.isEnabled = false
            configure(
                button: toggleAccountLink,
                title: "Link Account",
                addAction: #selector(linkAccount))
        }
    }
    
    func resourcesDidUpdate() {
        viewDidAppear(false)
    }
    
    func configure(button: UIButton,
                   title: String,
                   addAction: Selector) {
        
        button.setTitle(title, for: .normal)
        //button.setTitleColor(titleColor, for: .normal)
        
        button.removeTarget(nil, action: nil, for: .allEvents)
        button.addTarget(self, action: addAction, for: .touchDown)
    }
    
    @IBAction func unlinkAccount() {
        AppDelegate.showAlert(title: "Warning!", message: "This will remove your schedule from this device, but not from PreMatch.org. Do you wish to continue?", actions: [
            UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            }),
            UIAlertAction(title: "Unlink", style: .destructive, handler: { _ in
                ResourceProvider.clearSchedule()
                GIDSignIn.sharedInstance()?.signOut()
                MainViewController.refreshTabs()
            })
        ])
    }
    
    @IBAction func linkAccount() {
        if let welcome = AppDelegate.welcomeScreen() {
            present(welcome, animated: true, completion: {})
        }
    }
    
    @IBAction func didTapRefreshSchedule() {
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func didTapUpdateCalendar() {
        updateCalendar.isEnabled = false
        updateCalendar.reenableAfter(minutes: 5)
        
        let downloader = Downloader()
        downloader.readCalendarJSON(onSuccess: {
            do {
                let calendar = try DefinitionReader.read($0)
                let applies = ResourceProvider.schedule()?.applies(to: calendar)
                if !(applies ?? true) {
                    self.newCalendarNotApplicable()
                    return
                }
                try ResourceProvider.store(calendar: $0)
                AppDelegate.showAlert(title: "Success",
                                      message: "Downloaded \(calendar.name), version \(calendar.version)",
                    actions: [])
            } catch {
                self.downloadDidFail(nil, error)
            }
        }, onFailure: downloadDidFail)
    }
    
    private func downloadDidFail(_ response: HTTPURLResponse?, _ err: Error) {
        AppDelegate.showAlert(title: "Oops!",
                              message: response?.description ?? "" + err.localizedDescription,
                              actions: [],
                              controller: self)
    }
    private func newCalendarNotApplicable() {
        AppDelegate.showAlert(
            title: "Oops!",
            message: "The new calendar is not compatible with your locally stored schedule.",
            actions: [], controller: self)
    }
    
    private func isScheduleLinked() -> Bool {
        return ResourceProvider.schedule() != nil
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
