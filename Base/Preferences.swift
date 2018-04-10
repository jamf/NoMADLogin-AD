//
//  Preferences.swift
//  NoMADLoginAD
//
//  Created by Josh Wisenbaker on 1/10/18.
//  Copyright © 2018 NoMAD. All rights reserved.
//

import Foundation

enum Preferences: String {
    /// The desired AD domain as a `String`.
    case ADDomain
    /// A filesystem path to a background image as a `String`.
    case BackgroundImage
    /// Should new users be created as local administrators? Set as a `Bool`.
    case CreateAdminUser
    /// Should existing mobile accounts be converted into plain local accounts? Set as a Bool`.
    case DemobilizeUsers
    /// Should FDE be enabled at first login on APFS disks? Set as a `Bool`.
    case EnableFDE
    /// Should the PRK be saved to disk for the MDM Escrow Service to collect? Set as a `Bool`.
    case EnableFDERecoveryKey
    /// Ignore sites in AD. This is a compatibility measure for AD installs that have issues with sites. Set as a `Bool`.
    case IgnoreSites
    /// Force LDAP lookups to use SSL connections. Requires certificate trust be established. Set as a `Bool`.
    case LDAPOverSSL
    /// A filesystem path to an image to display on the login screen as a `String`.
    case LoginLogo
    /// Should NoLo display a macOS-style login screen instead of a window? Set as a `Bool`,
    case LoginScreen
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

    os_log("No NoLoAD preferences found. Checking new menu.nomad.login.ad", type: .debug)

    if let preference = UserDefaults(suiteName: "menu.nomad.login.ad")?.value(forKey: key.rawValue)  {
        os_log("Found managed preference: %{public}@", type: .debug, key.rawValue)
        return preference
    }
    return nil
}
