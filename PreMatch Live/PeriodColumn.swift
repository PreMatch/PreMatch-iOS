//
//  PeriodColumn.swift
//  PreMatch Live
//
//  Created by Michael Peng on 11/1/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import UIKit
import SevenPlusH

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

class PeriodColumn: UIView {
    private static let completedColor = UIColor.lightGray.withAlphaComponent(0.5)

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var blockLabel: UILabel!
    @IBOutlet weak var teacherLabel: UILabel!
    
    var labels: [UILabel] {
        get {
            return [timeLabel, blockLabel, teacherLabel]
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }
    
    func populate(block: String, time: RelativeTime?, schedule: SphSchedule?) {
        applyText(to: timeLabel, time.map(format))
        
        if (block.count > 2) {
            denoteSpecialPeriod(name: block, time: time)
            return
        }
        
        blockLabel.text = block
        
        if let schedule = schedule {
            let teacher = (try? schedule.currentTeacher(for: block)) ?? "?"
            applyText(to: teacherLabel, teacher)
            updateTeacherLabelLineCount(teacher: teacher)
        } else {
            teacherLabel.isHidden = true
        }
        
        if time == .now {
            makeBold()
        }
        if time == .done {
            markComplete()
        }
    }
    
    func denoteSpecialPeriod(name: String, time: RelativeTime?) {
        applyText(to: timeLabel, time.map(format))
        teacherLabel.text = name
        blockLabel.text = "\u{2605}"
    }
    
    func markComplete() {
        for label in labels {
            label.textColor = PeriodColumn.completedColor
        }
    }
    
    func makeBold() {
        for label in labels {
            label.font = UIFont(
                descriptor: label.font.fontDescriptor.withSymbolicTraits(.traitBold)!,
                size: 0)
        }
    }
    
    private func updateTeacherLabelLineCount(teacher: String) {
        let canSplit = teacher.contains("-") || teacher.contains(" ")
        teacherLabel.numberOfLines = canSplit ? 0 : 1;
    }
    
    private func applyText(to label: UILabel, _ str: String?) {
        if let str = str {
            label.isHidden = false
            label.text = str
        } else {
            label.isHidden = true
        }
    }
    
    private func loadNib() {
        Bundle.main.loadNibNamed("PeriodColumn", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
}
