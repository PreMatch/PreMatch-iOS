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

enum RelativeTime {
    case done
    case now
    case next
    case soon
}

private func format(relativeTime time: RelativeTime) -> String {
    switch time {
    case .done:
        return "Done"
    case .now:
        return "Now"
    case .next:
        return "Next"
    case .soon:
        return "Soon"
    }
}

private func relativeTimes(for day: SchoolDay, at date: Date) -> [RelativeTime] {
    if day.date > date {
        return Array(repeating: RelativeTime.soon, count: day.periods.count)
    }
    let time = Time.fromDate(date)!
    
    return day.periods.map { period in
        if time.isAfter(period) {
            return .done
        }
        if time.isInside(period) {
            return .now
        }
        if day.nextPeriod(at: time) == period {
            return .next
        }
        return .soon
    }
}

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
    @IBOutlet weak var dayExplanation: UILabel!
    @IBOutlet weak var vibrancyView: UIVisualEffectView!
    
    @IBOutlet weak var divider: UIView!
    @IBOutlet weak var periodStack: UIStackView!
    
    
    func showUnavailable(_ text: String) {
        leftView.isHidden = true
        rightView.isHidden = true
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
    }
    
    func showSchoolDay(_ schoolDay: SchoolDay, isToday: Bool) {
        dayExplanation.text = isToday ? "is today" : "is next"
        
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
        showBlocks(of: schoolDay)
    }
    
    func showBlocks(of day: SchoolDay) {
        let schedule = ResourceProvider.schedule()
        let times = relativeTimes(for: day, at: Date())
        
        compactBlocks.text = day.blocks.joined(separator: "  ")
        clearPeriodColumns()
        for (block, relativeTime) in zip(day.blocks, times) {
            addPeriodColumn(
                relativeTime: relativeTime,
                block: block,
                teacher: schedule == nil ?
                    nil : try? (schedule!.teacher(for: block)))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initRenderer()
        vibrancyView.effect = UIVibrancyEffect.widgetPrimary()
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
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
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        preferredContentSize = activeDisplayMode == .expanded ?
            CGSize(width: 0.0, height: 230.0) : maxSize
        
        compactBlocks.isHidden = activeDisplayMode == .expanded
        divider.isHidden = activeDisplayMode == .compact
    }
    
    func addPeriodColumn(relativeTime: RelativeTime, block: String, teacher: String?) {
        
        func makeBold(label: UILabel) {
            label.font = UIFont(
                descriptor: label.font.fontDescriptor.withSymbolicTraits(.traitBold)!,
                size: 0)
        }
        let bold = relativeTime == .now
        let complete = relativeTime == .done
        let viewWidth = UIScreen.main.bounds.width / 6
        
        let view = UIStackView()
        view.axis = .vertical
        view.widthAnchor.constraint(equalToConstant: viewWidth).isActive = true
        view.contentMode = .center
        
        let timeLabel = UILabel()
        timeLabel.text = format(relativeTime: relativeTime)
        timeLabel.font = timeLabel.font.withSize(14)
        
        let blockLabel = UILabel()
        blockLabel.text = block
        blockLabel.font = blockLabel.font.withSize(26)
        
        let teacherLabel = UILabel()
        teacherLabel.text = teacher
        teacherLabel.font = teacherLabel.font.withSize(11)
        teacherLabel.numberOfLines = 0
        teacherLabel.lineBreakMode = .byWordWrapping
        
        [timeLabel, blockLabel, teacherLabel].forEach {
            $0.textColor = UIColor.black
            $0.textAlignment = .center
            
            if bold {
                makeBold(label: $0)
            }
            if complete {
                $0.textColor = $0.textColor.withAlphaComponent(0.7)
            }
            view.addArrangedSubview($0)
        }
        
        blockLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        blockLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: blockLabel.topAnchor).isActive = true
        teacherLabel.topAnchor.constraint(equalTo: blockLabel.bottomAnchor).isActive = true
        
        periodStack.addArrangedSubview(view)
        
        view.topAnchor.constraint(equalTo: periodStack.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: periodStack.bottomAnchor).isActive = true
    }
    
    func clearPeriodColumns() {
        periodStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}
