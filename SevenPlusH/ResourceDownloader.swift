//
//  ResourceDownloader.swift
//  SevenPlusH
//
//  Created by Michael Peng on 10/22/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

public enum DownloadError: Error {
    case badConnection
    case unauthorized
    case noSuchSchedule
    case malformedSchedule(ParseError)
    case malformedCalendar(ParseError)
    case other(Error)
}

public typealias HTTPErrorHandler = (HTTPURLResponse?, Error) -> Void

public struct Downloader {
    static let loginEndpoint = "https://prematch.org/api/login"
    static let scheduleReadEndpoint = "https://prematch.org/api/schedule"
    static let rosterReadEndpoint = "https://prematch.org/api/classmates"
    static let calendarDefinitionEndpoint = "https://prematch.org/static/calendar.json"
    
    public init() {
    }
    
    private func classifyError(_ res: HTTPURLResponse?, _ err: Error) -> DownloadError {
        guard let res = res else {
            return DownloadError.badConnection
        }
        switch res.statusCode {
        case 401:
            return DownloadError.unauthorized
        case 404:
            return DownloadError.noSuchSchedule
        default:
            return DownloadError.other(err)
        }
    }
    
    public func login(idToken: String, onSuccess: @escaping () -> Void,
                       onFailure: @escaping HTTPErrorHandler) -> Void {
        AF.request(Downloader.loginEndpoint, parameters: ["id_token": idToken])
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
    
    public func readScheduleJSON(handle: String,
                                 processSchedule: @escaping (JSON) -> Void,
                                 onFailure: @escaping HTTPErrorHandler) -> Void {
        AF.request(Downloader.scheduleReadEndpoint, parameters: ["handle": handle])
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
    
    public func readCalendarJSON(onSuccess: @escaping (JSON) -> Void,
                                 onFailure: @escaping HTTPErrorHandler) -> Void {
        AF.request(Downloader.calendarDefinitionEndpoint)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .failure(let error):
                    onFailure(response.response, error)
                case .success(let value):
                    onSuccess(JSON(value))
                }
        }
    }
    
    public func storeSchedule(googleIdToken: String, handle: String,
                         calendar: SphCalendar,
                         onSuccess: @escaping (SphSchedule) -> Void,
                         onFailure: @escaping (DownloadError) -> Void) {
        login(idToken: googleIdToken, onSuccess: {
            self.readScheduleJSON(handle: handle,
                                  processSchedule: {
                                    do {
                                        let schedule = try SphSchedule.from(json: $0, calendar: calendar)
                                        ResourceProvider.store(schedule: schedule)
                                        onSuccess(schedule)
                                    } catch {
                                        onFailure(DownloadError.malformedSchedule(error as! ParseError))
                                    }
                                    
            },
                                  onFailure: { onFailure(self.classifyError($0, $1)) })
        }, onFailure: { onFailure(self.classifyError($0, $1)) })
        
    }
    
    public func storeCalendar(onSuccess: @escaping (SphCalendar) -> Void,
                         onFailure: @escaping (DownloadError) -> Void) -> Void {
        readCalendarJSON(onSuccess: {
            do {
                try ResourceProvider.store(calendar: $0)
                onSuccess(ResourceProvider.calendar()!)
            } catch {
                onFailure(DownloadError.malformedCalendar(error as! ParseError))
            }
        }, onFailure: { res, err in
            onFailure(self.classifyError(res, err))
        })
    }
    
    public func readRoster(block: String, semester: UInt8, onSuccess: @escaping (Roster) -> Void,
                           onFailure: @escaping (Error) -> Void) -> Void {
        AF.request(Downloader.rosterReadEndpoint,
                          parameters: ["block": block, "semester": String(semester + 1)])
            .validate()
            .responseJSON { response in
                switch response.result {
                case .failure(let error):
                    onFailure(error)
                case .success(let value):
                    do {
                        onSuccess(try self.parseRoster(data: JSON(value)))
                    } catch {
                        onFailure(error)
                    }
                }
        }
    }
    
    private func parseRoster(data: JSON) throws -> Roster {
        guard let students = data["students"].array else {
            throw ParseError.invalidFormat(fieldType: "array of students", invalidValue: data["students"].description)
        }
        return try students.map({ json in
            guard let name = json["name"].string else {
                throw ParseError.invalidFormat(fieldType: "student name", invalidValue: json["name"].description)
            }
            guard let handle = json["handle"].string else {
                throw ParseError.invalidFormat(fieldType: "student handle", invalidValue: json["handle"].description)
            }
            return Classmate(name: name, handle: handle)
        })
    }
}
