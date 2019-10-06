//
//  YSBlockDetailController.swift
//  PreMatch
//
//  Created by Michael Peng on 9/10/19.
//  Copyright © 2019 PreMatch. All rights reserved.
//

import UIKit
import SevenPlusH

class YSBlockDetailController: UIViewController {
    @IBOutlet weak var table: UITableView!
    var dataSource: YSDetailTableDataSource?
    var block: String?
    
    func prepare(forBlock block: String) {
        loadView()
        guard let schedule = ResourceProvider.schedule() else {
            title = "Missing Schedule"
            table.isHidden = true
            return
        }
        table.isHidden = false
        dataSource = YSDetailTableDataSource(schedule: schedule, block: block)
        table.dataSource = dataSource
        table.reloadData()
        title = "\(block) Block"
    }
}

class YSDetailTableDataSource: NSObject, UITableViewDataSource {
    private let schedule: SphSchedule
    private let block: String
    
    init(schedule: SphSchedule,
                  block: String) {
        self.schedule = schedule
        self.block = block
    }
    
    private let tableItemsPerSemester: [(String, SphSchedule, UITableView, UInt8) -> UITableViewCell] = [
        // Teacher
        { block, schedule, table, semester in
            let cell = table.dequeueReusableCell(withIdentifier: "blockData")!
            cell.textLabel?.text = "Teacher"
            cell.detailTextLabel?.text = try! schedule.teacher(for: block, in: semester)
            return cell
        },
        // Room number
            { block, schedule, table, semester in
                let cell = table.dequeueReusableCell(withIdentifier: "roomNumber") as! YSRoomNumberDetailCell
                // TODO store and reflect room number
                return cell
        },
        // View classmates
        { block, schedule, table, semester in
            let cell = table.dequeueReusableCell(withIdentifier: "viewClassmates") as! YSViewClassmatesDetailCell
            // TODO configure View Classmates to trigger list
            return cell
        }
    ]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableItemsPerSemester.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableItemsPerSemester[indexPath.row](
            block, schedule, tableView, UInt8(indexPath.section))
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Semester \(section + 1)"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
}

class YSRoomNumberDetailCell: UITableViewCell {
    // MARK: Outlets
    @IBOutlet weak var roomNumberField: UITextField!
    
}

class YSViewClassmatesDetailCell: UITableViewCell {
    // MARK: Outlets
    
}
