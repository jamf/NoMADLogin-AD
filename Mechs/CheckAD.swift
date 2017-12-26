//
//  CheckAD.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/20/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Cocoa
import os.log

class CheckAD: NoLoMechanism {
    @objc func run() {
        os_log("CheckAD mech starting", log: MechanismLog, type: .debug)
        os_log("Activating app", log: MechanismLog, type: .debug)
        NSApp.activate(ignoringOtherApps: true)
        os_log("Loading XIB", log: MechanismLog, type: .debug)
        let signIn = SignIn(windowNibName: NSNib.Name(rawValue: "SignIn"))
        os_log("Set mech for loginwindow", log: MechanismLog, type: .debug)
        signIn.mech = mech
        let windowTest = signIn.window
        if windowTest == nil {
            os_log("Could not create login window UI", log: MechanismLog, type: .default)
        }
        os_log("Displaying window", log: MechanismLog, type: .debug)
        NSApp.runModal(for: signIn.window!)
        os_log("CheckAD mech complete", log: MechanismLog, type: .debug)
    }
}
