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
        if let missing = calendar.allBlocks.first(where: { mapping[$0] == nil }) {
            throw ParseError.missingField(missing)
        }
        self.mapping = mapping.filter { key, _ in calendar.allBlocks.contains(key) }
        self.calendar = calendar
    }
    
    static func from(json: JSON, calendar: SphCalendar) throws -> SphSchedule {
        guard let dict = json.dictionary?.mapValues({ $0.string }) else {
            throw ParseError.invalidFormat(
                fieldType: "(entire expression)",
                invalidValue: "(not dictionary)")
        }
        
        if let nilKey = dict.first(where: { (key, value) in value == nil }) {
            throw ParseError.invalidFormat(
                fieldType: "Teacher of block \(nilKey)",
                invalidValue: "nil")
        }
        
        return try SphSchedule(
            mapping: dict.mapValues { $0! },
            calendar: calendar)
    }
    
    public func teacher(for block: String) throws -> String {
        if !calendar.allBlocks.contains(block) {
            throw ParseError.outOfRange(fieldType: "block", invalidValue: block)
        }
        return mapping[block]!
    }
}
