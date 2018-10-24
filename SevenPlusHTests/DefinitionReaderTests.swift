//
//  DefinitionReaderTests.swift
//  SevenPlusHTests
//
//  Created by Michael Peng on 10/16/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import XCTest
import Foundation
import SwiftyJSON
@testable import SevenPlusH

private func assertDate(_ date: Date, is year: Int, _ month: Int, _ day: Int) {
  let components = Calendar(identifier: .gregorian).dateComponents(
    in: TimeZone(identifier: "America/New_York")!,
    from: date)
  
  XCTAssertEqual(components.year, year)
  XCTAssertEqual(components.month, month)
  XCTAssertEqual(components.day, day)
}
private func assertExclusion(_ exclusion: Exclusion,
                             hasType theType: Day.Type,
                             isDescribedAs description: String?,
                             hasBlocks blocks: [String]?,
                             startsOn startYear: Int, _ startMonth: Int, _ startDay: Int,
                             endsOn endYear: Int, _ endMonth: Int, _ endDay: Int) {
  let excludedDay = exclusion.day(on: exclusion.interval.start, in: testCalendar)!
  XCTAssert(type(of: excludedDay) == theType)
    
    if let desc = description {
        XCTAssertEqual(
            excludedDay.description,
            desc)
    }
    if let blocks = blocks {
        XCTAssertEqual(
            (excludedDay as! SchoolDay).blocks,
            blocks)
    }
  
  assertDate(exclusion.interval.start, is: startYear, startMonth, startDay)
  assertDate(exclusion.interval.end, is: endYear, endMonth, endDay)
}

private func assertParseISODate(_ iso: String,
                                is year: Int, _ month: Int, _ day: Int) {
    assertDate(try! parseISODate(iso),
               is: year, month, day)
}

class DefinitionReaderTests: XCTestCase {
    private let definition: JSON = [
        "cycle_size": 8,
        "start_date": "2018-08-29",
        "end_date": "2019-06-14"
    ]
    
  func testParseISODate() {
        assertParseISODate("2018-08-30",
                           is: 2018, 8, 30)
        assertParseISODate("2019-01-02",
                           is: 2019, 1, 2)
        assertParseISODate("2018-04-30",
                           is: 2018, 4, 30)
  }
  
  func testReadHolidayExclusion() throws {
    let json: JSON = [
      "type": "holiday",
      "start_date": "2018-11-22",
      "end_date": "2018-11-23",
      "description": "Thanksgiving Break"
    ]
    let parsed: Exclusion = try DefinitionReader.parseExclusion(json, inDef: definition)
    
    assertExclusion(parsed,
                    hasType: Holiday.self,
                    isDescribedAs: "Thanksgiving Break",
                    hasBlocks: nil,
                    startsOn: 2018, 11, 22,
                    endsOn: 2018, 11, 23)
  }
    
    func testReadHalfDayExclusion() throws {
        let json: JSON = [
            "type": "half_day",
            "date": "2018-12-12",
            "blocks": ["A", "C", "E", "F"]
        ]
        let parsed = try DefinitionReader.parseExclusion(json, inDef: definition)
        
        assertExclusion(parsed,
                        hasType: HalfDay.self,
                        isDescribedAs: nil,
                        hasBlocks: ["A", "C", "E", "F"],
                        startsOn: 2018, 12, 12,
                        endsOn: 2018, 12, 12)
    }
    
    func testReadExamDayExclusion() throws {
        let json: JSON = [
            "type": "exam_day",
            "date": "2019-01-22",
            "blocks": ["B", "F"]
        ]
        let parsed = try DefinitionReader.parseExclusion(json, inDef: definition)
        
        assertExclusion(parsed,
                        hasType: ExamDay.self,
                        isDescribedAs: nil,
                        hasBlocks: ["B", "F"],
                        startsOn: 2019, 1, 22,
                        endsOn: 2019, 1, 22)
    }
    
    func testReadUnknownDayExclusion() throws {
        let json: JSON = [
            "type": "unknown",
            "date": "2019-01-16",
            "description": "Day Y"
        ]
        let parsed = try DefinitionReader.parseExclusion(json, inDef: definition)
        
        assertExclusion(parsed,
                        hasType: UnknownDay.self,
                        isDescribedAs: "Day Y",
                        hasBlocks: nil,
                        startsOn: 2019, 1, 16,
                        endsOn: 2019, 1, 16)
    }
    
    func testReadStandardDayExclusion() throws {
        let json: JSON = [
            "type": "standard_day",
            "date": "2019-04-12",
            "day_number": 5
        ]
        let parsed = try DefinitionReader.parseExclusion(json, inDef: definition)
        
        assertExclusion(parsed,
                        hasType: StandardDay.self,
                        isDescribedAs: nil,
                        hasBlocks: nil,
                        startsOn: 2019, 4, 12,
                        endsOn: 2019, 4, 12)
    }
    
    func testDateValidation() {
        let json: JSON = [
            "type": "holiday",
            "start_date": "2018-05-03",
            "end_date": "2018-05-04",
            "description": "Holiday from last year"
        ]
        XCTAssertThrowsError(try DefinitionReader.parseExclusion(json, inDef: definition))
    }
    
    func testDayValidation() {
        let json: JSON = [
            "type": "standard_day",
            "date": "2019-04-12",
            "day_number": 0
        ]
        XCTAssertThrowsError(try DefinitionReader.parseExclusion(json, inDef: definition))
    }
    
    func assertStandardDay(on dateISO: String, is number: DayNumber, in calendar: SphCalendar) {
        let date: Date = try! parseISODate(dateISO)
        let day = try! calendar.day(on: date) as! StandardDay
        XCTAssertEqual(day.number, number)
        XCTAssertEqual(day.date, date.withoutTime())
    }
    
//    func testReadOnline() throws {
//        let calendar = try Downloader().
//        assertStandardDay(on: "2018-10-18", is: 8, in: calendar)
//        assertStandardDay(on: "2019-01-25", is: 1, in: calendar)
//        assertStandardDay(on: "2019-05-06", is: 3, in: calendar)
//        assertStandardDay(on: "2018-11-05", is: 3, in: calendar)
//        
//        let gasDay = try calendar.day(on: parseISODate("2018-09-14")) as! Holiday
//        XCTAssertEqual(gasDay.description, "Day after Gas Explosion Apocalypse")
//        
//        assertStandardDay(on: "2018-09-17", is: 2, in: calendar)
//        XCTAssertEqual(
//            calendar.nextSchoolDate(after: try parseISODate("2018-11-20")),
//            try parseISODate("2018-11-21"))
//        XCTAssertEqual(
//            calendar.nextSchoolDate(after: try parseISODate("2019-04-12")),
//            try parseISODate("2019-04-22"))
//    }
}
