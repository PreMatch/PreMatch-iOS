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
public var ahsCalendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = ahsTimezone
    return cal
}()

public extension Date {
    func isWeekend() -> Bool {
        return ahsCalendar.isDateInWeekend(self)
    }
    func dayAfter() -> Date {
        return ahsCalendar.date(byAdding: .day, value: 1, to: self)!
    }
    func dayBefore() -> Date {
        return ahsCalendar.date(byAdding: .day, value: -1, to: self)!
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
        } else if shouldIncrement(on: date) {
            return (recursivelyIterate(from: date.dayBefore().withoutTime()) % 8) + 1
        } else {
            return recursivelyIterate(from: date.dayBefore().withoutTime())
        }
    }
    
    private func shouldIncrement(on date: Date) -> Bool {
        return calendar!.dayType(on: date, includeOverrides: false) == StandardDay.self &&
            calendar!.theExclusion(for: date, includeOverrides: false) == nil
    }
}

public class SphCalendar {
    public let name: String
    public let version: Double
    public let allBlocks: [String]
    let cycleSize: DayNumber
    
    public let interval: DateInterval
    let exclusions: [Exclusion]
    let overrides: [Exclusion]
    
    let iterator: DayIterator
    let timetable: SphTimetable
    
    let semesters: [DateInterval]
    
    init(name: String, version: Double, blocks: [String], cycleSize: DayNumber, interval: DateInterval,
         exclusions: [Exclusion], overrides: [Exclusion], standardPeriods: [Period], halfDayPeriods: [Period], examPeriods: [Period],
         dayBlocks: [[String]], semesters: [DateInterval]) {
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
        self.semesters = semesters
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
    
    public func nextSchoolDate(after date: Date) -> Date? {
        let tomorrow = date.dayAfter()
        
        if isSchoolDay(on: tomorrow) {
            return date.dayAfter()
        } else if !includes(date) {
            return nil
        } else {
            return nextSchoolDate(after: tomorrow)
        }
    }
    
    public func nextSchoolDay(after date: Date) -> SchoolDay? {
        if let nextDate = nextSchoolDate(after: date) {
            return try! day(on: nextDate) as! SchoolDay
        } else {
            return nil
        }
    }
    
    public func isSchoolDay(on date: Date) -> Bool {
        return dayType(on: date.withoutTime()) is SchoolDay.Type
    }
    
    public func semesterIndexOf(date: Date) -> UInt8? {
        for (index, item) in semesters.enumerated() {
            if item.contains(date) {
                return UInt8(index)
            }
        }
        return nil
    }
    
    public func allBlockSemesterCombinations() -> [String] {
        var output = [String]()
        
        for block in allBlocks {
            for semester in 1...(semesters.count) {
                output.append(block + String(semester))
            }
        }
        
        return output
    }
    
    func theExclusion(for date: Date, includeOverrides: Bool = true) -> Exclusion? {
        return (includeOverrides ? (exclusions + overrides) : exclusions).first { $0.includes(date) }
    }
}
