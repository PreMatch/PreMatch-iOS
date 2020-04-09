//
//  NODayBriefingTest.swift
//  PreMatchTests
//
//  Created by Michael Peng on 8/10/19.
//  Copyright © 2019 PreMatch. All rights reserved.
//

import XCTest
import SevenPlusH
import UserNotifications
@testable import PreMatch

func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var comp = DateComponents()
    comp.year = year
    comp.month = month
    comp.day = day
    
    return Calendar.current.date(from: comp)!
}

let calendar = SphCalendar(
        name: "NotificationOption Test Calendar",
        version: 1.0,
        blocks: ["A", "B", "C", "D", "E"],
        cycleSize: 5,
        interval: DateInterval(start: date(2019, 8, 28), end: date(2020, 6, 11)),
        exclusions: [],
        overrides: [
            Exclusion(
                interval: DateInterval(start: date(2019, 11, 11), end: date(2019, 11, 11)),
                dayGenerator: { date, calendar in HalfDay(date: date, calendar: calendar, blocks: ["B", "D"]) }),
            Exclusion(
                interval: DateInterval(start: date(2019, 12, 12), end: date(2019, 12, 12)),
                dayGenerator: { date, calendar in ExamDay(date: date, calendar: calendar, blocks: ["A"]) })
        ],
        standardPeriods: [Period(from: Time(7, 44), to: Time(8, 44)), Period(from: Time(8, 47), to: Time(9, 47)), Period(from: Time(9, 50), to: Time(10, 50))],
        halfDayPeriods: [Period(from: Time(7, 44), to: Time(8, 30)), Period(from: Time(8, 33), to: Time(9, 28))],
        examPeriods: [Period(from: Time(7, 44), to: Time(10, 0))],
        dayBlocks: [
            ["B", "C", "E"],
            ["E", "A", "D"],
            ["C", "D", "B"],
            ["A", "E", "B"],
            ["D", "C", "A"]
        ],
        semesters: [DateInterval(start: date(2019, 8, 28), end: date(2020, 1, 21)),
                    DateInterval(start: date(2020, 1, 22), end: date(2020, 6, 12))],
        releaseDate: date(2019, 8, 20)
    )

let schedule = try! SphSchedule(mapping: [
    "A1": "Aubrey",
    "A2": "Armstrong",
    "B1": "Bach",
    "B2": "Bach",
    "C1": "Caveney",
    "C2": "Caveney",
    "D1": "DiBenedetto",
    "D2": "Deschenes",
    "E1": "Emery",
    "E2": "Emory"
], calendar: calendar)

class NODayBriefingTest: XCTestCase {
    let defaults = UserDefaults()
    
    
    func testThrowsBadSettingsWhenNoTimeSetting() {
        let dayBriefing = NODayBriefing(calendar: calendar)
        if defaults.string(forKey: "dayBriefingTime") != nil {
            defaults.removeObject(forKey: "dayBriefingTime")
        }
        
        XCTAssertThrowsError(try dayBriefing.scheduleNotifications(withIdentifiers: ["d2019-08-29"]))
    }
    
    func testOneStandardDayWithoutSchedule() throws {
        let dayBriefing = NODayBriefing(calendar: calendar, schedule: nil)
        defaults.set("7:30", forKey: "dayBriefingTime")
        
        let requests = try dayBriefing.scheduleNotifications(
            withIdentifiers: ["d2019-09-06"])
        
        XCTAssertEqual(requests.count, 1)
        let request = requests.first!
        
        assertNotificationRequest(request, identifier: "d2019-09-06", contentTitle: "Your Daily Briefing",
                                  contentBody: "Today is a Day 3 with blocks CDB.",
                                  triggerYear: 2019, triggerMonth: 9, triggerDay: 6, triggerHour: 7, triggerMinute: 30)
    }
    
    func testOneStandardDayWithSchedule() throws {
        let dayBriefing = NODayBriefing(calendar: calendar, schedule: schedule)
        defaults.set("7:27", forKey: "dayBriefingTime")
        
        let request = (try dayBriefing.scheduleNotifications(
            withIdentifiers: ["d2019-09-04"])).first!
        
        assertNotificationRequest(request, identifier: "d2019-09-04", contentTitle: "Your Daily Briefing",
                                  contentBody: "Today is a Day 1 with blocks BCE. Your teachers for today are Bach, Caveney, and Emery.",
                                  triggerYear: 2019, triggerMonth: 9, triggerDay: 4, triggerHour: 7, triggerMinute: 27)
    }
    
    func testOneHalfDayWithoutSchedule() throws {
        let dayBriefing = NODayBriefing(calendar: calendar)
        defaults.set("7:32", forKey: "dayBriefingTime")
        
        let request = (try dayBriefing.scheduleNotifications(
            withIdentifiers: ["d2019-11-11"])).first!
        
        assertNotificationRequest(request, identifier: "d2019-11-11", contentTitle: "Your Half Day Briefing",
                                  contentBody: "Today is a half day with blocks BD.",
                                  triggerYear: 2019, triggerMonth: 11, triggerDay: 11, triggerHour: 7, triggerMinute: 32)
    }
    
    func testOneHalfDayWithSchedule() throws {
        let dayBriefing = NODayBriefing(calendar: calendar, schedule: schedule)
        defaults.set("7:13", forKey: "dayBriefingTime")
        
        let request = (try dayBriefing.scheduleNotifications(
            withIdentifiers: ["d2019-11-11"])).first!
        
        assertNotificationRequest(request, identifier: "d2019-11-11", contentTitle: "Your Half Day Briefing",
                                  contentBody: "Today is a half day with blocks BD. Your teachers for today are Bach and DiBenedetto.",
                                  triggerYear: 2019, triggerMonth: 11, triggerDay: 11, triggerHour: 7, triggerMinute: 13)
    }
    
    func testOneExamDayWithoutSchedule() throws {
        let dayBriefing = NODayBriefing(calendar: calendar)
        defaults.set("7:23", forKey: "dayBriefingTime")
        
        let request = (try dayBriefing.scheduleNotifications(
            withIdentifiers: ["d2019-12-12"])).first!
        
        assertNotificationRequest(request, identifier: "d2019-12-12", contentTitle: "Your Exam Day Briefing",
                                  contentBody: "Today is an exam day with blocks A. Good luck!",
                                  triggerYear: 2019, triggerMonth: 12, triggerDay: 12, triggerHour: 7, triggerMinute: 23)
    }
    
    func testOneExamDayWithSchedule() throws {
        let dayBriefing = NODayBriefing(calendar: calendar, schedule: schedule)
        defaults.set("7:25", forKey: "dayBriefingTime")
        
        let request = (try dayBriefing.scheduleNotifications(
            withIdentifiers: ["d2019-12-12"])).first!
        
        assertNotificationRequest(request, identifier: "d2019-12-12", contentTitle: "Your Exam Day Briefing",
                                  contentBody: "Today is an exam day with blocks A. Your teachers for today are Aubrey. Good luck!",
                                  triggerYear: 2019, triggerMonth: 12, triggerDay: 12, triggerHour: 7, triggerMinute: 25)
    }
    
    func testMultipleDays() throws {
        let dayBriefing = NODayBriefing(calendar: calendar)
        defaults.set("7:10", forKey: "dayBriefingTime")
        
        let requests = try dayBriefing.scheduleNotifications(
            withIdentifiers: ["d2019-09-05", "d2019-09-06", "d2019-09-09"])
        
        XCTAssertEqual(requests.count, 3)
        assertNotificationRequest(requests[0], identifier: "d2019-09-05", contentTitle: "Your Daily Briefing",
                                  contentBody: "Today is a Day 2 with blocks EAD.",
                                  triggerYear: 2019, triggerMonth: 9, triggerDay: 5, triggerHour: 7, triggerMinute: 10)
        assertNotificationRequest(requests[1], identifier: "d2019-09-06", contentTitle: "Your Daily Briefing",
                                  contentBody: "Today is a Day 3 with blocks CDB.",
                                  triggerYear: 2019, triggerMonth: 9, triggerDay: 6, triggerHour: 7, triggerMinute: 10)
        assertNotificationRequest(requests[2], identifier: "d2019-09-09", contentTitle: "Your Daily Briefing",
                                  contentBody: "Today is a Day 4 with blocks AEB.",
                                  triggerYear: 2019, triggerMonth: 9, triggerDay: 9, triggerHour: 7, triggerMinute: 10)
    }
    
    func testOneDayIdentifier() {
        let dayBriefing = NODayBriefing(calendar: calendar)
        
        XCTAssertEqual(dayBriefing.notificationIdentifiers(from: date(2019, 9, 4)).next()!.0, "d2019-09-04")
    }
    
    func testMultipleDaysIdentifier() {
        let dayBriefing = NODayBriefing(calendar: calendar)
        
        XCTAssertEqual(dayBriefing.notificationIdentifiers(from: date(2019, 9, 4)).prefix(5).map { $0.0 }, [
            "d2019-09-04", "d2019-09-05", "d2019-09-06", "d2019-09-09", "d2019-09-10"])
    }
    
    private func assertDateComponents(_ target: DateComponents, year: Int, month: Int, day: Int, hour: Int, minute: Int) {
        XCTAssertEqual(target.year, year)
        XCTAssertEqual(target.month, month)
        XCTAssertEqual(target.day, day)
        XCTAssertEqual(target.hour, hour)
        XCTAssertEqual(target.minute, minute)
    }
    
    private func assertNotificationRequest(_ request: UNNotificationRequest, identifier: String, contentTitle: String, contentBody: String, triggerYear: Int, triggerMonth: Int, triggerDay: Int, triggerHour: Int, triggerMinute: Int) {
        XCTAssertEqual(request.identifier, identifier)
        XCTAssertEqual(request.content.title, contentTitle)
        XCTAssertEqual(request.content.body, contentBody)
        assertDateComponents((request.trigger as! UNCalendarNotificationTrigger).dateComponents,
                             year: triggerYear, month: triggerMonth, day: triggerDay, hour: triggerHour, minute: triggerMinute)
    }
}
