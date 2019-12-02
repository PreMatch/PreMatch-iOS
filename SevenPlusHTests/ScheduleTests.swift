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
        "A1": "Aubrey",
        "B1": "Bach",
        "C1": "Caveney",
        "D1": "Deschenes",
        "E1": "Emory",
        "F1": "Foley",
        "G1": "Ganley",
        "A2": "Aubrey",
        "B2": "Bach",
        "C2": "Caveney",
        "D2": "Deschenes",
        "E2": "Emory",
        "F2": "Fazio",
        "G2": "Ganley"
    ]
    lazy var testSchedule = try! SphSchedule.from(
        json: json,
        calendar: testCalendar)
    
    func testParseFromJSON() {
        XCTAssertEqual(try! testSchedule.teacher(for: "A", in: 0), "Aubrey")
        XCTAssertEqual(try! testSchedule.teacher(for: "F", in: 1), "Fazio")
    }
    
    func testInitFromBadDict() {
        XCTAssertThrowsError(try SphSchedule(mapping: [
            "A1": "Aubrey",
            "B1": "Bach",
            "C1": "Caveney",
            "D1": "Deschenes",
            "E1": "Emory",
            "G1": "Ganley",
            "A2": "Aubrey",
            "B2": "Bach",
            "C2": "Caveney",
            "D2": "Deschenes",
            "E2": "Emory",
            "F2": "Fazio",
            "G2": "Ganley"
        ], calendar: testCalendar))
    }
    
    func testParseFromBadJSON() {
        XCTAssertThrowsError(try SphSchedule.from(
            json: ["A", "B", "C", "D"],
            calendar: testCalendar))
        
        XCTAssertThrowsError(try SphSchedule.from(json: [
            "A1": "Aubrey",
            "C1": "Caveney",
            "D1": "Deschenes",
            "E1": "Emery"
            ], calendar: testCalendar))
    }
    
    func testTeacherFor() {
        XCTAssertEqual(try! testSchedule.teacher(for: "B", in: 0), "Bach")
        XCTAssertEqual(try! testSchedule.teacher(for: "G", in: 1), "Ganley")
    }
    
    func testTeacherForBadBlock() {
        XCTAssertThrowsError(try testSchedule.teacher(for: "I", in: 1))
        XCTAssertThrowsError(try testSchedule.teacher(for: "", in: 1))
    }
}
