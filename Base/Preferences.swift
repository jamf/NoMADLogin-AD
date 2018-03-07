//
//  Preferences.swift
//  NoMADLoginAD
//
//  Created by Josh Wisenbaker on 1/10/18.
//  Copyright © 2018 NoMAD. All rights reserved.
//

import Foundation

enum Preferences: String {
    case ADDomain
    case CreateAdminUser
    case DemobilizeUsers
    case EnableFDE
    case EnableFDERecoveryKey
    case LDAPOverSSL
}


/// Looks in the `com.trusourcelabs.NoMAD`, `menu.nomad.NoMADLoginAD`, and `menu.nomad.login.ad` Defaults domains for a preference key.
/// This domain will override anything the user enters in the username field.
///
/// - Parameter key: A member of the `Preferences` enum
/// - Returns: The value, if any, for the preference. If no preference is set, returns `nil`
func getManagedPreference(key: Preferences) -> Any? {
    if let preference = UserDefaults(suiteName: "com.trusourcelabs.NoMAD")?.value(forKey: key.rawValue)  {
        os_log("Found managed preference: %{public}@", type: .debug, key.rawValue)
        return preference
    }

    os_log("No NoMAD preferences found. Checking NoLoAD", type: .debug)

    if let preference = UserDefaults(suiteName: "menu.nomad.NoMADLoginAD")?.value(forKey: key.rawValue)  {
        os_log("Found managed preference: %{public}@", type: .debug, key.rawValue)
        return preference
    }

    os_log("No NoLoAD preferences found. Checking new nomad.login", type: .debug)

    if let preference = UserDefaults(suiteName: "menu.nomad.nomad.login")?.value(forKey: key.rawValue)  {
        os_log("Found managed preference: %{public}@", type: .debug, key.rawValue)
        return preference
    }
    return nil
}
