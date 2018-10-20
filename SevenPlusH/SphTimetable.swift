//
//  SphTimetable.swift
//  SevenPlusH
//
//  Created by Michael Peng on 10/18/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation

public enum TimeError: Error {
    case outOfRange(badHour: UInt8, badMinute: UInt8)
}

public struct Time: Comparable, Equatable {
    public let hour: UInt8
    public let minute: UInt8
    public static var now: Time {
        get {
            return Time.fromDate(Date())!
        }
    }
    
    init(_ hour: UInt8, _ minute: UInt8) {
        self.hour = hour % 24;
        self.minute = minute % 60;
    }
    // Always returns time in ET
    public static func fromDate(_ date: Date) -> Time? {
        let components = ahsCalendar.dateComponents(in: ahsTimezone, from: date)
        
        if components.hour == nil || components.minute == nil {
            return nil
        }
        return Time(UInt8(components.hour!), UInt8(components.minute!))
    }
    
    public func asDateToday(timezone: TimeZone = ahsTimezone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timezone
        return cal.date(from: DateComponents(hour: Int(hour), minute: Int(minute)))!
    }
    
    public static func < (lhs: Time, rhs: Time) -> Bool {
        return lhs.minutesIntoDay() < rhs.minutesIntoDay()
    }
    
    public static func == (lhs: Time, rhs: Time) -> Bool {
        return lhs.minutesIntoDay() == rhs.minutesIntoDay()
    }
    
    public static func - (lhs: Time, rhs: Time) -> Int16 {
        return Int16(lhs.minutesIntoDay()) - Int16(rhs.minutesIntoDay())
    }
    
    public func isInside(_ period: TimeSpan) -> Bool {
        return period.includes(self)
    }
    
    public func isBefore(_ span: TimeSpan) -> Bool {
        return self < span.start
    }
    
    public func isAfter(_ span: TimeSpan) -> Bool {
        return self > span.end
    }
    
    private func minutesIntoDay() -> UInt16 {
        return UInt16(hour) * 60 + UInt16(minute)
    }
}

public protocol TimeSpan {
    var start: Time { get }
    var end: Time { get }
}

public extension TimeSpan {
    public func includes(_ time: Time) -> Bool {
        return time >= start && time <= end
    }
}

public struct Period: Equatable, TimeSpan {
    public let start: Time
    public let end: Time
    
    public var length: UInt16 {
        get {
            return UInt16(end - start)
        }
    }
    
    init(from: Time, to: Time) {
        start = min(from, to)
        end = max(from, to)
    }
}

public struct SphTimetable {
    let blocks: [String]
    let standardBlocks: [[String]]
    let standardDayPeriods: [Period]
    let halfDayPeriods: [Period]
    let examDayPeriods: [Period]
}
