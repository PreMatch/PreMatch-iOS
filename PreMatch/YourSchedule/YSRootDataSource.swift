//
//  YSRootDataSource.swift
//  PreMatch
//
//  Created by Michael Peng on 9/6/19.
//  Copyright © 2019 PreMatch. All rights reserved.
//

import Foundation
import UIKit
import SevenPlusH

class YSRootDataSource: NSObject, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let schedule = ResourceProvider.schedule() {
            return schedule.calendar.allBlocks.count
        }
        return 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "yourScheduleOption")!
        
        if let schedule = ResourceProvider.schedule() {
            let block: String = schedule.calendar.allBlocks[indexPath.row]
            let title = titleFor(block: block, in: schedule)
            
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = "\(block) Block"
        }
        
        return cell
    }
    
    func titleFor(block: String, in schedule: SphSchedule) -> String {
        return (0..<schedule.calendar.semesters.count)
            .map { semester in try! schedule.teacher(for: block, in: UInt8(semester)) }
            .uniqued()
            .joined(separator: " and ")
    }
}

// Creds to StackOverflow mxcl & Honey
public extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
