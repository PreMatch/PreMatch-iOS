//
//  PushNotificationDelegate.swift
//  PreMatch
//
//  Created by Michael Peng on 12/1/19.
//  Copyright © 2019 PreMatch. All rights reserved.
//

import Foundation
import UserNotifications
import Firebase
import Sentry

class PushNotificationDelegate : NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    private static var instance: PushNotificationDelegate?
    
    class func current() -> PushNotificationDelegate? {
        return instance
    }
    
    override init() {
        super.init()
        PushNotificationDelegate.instance = self
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("didReceiveRegistrationToken: " + fcmToken)
        Messaging.messaging().subscribe(toTopic: "calendarUpdates") { error in
            if let error = error {
                let event = Event(level: .error)
                event.message = "Failed to subscribe to calendarUpdates Firebase pub/sub"
                event.exceptions = [Exception(value: error.localizedDescription, type: "Firebase error")]
                Client.shared?.send(event: event) { _ in }
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("received userNotificationCenter:willPresent: message")
        completionHandler(.alert)
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(userInfo.debugDescription)
        completionHandler(.noData)
    }
}
