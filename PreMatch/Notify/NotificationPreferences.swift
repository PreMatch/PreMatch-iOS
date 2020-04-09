//
//  NotificationPreferences.swift
//  PreMatch
//
//  Created by Michael Peng on 8/11/19.
//  Copyright © 2019 PreMatch. All rights reserved.
//

import Foundation
import UserNotifications

/// Provides an abstraction for the retrieval and storage of notification preferences, including whether the user has allowed this app to notify them, the NotificationOptions that are enabled, and their respective scheduled semesters.
///
/// The `notify` field in `UserDefaults` can take on one of the following states:
/// - `nil`: Haven't asked for permission or permission denied
/// - `[]`: Permission granted, but no NotificationOptions enabled
/// - `['e', 'r']`: Permission granted, options `e` and `r` are enabled
public class NotificationPreferences {
    private static let defaults = UserDefaults()
    private static let notifyCenter = UNUserNotificationCenter.current()
    
    class func isOptionEnabled(identifier: Character) -> Bool {
        return notifyArray?.contains(identifier) ?? false
    }
    
    class func permissionGranted() -> Bool {
        return notifyArray != nil
    }
    
    class func didGrantPermission() {
        if notifyArray == nil {
            notifyArray = ""
        }
    }
    
    class func didRevokePermission() {
        defaults.set(nil, forKey: "notify")
    }
    
    class func didEnableOption(identifier: Character) {
        if !isOptionEnabled(identifier: identifier) {
            if var array = notifyArray {
                array.append(identifier)
                notifyArray = array
            }
        }
    }
    
    class func didDisableOption(identifier: Character) {
        notifyArray = notifyArray?.filter { $0 != identifier }
    }
    
    class func didClearNotifications() {
        if permissionGranted() {
            notifyArray = ""
        }
    }
    
    class func updatePermissionGranted() {
        notifyCenter.getNotificationSettings { (settings) in
            let granted = settings.authorizationStatus == .authorized
            if granted {
                didGrantPermission()
            } else {
                didRevokePermission()
            }
        }
    }
    
    private static var notifyArray: String? {
        get {
            return defaults.string(forKey: "notify")
        }
        set(new) {
            defaults.set(new, forKey: "notify")
        }
    }
    
}
