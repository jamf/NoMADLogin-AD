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
    /// list of domains to show in the domain pull down
    case AdditionalADDomainList
    /// add user's NT domain name as an alias to newly created accounts
    case AliasNTName
    /// add user's UPN as an alias to newly created accounts
    case AliasUPN
    /// Allow network select button on login window
    case AllowNetworkSelection
    /// Allow network text
    case AllowNetworkText
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
    /// Should existing mobile accounts be converted into plain local accounts? Set as a `Bool`.
    case CustomNoMADLocation
    /// If defined it specifies the custom location of the application to be given access to the keychain item. Set as a `String`
    case DemobilizeUsers
    /// Should we always have a password already set up before demobilizing
    case DemobilizeForcePasswordCheck
    /// Should we preserve the AltSecurityIdentities OD attribute during demobilization
    case DemobilizeSaveAltSecurityIdentities
    /// Dissallow local auth, and always do network authentication
    case DenyLocal
    /// Users to allow locally when DenyLocal is on
    case DenyLocalExcluded
    /// List of groups that should have it's members allowed to sign in. Set as an Array of Strings of the group name
    case DenyLoginUnlessGroupMember
    /// Defines which system inforation should be showed by default. Set as `String`.
    case DefaultSystemInformation
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
    /// Allow for guest accounts
    case GuestUser
    /// the accounts to allow as an array of strings
    case GuestUserAccounts
    /// where to put the guest user password
    case GuestUserAccountPasswordPath
    /// First name for the guest user
    case GuestUserFirst
    /// Last name for  the guest user
    case GuestUserLast
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
    /// If the create User mech should manage the SecureTokens with a service account
    case ManageSecureTokens
    /// If Notify should add additional logging
    case NotifyLogStyle
    /// NT Domain to AD domain mappings
    case NTtoADDomainMappings
    /// should we migrate users?
    case Migrate
    /// should we hide users when we migrate?
    case MigrateUsersHide
    /// If the powercontrol options should be disabled in the SignIn UI
    case PowerControlDisabled
    /// should we recursively looku groups at login
    case RecursiveGroupLookup
    /// Path to script to run, currently only one script path can be used, if you want to run this multiple times, keep the logic in your script
    case ScriptPath
    /// Arguments for the script, if any
    case ScriptArgs
    /// Should NoMAD Login enable all users that login with with a secure token as a `Bool`
    case SecureTokenManagementEnableOnlyAdminUsers
    /// Path of the icon to be used for the Secure Token management user as `String`
    case SecureTokenManagementIconPath
    /// Should NoMAD Login only enable the first admin user that login with with a secure token as a `Bool`
    case SecureTokenManagementOnlyEnableFirstUser
    /// Full Name of the Secure Token Management user as a `String`
    case SecureTokenManagementFullName
    /// The UID to use for the Management Account as a `Int` or `String`
    case SecureTokenManagementUID
    /// The location to save and read the Secure Token management password as a `String`
    case SecureTokenManagementPasswordLocation
    /// Length fo the SecureToken Management User's password as an `Int`
    case SecureTokenManagementPasswordLength
    /// Username to use to for the securetoken management account as a `String`
    case SecureTokenManagementUsername
    /// Tool to use for UID numbers
    case UIDTool
    /// Use the CN from AD as the full name
    case UseCNForFullName
    /// A string to show as the placeholder in the Username textfield
    case UseCNForFullNameFallback
    /// Uses the CN as the fullname on the account when the givenName and sn fields are blank
    case UsernameFieldPlaceholder
    /// A filesystem path to an image to set the user profile image to as a `String`
    case UserProfileImage
    
    //UserInput bits
    
    case UserInputOutputPath
    case UserInputUI
    case UserInputLogo
    case UserInputTitle
    case UserInputMainText
    
    //Messages
    
    case MessagePasswordSync // what to show when the password needs to sync
    
    //Password update keys
      
      case PasswordOverwriteSilent // will silently update user password to new one
      case PasswordOverwriteOptional // allow the user to stomp on the password if interested

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
