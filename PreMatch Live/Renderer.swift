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
private var timeFormatter = DateFormatter()
private func formatTime(_ time: Date) -> String {
    timeFormatter.timeStyle = .short
    return timeFormatter.string(from: time)
}

private func relativeExpression(for target: Date, relativeTo now: Date) -> String? {
    if ahsCalendar.isDate(now.dayAfter(), inSameDayAs: target) {
        return "tomorrow"
    }
    let targetComps = ahsCalendar.dateComponents(in: ahsTimezone, from: target),
        nowComps = ahsCalendar.dateComponents(in: ahsTimezone, from: now)
    
    guard let targetWeek = targetComps.weekOfYear,
        let thisWeek = nowComps.weekOfYear else {
            return nil
    }
    
    if targetWeek == thisWeek + 1 {
        formatter.dateFormat = "EEEE"
        return "next " + formatter.string(from: target)
    }
    
    return nil
}

private protocol Handler {
    func applicable(_ date: Date, in calendar: SphCalendar) -> Bool
    func apply(_ date: Date,
               in calendar: SphCalendar,
               for schedule: SphSchedule?,
               to view: TodayViewController)
}

struct OutsideYearHandler: Handler {
    func applicable(_ date: Date, in calendar: SphCalendar) -> Bool {
        return !calendar.includes(date)
    }
    func apply(_ date: Date, in calendar: SphCalendar,
               for: SphSchedule?, to view: TodayViewController) {
        view.showUnavailable("Not in current school year")
    }
}

struct AfterReleaseHandler: Handler {
    func applicable(_ date: Date, in calendar: SphCalendar) -> Bool {
        return DateInterval(start: calendar.releaseDate, end: calendar.interval.start).contains(date)
    }
    
    func apply(_ _: Date, in calendar: SphCalendar,
               for schedule: SphSchedule?, to view: TodayViewController) {
        let date = calendar.interval.start
        let day = try! calendar.day(on: date) as! SchoolDay
        let firstBlock = day.blocks.first
        let semester = schedule?.calendar.semesterIndexOf(date: date)
        let firstTeacher = (firstBlock == nil || schedule == nil) ?
            "Someone unknown" : (try? schedule?.teacher(for: firstBlock!, in: semester!)) ?? "H-block"
        
        view.show(
            title: "First Teacher: \(firstTeacher ?? "Unknown")",
            info: "Block \(firstBlock ?? "?")\nEnjoy what remains of summer ☀️")
        view.showSchoolDay(day, isToday: false)
    }
}

struct HolidayHandler: Handler {
    func applicable(_ date: Date, in calendar: SphCalendar) -> Bool {
        return calendar.includes(date) && !calendar.isSchoolDay(on: date)
    }
    func apply(_ date: Date, in calendar: SphCalendar,
               for: SphSchedule?, to view: TodayViewController) {
        let schoolDay = calendar.nextSchoolDay(after: date)!
        let day = try! calendar.day(on: date)
        
        view.show(
            title: "Today is \(day.description)",
            info: "Showing next school day\n\(format(schoolDay.date, long: true))")
        view.showSchoolDay(schoolDay, isToday: false)
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
               for schedule: SphSchedule?, to view: TodayViewController) {
        
        let day = try! calendar.day(on: date) as! SchoolDay
        let firstBlock = day.blocks.first
        let semester = schedule?.calendar.semesterIndexOf(date: date)
        let firstTeacher = (firstBlock == nil || schedule == nil) ?
            "Someone unknown" : (try? schedule?.teacher(for: firstBlock!, in: semester!)) ?? "H-block"
        
        view.show(
            title: "Next: \(firstTeacher ?? "Unknown")",
            info: "Block \(firstBlock ?? "?")\nGood morning 🌅")
        view.showSchoolDay(day, isToday: true)
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
               for schedule: SphSchedule?, to view: TodayViewController) {
        
        let day = calendar.nextSchoolDay(after: date)!
        let expr = relativeExpression(for: day.date, relativeTo: date)
        let startingTime = day.periods.first?.start.asDateToday()
        
        view.show(
            title: "\((expr ?? "the next school day").capitalized) will be \(day.description)",
            info: "School starts at \(startingTime == nil ? "<unknown>" : formatTime(startingTime!))")
        view.showSchoolDay(day, isToday: false)
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
    
    func apply(_ date: Date, in calendar: SphCalendar,
               for schedule: SphSchedule?, to view: TodayViewController) {
        let day = try! calendar.day(on: date) as! SchoolDay
        let now: Time = Time.fromDate(date)!
        
        let currentPeriodIndex = day.periodIndex(at: now)
        let currentBlock = day.block(at: now)
        let currentPeriod = day.period(at: now)
        let currentSemester = calendar.semesterIndexOf(date: date)
        let currentTeacher = currentBlock == nil ? "Unknown" :
            (try? schedule?.teacher(for: currentBlock!, in: currentSemester!)) ?? "Unknown"
        
        view.showSchoolDay(day, isToday: true)
        if currentPeriodIndex == UInt8(day.periods.count - 1) {
            // Last block
            let endTime = formatTime(currentPeriod!.end.asDateToday())
            view.show(title: "Now: \(currentTeacher ?? "Unknown")",
                info: "Block \(currentBlock!) ends at \(endTime)\nThis is the last block!")
           return
        }
        
        let nextIndex = day.nextPeriodIndex(at: now)!
        let nextBlock = day.blocks[Int(nextIndex)]
        let nextTeacher = schedule == nil ? "Unknown" :
            (try? schedule?.teacher(for: nextBlock, in: currentSemester!)) ?? "Unknown"
        
        if currentPeriodIndex == nil {
            view.show(title: "Go to \(nextTeacher ?? "Unknown")",
                info: "Block \(nextBlock)")
        } else {
            let endTime = formatTime(currentPeriod!.end.asDateToday())
            view.show(title: "Now: \(currentTeacher ?? "Unknown")",
                info: "Block \(currentBlock!) ends at \(endTime)\nNext: Block \(nextBlock) with \(nextTeacher ?? "Unknown")")
        }
    }
}

struct Renderer {
    private let handlers: [Handler] = [
        AfterReleaseHandler(),
        OutsideYearHandler(),
        HolidayHandler(),
        BeforeSchoolHandler(),
        AfterSchoolHandler(),
        DuringSchoolHandler()
    ]
    private var calendar: SphCalendar
    private var schedule: SphSchedule?
    private let view: TodayViewController
    
    init(renderTo view: TodayViewController) throws {
        guard let calendar = ResourceProvider.calendar() else {
            throw ProviderError.noCalendarAvailable
        }
        self.calendar = calendar
        schedule = ResourceProvider.schedule()
        self.view = view
    }
    
    public func render() -> Bool {
        let date = Date()
        guard let handler = handlers.first(where: { $0.applicable(date, in: calendar) }) else {
            return false
        }
        handler.apply(date, in: calendar, for: schedule, to: view)
        return true
    }
}
