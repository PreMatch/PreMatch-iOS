//
//  NotificationOptionTest.swift
//  PreMatchTests
//
//  Created by Michael Peng on 8/11/19.
//  Copyright © 2019 PreMatch. All rights reserved.
//

import Foundation
import XCTest
@testable import PreMatch

class NotificationOptionTest: XCTestCase {
    func testSchedulingRangeBeforeFirstSemester() throws {
        let (interval, sem) = try schedulingRange(from: date(2019, 8, 20), inCalendar: calendar)
        
        XCTAssertEqual(interval.start, date(2019, 8, 28))
        XCTAssertEqual(interval.end, date(2020, 1, 21))
        XCTAssertEqual(sem, 0)
    }
    
    func testSchedulingRangeDuringFirstSemester() throws {
        let (interval, sem) = try schedulingRange(from: date(2019, 10, 4), inCalendar: calendar)
        
        XCTAssertEqual(interval.start, date(2019, 10, 4))
        XCTAssertEqual(interval.end, date(2020, 1, 21))
        XCTAssertEqual(sem, 0)
    }
    
    func testSchedulingRangeDuringSecondSemester() throws {
        let (interval, sem) = try schedulingRange(from: date(2020, 2, 1), inCalendar: calendar)
        
        XCTAssertEqual(interval.start, date(2020, 2, 1))
        XCTAssertEqual(interval.end, date(2020, 6, 12))
        XCTAssertEqual(sem, 1)
    }
    
    func testSchedulingRangeAfterSchoolYearEnds() throws {
        XCTAssertThrowsError(try schedulingRange(from: date(2020, 7, 10), inCalendar: calendar), "scheduling past end-of-year did not throw error") { (error) in
            if case let NotificationConfigError.dateOutOfRange(str) = error {
                XCTAssertEqual(str, "Cannot schedule notifications for a school year in the past")
            } else {
                XCTFail()
            }
        }
    }
}
