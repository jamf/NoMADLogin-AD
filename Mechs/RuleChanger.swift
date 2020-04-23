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
    private let kRuleChangerMech = "NoMADLoginAD:RuleChanger,privileged"
    
    @objc func run() {
        os_log("Rule changer beginning check", log: ruleChangerLog, type: .debug)
        
        if FileManager.default.fileExists(atPath: kStashFile) {
            os_log("Rules need to be reset back to custom", log: ruleChangerLog, type: .debug)
            updateRules()
            allowLogin()
        } else if isResetPasswordSituation() || isSystemUpdate() {
            os_log("Resetting rules for system.login.console to default", log: ruleChangerLog, type: .debug)
            stashRules()
            _ = cliTask("/usr/local/bin/authchanger -reset -preLogin \(kRuleChangerMech)")
            _ = cliTask("/usr/bin/killall loginwindow")
            denyLogin()
        } else {
            os_log("Nothing to change, allowing login", log: ruleChangerLog, type: .debug)
            allowLogin()
        }
    }
    
    private func isResetPasswordSituation() -> Bool {
        os_log("Checking for password reset", log: ruleChangerLog, type: .error)
        return (getEFIUUID(key: "efilogin-reset-ident") != nil)
    }
    
    private func isSystemUpdate() -> Bool {
        os_log("Checking for System Update", log: ruleChangerLog, type: .error)
        return FileManager.default.fileExists(atPath: "/var/db/.StagedAppleUpgrade")
    }
    
    private func stashRules() {
        var rights: CFDictionary?
        let err = AuthorizationRightGet(kConsoleRight, &rights)
        os_log("Stashing current rule set", log: ruleChangerLog, type: .error)
        if let rights = rights as? [String:CFDictionary],
            err == errAuthorizationSuccess,
            let mechs = rights[kMechanisms] {
            
            let data = NSKeyedArchiver.archivedData(withRootObject: mechs)
            let fileURL = URL.init(fileURLWithPath: kStashFile)
            do {
                os_log("Writing rule stash file", log: ruleChangerLog, type: .error)
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
            var err = AuthorizationRightGet(kConsoleRight, &rights)
            if var rights = rights as? [String:AnyObject],
                err == errAuthorizationSuccess {
                rights[kMechanisms] = rules as AnyObject
                err = AuthorizationRightSet(getAuth(), kConsoleRight, rights as CFTypeRef, nil, nil, nil)
                os_log("Authorization Right Set Result: %{public}@", log: ruleChangerLog, type: .error, err.description)
                do {
                    os_log("Removing rule stash file", log: ruleChangerLog, type: .error)
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    os_log("Failed to remove rule stash file", log: ruleChangerLog, type: .error)
                }
            }
        }
    }
    
    private func getAuth() -> AuthorizationRef {
        os_log("Creating new AuthRef", log: ruleChangerLog, type: .error)
        var authRef : AuthorizationRef? = nil
        _ = AuthorizationCreate(nil, nil, AuthorizationFlags(rawValue: 0), &authRef)
        return authRef!
    }
}
