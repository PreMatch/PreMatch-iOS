//
//  NotificationOption.swift
//  PreMatch
//
//  Created by Michael Peng on 8/10/19.
//  Copyright © 2019 PreMatch. All rights reserved.
//

import Foundation
import UserNotifications
import SevenPlusH

protocol NotificationOption {
    /// A unique character among all notification options that represents this option.
    ///
    /// Used to denote user preferences in UserDefaults. Must be a prefix of the identifiers of all notifications scheduled by the current option.
    static var id: Character { get }
    
    /// A human-readable name that summarizes this notification option.
    ///
    /// Shown to the user in the Notifications tab.
    static var name: String { get }
    
    // from and to are both inclusive
    func scheduleNotifications(from: Date, to: Date) throws -> [UNNotificationRequest]
    func notificationIdentifiers(from: Date, to: Date) -> [String]
}

public func schedulingRange(from date: Date, inCalendar cal: SphCalendar) throws -> (DateInterval, Int) {
    
    for (n, semester) in cal.semesters.enumerated() {
        if date < semester.start {
            return (semester, n)
        }
        if semester.contains(date) {
            return (DateInterval(start: date, end: semester.end), n)
        }
    }
    
    throw NotificationConfigError.dateOutOfRange("Cannot schedule notifications for a school year in the past")
}

enum NotificationConfigError: Error {
    case badSettings(String)
    case dateOutOfRange(String)
    case missingCalendar
    case notAllowedToNotify
}
