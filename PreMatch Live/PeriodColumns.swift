//
//  PeriodColumns.swift
//  PreMatch Live
//
//  Created by Michael Peng on 10/25/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import UIKit
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

private func relativeTimes(for day: SchoolDay, at date: Date) -> [RelativeTime?] {
    if day.date > date {
        return Array(repeating: nil, count: day.periods.count)
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

class PeriodColumns: UIStackView {
    private var hasRelativeTimes: Bool = true

    func render(for day: SchoolDay, at time: Date, in schedule: SphSchedule?) {
        clearPeriodColumns()
        let times = relativeTimes(for: day, at: time)
        hasRelativeTimes = times.contains(where: { $0 != nil })
        
        for (block, time) in zip(day.blocks, times) {
            addColumn(time, block: block,
                      teacher: schedule == nil ? nil :
                        try? schedule!.teacher(for: block))
        }
    }
    
    func expandedWidgetHeight() -> CGFloat {
        return hasRelativeTimes ? 230 : 210;
    }
    
    private func addColumn(_ time: RelativeTime?, block: String, teacher: String?) {
        
        let bold = time == .now
        let complete = time == .done
        let viewWidth = UIScreen.main.bounds.width / 6
        
        let view = UIStackView()
        view.axis = .vertical
        view.widthAnchor.constraint(equalToConstant: viewWidth).isActive = true
        view.contentMode = .center
        
        let timeLabel = time == nil ? nil : UILabel()
        timeLabel?.text = format(relativeTime: time!)
        timeLabel?.font = timeLabel?.font.withSize(14)
        
        let blockLabel = UILabel()
        blockLabel.text = block
        blockLabel.font = blockLabel.font.withSize(28)
        
        let teacherLabel = UILabel()
        teacherLabel.text = teacher
        teacherLabel.font = teacherLabel.font.withSize(11)
        teacherLabel.numberOfLines = 0
        teacherLabel.lineBreakMode = .byWordWrapping
        
        for label in [timeLabel, blockLabel, teacherLabel] {
            if let label = label {
                label.textColor = complete ? UIColor.lightGray : UIColor.black
                label.textAlignment = .center
            
                if bold {
                    makeBold(label: label)
                }
                view.addArrangedSubview(label)
            }
        }
        
        blockLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        blockLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        timeLabel?.bottomAnchor.constraint(equalTo: blockLabel.topAnchor).isActive = true
        teacherLabel.topAnchor.constraint(equalTo: blockLabel.bottomAnchor).isActive = true
        
        self.addArrangedSubview(view)
        
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    private func makeBold(label: UILabel) {
        label.font = UIFont(
            descriptor: label.font.fontDescriptor.withSymbolicTraits(.traitBold)!,
            size: 0)
    }
    
    private func clearPeriodColumns() {
        arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}
