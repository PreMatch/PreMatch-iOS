//
//  SphSchedule.swift
//  SevenPlusH
//
//  Created by Michael Peng on 10/22/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation
import SwiftyJSON

public class SphSchedule {
    let mapping: [String: String]
    public let calendar: SphCalendar
    
    public init(mapping: [String: String], calendar: SphCalendar) throws {
        if let missing = calendar.allBlockSemesterCombinations().first(where: { mapping[$0] == nil }) {
            throw ParseError.missingField(missing)
        }
        self.mapping = mapping.filter { key, _ in calendar.allBlockSemesterCombinations().contains(key) }
        self.calendar = calendar
    }
    
    static func from(json: JSON, calendar: SphCalendar) throws -> SphSchedule {
        guard let dict = json.dictionary?
            .mapValues({ $0.string })
            .filter({ pair in calendar.allBlockSemesterCombinations().contains(pair.key) }) else {
                
            throw ParseError.invalidFormat(
                fieldType: "(entire expression)",
                invalidValue: "(not dictionary)")
        }
        
        if let nilKey = dict.first(where: {(key, value) in value == nil }) {
            throw ParseError.invalidFormat(
                fieldType: "Teacher of block \(nilKey.key)",
                invalidValue: "nil")
        }
        
        return try SphSchedule(
            mapping: dict.mapValues { $0! },
            calendar: calendar)
    }
    
    public func applies(to calendar: SphCalendar) -> Bool {
        return calendar.allBlockSemesterCombinations().allSatisfy { mapping[$0] != nil }
    }
    
    public func currentTeacher(for block: String) throws -> String {
        guard let semester = calendar.semesterIndexOf(date: Date()) else {
            throw CalendarError.outOfRange
        }
        return try teacher(for: block, in: semester)
    }
    
    /// semesterIndex is zero-based
    public func teacher(for block: String, in semesterIndex: UInt8) throws -> String {
        if !calendar.allBlocks.contains(block) {
            throw ParseError.outOfRange(fieldType: "block", invalidValue: block)
        }
        if semesterIndex >= calendar.semesters.count {
            throw ParseError.outOfRange(fieldType: "semester index", invalidValue: String(semesterIndex))
        }
        return mapping[block + String(semesterIndex + 1)]!
    }
}
