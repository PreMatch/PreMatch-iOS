//
//  SphCalendar.swift
//  PreMatch
//
//  Created by Michael Peng on 10/10/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation

enum Result<T, E> {
    case ok(T)
    case error(E)
}

enum CalendarError: Error {
    case outOfRange
}

public let ahsTimezone = TimeZone(identifier: "America/New_York")!

public extension Date {
    
    func isWeekend() -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = ahsTimezone
        return calendar.isDateInWeekend(self)
    }
    func dayAfter() -> Date {
        return self + 24*60*60
    }
    func dayBefore() -> Date {
        return self - 24*60*60
    }
    func withoutTime(in timezone: TimeZone = ahsTimezone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone
        return calendar.startOfDay(for: self)
    }
}

class DayIterator {
    var mapping: [Date: DayNumber] = [:]
    var calendar: SphCalendar?
    
    init(start: Date) {
        mapping[start] = 1
    }
    
    func numberOfDate(_ date: Date, for calendar: SphCalendar) -> DayNumber? {
        if !calendar.isSchoolDay(on: date) {
            return nil
        }
        self.calendar = calendar
        
        let number = recursivelyIterate(from: date.withoutTime())
        mapping[date] = number
        return number
    }
    
    private func recursivelyIterate(from date: Date) -> DayNumber {
        if let number = mapping[date.withoutTime()] {
            return number
        } else if calendar!.dayType(on: date, includeOverrides: false) == StandardDay.self {
            return (recursivelyIterate(from: date.dayBefore().withoutTime()) % 8) + 1
        } else {
            return recursivelyIterate(from: date.dayBefore().withoutTime())
        }
    }
}

public class SphCalendar {
    let name: String
    let version: Double
    let allBlocks: [String]
    let cycleSize: DayNumber
    
    let interval: DateInterval
    let exclusions: [Exclusion]
    let overrides: [Exclusion]
    
    let iterator: DayIterator
    let timetable: SphTimetable
    
    init(name: String, version: Double, blocks: [String], cycleSize: DayNumber, interval: DateInterval,
         exclusions: [Exclusion], overrides: [Exclusion], standardPeriods: [Period], halfDayPeriods: [Period], examPeriods: [Period],
         dayBlocks: [[String]]) {
        self.name = name
        self.version = version
        self.allBlocks = blocks
        self.cycleSize = cycleSize
        self.interval = interval
        self.exclusions = exclusions
        self.overrides = overrides
        self.iterator = DayIterator(start: interval.start)
        self.timetable = SphTimetable(
            blocks: blocks,
            standardBlocks: dayBlocks,
            standardDayPeriods: standardPeriods,
            halfDayPeriods: halfDayPeriods,
            examDayPeriods: examPeriods)
    }
    
    public func includes(_ date: Date) -> Bool {
        return interval.contains(date)
    }
    
    public func day(on datetime: Date) throws -> Day {
        let date = datetime.withoutTime()
        
        if !includes(date) {
            throw CalendarError.outOfRange
        }
        if let ex = theExclusion(for: date) {
            return ex.day(on: date, in: self)!
        } else if date.isWeekend() {
            return Weekend(date: date, calendar: self)
        } else {
            let number = iterator.numberOfDate(date, for: self)
            return StandardDay(date: date, number: number!, calendar: self)
        }
    }
    
    public func standardBlocks(of day: StandardDay) -> [String] {
        return timetable.standardBlocks[Int(day.number - 1)]
    }
    
    public func dayType(on date: Date, includeOverrides: Bool = true) -> Day.Type? {
        if !interval.contains(date) {
            return nil
        }
        if let day = theExclusion(for: date, includeOverrides: includeOverrides)?.day(on: date, in: self)! {
            return type(of: day)
        } else if (date.isWeekend()) {
            return Weekend.self
        } else {
            return StandardDay.self
        }
    }
    
    public func isSchoolDay(on date: Date) -> Bool {
        return dayType(on: date) is SchoolDay.Type
    }
    
    private func theExclusion(for date: Date, includeOverrides: Bool = true) -> Exclusion? {
        return (includeOverrides ? (exclusions + overrides) : exclusions).first { $0.includes(date) }
    }
}
