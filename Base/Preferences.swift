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
    /// Allows appending of other domains at the loginwindow. Set as a `Bool` to allow any, or as an Array of Strings to whitelist
    case AdditionalADDomains
    /// A filesystem path to a background image as a `String`.
    case BackgroundImage
    /// An image to display as the background image as a Base64 encoded `String`.
    case BackgroundImageData
    /// The alpha value of the background image as an `Int`.
    case BackgroundImageAlpha
    /// Should new users be created as local administrators? Set as a `Bool`.
    case CreateAdminUser
    /// List of groups that should have its members created as local administrators. Set as an Array of Strings of the group name.
    case CreateAdminIfGroupMember
    /// Should existing mobile accounts be converted into plain local accounts? Set as a Bool`.
    case DemobilizeUsers
    /// Dissallow local auth, and always do network authentication
    case DenyLocal
    /// Users to allow locally when DenyLocal is on
    case DenyLocalExcluded
    /// List of groups that should have it's members allowed to sign in. Set as an Array of Strings of the group name
    case DenyLoginUnlessGroupMember
    /// Should FDE be enabled at first login on APFS disks? Set as a `Bool`.
    case EnableFDE
    /// Should the PRK be saved to disk for the MDM Escrow Service to collect? Set as a `Bool`.
    case EnableFDERecoveryKey
    // Specify a custom path for the recovery key
    case EnableFDERecoveryKeyPath
    // Should we rotate the PRK
    case EnableFDERekey
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
    /// Force specific LDAP servers instead of finding them via DNS
    case LDAPServers
    /// Fallback to local auth if the network is not available
    case LocalFallback
    /// A filesystem path to an image to display on the login screen as a `String`.
    case LoginLogo
    /// Alpha value for the login logo
    case LoginLogoAlpha
    /// A Base64 encoded string of an image to display on the login screen.
    case LoginLogoData
    /// Should NoLo display a macOS-style login screen instead of a window? Set as a `Bool`,
    case LoginScreen
    /// should we migrate users?
    case Migrate
    /// should we hide users when we migrate?
    case MigrateUsersHide
    /// If Notify should add additional logging
    case NotifyLogStyle
    /// Path to script to run, currently only one script path can be used, if you want to run this multiple times, keep the logic in your script
    case ScriptPath
    /// Arguments for the script, if any
    case ScriptArgs
    /// Use the CN from AD as the full name
    case UseCNForFullName
    /// A string to show as the placeholder in the Username textfield
    case UsernameFieldPlaceholder
    /// A filesystem path to an image to set the user profile image to as a `String`
    case UserProfileImage
    
    //UserInput bits
    
    case UserInputOutputPath
    case UserInputUI
    case UserInputLogo
    case UserInputTitle
    case UserInputMainText
}


/// Looks in the `com.trusourcelabs.NoMAD`, `menu.nomad.NoMADLoginAD`, and `menu.nomad.login.ad` Defaults domains for a preference key.
/// This domain will override anything the user enters in the username field.
///
/// - Parameter key: A member of the `Preferences` enum
/// - Returns: The value, if any, for the preference. If no preference is set, returns `nil`
func getManagedPreference(key: Preferences) -> Any? {
    
    os_log("Checking menu.nomad.login.ad preference domain.", type: .debug)

    if let preference = UserDefaults(suiteName: "menu.nomad.login.ad")?.value(forKey: key.rawValue)  {
        os_log("Found managed preference: %{public}@", type: .debug, key.rawValue)
        return preference
    }

    os_log("No menu.nomad.login.ad preference found. Checking menu.nomad.NoMADLoginAD", type: .debug)

    if let preference = UserDefaults(suiteName: "menu.nomad.NoMADLoginAD")?.value(forKey: key.rawValue)  {
        os_log("Found managed preference: %{public}@", type: .debug, key.rawValue)
        return preference
    }
    
    os_log("No menu.nomad.NoMADLoginAD preference found. Checking com.trusourcelabs.NoMAD", type: .debug)

    if let preference = UserDefaults(suiteName: "com.trusourcelabs.NoMAD")?.value(forKey: key.rawValue)  {
        os_log("Found managed preference: %{public}@", type: .debug, key.rawValue)
        return preference
    }
    
    return nil
}
