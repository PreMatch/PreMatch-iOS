//
//  DefinitionReader.swift
//  SevenPlusH
//
//  Created by Michael Peng on 10/15/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation
import SwiftyJSON

public enum ParseError: Error {
    case missingField(String)
    case invalidFormat(fieldType: String, invalidValue: String)
    case outOfRange(fieldType: String, invalidValue: String)
}

func parseISODate(_ iso: String,
                  timezone: TimeZone = ahsTimezone) throws -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = timezone
    formatter.formatOptions = .withFullDate
    
    guard let date = formatter.date(from: iso) else {
        throw ParseError.invalidFormat(fieldType: "Date", invalidValue: iso)
    }
    return date
}

extension Time {
    // [10, 20] -> 10:20
    static func fromJSON(_ json: JSON) throws -> Time {
        let hour = json[0].uInt8
        let minute = json[1].uInt8
        
        if hour == nil || minute == nil {
            throw ParseError.invalidFormat(fieldType: "time", invalidValue: json.stringValue)
        }
        return Time(hour!, minute!)
    }
}

extension Period {
    // [[7, 20], [9, 10]]
    static func fromJSON(_ json: JSON) throws -> Period {
        let (start, end) = (json[0], json[1])
        
        return Period(from: try Time.fromJSON(start), to: try Time.fromJSON(end))
    }
}

public class DefinitionReader {
    
    public class func read(_ json: JSON) throws -> SphCalendar {
        let blocks = try requiredField("blocks", json["blocks"].array)
        let startDate = try parseISODate(try requiredField("start date", json["start_date"].string))
        let endDate = try parseISODate(try requiredField("end date", json["end_date"].string))
        let exclusions = try requiredField("exclusions", json["exclusions"].array)
        let overrides = try requiredField("overrides", json["overrides"].array)
        let dayBlocks = try requiredField("standard day blocks collection", json["day_blocks"].array).map { blocks in
            try requiredField("standard day block array", blocks.array).map {
                try requiredField("standard day block string", $0.string)
            }
        }
        let semesterJSONs = try requiredField("semesters", json["semesters"].array)
        let semesters = try semesterJSONs.map { (interval: JSON) -> DateInterval in
            let dates = try requiredField("semester date interval", interval.array).map { try parseISODate($0.stringValue) }
            return DateInterval(start: dates[0], end: dates[1])
        }
        let releaseDateISO = try requiredField("schedule release date", json["schedule_release"].string)
        let releaseDate = try parseJsonDate(releaseDateISO)
        
        return SphCalendar(
            name: try requiredField("definition name", json["name"].string),
            version: try requiredField("version", json["version"].double),
            blocks: blocks.map { $0.stringValue },
            cycleSize: try requiredField("cycle size", json["cycle_size"].uInt8),
            interval: DateInterval(start: startDate, end: endDate),
            exclusions: try exclusions.map { try parseExclusion($0, inDef: json) },
            overrides: try overrides.map { try parseExclusion($0, inDef: json) },
            standardPeriods: try readPeriods(from: json["periods"], name: "standard periods"),
            halfDayPeriods: try readPeriods(from: json["half_day_periods"], name: "half day periods"),
            examPeriods: try readPeriods(from: json["exam_day_periods"], name: "exam day periods"),
            dayBlocks: dayBlocks,
            semesters: semesters,
            releaseDate: releaseDate
        )
    }
    
    class func parseExclusion(_ json: JSON, inDef def: JSON) throws -> Exclusion {
        return try ExclusionParser.parse(json, fromDef: def)
    }
    
    private class func readPeriods(from json: JSON, name: String) throws -> [Period]{
        let periods: [JSON] = try requiredField(name, json.array)
        return try periods.map { try Period.fromJSON($0) }
    }
    
    static let jsonDate = DateFormatter()
    private class func parseJsonDate(_ dateString: String) throws -> Date {
        jsonDate.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        jsonDate.locale = .init(identifier: "en_US_POSIX")
        guard let out = jsonDate.date(from: dateString) else {
            throw ParseError.invalidFormat(fieldType: "schedule release date", invalidValue: dateString)
        }
        return out
    }
    
}
