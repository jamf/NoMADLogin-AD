//
//  Notify.swift
//  NoMADLogin-AD
//
//  Created by Joel Rennich on 3/30/18.
//  Copyright © 2018 Orchard & Grove. All rights reserved.
//

import Foundation
import Cocoa

class Notify : NoLoMechanism {
    
    // class to launch the NoMAD Login Notify screen
    
    @objc func run() {
        
        NSApp.activate(ignoringOtherApps: true)
        let notifyWindow = NoLoNotify(windowNibName: NSNib.Name(rawValue: "NoLoNotify"))
        
        notifyWindow.mech = mech
        
        let windowTest = notifyWindow.window
        
        if windowTest == nil {
            NSLog("No dice on the window")
        }
        
        NSLog("Setting up window")
        
        let modalSession = NSApp.beginModalSession(for: notifyWindow.window!)
        
        while NSApp.runModalSession(modalSession) == .continue {
            
            // let things run for a 1/2 second before going back
            
            RunLoop.main.run(until: Date().addingTimeInterval(0.5))
            
        }
        
        NSLog("Stopping modal window")
        
        NSApp.endModalSession(modalSession)
    }
}
