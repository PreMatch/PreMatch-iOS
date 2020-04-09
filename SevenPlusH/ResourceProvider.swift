//
//  ResourceProvider.swift
//  SevenPlusH
//
//  Created by Michael Peng on 10/19/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation
import SwiftyJSON

public enum ProviderError: Error {
    case noCalendarAvailable
}

public struct ResourceProvider {
    private static var _schedule: SphSchedule?
    private static var _calendar: SphCalendar?
    private static let defaults = UserDefaults(suiteName: "group.com.prematch.data")!

    public static func schedule(_ calendar: SphCalendar? = calendar()) -> SphSchedule? {
        if let sched = _schedule {
            return sched
        }
        if let data = defaults.dictionary(forKey: "schedule"),
            let calendar = calendar {
            _schedule = try? SphSchedule(
                mapping: data.mapValues { $0 as! String },
                calendar: calendar)
            return _schedule
        }
        return nil
    }
    
    /// Gets the currently stored calendar instance.
    /// - Returns: The stored calendar instance, or `nil` if no calendar is present.
    public static func calendar() -> SphCalendar? {
        if let cal = _calendar {
            return cal
        }
        if let data = defaults.data(forKey: "calendar"),
            let calendar = try? DefinitionReader.read(JSON(data)) {
            _calendar = calendar
            return calendar
        }
        return nil
    }
    
    public static func store(calendar: JSON) throws {
        _calendar = try DefinitionReader.read(calendar)
        defaults.set(try calendar.rawData(), forKey: "calendar")
    }
    public static func store(schedule: SphSchedule) {
        _schedule = schedule
        defaults.set(schedule.mapping, forKey: "schedule")
    }
    public static func clearSchedule() {
        _schedule = nil
        defaults.removeObject(forKey: "schedule")
    }
}
