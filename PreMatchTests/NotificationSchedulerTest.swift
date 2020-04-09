//
//  NotificationSchedulerTest.swift
//  PreMatchTests
//
//  Created by Michael Peng on 4/8/20.
//  Copyright © 2020 PreMatch. All rights reserved.
//

import Foundation
import XCTest
@testable import PreMatch

extension Date {
    func plus(hours: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: 1, to: self)!
    }
}

// I'm not being crazy? I found no built-in solution?
extension Array where Element: Any {
    func makeAnyIterator() -> AnyIterator<Element> {
        var index = 0
        return AnyIterator<Element> {
            while (index < self.count) {
                let element = self[index]
                index += 1
                return element
            }
            return nil
        }
    }
}

fileprivate func iterators() -> [AnyIterator<(String, Date)>] {
    return [
        [
            ("a1", date(2020, 4, 3)),
            ("a2", date(2020, 4, 4)),
            ("a3", date(2020, 4, 5)),
            ("a4", date(2020, 4, 8))
        ].makeAnyIterator(),
        [
            ("b1", date(2020, 4, 3)),
            ("b2", date(2020, 4, 3).plus(hours: 1)),
            ("b3", date(2020, 4, 4)),
            ("b4", date(2020, 4, 4).plus(hours: 2))
        ].makeAnyIterator(),
        [
            ("c1", date(2020, 4, 8)),
            ("c2", date(2020, 4, 12)),
            ("c3", date(2020, 4, 20))
        ].makeAnyIterator()
    ]
}

class NotificationSchedulerTest: XCTestCase {
    func testScheduleAllAvailable() {
        let scheduler = NotificationScheduler(iterators(), limit: 64)
        let pending = scheduler.pendingNotifications()
        
        XCTAssertEqual(pending, ["a1", "a2", "a3", "a4", "b1", "b2", "b3", "b4", "c1", "c2", "c3"])
    }
    
    func testScheduleWithoutAFew() {
        let scheduler = NotificationScheduler(iterators(), limit: 9)
        let pending = scheduler.pendingNotifications()
        
        XCTAssertEqual(pending, ["a1", "a2", "a3", "a4", "b1", "b2", "b3", "b4", "c1"])
    }
    
    func testScheduleFirstFew() {
        let scheduler = NotificationScheduler(iterators(), limit: 5)
        let pending = scheduler.pendingNotifications()
        
        XCTAssertEqual(pending, ["a1", "b1", "b2", "a2", "b3"])
    }
    
    func testScheduleFirstDay() {
        let scheduler = NotificationScheduler(iterators(), limit: 3)
        let pending = scheduler.pendingNotifications()
        
        XCTAssertEqual(pending, ["a1", "b1", "b2"])
    }
}
