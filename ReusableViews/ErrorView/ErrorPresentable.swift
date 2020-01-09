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
                logger.ui.debug(message: "Could not create ErrorView from nib or window's content view is nil.")
                logger.ui.debug(message: "ErrorView adding error. Window's content view: \(self.window?.contentView.debugDescription ?? "Nil")")
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
        let errorDescription = "\(LoginStrings.errorDescription.localized): \(description ?? LoginStrings.unknown.localized)"
        let errorMessage = "\(LoginStrings.errorContactAdministrator.localized)\n\n\(errorDescription)"
        return errorMessage
    }
}
