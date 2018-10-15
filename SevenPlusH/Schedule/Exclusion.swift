//
//  Exclusion.swift
//  PreMatch
//
//  Created by Michael Peng on 10/11/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation

struct Exclusion {
  let interval: DateInterval
  let dayGenerator: (Date, SphCalendar) -> Day
  
  func includes(_ date: Date) -> Bool {
    return interval.contains(date)
  }
  
  func day(on date: Date, in calendar: SphCalendar) -> Day? {
    return includes(date) ? dayGenerator(date, calendar) : nil
  }
}
