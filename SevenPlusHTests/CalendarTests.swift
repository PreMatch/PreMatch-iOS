//
//  PreMatchTests.swift
//  PreMatchTests
//
//  Created by Michael Peng on 10/5/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import XCTest
@testable import SevenPlusH

fileprivate func dateFromISO(iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = TimeZone(identifier: "America/New_York")
    formatter.formatOptions = .withFullDate
    
    return formatter.date(from: iso)!
}

fileprivate func dateFor(_ year: Int, _ month: Int, _ day: Int) -> Date {
    return Calendar.current.date(from: DateComponents(year:year, month:month, day:day))!
}

fileprivate func intervalFromISO(_ from: String, _ to: String) -> DateInterval {
    return DateInterval(start: dateFromISO(iso: from), end: dateFromISO(iso: to))
}

fileprivate func holidayExclusion(from: Date, to: Date, is description: String) -> Exclusion {
    return Exclusion(
        interval: DateInterval(start: from, end: to),
        dayGenerator: {
            // Swift, please
            date, calendar in Holiday(date: date, description: description, calendar: calendar)
    })
}

let testCalendar = SphCalendar(
    name: "The Testing Definition",
    version: 1.0,
    blocks: ["A", "B", "C", "D", "E", "F", "G"],
    cycleSize: 8,
    interval: DateInterval(start:dateFor(2018, 8, 29), end:dateFor(2019, 6, 14)),
    exclusions: [
        holidayExclusion(from: dateFor(2018, 8, 31), to: dateFor(2018, 9, 3), is: "Labor Day"),
        holidayExclusion(from: dateFor(2018, 9, 10), to: dateFor(2018, 9, 10), is: "Rosh Hashanah")
    ],
    overrides: [],
    standardPeriods: [
        Period(from: Time(7, 44), to: Time(8, 44)),
        Period(from: Time(8, 48), to: Time(10, 3)),
        Period(from: Time(10, 7), to: Time(11, 7)),
        Period(from: Time(11, 11), to: Time(13, 1)),
        Period(from: Time(13, 5), to: Time(14, 5))
    ],
    halfDayPeriods: [
        Period(from: Time(7, 44), to: Time(8, 29)),
        Period(from: Time(8, 33), to: Time(9, 16)),
        Period(from: Time(9, 20), to: Time(10, 3)),
        Period(from: Time(10, 7), to: Time(10, 50))
    ],
    examPeriods: [
        Period(from: Time(8, 0), to: Time(9, 30)),
        Period(from: Time(10, 0), to: Time(11, 30)),
        Period(from: Time(13, 0), to: Time(14, 0))
    ],
    dayBlocks: [
        ["A", "C", "H", "E", "G"],
        ["B", "D", "F", "G", "E"],
        ["A", "H", "D", "C", "F"],
        ["B", "A", "H", "G", "E"],
        ["C", "B", "F", "D", "G"],
        ["A", "H", "E", "F", "C"],
        ["B", "A", "D", "E", "G"],
        ["C", "B", "H", "F", "D"]
    ],
    semesters: [
        DateInterval(start: dateFor(2018, 8, 29), end: dateFor(2019, 1, 22)),
        DateInterval(start: dateFor(2019, 1, 23), end: dateFor(2019, 6, 14))],
    releaseDate: dateFor(2018, 8, 22)
)

class CalendarTests: XCTestCase {
    let calendar = testCalendar
    
    func calendarDayOnDate<T: Day>(_ date: Date) -> T {
        do {
            return try calendar.day(on: date) as! T
        } catch {
            XCTFail("Expected calendar day on \(date), received \(error)")
            exit(1)
        }
    }
    
    func assertStandardDay(on year: Int, _ month: Int, _ day: Int, hasNumber number: DayNumber) {
        let date = dateFor(year, month, day)
        let day: StandardDay = calendarDayOnDate(date)
        
        XCTAssertEqual(day.date, date)
        XCTAssertEqual(day.number, number)
        XCTAssertTrue(day.calendar === calendar)
    }
    
    func assertHoliday(on year: Int, _ month: Int, _ day: Int, is description: String) {
        let date = dateFor(year, month, day)
        let day: Holiday = calendarDayOnDate(date)
        
        XCTAssertEqual(day.date, date)
        XCTAssertEqual(day.description, description)
    }
    
    func testFirstCycleDays() {
        assertStandardDay(on: 2018, 8, 29, hasNumber: 1)
        assertStandardDay(on: 2018, 8, 30, hasNumber: 2)
        assertStandardDay(on: 2018, 9, 6, hasNumber: 5)
    }
    
    func testNextCycleDays() {
        assertStandardDay(on: 2018, 9, 18, hasNumber: 4)
        assertStandardDay(on: 2018, 9, 13, hasNumber: 1)
    }
    
    func testHolidays() {
        assertHoliday(on: 2018, 9, 1, is: "Labor Day")
        assertHoliday(on: 2018, 9, 10, is: "Rosh Hashanah")
    }
    
    func testIsWeekend() {
        let date: Date = dateFor(2018, 10, 13)
        XCTAssertTrue(Calendar.current.isDateInWeekend(date))
    }
    
    func testNextSchoolDay() {
        XCTAssertEqual(calendar.nextSchoolDate(after: dateFor(2018, 8, 29)), dateFor(2018, 8, 30))
        XCTAssertEqual(calendar.nextSchoolDate(after: dateFor(2018, 9, 1)), dateFor(2018, 9, 4))
        let day = calendar.nextSchoolDay(after: dateFor(2018, 8, 29))! as! StandardDay
    
        XCTAssertEqual(day.date, dateFor(2018, 8, 30))
        XCTAssertEqual(day.number, 2)
    }
}
