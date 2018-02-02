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
        os_log("CheckAD mech starting", log: checkADLog, type: .debug)
        os_log("Activating app", log: checkADLog, type: .debug)
        NSApp.activate(ignoringOtherApps: true)
        os_log("Loading XIB", log: checkADLog, type: .debug)
        let signIn = SignIn(windowNibName: NSNib.Name(rawValue: "SignIn"))
        os_log("Set mech for loginwindow", log: checkADLog, type: .debug)
        signIn.mech = mech
        if let domain = self.managedDomain {
            os_log("Set managed domain for loginwindow", log: checkADLog, type: .debug)
            signIn.domainName = domain.uppercased()
        }
        if let isSSLRequired = self.isSSLRequired {
            os_log("Set SSL required", log: checkADLog, type: .debug)
            signIn.isSSLRequired = isSSLRequired
        }
        let windowTest = signIn.window
        if windowTest == nil {
            os_log("Could not create login window UI", log: checkADLog, type: .default)
        }
        os_log("Displaying window", log: checkADLog, type: .debug)
        NSApp.runModal(for: signIn.window!)
        os_log("CheckAD mech complete", log: checkADLog, type: .debug)
    }
}
