//
//  LogOnly.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/23/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Foundation
import Security.AuthorizationTags
import SecurityInterface.SFAuthorizationPluginView
import os.log

/// AuthorizationPlugin mechanism that simply logs the hint and context values that are being passed around.
class LogOnly : NoLoMechanism {
    
    let contextKeys = [kAuthorizationEnvironmentUsername,
                       kAuthorizationEnvironmentPassword,
                       kAuthorizationEnvironmentShared,
                       kAuthorizationRightExecute,
                       kAuthorizationEnvironmentIcon,
                       kAuthorizationEnvironmentPrompt]
    
    let hintKeys = ["uid",
                    "gid",
                    "longname",
                    "shell",
                    "authorize-right",
                    "authorize-rule",
                    "client-path",
                    "client-pid",
                    "client-type",
                    "client-uid",
                    "client-pid",
                    "tries",
                    "suggested-user",
                    "require-user-in-group",
                    "reason",
                    "token-name",
                    "afp_dir",
                    "kerberos-principal",
                    "mountpoint",
                    "new-password",
                    "show-add-to-keychain",
                    "add-to-keuychain",
                    "Home_Dir_Mount_Result",
                    "homeDirType",
                    "noMADUser",
                    "noMADFirst",
                    "noMADLast",
                    "noMADFull"]
    
    // class to iterate anything in the context and hits and print them out
    // heavily influenced by the Apple NullAuth sample code
    
    @objc  func run() {
        os_log("LogOnly mech starting", log: loggerMech, type: .debug)

        os_log("Printing security context arguments", log: loggerMech, type: .debug)
        getArguments()
        os_log("Printing LAContext Tokens", log: loggerMech, type: .debug)
        getTokens()

        os_log("Printing all context values:", log: loggerMech, type: .debug)
        for item in contextKeys {
            if let result = getContextString(type: item) {
                os_log("Context item %{public}@: %{public}@", log: loggerMech, type: .default, item, result)
            }
        }

        os_log("Printing all hint values:", log: loggerMech, type: .debug)
        for item in hintKeys {
            if let result = getHint(type: HintType(rawValue: item)!) as? String {
                os_log("Hint item %{public}@: %{public}@", log: loggerMech, type: .default, item, result)
            }
        }

        let _ = allowLogin()
        os_log("LogOnly mech complete", log: loggerMech, type: .debug)
    }
}
