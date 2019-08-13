//
//  QueryViewController.swift
//  PreMatch
//
//  Created by Michael Peng on 10/24/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import UIKit
import SevenPlusH

class QueryViewController: UIViewController, ResourceUser {
    weak static var instance: QueryViewController?
    
    let dataSource = QueryDataSource(day: nil)
    
    //MARK: Properties
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var periodTable: UITableView!
    @IBOutlet weak var textLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        QueryViewController.instance = self
        viewDidAppear(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        periodTable.dataSource = dataSource
        
        if let calendar = ResourceProvider.calendar() {
            datePicker.minimumDate = calendar.interval.start
            datePicker.maximumDate = calendar.interval.end
            
            datePickerChanged(picker: datePicker)
        } else {
            showText(message: "Local calendar unavailable")
        }
        datePicker.addTarget(self, action: #selector(datePickerChanged(picker:)),
                             for: .valueChanged)
    }
    
    func resourcesDidUpdate() {
        viewDidAppear(false)
    }
    
    @objc func datePickerChanged(picker: UIDatePicker) {
        let date = correctGlobalDate(picker.date)
        if let calendar = ResourceProvider.calendar(),
            let day = (try? calendar.day(on: date)) {
            let schoolDay = day as? SchoolDay
            
            if schoolDay != nil && schoolDay!.blocks.count > 0 {
                showTable(daySource: schoolDay!)
            } else {
                showText(message: "\(format(date: date)) is \(day.description)")
            }
            
        } else {
            showText(message: "Local calendar unavailable")
        }
    }
    
    private func correctGlobalDate(_ date: Date) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.calendar = ahsCalendar
        
        return ahsCalendar.date(from: comps)!.withoutTime()
    }
    
    private func showText(message: String) {
        textLabel.text = message
        periodTable.isHidden = true
        textLabel.isHidden = false
    }
    
    private func showTable(daySource: SchoolDay) {
        dataSource.day = daySource
        periodTable.reloadData()
        
        textLabel.isHidden = true
        periodTable.isHidden = false
        textLabel.text = ""
    }
    
    private let formatter = DateFormatter()
    
    private func format(date: Date, long: Bool = false) -> String {
        formatter.dateFormat = (long ? "EEEE, " : "") + "MMM d"
        return formatter.string(from: date)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
