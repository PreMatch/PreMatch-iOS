//
//  Day.swift
//  PreMatch
//
//  Created by Michael Peng on 10/11/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation

public typealias DayNumber = UInt8

public protocol Day {
    var date: Date { get }
    var description: String { get }
    var calendar: SphCalendar { get }
}

public protocol SchoolDay: Day, TimeSpan {
    var blocks: [String] { get }
    var periods: [Period] { get }
}

public extension SchoolDay {
    var start: Time {
        get {
            return periods.first?.start ?? Time(7, 44)
        }
    }
    var end: Time {
        get {
            return periods.last?.end ?? Time(14, 20)
        }
    }
    public func periodIndex(at time: Time) -> UInt8? {
        return periods.firstIndex { time.isInside($0) }.map { UInt8($0) }
    }
    public func period(at time: Time) -> Period? {
        return periods.first { time.isInside($0) }
    }
    public func nextPeriod(at time: Time) -> Period? {
        return periods.first { time.isBefore($0) }
    }
    public func nextPeriodIndex(at time: Time) -> UInt8? {
        return periods.firstIndex { time.isBefore($0) }.map { UInt8($0) }
    }
    public func block(at time: Time) -> String? {
        let index = periodIndex(at: time)
        return index == nil ? nil : blocks[Int(index!)]
    }
}

public struct StandardDay: SchoolDay {
    public let date: Date
    public var description: String {
        get {
            return "day \(self.number)"
        }
    }
    public let number: DayNumber
    public let calendar: SphCalendar
    
    public var blocks: [String] {
        get {
            return calendar.standardBlocks(of: self)
        }
    }
    public var periods: [Period] {
        get {
            return calendar.timetable.standardDayPeriods
        }
    }
    
}

public struct HalfDay: SchoolDay {
    public let date: Date
    public let description: String
    public let calendar: SphCalendar
    public let blocks: [String]
    public var periods: [Period] {
        get {
            return calendar.timetable.halfDayPeriods
        }
    }
    
    public init(date: Date, description: String = "a half-day", calendar: SphCalendar, blocks: [String]) {
        self.date = date
        self.description = description
        self.calendar = calendar
        self.blocks = blocks
    }
}

public struct ExamDay: SchoolDay {
    public let date: Date
    public let description: String
    public let calendar: SphCalendar
    public let blocks: [String]
    public var periods: [Period] {
        get {
            return calendar.timetable.examDayPeriods
        }
    }
    
    public init(date: Date, description: String = "an exam day", calendar: SphCalendar, blocks: [String]) {
        self.date = date
        self.description = description
        self.calendar = calendar
        self.blocks = blocks
    }
}

public struct UnknownDay: SchoolDay {
    public let date: Date
    public let description: String
    public let calendar: SphCalendar
    public let blocks: [String] = []
    public let periods: [Period] = []
}

public struct Holiday: Day {
    public let date: Date
    public let description: String
    public let calendar: SphCalendar
}

public struct Weekend: Day {
    public let date: Date
    public var description: String {
        get {
            let df = DateFormatter()
            df.dateFormat = "EEEE"
            return "a \(df.string(from: date))"
        }
    }
    public let calendar: SphCalendar
}
