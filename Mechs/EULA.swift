//
//  EULA.swift
//  NoMADLoginOkta
//
//  Created by Joel Rennich on 3/31/18.
//  Copyright © 2018 Orchard & Grove. All rights reserved.
//

import Foundation
import Cocoa

class EULA : NoLoMechanism {
    
    // simple mechanism to show the EULA UI
    
    @objc func run() {
        
        os_log("EULA mech starting", log: eulaLog, type: .debug)
        guard getManagedPreference(key: .EULAText) != nil else {
            os_log("No EULA text was set", log: eulaLog, type: .debug)
            os_log("EULA mech complete", log: eulaLog, type: .debug)
            _ = allowLogin()
            return
        }
        
        os_log("Activating app", log: eulaLog, type: .debug)
        NSApp.activate(ignoringOtherApps: true)
        os_log("Loading XIB", log: eulaLog, type: .debug)
        let eula = EULAUI(windowNibName: NSNib.Name("EULAUI"))
        eula.mech = mech
        
        let windowTest = eula.window
        if windowTest == nil {
            os_log("Could not create EULA window UI", log: eulaLog, type: .default)
        }
        os_log("Displaying window", log: eulaLog, type: .debug)
        
        //NSApp.runModal(for: eula.window!)
        
        let modalSession = NSApp.beginModalSession(for: eula.window!)
        
        while NSApp.runModalSession(modalSession) == .continue {
            
            // let things run for a 1/10 second before going back
            
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        }
        
        NSApp.endModalSession(modalSession)
        
        os_log("EULA mech complete", log: eulaLog, type: .debug)
    }
}
