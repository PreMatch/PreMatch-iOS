//
//  TodayViewController.swift
//  PreMatch Live
//
//  Created by Michael Peng on 10/6/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import UIKit
import NotificationCenter
import SevenPlusH

class TodayViewController: UIViewController, NCWidgetProviding {
    
    var renderer: Renderer? = nil
    
    //MARK: Properties
    @IBOutlet weak var dayNumber: UILabel!
    @IBOutlet weak var boldTitle: UILabel!
    @IBOutlet weak var specialDayLabel: UILabel!
    @IBOutlet weak var unavailableLabel: UILabel!
    @IBOutlet weak var compactBlocks: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var rightView: UIView!
    
    func showUnavailable(_ text: String) {
        leftView.isHidden = true
        rightView.isHidden = true
        unavailableLabel.text = text
        unavailableLabel.isHidden = false
    }
    func show(title: String, info: String) {
        boldTitle.text = title
        infoLabel.text = info
        infoLabel.sizeToFit()
        leftView.isHidden = false
        rightView.isHidden = false
    }
    func showSchoolDay(_ schoolDay: SchoolDay) {
        switch schoolDay {
            
        case let day as StandardDay:
            dayNumber.text = String(day.number)
        
        case is HalfDay:
            specialDayLabel.text = "Half Day"
            specialDayLabel.isHidden = false
        
        case is ExamDay:
            specialDayLabel.text = "Exam Day"
            specialDayLabel.isHidden = false
        
        case let day as UnknownDay:
            dayNumber.text = String(day.description.last ?? "?")
            
        default:
            print("Unknown schoolDay in showSchoolDay: \(schoolDay.description)")
        }
        showBlocks(schoolDay.blocks)
    }
    func showBlocks(_ blocks: [String]) {
        compactBlocks.text = blocks.joined(separator: "  ")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initRenderer()
        
//        if let provider = try? ResourceProvider() {
//            if let nextDate = try? provider.readCalendar().nextSchoolDate(after: Date()) {
//                provider.readSchedule(onSuccess: { schedule in
//                    let day = try! provider.readCalendar().day(on: nextDate!) as! StandardDay
//                    self.dayNumber.text = String(day.number)
//                }, onFailure: { res, error in
//                    print(error)
//                })
//            }
//        }
        // Do any additional setup after loading the view from its nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        
        completionHandler(renderer?.render() == true ? .newData : .noData)
    }
    
    func initRenderer() {
        if renderer == nil {
            do {
                renderer = try Renderer(renderTo: self)
            } catch {
                showUnavailable("Set me up in the app!")
            }
        }
    }
    
}
