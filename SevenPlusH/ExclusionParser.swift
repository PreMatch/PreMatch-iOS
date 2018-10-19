//
//  ExclusionReader.swift
//  SevenPlusH
//
//  Created by Michael Peng on 10/18/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation
import SwiftyJSON

func requiredField<T>(_ field: String, _ value: T?) throws -> T {
    guard let value = value else {
        throw ParseError.missingField(field)
    }
    return value
}

class ExclusionParser {
    private static let typeParsers: [String: (JSON, JSON) throws -> Exclusion] = [
        "holiday": { json, def in
            let startDate = try dateField(json["start_date"].string, inDef: def, "start date")
            let endDate = try dateField(json["end_date"].string, inDef: def, "end date")
            let description = try requiredField("description", json["description"].string)
            
            return Exclusion(
                interval: DateInterval(start: startDate, end: endDate),
                dayGenerator: { date, calendar in
                    return Holiday(date: date, description: description, calendar: calendar)
            })
        },
        "half_day": { json, def in
            let date = try dateField(json["date"].string, inDef: def)
            let blocks = try requiredField("blocks", json["blocks"].array).map { block in
                block.stringValue
            }
            return Exclusion(
                interval: DateInterval(start: date, end: date),
                dayGenerator: { date, calendar in
                    return HalfDay(date: date, calendar: calendar, blocks: blocks)
            })
        },
        "exam_day": { json, def in
            let date = try dateField(json["date"].string, inDef: def)
            let blocks = try requiredField("blocks", json["blocks"].array).map { block in
                block.stringValue
            }
            return Exclusion(
                interval: DateInterval(start: date, end: date),
                dayGenerator: { date, calendar in
                    return ExamDay(date: date, calendar: calendar, blocks: blocks)
            })
        },
        "unknown": { json, def in
            let date = try dateField(json["date"].string, inDef: def)
            let description = try requiredField("description", json["description"].string)
            return Exclusion(
                interval: DateInterval(start: date, end: date),
                dayGenerator: { date, calendar in
                    return UnknownDay(date: date, description: description, calendar: calendar)
            })
        },
        "standard_day": { json, def in
            let date = try dateField(json["date"].string, inDef: def)
            let number = try standardDayField(json["day_number"].uInt8, inDef: def)
            return Exclusion(
                interval: DateInterval(start: date, end: date),
                dayGenerator: { date, calendar in
                    return StandardDay(
                        date: date,
                        number: DayNumber(number),
                        calendar: calendar)
            })
        }
    ]
    
    class func dateField(_ value: String?, inDef def: JSON, _ name: String = "date") throws -> Date {
        let date = try parseISODate(try requiredField(name, value))
        let start = try parseISODate(try requiredField("start date", def["start_date"].string))
        let end = try parseISODate(try requiredField("end date", def["end_date"].string))
        
        if !DateInterval(start: start, end: end).contains(date) {
            // Value is guaranteed to be non-null. It passed requiredFieldValue.
            throw ParseError.outOfRange(fieldType: "date", invalidValue: value!)
        }
        return date
    }
    class func standardDayField(_ value: DayNumber?, inDef def: JSON) throws -> DayNumber {
        let number = try requiredField("day number", value)
        let cycleSize = try requiredField("cycle size", def["cycle_size"].uInt8)
        
        if number < 1 || number > cycleSize {
            throw ParseError.outOfRange(fieldType: "day number", invalidValue: String(number))
        }
        return number
    }
    
    class func parse(_ json: JSON, fromDef def: JSON) throws -> Exclusion {
        let dayType = try requiredField("type", json["type"].string)
        
        guard let parser = typeParsers[dayType] else {
            throw ParseError.invalidFormat(fieldType: "type", invalidValue: dayType)
        }
        
        return try parser(json, def)
    }
}
