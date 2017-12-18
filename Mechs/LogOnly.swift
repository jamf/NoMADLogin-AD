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
    
    @objc func run() {
        // starting with the context basics
        NSLog("%@", "User logging in: \(String(describing: username))")
        NSLog("%@", "UID of user logging in: \(String(describing: uid))")

        getArguments()
        getTokens()
        
        for item in contextKeys {
            let result = getContext(type: item)
            if result != nil {
                NSLog("%@", "Context Item \(item): \(String(describing: result))")
            }
        }
        
        for item in hintKeys {
            let result = getHint(type: HintType(rawValue: item)!)
            if result != nil {
                NSLog("%@", "Hint Item \(item): \(String(describing: result))")
            }
        }
        let _ = allowLogin()
    }
}
