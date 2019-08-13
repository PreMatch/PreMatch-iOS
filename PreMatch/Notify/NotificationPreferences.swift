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
/// - `["r1", "e1", ...]`: NotificationOptions with identifiers `r` and `e` have semester 1 scheduled
public class NotificationPreferences {
    private static let defaults = UserDefaults()
    private static let notifyCenter = UNUserNotificationCenter.current()
    
    class func isOptionEnabled(identifier: Character) -> Bool {
        return notifyArray?.contains(where: idIs(identifier)) ?? false
    }
    
    class func isSemesterScheduled(identifier: Character, semester: UInt8) -> Bool {
        guard let option = notifyArray?.first(where: idIs(identifier)) else {
            return false
        }
        return option.contains(String(semester))
    }
    
    class func permissionGranted() -> Bool {
        return notifyArray != nil
    }
    
    class func didGrantPermission() {
        if notifyArray == nil {
            notifyArray = []
        }
    }
    
    class func didRevokePermission() {
        defaults.set(nil, forKey: "notify")
    }
    
    class func didEnableOption(identifier: Character, semester: UInt8) {
        if !isOptionEnabled(identifier: identifier) {
            if var array = notifyArray {
                array.append("\(identifier)\(semester)")
                notifyArray = array
            }
        } else {
            var array = notifyArray!
            var item = array.first(where: idIs(identifier))!
            array.removeAll(where: idIs(identifier))
            
            if !item.contains(String(semester)) {
                item += String(semester)
            }
            
            array.append(item)
            notifyArray = array
        }
    }
    
    class func didDisableOption(identifier: Character, semester: UInt8) {
        guard var array = notifyArray,
            var item = array.first(where: idIs(identifier)) else {return}
        array.removeAll(where: idIs(identifier))
        
        item = item.filter { $0 != String(semester).first! }
        
        if item.count > 1 {
            array.append(item)
        }
        notifyArray = array
    }
    
    class func didClearNotifications() {
        if permissionGranted() {
            notifyArray = []
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
    
    private class func idIs(_ id: Character) -> ((String) -> Bool) {
        return { $0.first! == id }
    }
    
    
    private static var notifyArray: [String]? {
        get {
            return defaults.stringArray(forKey: "notify")
        }
        set(new) {
            defaults.set(new, forKey: "notify")
        }
    }
    
}
