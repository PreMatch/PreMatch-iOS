//
//  QueryDataSource.swift
//  PreMatch
//
//  Created by Michael Peng on 10/27/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import UIKit
import SevenPlusH

class QueryDataSource: NSObject, UITableViewDataSource {
    var day: SchoolDay?
    
    init(day: SchoolDay?) {
        self.day = day
    }
    
    //MARK: - UITableViewDataSource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return day?.blocks.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "periodCell")!
        let schedule = ResourceProvider.schedule()
        
        cell.textLabel!.text = day?.blocks[indexPath.row]
        
        if schedule != nil && day != nil {
            let semester = schedule!.calendar.semesterIndexOf(date: day!.date)
            if semester != nil {
                cell.detailTextLabel!.text = (try? schedule!.teacher(for: day!.blocks[indexPath.row],
                                                                     in: semester!)) ?? "?"
            }
        } else {
            cell.detailTextLabel!.text = "?"
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return day?.description.capitalized
    }
}
