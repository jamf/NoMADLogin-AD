//
//  CheckAD.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/20/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Foundation
import Cocoa
import SecurityInterface.SFAuthorizationPluginView

class CheckAD: NoLoMechanism {
    @objc func run() {
        NSApp.activate(ignoringOtherApps: true)
        let signIn = SignIn(windowNibName: NSNib.Name(rawValue: "SignIn"))
        signIn.mech = self.mechanism.pointee
        let windowTest = signIn.window
        if windowTest == nil {
            NSLog("No dice on the window")
        }
        NSLog("Setting up window")
        NSApp.runModal(for: signIn.window!)
    }
}
