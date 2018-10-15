//
//  SphCalendar.swift
//  PreMatch
//
//  Created by Michael Peng on 10/10/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation

enum Result<T, E> {
  case ok(T)
  case error(E)
}

enum CalendarError: Error {
  case outOfRange
}

extension Date {
  func isWeekend() -> Bool {
    return Calendar.current.isDateInWeekend(self)
  }
  func dayAfter() -> Date {
    return self + 24*60*60
  }
  func dayBefore() -> Date {
    return self - 24*60*60
  }
}

class DayIterator {
  var mapping: [Date: DayNumber] = [:]
  var calendar: SphCalendar?
  
  init(start: Date) {
    mapping[start] = 1
  }
  
  func numberOfDate(_ date: Date, for calendar: SphCalendar, _ useRecursion: Bool = true) -> DayNumber? {
    if !calendar.isSchoolDay(on: date) {
      return nil
    }
    self.calendar = calendar
    
    let number = useRecursion ? recursivelyIterate(from: date) : iterate(from: date)
    mapping[date] = number
    return number
  }
  
  private func mostRecentMapping(from date: Date) -> (Date, DayNumber) {
    return mapping.filter { d, _ in d <= date }.max { a, b in a.key < b.key }!
  }
  
  private func recursivelyIterate(from date: Date) -> DayNumber {
    if let number = mapping[date] {
      return number
    } else if calendar!.dayType(on: date) == StandardDay.self {
      return (recursivelyIterate(from: date.dayBefore()) % 8) + 1
    } else {
      return recursivelyIterate(from: date.dayBefore())
    }
  }
  private func iterate(from date: Date) -> DayNumber {
    var (currentDate, currentNumber) = mostRecentMapping(from: date)
    while currentDate < date {
      currentDate = currentDate.dayAfter()
      if calendar!.dayType(on: currentDate) == StandardDay.self {
        currentNumber = (currentNumber % 8) + 1
      }
    }
    return currentNumber
  }
}

class SphCalendar {
  let name: String
  let version: Double
  let allBlocks: [String]
  let cycleSize: Int
  
  let interval: DateInterval
  let exclusions: [Exclusion]
  let overrides: [Exclusion]
  
  let iterator: DayIterator
  
  init(name: String, version: Double, blocks: [String], cycleSize: Int, interval: DateInterval, exclusions: [Exclusion], overrides: [Exclusion]) {
    self.name = name
    self.version = version
    self.allBlocks = blocks
    self.cycleSize = cycleSize
    self.interval = interval
    self.exclusions = exclusions
    self.overrides = overrides
    self.iterator = DayIterator(start: interval.start)
  }
  
  func includes(_ date: Date) -> Bool {
    return interval.contains(date)
  }
  
  func day(on date: Date) throws -> Day {
    if !includes(date) {
      throw CalendarError.outOfRange
    }
    if let ex = theExclusion(for: date) {
      return ex.day(on: date, in: self)!
    } else if date.isWeekend() {
      return Weekend(date: date, calendar: self)
    } else {
      let number = iterator.numberOfDate(date, for: self)
      return StandardDay(date: date, number: number!, calendar: self)
    }
  }
  
  func blocks(of: Day) -> [String] {
    return []
  }
  
  func dayType(on date: Date) -> Day.Type? {
    if !interval.contains(date) {
      return nil
    }
    if let day = theExclusion(for: date)?.day(on: date, in: self)! {
      return type(of: day)
    } else if (date.isWeekend()) {
      return Weekend.self
    } else {
      return StandardDay.self
    }
  }
  
  func isSchoolDay(on date: Date) -> Bool {
    return dayType(on: date) is SchoolDay.Type
  }
  
  private func theExclusion(for date: Date) -> Exclusion? {
    return (exclusions + overrides).first {
      ex in ex.includes(date)
    }
  }
}
