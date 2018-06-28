//
//  SierraFixes.swift
//  NoMADLoginAD
//
//  Created by Josh Wisenbaker on 2/21/18.
//  Copyright © 2018 Orchard & Grove. All rights reserved.
//

import Foundation
import NoMAD_ADAuth

class SierraFixes: NoLoMechanism {

    @objc  func run() {
        os_log("Running SierraFixes mech.", log: sierraFixesLog, type: .debug)
        if #available(macOS 10.13, *) {
            _ = allowLogin()
            return
        }
        killMiniBuddy()
        os_log("MiniBuddy kill attempted, allow login", log: sierraFixesLog, type: .debug)
        _ = allowLogin()
        os_log("Completed SierraFixes mech.", log: sierraFixesLog, type: .debug)
    }

    fileprivate func killMiniBuddy() {
        os_log("OS version is less than 10.13 so we need to kill SetupAssistantSpringboard and MiniLauncher", log: sierraFixesLog, type: .debug)
        DispatchQueue.main.async {
            sleep(5)
            _ = cliTask("/usr/bin/killall SetupAssistantSpringboard")
            _ = cliTask("/usr/bin/killall MiniLauncher")
        }
    }
}
