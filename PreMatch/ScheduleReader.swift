//
//  ScheduleReader.swift
//  PreMatch
//
//  Created by Michael Peng on 10/5/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//
import Foundation
import UIKit
import Alamofire
import GoogleSignIn

typealias Schedule = JSON

class ScheduleReader {
  static let loginEndpoint = "https://prematch.org/api/login"
  static let scheduleReadEndpoint = "https://prematch.org/api/schedule"

  private func handleClientError(error: Error) {
    GIDSignIn.sharedInstance().signOut()
    
    AppDelegate.showAlert(
      title: "Ouch!",
      message: "I couldn't get your schedule. Check your Internet connection.",
      actions: [])
  }
  
  private func handleServerError(response: HTTPURLResponse?, error: Error) {
    GIDSignIn.sharedInstance().signOut()
    
    if response == nil {
      AppDelegate.showAlert(title: "Oops!", message: "The server didn't respond. Try again?", actions: [])
      return
    }
    
    switch response!.statusCode {
    case 401:
      AppDelegate.showAlert(title: "Oof!", message: "The request was unauthorized. Try again?", actions: [])
    case 422:
      AppDelegate.showAlert(title: "Oops!", message: "Apparently I didn't provide a handle. Try again?", actions: [])
    case 404:
      let actions = [
        UIAlertAction(title: "Go", style: .default, handler: { action in
          UIApplication.shared.openURL(URL(string: "https://prematch.org/login")!)
        }),
        UIAlertAction(title: "Cancel", style: .cancel)
      ]
      
      AppDelegate.showAlert(title: "Schedule Missing",
                            message: "You don't have a schedule recorded with PreMatch. Enter it on PreMatch.org.",
                            actions: actions)
    default:
      AppDelegate.showAlert(title: "Error \(response!.statusCode)!",
        message: "Oops, there was an error. Please let us know of this. \(error.localizedDescription)",
        actions: [])
    }
  }
  
  private func login(idToken: String, onSuccess: @escaping () -> Void) -> Void {
    Alamofire.request(ScheduleReader.loginEndpoint, parameters: ["id_token": idToken])
      .validate()
      .responseJSON { response in
        switch response.result {
        case .failure(let error):
          GIDSignIn.sharedInstance().signOut()
          AppDelegate.showAlert(title: "Ouch!",
                                message: "PreMatch sign-in failed. \(error.localizedDescription)",
                                actions: [])
        case .success:
          onSuccess()
        }
    }
  }
  
  private func readSchedule(handle: String, processSchedule: @escaping (Schedule) -> Void) -> Void {
    Alamofire.request(ScheduleReader.scheduleReadEndpoint, parameters: ["handle": handle])
      .validate()
      .responseJSON { response in
        switch response.result {
        case .failure(let error):
          self.handleServerError(response: response.response, error: error)
        case .success(let value):
          processSchedule(JSON(value))
        }
    }
  }
  
  // Handles them errors
  func read(handle: String, googleIdToken: String, processSchedule: @escaping (Schedule) -> Void) {
    
    login(idToken: googleIdToken) {
      self.readSchedule(handle: handle, processSchedule: { schedule in
        processSchedule(schedule)
      })
    }
  }
}
