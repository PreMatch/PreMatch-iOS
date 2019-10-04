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
    @IBOutlet weak var dayHeader: UILabel!
    @IBOutlet weak var dayNumber: UILabel!
    @IBOutlet weak var boldTitle: UILabel!
    @IBOutlet weak var specialDayLabel: UILabel!
    @IBOutlet weak var unavailableLabel: UILabel!
    @IBOutlet weak var compactBlocks: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var rightView: UIView!
    @IBOutlet weak var dayExplanation: UILabel!
    
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var periodStack: PeriodColumns!
    
    
    func showUnavailable(_ text: String) {
        leftView.isHidden = true
        rightView.isHidden = true
        periodStack.isHidden = true
        divider.isHidden = true
        
        unavailableLabel.text = text
        unavailableLabel.isHidden = false
    }
    func show(title: String, info: String) {
        boldTitle.text = title
        infoLabel.text = info
        infoLabel.sizeToFit()
        leftView.isHidden = false
        rightView.isHidden = false
        self.extensionContext?.widgetLargestAvailableDisplayMode = .compact
    }
    
    func showSchoolDay(_ schoolDay: SchoolDay, isToday: Bool) {
        dayExplanation.text = isToday ? "" : "is next"
    
        specialDayLabel.isHidden = schoolDay is StandardDay
        dayHeader.isHidden = !specialDayLabel.isHidden
        dayNumber.isHidden = dayHeader.isHidden
        dayExplanation.isHidden = dayHeader.isHidden
        
        switch schoolDay {
            
        case let day as StandardDay:
            dayNumber.text = String(day.number)
        
        case is HalfDay:
            specialDayLabel.text = "Half Day"
        
        case is ExamDay:
            specialDayLabel.text = "Exam Day"
        
        case let day as UnknownDay:
            dayNumber.text = String(day.description.last ?? "?")
            
        default:
            print("Unknown schoolDay in showSchoolDay: \(schoolDay.description)")
        }
        showBlocks(of: schoolDay)
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    }
    
    func showBlocks(of day: SchoolDay) {
        let schedule = ResourceProvider.schedule()
        
        compactBlocks.text = day.blocks.joined(separator: "  ")
        periodStack.render(for: day, at: Date(), in: schedule)
    }
    
    func render() {
        let success = initRendererSuccess()
        self.extensionContext?.widgetLargestAvailableDisplayMode =
            success ? .expanded : .compact
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // No longer: vibrancyView.effect = UIVibrancyEffect.widgetPrimary()
        render()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        render()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(renderer?.render() == true ? .newData : .noData)
    }
    
    func initRendererSuccess() -> Bool {
        if renderer == nil {
            do {
                renderer = try Renderer(renderTo: self)
                return true
            } catch {
                showUnavailable("Set me up in the app!")
                return false
            }
        }
        return true
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        preferredContentSize = activeDisplayMode == .expanded ?
            CGSize(width: 0.0, height: periodStack.expandedWidgetHeight()) : maxSize
        
        compactBlocks.isHidden = activeDisplayMode == .expanded
        divider.isHidden = activeDisplayMode == .compact
    }
}
