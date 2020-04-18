//
//  RuleChanger.swift
//  NoMADLoginAD
//
//  Created by Joel Rennich on 4/17/20.
//  Copyright © 2020 Orchard & Grove. All rights reserved.
//

import Foundation
import os.log
import Security.AuthorizationDB
import NoMAD_ADAuth

class RuleChanger: NoLoMechanism {
    
    private let kConsoleRight = "system.login.console"
    private let kMechanisms = "mechanisms"
    private let kStashFile = "/var/db/NoMADAuthRules"

    @objc func run() {
        os_log("Rule changer beginning check", log: ruleChangerLog, type: .debug)
        
        if isResetPasswordSituation() || isSystemUpdate() {
            os_log("Resetting rules for system.login.console to default", log: ruleChangerLog, type: .debug)
            stashRules()
            _ = cliTask("/usr/local/bin/authchanger -reset")
            _ = cliTask("/usr/bin/killall loginwindow")
            denyLogin()
        } else if FileManager.default.fileExists(atPath: kStashFile) {
            os_log("Rules need to be reset back to custom", log: ruleChangerLog, type: .debug)
            _ = cliTask("/usr/bin/killall loginwindow")
            denyLogin()
        } else {
            os_log("Nothing to change, allowing login", log: ruleChangerLog, type: .debug)
            allowLogin()
        }
    }
    
    private func isResetPasswordSituation() -> Bool {
        getEFIUUID(key: "efilogin-reset-ident") != nil
    }
    
    private func isSystemUpdate() -> Bool {
        return FileManager.default.fileExists(atPath: "/var/db/.StagedAppleUpgrade")
    }
    
    private func stashRules() {
        var rights: CFDictionary?
        let err = AuthorizationRightGet(kConsoleRight, &rights)
        
        if let rights = rights as? [String:CFDictionary],
            err == errAuthorizationSuccess,
            let mechs = rights[kMechanisms],
            let data = try? NSKeyedArchiver.archivedData(withRootObject: mechs) {
            
            let fileURL = URL.init(fileURLWithPath: kStashFile)
            do {
                try data.write(to: fileURL)
                try FileManager.default.setAttributes([FileAttributeKey.posixPermissions : 0o750], ofItemAtPath: kStashFile)
            } catch {
                os_log("Errors writing rule stash file", log: ruleChangerLog, type: .error)
            }
        }
    }
    
    private func updateRules() {
        let fileURL = URL.init(fileURLWithPath: kStashFile)

        if let data = try? Data.init(contentsOf: fileURL),
            let rules = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String] {
             var rights: CFDictionary?
             let err = AuthorizationRightGet(kConsoleRight, &rights)
            
        }
    }
}
