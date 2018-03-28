//
//  PowerControl.swift
//  NoMADLoginAD
//
//  Created by Josh Wisenbaker on 2/9/18.
//  Copyright © 2018 NoMAD. All rights reserved.
//

import NoMAD_ADAuth
import IOKit
import IOKit.pwr_mgt

enum SpecialUsers: String {
    case noloSleep
    case noloRestart
    case noloShutdown
}

class PowerControl: NoLoMechanism {

    @objc   func run() {
        os_log("PowerControl mech starting", log: powerControlLog, type: .debug)

        guard let userName = nomadUser else {
            os_log("No username was set somehow, pass the login to the next mech.", log: powerControlLog, type: .debug)
            let _ = allowLogin()
            return
        }

        switch userName {
        case SpecialUsers.noloSleep.rawValue:
            os_log("Sleeping system.", log: powerControlLog, type: .debug)
            let port = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
            IOPMSleepSystem(port)
            IOServiceClose(port)
        case SpecialUsers.noloShutdown.rawValue:
            os_log("Shutting system down system", log: powerControlLog, type: .default)
            let _ = cliTask("/sbin/shutdown -h now")
        case SpecialUsers.noloRestart.rawValue:
            os_log("Restarting system", log: powerControlLog, type: .default)
            let _ = cliTask("/sbin/shutdown -r now")
        default:
            os_log("No special users named. pass login to the next mech.", log: powerControlLog, type: .default)
            let _ = allowLogin()
        }
    }
}
