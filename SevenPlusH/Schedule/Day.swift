//
//  Day.swift
//  PreMatch
//
//  Created by Michael Peng on 10/11/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation

typealias DayNumber = UInt8

protocol Day {
  var date: Date { get }
  var description: String { get }
  var calendar: SphCalendar { get }
}

protocol SchoolDay: Day {
  var blocks: [String] { get }
}

extension SchoolDay {
  var blocks: [String] {
    get {
      return calendar.blocks(of: self)
    }
  }
}

struct StandardDay: SchoolDay {
  let date: Date
  var description: String {
    get {
      return "a Day \(self.number)"
    }
  }
  let number: DayNumber
  let calendar: SphCalendar
}

struct HalfDay: SchoolDay {
  let date: Date
  let description: String = "a half-day"
  let calendar: SphCalendar
}

struct ExamDay: SchoolDay {
  let date: Date
  let description: String = "an exam day"
  let calendar: SphCalendar
}

struct UnknownDay: SchoolDay {
  let date: Date
  let description: String
  let calendar: SphCalendar
  let blocks: [String] = []
}

struct Holiday: Day {
  let date: Date
  let description: String
  let calendar: SphCalendar
}

struct Weekend: Day {
  let date: Date
  var description: String {
    get {
      let df = DateFormatter()
      df.dateFormat = "EEEE"
      return "a \(df.string(from: date))"
    }
  }
  let calendar: SphCalendar
}
