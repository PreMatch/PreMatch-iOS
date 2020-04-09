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

class YSTableCell: UITableViewCell {
    var block: String? = nil
    
    func setup(block: String, in schedule: SphSchedule) {
        self.block = block
        textLabel?.text = titleFor(block: block, in: schedule)
        detailTextLabel?.text = "\(block) Block"
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func handleSelection(view: UIViewController) {
        // FIXME: Block details hidden for v1.1
        //view.performSegue(withIdentifier: "showBlockDetails", sender: self)
    }
    
    private func titleFor(block: String, in schedule: SphSchedule) -> String {
        return (0..<schedule.calendar.semesters.count)
            .map { semester in try! schedule.teacher(for: block, in: UInt8(semester)) }
            .uniqued()
            .joined(separator: " and ")
    }
}

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
        let cell = tableView.dequeueReusableCell(withIdentifier: "yourScheduleOption")! as! YSTableCell
        
        if let schedule = ResourceProvider.schedule() {
            let block: String = schedule.calendar.allBlocks[indexPath.row]
            cell.setup(block: block, in: schedule)
        }
        
        return cell
    }
    
    
}

// Creds to StackOverflow mxcl & Honey
public extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
