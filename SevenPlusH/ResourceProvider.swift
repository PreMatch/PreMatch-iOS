//
//  ResourceProvider.swift
//  SevenPlusH
//
//  Created by Michael Peng on 10/19/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

public typealias Schedule = [String: String]

private func require<T>(_ value: T?, otherwise error: Error) throws -> T {
    if let value = value {
        return value
    } else {
        throw error
    }
}

public enum InMemoryError: Error {
    case notSet
}

public enum DefaultsError: Error {
    case defaultsUnavailable
    case noSuchKey(badKey: String)
    case badValueType(dict: [String: Any])
    case writeFailed
}

struct InMemoryProvider {
    private static var _calendar: SphCalendar?
    private static var _schedule: Schedule?
    
    func calendar() throws -> SphCalendar {
        return try require(InMemoryProvider._calendar, otherwise: InMemoryError.notSet)
    }
    
    func schedule() throws -> Schedule {
        return try require(InMemoryProvider._schedule, otherwise: InMemoryError.notSet)
    }
    
    static func write(calendarJSON: JSON) {
        do {
            write(calendar: try DefinitionReader.read(calendarJSON))
        } catch {
            print(error)
        }
    }
    static func write(calendar: SphCalendar) {
        _calendar = calendar
    }
    static func write(schedule: Schedule) {
        _schedule = schedule
    }
}

struct DefaultsProvider {
    private static let defaults = UserDefaults(suiteName: "group.org.prematch.data")
    
    func calendar() throws -> SphCalendar {
        let json = try require(
            try DefaultsProvider.getDefaults().data(forKey: "calendar"),
            otherwise: DefaultsError.noSuchKey(badKey: "calendar"))
        
        return try DefinitionReader.read(JSON(data: json))
    }
    
    func schedule() throws -> Schedule {
        let dict = try require(
            try DefaultsProvider.getDefaults().dictionary(forKey: "schedule"),
            otherwise: DefaultsError.noSuchKey(badKey: "schedule"))
        
        if !(dict.values.allSatisfy { $0 is String }) {
            throw DefaultsError.badValueType(dict: dict)
        }
        
        return dict.mapValues { $0 as! String }
    }
    
    static func write(calendarJSON: Data) throws {
        try write(calendarJSON, forKey: "calendar")
    }
    static func write(schedule: Schedule) throws {
        try write(schedule, forKey: "schedule")
    }
    
    static var accountHandle: String? {
        get {
            return defaults?.string(forKey: "handle")
        }
        set(handle) {
            defaults?.set(handle, forKey: "handle")
        }
    }
    static var accountGoogleIdToken: String? {
        get {
            return defaults?.string(forKey: "idToken")
        }
        set(token) {
            defaults?.set(token, forKey: "idToken")
        }
    }
    
    private static func getDefaults() throws -> UserDefaults {
        if let defaults = defaults {
            return defaults
        } else {
            throw DefaultsError.defaultsUnavailable
        }
    }
    
    private static func write(_ obj: Any?, forKey: String) throws {
        let defaults = try require(self.defaults,
                    otherwise: DefaultsError.defaultsUnavailable)
        defaults.set(obj, forKey: forKey)
        
        if !defaults.synchronize() {
            throw DefaultsError.writeFailed
        }
        
    }
}

enum DownloadError: Error {
    case badConnection
    case malformedSchedule
    case other(Error)
}

typealias SerializedSchedule = JSON

private struct OnlineProvider {
    static let loginEndpoint = "https://prematch.org/api/login"
    static let scheduleReadEndpoint = "https://prematch.org/api/schedule"
    static let calendarDefinitionEndpoint = "https://prematch.org/static/calendar.json"
    
    //    private func handleClientError(error: Error) {
    //        GIDSignIn.sharedInstance().signOut()
    //
    //        AppDelegate.showAlert(
    //            title: "Ouch!",
    //            message: "I couldn't get your schedule. Check your Internet connection.",
    //            actions: [])
    //    }
    //
    //    fileprivate func handleMissingSchedule() {
    //        let actions = [
    //            UIAlertAction(title: "Go", style: .default, handler: { action in
    //                UIApplication.shared.open(URL(string: "https://prematch.org/login")!)
    //            }),
    //            UIAlertAction(title: "Cancel", style: .cancel)
    //        ]
    //
    //        AppDelegate.showAlert(title: "Schedule Missing",
    //                              message: "You don't have a schedule recorded with PreMatch. Enter it on PreMatch.org.",
    //                              actions: actions)
    //    }
    
    //    private func handleServerError(response: HTTPURLResponse?, error: Error) {
    //        GIDSignIn.sharedInstance().signOut()
    //
    //        if response == nil {
    //            AppDelegate.showAlert(title: "Oops!", message: "The server didn't respond. Try again?", actions: [])
    //            return
    //        }
    //
    //        switch response!.statusCode {
    //        case 401:
    //            AppDelegate.showAlert(title: "Oof!", message: "The request was unauthorized. Try again?", actions: [])
    //        case 422:
    //            AppDelegate.showAlert(title: "Oops!", message: "Apparently I didn't provide a handle. Try again?", actions: [])
    //        case 404:
    //            handleMissingSchedule()
    //        default:
    //            AppDelegate.showAlert(title: "Error \(response!.statusCode)!",
    //                message: "Oops, there was an error. Please let us know of this. \(error.localizedDescription)",
    //                actions: [])
    //        }
    //    }
    
    private func login(idToken: String, onSuccess: @escaping () -> Void,
                       onFailure: @escaping (HTTPURLResponse?, Error) -> Void) -> Void {
        Alamofire.request(OnlineProvider.loginEndpoint, parameters: ["id_token": idToken])
            .validate()
            .responseJSON { response in
                switch response.result {
                case .failure(let error):
                    onFailure(response.response, error)
                case .success:
                    onSuccess()
                }
        }
    }
    
    private func readSchedule(handle: String,
                              processSchedule: @escaping (SerializedSchedule) -> Void,
                              onFailure: @escaping (HTTPURLResponse?, Error) -> Void) -> Void {
        Alamofire.request(OnlineProvider.scheduleReadEndpoint, parameters: ["handle": handle])
            .validate()
            .responseJSON { response in
                switch response.result {
                case .failure(let error):
                    onFailure(response.response, error)
                case .success(let value):
                    processSchedule(JSON(value))
                }
        }
    }
    
    private func deserialize(_ schedule: SerializedSchedule) throws -> Schedule {
        if let response = schedule.dictionaryObject {
            // TODO move actual schedule into a property
            let dict = response.filter { _, value in value is String }
            if dict.isEmpty {
                throw DownloadError.malformedSchedule
            }
            return dict.mapValues { $0 as! String }
        } else {
            throw DownloadError.malformedSchedule
        }
    }
    
    func schedule(onSuccess: @escaping (Schedule) -> Void,
                  onFailure: @escaping (HTTPURLResponse?, Error) -> Void) {
        login(idToken: googleIdToken, onSuccess: {
            self.readSchedule(handle: self.handle,
                              processSchedule: {
                                do {
                                    onSuccess(try self.deserialize($0))
                                } catch {
                                    onFailure(nil, error)
                                }
                                
            },
                              onFailure: onFailure)
        }, onFailure: onFailure)
        
    }
    
    func calendar() throws -> (SphCalendar, Data) {
        let data = try Data(contentsOf: URL(string: "https://prematch.org/static/calendar.json")!)
        
        return (try DefinitionReader.read(JSON(data)), data)
    }
    
    func storeHandleAndToken() {
        DefaultsProvider.accountHandle = handle
        DefaultsProvider.accountGoogleIdToken = googleIdToken
    }
    
    let handle: String
    let googleIdToken: String
    
    init(handle: String, googleIdToken: String) {
        self.handle = handle
        self.googleIdToken = googleIdToken
        storeHandleAndToken()
    }
}

public enum ProviderError: Error {
    case multipart(errors: [Error])
    case notLoggedInAndNotAvailableOffline
    case other
}

public struct ResourceProvider {
    private struct Providers {
        let memory: InMemoryProvider
        let defaults: DefaultsProvider
        let online: OnlineProvider
    }
    private let provider: Providers
    
    public init() throws {
        let handle = DefaultsProvider.accountHandle
        let googleIdToken = DefaultsProvider.accountGoogleIdToken
        
        if handle == nil || googleIdToken == nil {
            throw ProviderError.notLoggedInAndNotAvailableOffline
        }
        
        self.init(handle: handle!, googleIdToken: googleIdToken!)
    }
    
    public init(handle: String, googleIdToken: String) {
        provider = Providers(
            memory: InMemoryProvider(),
            defaults: DefaultsProvider(),
            online: OnlineProvider(
                handle: handle,
                googleIdToken: googleIdToken))
    }
    
    public func readSchedule(onSuccess: @escaping (Schedule) -> Void,
                             onFailure: @escaping (HTTPURLResponse?, Error) -> Void) {
        // TODO Accumulate errors from memory and defaults to pass into onFailure
        if let sched = (try? provider.memory.schedule()) ?? (try? provider.defaults.schedule()) {
            InMemoryProvider.write(schedule: sched)
            onSuccess(sched)
        } else {
            provider.online.schedule(onSuccess: {
                try? DefaultsProvider.write(schedule: $0)
                InMemoryProvider.write(schedule: $0)
                onSuccess($0)
            }, onFailure: onFailure)
        }
    }
    
    public func readScheduleSync() throws -> Schedule {
        var schedule: Schedule? = nil
        var error: (HTTPURLResponse?, Error)? = nil
        let semaphore = DispatchSemaphore(value: 1)
        
        readSchedule(
            onSuccess: { schedule = $0; semaphore.signal() },
            onFailure: { error = ($0, $1); semaphore.signal() })
        
        semaphore.wait()
        if error != nil || schedule == nil {
            throw error?.1 ?? ProviderError.other
        } else {
            return schedule!
        }
    }
    
    public func readCalendar() throws -> SphCalendar {
        // Is there something better?
        var errors: [Error] = []
        
        do {
            return try provider.memory.calendar()
        } catch {
            errors.append(error)
            print(error)
            do {
                let calendar = try provider.defaults.calendar()
                InMemoryProvider.write(calendar: calendar)
                return calendar
            } catch {
                errors.append(error)
                print(error)
                do {
                    let (calendar, data) = try provider.online.calendar()
                    try? DefaultsProvider.write(calendarJSON: data)
                    InMemoryProvider.write(calendarJSON: JSON(data))
                    return calendar
                } catch {
                    errors.append(error)
                    throw ProviderError.multipart(errors: errors)
                }
            }
        }
    }
}
