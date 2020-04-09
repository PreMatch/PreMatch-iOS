//
//  NotificationScheduler.swift
//  PreMatch
//
//  Created by Michael Peng on 4/7/20.
//  Copyright © 2020 PreMatch. All rights reserved.
//

import Foundation
import UserNotifications
import Sentry

/// `NotificationScheduler`: Figure out what 64 notifications should be scheduled.
/// schedule these 64 notifications asynchronously, leaving the loading UI elsewhere.
///
/// **Logic:** All iterators are sorted by date. Increase the ending date until 64 notifications reached.
class NotificationScheduler {
    
    static let defaultRenewErrorHandler: (Error?) -> Void = { error in
        print("failed to populate notification requests", error ?? "unknown error = nil")
        let event = Event(level: .error)
        event.message = "failed to populate notification requests"
        event.extra = ["error": error ?? "nil"]
        Client.shared?.send(event: event, completion: nil)
    }
    
    class func renewNotifications(
        onError: ((Error?) -> Void)? = defaultRenewErrorHandler,
        onProgress: ((Float) -> Void)?) throws {
        
        let options = (try getNotificationOptions()).map { $0.notificationIdentifiers(from: Date()) }
        let scheduler = NotificationScheduler(options)
        
        scheduler.populateNotificationRequests(onError: onError, onProgress: onProgress)
    }
    
    let options: [AnyIterator<(String, Date)>]
    let scheduledLimit: Int
    
    init(_ options: [AnyIterator<(String, Date)>], limit: Int = 64) {
        self.options = options
        self.scheduledLimit = limit
    }
    
    func pendingNotifications() -> Set<String> {
        var output: [(String, Date)] = []
        var remainingOptions = options
        
        while !remainingOptions.isEmpty {
            remainingOptions = remainingOptions.filter { iterator in
                guard let (id, date) = iterator.next() else { return false }
                let dateBeforeLast = output.isEmpty ? true : date < output.last!.1
                let outputFull = output.count >= scheduledLimit
                
                if !outputFull || dateBeforeLast {
                    output.insertSorted((id, date), comparator: self.compareCandidates)
                }
                if outputFull {
                    output = output.dropLast(output.count - scheduledLimit)
                }
                return dateBeforeLast || !outputFull
            }
        }
        
        return Set(output.map { $0.0 }.prefix(scheduledLimit))
    }
    
    /// Async schedules any missing notification requests until the limit of 64 notifications.
    /// - Parameters:
    ///   - onError: Callback for when an error occurs while scheduling. Most likely because calendar is missing
    ///   - onProgress: Callback for when one notification is scheduled. The parameter is ratio of completion (1 = done)
    func populateNotificationRequests(onError: ((Error?) -> Void)?, onProgress: ((Float) -> Void)?) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { reqs in
            if reqs.count < self.scheduledLimit {
                let idealPending = self.pendingNotifications()
                let missing = idealPending.subtracting(Set(reqs.map { $0.identifier }))
                var requestsDone = 0
                
                for id in missing {
                    do {
                        try self.scheduleRequest(id: id) { error in
                            if let error = error, let onError = onError {
                                onError(error)
                            } else {
                                requestsDone += 1
                                if let onProgress = onProgress {
                                    onProgress(Float(requestsDone) / Float(missing.count))
                                }
                            }
                        }
                    } catch {
                        guard let onError = onError else { continue }
                        onError(error)
                    }
                }
            }
        }
    }
    
    /// A dictionary that maps each notification option's identifier to the option instance.
    lazy var optionIdentifierDict: Dictionary<Character, NotificationOption> = {
        var dict = Dictionary<Character, NotificationOption>()
        for option in (try? getNotificationOptions()) ?? [] {
            dict[option.id] = option
        }
        return dict
    }()
    
    func scheduleRequest(id: String, completion: ((Error?) -> Void)? = nil) throws {
        let request = try optionIdentifierDict[id.first!]!.scheduleNotification(withIdentifier: id)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: completion)
    }
    
    private func compareCandidates(_ a: (String, Date), _ b: (String, Date)) -> ComparisonResult {
        return a.1.compare(b.1)
    }
}

extension Array where Element: Any {
    mutating func insertSorted(_ elem: Element, comparator: (Element, Element) -> ComparisonResult) {
        var low = 0, high = self.count
        while low < high {
            let mid = (low + high) / 2
            let comparison = comparator(self[mid], elem)
            
            switch comparison {
            case .orderedAscending: // self[mid] < elem
                low = mid + 1
            case .orderedDescending:
                high = mid
            case .orderedSame:
                self.insert(elem, at: mid)
                return
            }
        }
        self.insert(elem, at: low)
    }
}
