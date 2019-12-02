//
//  DownloadErrorHandler.swift
//  PreMatch
//
//  Created by Michael Peng on 11/1/18.
//  Copyright © 2018 PreMatch. All rights reserved.
//

import Foundation
import UIKit
import SevenPlusH
import GoogleSignIn

func dispatchError(_ err: DownloadError) {
    switch err {
    case .badConnection:
        handleBadConnection()
    case .malformedSchedule(let error), .malformedCalendar(let error):
        handleMalformed(error)
    case .noSuchSchedule:
        handleMissingSchedule()
    case .unauthorized:
        handleUnauthorized()
    case .other(let error):
        handleUnknown(error: error)
    }
}
private func handleBadConnection() {
    GIDSignIn.sharedInstance().signOut()
    
    AppDelegate.showAlert(
        title: "Ouch!",
        message: "I couldn't get your schedule. Check your Internet connection.",
        actions: [],
        controller: GIDSignIn.sharedInstance()!.presentingViewController)
}

private func handleMalformed(_ err: ParseError) {
    var title = "Error"
    var message = "An unknown error has occurred."
    
    switch err {
    case .invalidFormat(let fieldType, let invalidValue):
        title = "Invalid Format"
        message = "A field with type \(String(reflecting: fieldType)) has an invalid value: \(String(reflecting: invalidValue))"
    case .missingField(let field):
        title = "Missing Field"
        message = "The field \"\(field)\" is missing"
    case .outOfRange(let fieldType, let invalidValue):
        title = "Out of Range"
        message = "A field with type \(String(reflecting: fieldType)) has a value that is out of range: \(String(reflecting: invalidValue))"
    }
    
    AppDelegate.showAlert(title: title, message: message, actions: [], controller: GIDSignIn.sharedInstance()!.presentingViewController)
}

fileprivate func handleMissingSchedule() {
    let actions = [
        UIAlertAction(title: "Go", style: .default, handler: { action in
            UIApplication.shared.open(URL(string: "https://prematch.org/login")!)
        }),
        UIAlertAction(title: "Cancel", style: .cancel)
    ]
    
    AppDelegate.showAlert(title: "Schedule Missing",
                          message: "You don't have a schedule recorded with PreMatch. Enter it on PreMatch.org.",
                          actions: actions,
                          controller: GIDSignIn.sharedInstance()!.presentingViewController)
}

private func handleUnknown(error: Error) {
    
    AppDelegate.showAlert(title: "Unknown Error!",
                          message: "Oops, there was an error. Please let us know of this. \(error.localizedDescription)",
        actions: [],
        controller: GIDSignIn.sharedInstance()!.presentingViewController)
}

private func handleUnauthorized() {
    AppDelegate.showAlert(title: "Oof!", message: "The request was unauthorized. Try again?", actions: [],
                          controller: GIDSignIn.sharedInstance()!.presentingViewController)
}
