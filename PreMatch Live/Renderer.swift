//
//  Renderer.swift
//  PreMatch Live
//
//  Created by Michael Peng on 10/20/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation
import SevenPlusH

private var formatter = DateFormatter()
private func format(_ date: Date, long: Bool = false) -> String {
    formatter.dateFormat = (long ? "EEEE, " : "") + "MMM d, yyyy"
    return formatter.string(from: date)
}

private protocol Handler {
    func applicable(_ date: Date, in calendar: SphCalendar) -> Bool
    func apply(_ date: Date,
               in calendar: SphCalendar,
               for schedule: Schedule,
               to view: TodayViewController)
}

struct OutsideYearHandler: Handler {
    func applicable(_ date: Date, in calendar: SphCalendar) -> Bool {
        return !calendar.includes(date)
    }
    func apply(_ date: Date, in calendar: SphCalendar,
               for: Schedule, to view: TodayViewController) {
        view.showUnavailable("Not inside current school year")
    }
}

struct HolidayHandler: Handler {
    func applicable(_ date: Date, in calendar: SphCalendar) -> Bool {
        return calendar.includes(date) && !calendar.isSchoolDay(on: date)
    }
    func apply(_ date: Date, in calendar: SphCalendar,
               for: Schedule, to view: TodayViewController) {
        let schoolDay = calendar.nextSchoolDay(after: date)!
        let day = try! calendar.day(on: date)
        
        view.show(
            title: "Today is \(day.description)",
            info: "Showing next school day\n\(format(schoolDay.date, long: true))")
        view.showSchoolDay(schoolDay)
    }
}

struct BeforeSchoolHandler: Handler {
    func applicable(_ date: Date, in calendar: SphCalendar) -> Bool {
        if calendar.isSchoolDay(on: date) {
            let day = try! calendar.day(on: date) as! SchoolDay
            return Time.fromDate(date)!.isBefore(day)
        }
        return false
    }
    
    func apply(_ date: Date, in calendar: SphCalendar,
               for schedule: Schedule, to view: TodayViewController) {
        
        let day = try! calendar.day(on: date) as! SchoolDay
        let firstBlock = day.blocks.first
        let firstTeacher = schedule[firstBlock ?? ""] ?? "Someone unknown"
        
        view.show(
            title: "Today is \(day.description)",
            info: firstTeacher + " is next")
    }
}

struct AfterSchoolHandler: Handler {
    func applicable(_ date: Date, in calendar: SphCalendar) -> Bool {
        if calendar.isSchoolDay(on: date) {
            let day = try! calendar.day(on: date) as! SchoolDay
            return Time.fromDate(date)!.isAfter(day)
        }
        return false
    }
    
    func apply(_ date: Date, in calendar: SphCalendar,
               for schedule: Schedule, to view: TodayViewController) {
        
        let today = try! calendar.day(on: date) as! SchoolDay
        let day = calendar.nextSchoolDay(after: date)!
        
        view.show(
            title: "Today was \(today.description)",
            info: "Showing next school day\n\(format(day.date, long: true))")
        view.showSchoolDay(day)
    }
}

struct DuringSchoolHandler: Handler {
    func applicable(_ date: Date, in calendar: SphCalendar) -> Bool {
        if calendar.isSchoolDay(on: date) {
            let day = try! calendar.day(on: date) as! SchoolDay
            return Time.fromDate(date)!.isInside(day)
        }
        return false
    }
    
    func apply(_ date: Date, in calendar: SphCalendar, for schedule: Schedule, to view: TodayViewController) {
        let day = try! calendar.day(on: date) as! SchoolDay
        let now: Time = Time.fromDate(date)!
        
        let currentPeriodIndex = day.periodIndex(at: now)
        let currentBlock = day.block(at: now)
        let currentTeacher = currentBlock == nil ? nil :
            schedule[currentBlock!] ?? "Unknown"
        
        if currentPeriodIndex == UInt8(day.periods.count - 1) {
            // Last block
            view.show(title: "Now: \(currentTeacher!)",
                info: "Block \(currentBlock!)\nThis is the last block!")
            return
        }
        
        let nextIndex = day.nextPeriodIndex(at: now)!
        let nextBlock = day.blocks[Int(nextIndex)]
        let nextTeacher = schedule[nextBlock] ?? "Unknown"
        
        if currentPeriodIndex == nil {
            view.show(title: "Next: \(nextTeacher)",
                info: "Block \(nextBlock)\nGood morning.")
        } else {
            view.show(title: "Now: \(currentTeacher!)",
                info: "Block \(currentBlock!)\nNext: Block \(nextBlock) with \(nextTeacher)")
        }
    }
}

struct Renderer {
    private let handlers: [Handler] = [
        OutsideYearHandler(),
        HolidayHandler(),
        BeforeSchoolHandler(),
        AfterSchoolHandler()
    ]
    private let calendar: SphCalendar
    private var schedule: Schedule
    private let view: TodayViewController
    
    init(renderTo view: TodayViewController) throws {
        let provider = try ResourceProvider()
        calendar = try provider.readCalendar()
        schedule = try provider.readScheduleSync()
        self.view = view
    }
    
    public func render() -> Bool {
        let date = Date()
        guard let handler = handlers.first(where: { $0.applicable(Date(), in: self.calendar) }) else {
            return false
        }
        handler.apply(date, in: calendar, for: schedule, to: view)
        return true
    }
}
