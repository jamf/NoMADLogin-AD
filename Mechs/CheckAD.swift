//
//  CheckAD.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/20/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Cocoa

class CheckAD: NoLoMechanism {
    @objc func run() {
        NSApp.activate(ignoringOtherApps: true)
        let signIn = SignIn(windowNibName: NSNib.Name(rawValue: "SignIn"))
        signIn.mech = mech
        let windowTest = signIn.window
        if windowTest == nil {
            NSLog("%@", "Could not create login window UI")
        }
        NSApp.runModal(for: signIn.window!)
    }
}
