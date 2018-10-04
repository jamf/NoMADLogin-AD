//
//  UserInput.swift
//  NoMADLoginAD
//
//  Created by Joel Rennich on 9/29/18.
//  Copyright © 2018 Orchard & Grove. All rights reserved.
//

import Foundation
import Cocoa

@objc class UserInput : NoLoMechanism {
    
    @objc func run() {
        // run the UI if we have the settings
        if let inputSettings = getManagedPreference(key: .UserInputUI) as? [ String : AnyObject ] {
            
            os_log("Activating app", log: userinputLog, type: .default)
            NSApp.activate(ignoringOtherApps: true)
            os_log("Loading XIB", log: userinputLog, type: .default)
            let userInput = UserInputUI(windowNibName: NSNib.Name(rawValue: "UserInputUI"))
            userInput.mech = mech
            userInput.inputSettings = inputSettings
            
            let windowTest = userInput.window
            if windowTest == nil {
                os_log("Could not create User Input window UI", log: userinputLog, type: .default)
            }
            os_log("Displaying window", log: userinputLog, type: .default)
            
            //NSApp.runModal(for: eula.window!)
            
            let modalSession = NSApp.beginModalSession(for: userInput.window!)
            
            while NSApp.runModalSession(modalSession) == .continue {
                
                // let things run for a 1/10 second before going back
                
                RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            }
            
            NSApp.endModalSession(modalSession)
            
        } else {
            _ = allowLogin()
            return
        }
    }
}
