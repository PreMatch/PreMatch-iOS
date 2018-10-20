//
//  TimetableTests.swift
//  SevenPlusHTests
//
//  Created by Michael Peng on 10/18/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import XCTest
import Foundation
import SwiftyJSON
@testable import SevenPlusH


class TimeTests: XCTestCase {
    private func todayAtTime(_ hour: Int, _ min: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar.date(from: DateComponents(hour: hour, minute: min))!
    }
    
    func testDateConversion() {
        let time = Time(13, 0)
        let date = time.asDateToday()
        
        XCTAssertEqual(date, todayAtTime(13, 0))
    }
    
    func testValidation() {
        XCTAssertEqual(Time(24, 0), Time(0, 0))
        XCTAssertEqual(Time(10, 60), Time(10, 0))
    }
    
    func testComparison() {
        let time = Time(10, 10)
        let otherTime = Time(14, 0)
        
        XCTAssertLessThan(time, otherTime)
        XCTAssertGreaterThan(otherTime, time)
        XCTAssertEqual(time, Time(10, 10))
    }
    
    func testArithmetic() {
        let time = Time(14, 15)
        let otherTime = Time(12, 52)
        
        XCTAssertEqual(otherTime - time, -83)
        XCTAssertEqual(time - otherTime, 83)
    }
    
    func testInitFromJSON() throws {
        let json: JSON = [10, 24]
        let time = try Time.fromJSON(json)
        
        XCTAssertEqual(time, Time(10, 24))
    }
    
    func testInitFromBadJSON() throws {
        let json: JSON = ["bad json", 20]
        XCTAssertThrowsError(try Time.fromJSON(json))
    }
    
    func testInitFromDate() {
        let time = Time.fromDate(ahsCalendar.date(from:
            DateComponents(hour: 23, minute: 20))!)
        XCTAssertEqual(time, Time(23, 20))
    }
}

class PeriodTests: XCTestCase {
    func testValidation() {
        XCTAssertEqual(Period(from: Time(12, 20), to: Time(12, 0)), Period(from: Time(12, 0), to: Time(12, 20)))
    }
    
    func testLength() {
        XCTAssertEqual(Period(from: Time(12, 20), to: Time(12, 50)).length, 30)
        XCTAssertEqual(Period(from: Time(1, 14), to: Time(5, 42)).length, 268)
    }
    
    func testInclusion() {
        let period = Period(from: Time(10, 20), to: Time(11, 20))
        
        XCTAssertTrue(Time(10, 45).isInside(period))
        XCTAssertTrue(Time(10, 20).isInside(period))
        XCTAssertTrue(Time(11, 20).isInside(period))
        XCTAssertFalse(Time(10, 19).isInside(period))
    }
    
    func testInitFromJSON() throws {
        let json: JSON = [[10, 40], [2, 14]]
        let period = try Period.fromJSON(json)
        
        XCTAssertEqual(period.start, Time(2, 14))
        XCTAssertEqual(period.end, Time(10, 40))
    }
}

class TimetableTests: XCTestCase {
    // Code being tested is defined within the SchoolDay subtypes.
    
    let standardTestDay = StandardDay(date: try! parseISODate("2018-10-18"), number: 8, calendar: testCalendar)
    let halfTestDay = HalfDay(date: try! parseISODate("2018-10-19"), calendar: testCalendar, blocks: ["A", "C", "E", "G"])
    let examTestDay = ExamDay(date: try! parseISODate("2019-01-18"), calendar: testCalendar, blocks: ["A", "E"])
    
    func testStandardDayBlocks() throws {
        XCTAssertEqual(standardTestDay.blocks, ["C", "B", "H", "F", "D"])
    }
    
    func testStandardDayPeriods() {
        XCTAssertEqual(standardTestDay.periods, testCalendar.timetable.standardDayPeriods)
    }
    
    func testHalfDayPeriods() {
        XCTAssertEqual(halfTestDay.periods, testCalendar.timetable.halfDayPeriods)
    }
    
    func testExamDayPeriods() {
        XCTAssertEqual(examTestDay.periods, testCalendar.timetable.examDayPeriods)
    }
    
    func testPeriodsAsTimespan() {
        XCTAssertTrue(Time(7, 43).isBefore(standardTestDay))
        XCTAssertFalse(Time(7, 44).isBefore(standardTestDay))
        XCTAssertTrue(Time(14, 5).isInside(standardTestDay))
        XCTAssertTrue(Time(16, 0).isAfter(standardTestDay))
    }
    
    func testPeriodIndexInDay() {
        XCTAssertEqual(standardTestDay.periodIndex(at: Time(8, 0)), 0)
        XCTAssertEqual(standardTestDay.periodIndex(at: Time(12, 20)), 3)
        XCTAssertEqual(halfTestDay.periodIndex(at: Time(9, 4)), 1)
        XCTAssertEqual(halfTestDay.periodIndex(at: Time(12, 0)), nil)
    }
    
    func testPeriodInDay() {
        XCTAssertEqual(standardTestDay.period(at: Time(9, 20)), Period(from: Time(8, 48), to: Time(10, 3)))
        XCTAssertEqual(standardTestDay.period(at: Time(6, 0)), nil)
    }
    
    func testNextPeriodInDay() {
        XCTAssertEqual(standardTestDay.nextPeriod(at: Time(8, 45)), Period(from: Time(8, 48), to: Time(10, 3)))
        XCTAssertEqual(halfTestDay.nextPeriod(at: Time(6, 45)), Period(from: Time(7, 44), to: Time(8, 29)))
        XCTAssertEqual(examTestDay.nextPeriod(at: Time(13, 59)), nil)
    }
    
    func testNextPeriodIndexInDay() {
        XCTAssertEqual(standardTestDay.nextPeriodIndex(at: Time(12, 45)), 4)
        XCTAssertEqual(halfTestDay.nextPeriodIndex(at: Time(8, 45)), 2)
        XCTAssertEqual(examTestDay.nextPeriodIndex(at: Time(13, 59)), nil)
    }
    
    func testBlockAtTimeInDay() {
        XCTAssertEqual(standardTestDay.block(at: Time(10, 42)), "H")
        XCTAssertEqual(halfTestDay.block(at: Time(8, 45)), "C")
        XCTAssertEqual(halfTestDay.block(at: Time(6, 13)), nil)
    }
}
