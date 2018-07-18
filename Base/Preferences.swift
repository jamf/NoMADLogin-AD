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
    /// A string to show as the placeholder in the Username textfield
    case UsernameFieldPlaceholder
    /// A filesystem path to a background image as a `String`.
    case BackgroundImage
    /// The alpha value of the background image as an `Int`.
    case BackgroundImageAlpha
    /// Should new users be created as local administrators? Set as a `Bool`.
    case CreateAdminUser
    /// List of groups that should have its members created as local administrators. Set as an Array of Strings of the group name.
    case CreateAdminIfGroupMember
    /// Should existing mobile accounts be converted into plain local accounts? Set as a Bool`.
    case DemobilizeUsers
    /// Should FDE be enabled at first login on APFS disks? Set as a `Bool`.
    case EnableFDE
    /// Should the PRK be saved to disk for the MDM Escrow Service to collect? Set as a `Bool`.
    case EnableFDERecoveryKey
    /// Path for where the EULA acceptance info goes
    case EULAPath
    /// Text for EULA as a `String`.
    case EULAText
    /// Headline for EULA as a `String`.
    case EULATitle
    /// Subhead for EULA as a `String`.
    case EULASubTitle
    /// Ignore sites in AD. This is a compatibility measure for AD installs that have issues with sites. Set as a `Bool`.
    case IgnoreSites
    /// Adds a NoMAD entry into the keychain. `Bool` value.
    case KeychainAddNoMAD
    /// Should NoLo create a Keychain if it doesn't exist. `Bool` value.
    case KeychainCreate
    /// Should NoLo reset the Keychain if the login pass doesn't match. `Bool` value.
    case KeychainReset
    /// Force LDAP lookups to use SSL connections. Requires certificate trust be established. Set as a `Bool`.
    case LDAPOverSSL
    /// A filesystem path to an image to display on the login screen as a `String`.
    case LoginLogo
    /// A Base64 encoded string of an image to display on the login screen.
    case LoginLogoData
    /// Should NoLo display a macOS-style login screen instead of a window? Set as a `Bool`,
    case LoginScreen
    /// A filesystem path to an image to set the user profile image to as a `String`
    case UserProfileImage
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
