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
    private let kHeightWithoutTimes: CGFloat = 110
    private let kHeightWithTimes: CGFloat = 120
    
    private var hasRelativeTimes: Bool = true

    func render(for day: SchoolDay, at time: Date, in schedule: SphSchedule?) {
        clearPeriodColumns()
        let times = relativeTimes(for: day, at: time)
        hasRelativeTimes = times.contains(where: { $0 != nil })
        
        heightAnchor.constraint(equalToConstant: hasRelativeTimes ?
            kHeightWithTimes : kHeightWithoutTimes)
        
        for (block, time) in zip(day.blocks, times) {
            addColumn(time, block: block,
                      schedule: schedule)
        }
    }
    
    func expandedWidgetHeight() -> CGFloat {
        return hasRelativeTimes ? kHeightWithTimes + 110 : kHeightWithoutTimes + 110
    }
    
    private func addColumn(_ time: RelativeTime?, block: String, schedule: SphSchedule?) {
        
        let viewWidth = bounds.width / 5
        
        let view = PeriodColumn()
        view.widthAnchor.constraint(equalToConstant: viewWidth)
        view.populate(
            block: block,
            time: time,
            schedule: schedule)
        
        self.addArrangedSubview(view)
        
//        view.topAnchor.constraint(equalTo: topAnchor, constant: time == nil ? -50 : 0).isActive = true
//        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
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
