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

class CalendarTests: XCTestCase {
  let calendar = SphCalendar(
    name: "The Testing Definition",
    version: 1.0,
    blocks: ["A", "B", "C", "D", "E", "F", "G"],
    cycleSize: 8,
    interval: DateInterval(start:dateFor(2018, 8, 29), end:dateFor(2019, 6, 14)),
    exclusions: [
      holidayExclusion(from: dateFor(2018, 8, 31), to: dateFor(2018, 9, 3), is: "Labor Day"),
      holidayExclusion(from: dateFor(2018, 9, 10), to: dateFor(2018, 9, 10), is: "Rosh Hashanah")
    ],
    overrides: [
    ])
  
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
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
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
    // TODO NEXT: Date timezone UTC vs EDT/EST
    let date: Date = dateFor(2018, 10, 13)
    XCTAssertTrue(Calendar.current.isDateInWeekend(date))
  }
  
  func testIterationSpeed() {
    self.measure {
      
      do {
        for _ in 1...100000 {
          try calendar.day(on: dateFor(2019, 3, 14))
        }
      } catch {
        XCTFail(error.localizedDescription)
      }
    }
  }
  
}
