//
//  ScheduleTests.swift
//  SevenPlusHTests
//
//  Created by Michael Peng on 10/22/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation
import XCTest
import SwiftyJSON
@testable import SevenPlusH

class ScheduleTests: XCTestCase {
    let json: JSON = [
        "status": "success",
        "A": "Aubrey",
        "B": "Bach",
        "C": "Caveney",
        "D": "Deschenes",
        "E": "Emory",
        "F": "Foley",
        "G": "Ganley"
    ]
    let dict = [
        "status": "success",
        "A": "Aubrey",
        "B": "Bach",
        "C": "Caveney",
        "D": "Deschenes",
        "E": "Emory",
        "F": "Foley",
        "G": "Ganley"
    ]
    let testSchedule = try! SphSchedule(
        mapping: [
            "A": "Abbott",
            "B": "Burns",
            "C": "Costagliola",
            "D": "Desfosse",
            "E": "Emery",
            "F": "Fazio",
            "G": "Germaine"
        ],
        calendar: testCalendar)
    
    func testParseFromJSON() {
        let schedule = try! SphSchedule.from(json: json, calendar: testCalendar)
        
        XCTAssertEqual(try! schedule.teacher(for: "A"), "Aubrey")
        XCTAssertEqual(try! schedule.teacher(for: "G"), "Ganley")
    }
    
    func testInitFromDict() {
        let schedule = try! SphSchedule(mapping: dict, calendar: testCalendar)
        
        XCTAssertEqual(try! schedule.teacher(for: "B"), "Bach")
        XCTAssertEqual(try! schedule.teacher(for: "D"), "Deschenes")
    }
    
    func testInitFromBadDict() {
        XCTAssertThrowsError(try SphSchedule(mapping: [
            "A": "Aubrey",
            "B": "Bach",
            "C": "Caveney",
            "D": "DiBenedetto",
            "F": "Fazio",
            "G": "Germaine"
        ], calendar: testCalendar))
    }
    
    func testParseFromBadJSON() {
        XCTAssertThrowsError(try SphSchedule.from(
            json: ["A", "B", "C", "D"],
            calendar: testCalendar))
        
        XCTAssertThrowsError(try SphSchedule.from(json: [
            "A": "Aubrey",
            "C": "Caveney",
            "D": "Deschenes",
            "E": "Emery"
            ], calendar: testCalendar))
    }
    
    func testTeacherFor() {
        XCTAssertEqual(try! testSchedule.teacher(for: "B", in: 1), "Burns")
        XCTAssertEqual(try! testSchedule.teacher(for: "G", in: 1), "Germaine")
    }
    
    func testTeacherForBadBlock() {
        XCTAssertThrowsError(try testSchedule.teacher(for: "I", in: 1))
        XCTAssertThrowsError(try testSchedule.teacher(for: "", in: 1))
    }
}
