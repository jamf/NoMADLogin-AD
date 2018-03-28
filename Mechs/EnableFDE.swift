//
//  EnableFDE.swift
//  NoMADLoginAD
//
//  Created by Admin on 2/5/18.
//  Copyright © 2018 NoMAD. All rights reserved.
//

import Cocoa

class EnableFDE : NoLoMechanism {
    
    // basic mech to enable FileVault
    // needs to be a separate mech b/c it needs to run after loginwindow:done
    
    @objc  func run() {
        
        os_log("Running EnableFDE mech.", log: enableFDELog, type: .debug)
        
        // FileVault
        
        if getManagedPreference(key: .EnableFDE) as? Bool == true {
            enableFDE()
        }
        
        // Always let login through
        
        let _ = allowLogin()
    }
    
    fileprivate func enableFDE() {
        
        // check to see if boot volume is AFPS, otherwise do nothing
        
        if volumeAPFS() {
            
            // enable FDE on volume by using fdesetup
            
            os_log("Enabling FileVault", log: enableFDELog, type: .default)
            
            let userArgs = [
                "Username" : nomadUser ?? "",
                "Password" : nomadPass ?? "",
                ]
            
            var userInfo : Data
            
            do {
                userInfo = try PropertyListSerialization.data(fromPropertyList: userArgs,
                                                              format: PropertyListSerialization.PropertyListFormat.xml,
                                                              options: 0)
            } catch {
                os_log("Unable to create fdesetup arguments.", log: enableFDELog, type: .error)
                return
            }
            
            let inPipe = Pipe.init()
            let outPipe = Pipe.init()
            let errorPipe = Pipe.init()
            
            let task = Process.init()
            task.launchPath = "/usr/bin/fdesetup"
            task.arguments = ["enable", "-outputplist", "-inputplist"]
            
            task.standardInput = inPipe
            task.standardOutput = outPipe
            task.standardError = errorPipe
            task.launch()
            inPipe.fileHandleForWriting.write(userInfo)
            inPipe.fileHandleForWriting.closeFile()
            task.waitUntilExit()
            
            let outputData = outPipe.fileHandleForReading.readDataToEndOfFile()
            outPipe.fileHandleForReading.closeFile()
            
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8)
            errorPipe.fileHandleForReading.closeFile()
            
            let output = NSString(data: outputData, encoding: String.Encoding.utf8.rawValue)! as String
                    
            // write out the PRK if asked to
            
            if getManagedPreference(key: .EnableFDERecoveryKey) as? Bool == true {
                do {
                    os_log("Attempting to write key to: %{public}@", log: enableFDELog, type: .debug, "/var/db/.NoMADFDESetup")
                    try output.write(toFile: "/var/db/.NoMADFDESetup", atomically: true, encoding: String.Encoding.ascii)
                } catch {
                    os_log("Unable to finish fdesetup: %{public}@", log: enableFDELog, type: .error, errorMessage ?? "Unkown error")
                }
            }
        } else {
            os_log("Boot volume is not APFS, skipping FDE.", log: enableFDELog, type: .debug)
        }
    }
    
    fileprivate func volumeAPFS() -> Bool {
        
        // get shared workspace manager
        
        let ws = NSWorkspace.shared
        
        var description: NSString?
        var type: NSString?
        
        let err = ws.getFileSystemInfo(forPath: "/", isRemovable: nil, isWritable: nil, isUnmountable: nil, description: &description, type: &type)
        
        if !err {
            os_log("Error determining file system", log: enableFDELog, type: .error)
            return false
        }
        
        if type == "apfs" {
            os_log("Filesystem is APFS, enabling FileVault", log: enableFDELog)
            return true
        } else {
            os_log("Filesystem is not APFS, skipping FileVault", log: enableFDELog, type: .error)
            return false
        }
    }
}
