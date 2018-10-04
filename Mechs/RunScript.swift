//
//  RunScript.swift
//  NoMADLoginAD
//
//  Created by Joel Rennich on 3/30/18.
//  Copyright © 2018 Orchard & Grove. All rights reserved.
//

import Foundation

class RunScript : NoLoMechanism {
    
    let kArgError = "ERROR"
    
    @objc func run() {
        os_log("RunScript mech starting", log: runScriptLog, type: .default)
        if let scriptPath = getManagedPreference(key: .ScriptPath) as? String {
            let task = Process.init()
            
            // check to make sure the path is there
            
            let fm = FileManager.default
            
            if fm.isExecutableFile(atPath: scriptPath) {
                task.launchPath = scriptPath
                
                if let args = getManagedPreference(key: .ScriptArgs) as? [String] {
                    task.arguments = args
                }
                
                do {
                    if #available(OSX 10.13, *) {
                        try task.run()
                    } else {
                        task.launch()
                    }
                    
                    // snooze for a second before we hit the next mechanism to let things start
                    
                    sleep(1)
                } catch {
                    os_log("Unable to run script.", log: runScriptLog, type: .default)
                }
            } else {
                // ScriptPath isn't executable
                os_log("Script path is not executable.", log: runScriptLog, type: .default)
            }
        } else {
            os_log("Unable to get path to script, allowing login.", log: runScriptLog, type: .default)
        }
        
        // always let login proceed
        _ = allowLogin()

    }
}
