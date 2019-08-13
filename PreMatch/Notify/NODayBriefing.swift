//
//  NODayBriefing.swift
//  PreMatch
//
//  Created by Michael Peng on 8/10/19.
//  Copyright © 2019 PreMatch. All rights reserved.
//

import Foundation
import UserNotifications
import SevenPlusH

/// A NotificationOption that delivers notifications before each school day.
///
/// # Scheme
/// All day briefings take the form _"Today is a Day X with blocks XXXXX. Your teachers for today are A, B, C, D, and E."_
/// If the user has integrated their personal schedule, then the second sentence is included. Otherwise, it is excluded.
/// DayBriefing notifications are only scheduled for school days, regardless of type.
///
/// # Variations
/// ## Half Days
/// A day briefing for a half day takes the form _"Today is a half day with blocks XXXX. Your teachers for today are A, B, C, and D."_
/// ## Exam Days
/// A day briefing for an exam day takes the form _"Today is an exam day with blocks X and X. Good luck!"_
///
/// # Configurations
/// The user chooses the time to deliver DayBriefing notifications. This time value will be saved in the form `XX:XX` in the app group UserDefaults with key `dayBriefingTime`. If this value is not found when `scheduleNotifications` is called, a `NotificationConfigError.badSettings` error will be thrown.
class NODayBriefing: NotificationOption {
    static let id: Character = "d"
    static let name: String = "School Day Briefing"
    
    let calendar: SphCalendar
    let schedule: SphSchedule?
    
    init(calendar: SphCalendar, schedule: SphSchedule? = nil) {
        self.calendar = calendar
        self.schedule = schedule
    }
    
    func scheduleNotifications(from: Date, to: Date) throws -> [UNNotificationRequest] {
        guard let notifyTime = UserDefaults().string(forKey: "dayBriefingTime") else {
            throw NotificationConfigError.badSettings("Missing time for day briefings")
        }
        var output: [UNNotificationRequest] = []
        
        var date = from.withoutTime()
        while date.withoutTime() <= to.withoutTime() {
            switch try calendar.day(on: date) {
                
            case let day as StandardDay:
                output.append(requestForDay(day, bodyInitial: "Today is a Day \(day.number) with blocks", notifyTime: notifyTime))
                
            case let day as HalfDay:
                output.append(requestForDay(day, title: "Your Half Day Briefing", bodyInitial: "Today is a half day with blocks", notifyTime: notifyTime))
            
            case let day as ExamDay:
                output.append(requestForDay(day, title: "Your Exam Day Briefing",
                                            bodySuffix: " Good luck!",
                                            bodyInitial: "Today is an exam day with blocks", notifyTime: notifyTime))
            default:
                break
            }
            date = ahsCalendar.date(byAdding: .day, value: 1, to: date)!.withoutTime()
        }
        
        return output
    }
    
    func notificationIdentifiers(from: Date, to: Date) -> [String] {
        let acceptedTypes: [Day.Type] = [StandardDay.self, HalfDay.self, ExamDay.self]
        var output: [String] = []
        
        var date = from.withoutTime()
        while date <= to.withoutTime() {
            if acceptedTypes.contains(where: { $0 == calendar.dayType(on: date) }) {
                output.append(identifier(for: date))
            }
            date = ahsCalendar.date(byAdding: .day, value: 1, to: date)!.withoutTime()
        }
        
        return output
    }
    
    private func requestForDay(_ day: SchoolDay, title: String = "Your Daily Briefing", bodySuffix: String = "", bodyInitial: String, notifyTime: String) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = dayText(for: day, initial: bodyInitial) + bodySuffix
        
        return UNNotificationRequest(
            identifier: identifier(for: day.date),
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: dateMatchComponents(day.date, notifyTime), repeats: false))
    }
    
    private func dayText(for day: SchoolDay, initial: String) -> String {
        let part1 = "\(initial) \(day.blocks.joined())."
        guard let schedule = self.schedule else {
            return part1
        }
        let semester = calendar.semesterIndexOf(date: day.date)!
        let teachers = day.blocks.map { (try? schedule.teacher(for: $0, in: semester)) ?? "(unknown)" }
        return part1 + " Your teachers for today are " + humanFriendlyJoin(teachers) + "."
    }
    
    private func humanFriendlyJoin(_ elements: [String]) -> String {
        if elements.count == 0 {
            return "none"
        }
        if elements.count == 1 {
            return elements.first!
        }
        if elements.count == 2 {
            return elements.joined(separator: " and ")
        }
        
        // The Oxford comma (before 'and') is conventionally included in the US if there are more than two elements.
        return elements.dropLast().joined(separator: ", ") + ", and " + elements.last!
    }
    
    private func dateMatchComponents(_ date: Date, _ timeString: String) -> DateComponents {
        let dateComp = ahsCalendar.dateComponents(in: ahsTimezone, from: date.withoutTime())
        let (hour, minute) = NODayBriefing.parseTime(timeString)
        
        var newComp = DateComponents()
        newComp.calendar = ahsCalendar
        newComp.year = dateComp.year
        newComp.month = dateComp.month
        newComp.day = dateComp.day
        newComp.hour = Int(hour)
        newComp.minute = Int(minute)
        return newComp
    }
    
    lazy var dateFormat: ISO8601DateFormatter = {
        let dateFormat = ISO8601DateFormatter()
        dateFormat.formatOptions = .withFullDate
        return dateFormat
    }()
    
    private func identifier(for date: Date) -> String {
        return "\(NODayBriefing.id)\(dateFormat.string(from: date))"
    }
    
    fileprivate class func parseTime(_ str: String) -> (UInt8, UInt8) {
        let components = str.split(separator: ":").map { UInt8($0)! }
        return (components[0], components[1])
    }
}

class NODayBriefingSettingsController: UIViewController {
    
    lazy var timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df
    }()
    
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBOutlet weak var notifyTimePicker: UIDatePicker!
    @IBOutlet weak var notifyTimeLabel: UILabel!
    @IBOutlet weak var applyButton: UIBarButtonItem!
    @IBOutlet weak var discardButton: UIBarButtonItem!
    
    let defaults = UserDefaults()

    override func viewDidLoad() {
        let dayBriefingEnabled = NotificationPreferences.isOptionEnabled(identifier: NODayBriefing.id)
        enableSwitch.setOn(dayBriefingEnabled, animated: false)
        
        if dayBriefingEnabled {
            if let notifyTime = defaults.string(forKey: "dayBriefingTime") {
                let (hour, minute) = NODayBriefing.parseTime(notifyTime)
                notifyTimePicker.setDate(ahsCalendar.date(bySettingHour: Int(hour), minute: Int(minute), second: 0, of: notifyTimePicker.date)!, animated: false)
            }
        }
        
        onEnableChange(to: dayBriefingEnabled)
    }
    
    @IBAction func enableSwitchDidChange() {
        onEnableChange(to: enableSwitch.isOn)
    }
    
    @IBAction func discardButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func timePickerChanged() {
        if enableSwitch.isOn {
            updateNotifyTimeLabel()
        }
    }
    
    @IBAction func applyButtonPressed() {
        let previouslyEnabled = NotificationPreferences.isOptionEnabled(identifier: NODayBriefing.id)
        let previousTime = UserDefaults().string(forKey: "dayBriefingTime")
        let newEnabled = enableSwitch.isOn
        let newTime = timeFormatter.string(from: notifyTimePicker.date)
        
        do {
            if !previouslyEnabled && !newEnabled {
                discardButtonPressed()
                return
            }
            
            guard let calendar = ResourceProvider.calendar() else {
                throw NotificationConfigError.missingCalendar
            }
            let option = NODayBriefing(calendar: calendar, schedule: ResourceProvider.schedule())
            if previouslyEnabled && !newEnabled {
                try removePendingRequests(calendar: calendar, option)
                discardButtonPressed()
                return
            }
            if previouslyEnabled && newEnabled {
                if newTime == previousTime {
                    discardButtonPressed()
                    return
                }
                try removePendingRequests(calendar: calendar, option)
                
            }
            if newEnabled {
                defaults.set(timeFormatter.string(from: notifyTimePicker.date), forKey: "dayBriefingTime")
                try scheduleRequests(option, calendar: calendar, completion: nil)
            } else {
                discardButtonPressed()
            }
            
        } catch NotificationConfigError.dateOutOfRange(let str) {
            AppDelegate.showAlert(title: "The school year has ended!", message: "You attempted to schedule notifications after the current school year has ended! Please wait for the next year's calendar to be made active. Error: \(str)", actions: [], controller: self, okHandler: { (_) in
                self.discardButtonPressed()
            })
        } catch NotificationConfigError.missingCalendar {
            AppDelegate.showAlert(title: "There is no calendar!", message: "There is no current calendar that is accessible. Please let us know of this!", actions: [], controller: self, okHandler: { (_) in
                self.discardButtonPressed()
                UIApplication.shared.open(URL(string: "mailto:ios@prematch.org?subject=Error%20In%20PreMatch:%20Missing%20Calendar")!)
            })
        } catch {
            print(error)
            AppDelegate.showAlert(title: "Unknown Error!", message: "We were not expecting this, either. Please let us know of this! Message: \(error)", actions: [], controller: self, okHandler: { (_) in
                self.discardButtonPressed()
                UIApplication.shared.open(URL(string: "mailto:ios@prematch.org?subject=Error%20In%20PreMatch")!)
            })
        }
    }
    
    private func onEnableChange(to newState: Bool) {
        notifyTimePicker.isHidden = !newState
        if newState {
            updateNotifyTimeLabel()
        } else {
            notifyTimeLabel.text = "N/A"
        }
    }
    
    private func removePendingRequests(calendar: SphCalendar, _ option: NODayBriefing) throws {
        let (interval, semester) = try schedulingRange(from: Date(), inCalendar: calendar)
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:
            option.notificationIdentifiers(from: interval.start, to: interval.end))
        NotificationPreferences.didDisableOption(identifier: NODayBriefing.id, semester: UInt8(semester))
    }
    
    private func scheduleRequests(_ option: NODayBriefing, calendar: SphCalendar, completion: ((Error?) -> Void)? = nil) throws {
        let notify = UNUserNotificationCenter.current()
        let (interval, semester) = try schedulingRange(from: Date(), inCalendar: calendar)
        // TODO fix truncation to 64 with more systematic auto-scheduling
        let requests = try option.scheduleNotifications(from: interval.start, to: interval.end).prefix(upTo: 64)
        
        NotificationPreferences.didEnableOption(identifier: NODayBriefing.id, semester: UInt8(semester))
        
        let progressAlert = UIAlertController(title: "Scheduling...", message: "Scheduling \(requests.count) notifications... 0 done.", preferredStyle: .alert)
        let progressBar = UIProgressView(progressViewStyle: .default)
        progressBar.frame = CGRect(x: 10, y: 70, width: 250, height: 0)
        progressAlert.view.addSubview(progressBar)
        present(progressAlert, animated: true, completion: nil)
        
        DispatchQueue.global(qos: .background).async {
            var cont = true
            var scheduled = 0
            var currentId: String? = nil
            
            print(requests.map { $0.identifier })
            
            for (_, req) in requests.enumerated() {
                notify.add(req, withCompletionHandler: completion ?? {
                    if let error = $0 {
                        cont = false
                        DispatchQueue.main.async {
                            progressAlert.dismiss(animated: true, completion: nil)
                            AppDelegate.showAlert(title: "Failed to Schedule Notifications", message: error.localizedDescription, actions: [], controller: self, okHandler: { _ in
                                NotificationPreferences.didDisableOption(identifier: NODayBriefing.id, semester: UInt8(semester))
                                self.discardButtonPressed()
                            })
                        }
                    } else {
                        scheduled += 1
                        currentId = req.identifier
                    }
                    })
                if !cont {
                    return
                }
            }
            
            while scheduled < requests.count {
                DispatchQueue.main.async {
                    progressAlert.message = "Scheduling \(requests.count) notifications... \(scheduled) done."
                    progressBar.setProgress(Float(scheduled) / Float(requests.count), animated: true)
                }
            }
            
            DispatchQueue.main.async {
                progressAlert.title = "Scheduled!"
                progressAlert.message = "Successfully scheduled \(scheduled) notifications"
                progressBar.removeFromSuperview()
                progressAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { _ in
                    self.discardButtonPressed()
                }))
            }
            
        }
    }
    
    private func updateNotifyTimeLabel() {
        notifyTimeLabel.text = timeFormatter.string(from: notifyTimePicker.date)
    }
}
