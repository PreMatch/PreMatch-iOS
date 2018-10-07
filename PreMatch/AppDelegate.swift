//
//  AppDelegate.swift
//  PreMatch
//
//  Created by Michael Peng on 10/5/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import UIKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

  var window: UIWindow?
  
  class func showAlert(title: String, message: String, actions: [UIAlertAction]) {
    let alert = UIAlertController(
      title: title,
      message: message,
      preferredStyle: .alert)
    
    if actions.isEmpty {
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    } else {
      for action in actions {
        alert.addAction(action)
      }
    }
    
    UIApplication.shared.delegate?.window??.rootViewController?.present(
      alert, animated: true, completion: nil)
  }
  
  func initializeLogin() {
    GIDSignIn.sharedInstance().clientID = "764760025104-70ao2s5vql3ldi54okdf9tbkd4chtama.apps.googleusercontent.com"
    GIDSignIn.sharedInstance().delegate = self
  }

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    
    initializeLogin()
    return true
  }

  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    return GIDSignIn.sharedInstance().handle(url as URL?,
        sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
        annotation: options[UIApplicationOpenURLOptionsKey.annotation])
  }
  
  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
    
    if let error = error {
      print("Oops! I couldn't sign you in with Google: " + error.localizedDescription)
    } else if let email = user.profile.email {
      let handle = email.split(separator: "@")[0]
      
      ScheduleReader().read(handle: String(handle), googleIdToken: user.authentication.idToken) { schedule in
        AppDelegate.showAlert(title: "Success", message: schedule.description, actions: [])
      }
    }
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

