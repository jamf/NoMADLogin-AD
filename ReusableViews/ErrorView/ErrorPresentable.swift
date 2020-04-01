//
//  ErrorPresentable.swift
//  JamfConnectLogin
//
//  Created by Bartosz Odrzywolek on 29/03/2019.
//  Copyright © 2019 Jamf. All rights reserved.
//

import Cocoa

protocol ErrorPresentable {
    var window: NSWindow? { get }
    func presentError(description: String, completion: (() -> Void)?)
    func getErrorMessage(withDescription description: String?) -> String
}

extension ErrorPresentable {
    func presentError(description: String, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async{
            guard   let errorView = ErrorView.createFromNib(in: .mainLogin),
                    let windowContentView = self.window?.contentView
                    else {
                os_log("Could not create ErrorView from nib or window's content view is nil", log: uiLog, type: .debug)
                os_log("ErrorView adding error. Window's content view: %{public}@ contains ErrorView instance", log: uiLog, type: .debug, self.window?.contentView.debugDescription ?? "Nil")
                return
            }
            errorView.frame = windowContentView.frame
            errorView.configureUI(message: description)
            errorView.set(completionHandler: completion)
            errorView.add(to: windowContentView)
            errorView.window?.makeFirstResponder(errorView)
        }
    }
    
    func hideError() {
        let firstResponder = self.window?.firstResponder
        if let first = firstResponder as? ErrorView {
            first.dismiss()
        }
    }

    func getErrorMessage(withDescription description: String?) -> String {
        // Login Strings not present in NoMAD Login - Port issue
        //let errorDescription = "\(LoginStrings.errorDescription.localized): \(description ?? LoginStrings.unknown.localized)"
        //let errorMessage = "\(LoginStrings.errorContactAdministrator.localized)\n\n\(errorDescription)"
        let errorMessage = "An error has occured, please contat your systems administrator.\n\nDescription \(description ?? "Unknown")"
        return errorMessage
    }
}
