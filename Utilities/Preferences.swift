//
//  Preferences.swift
//  NoMAD Pro
//
//  Created by Joel Rennich on 4/24/17.
//  Copyright © 2017 Orchard & Grove. All rights reserved.
//

import Foundation

/// A convenience name for `UserDefaults.standard`

let defaults = UserDefaults.standard

/*
 
 // Prefrences and what they do

 AuthServer - String - Authentication server to use - "dev-650129.oktapreivew.com"
 AuthType - String - Authentication method to use - "Okta"
 GetHelpType - String - What method the Get Help menu uses - "Web"
 GetHelpOptions - String - configuratin for the Get Help menu
 
 -- hide menus --
 
 HideChangePassword - Bool - removes the Change Password menu
 HideGetHelp - Bool - Removes the Get Help menu
 HideGetSoftware - Bool - Removes the Get Software menu
 HideLockScreen - Bool - Removes the Lock Screen menu
 HidePreferences - Bool - Remvoes the Preferences menu
 HideQuit - Bool - Removes the Quit menu
 
 FirstRunDone - Bool - Determines if the first run window has been shown or not
 
 KeychainItems - [String] - Array of keychain item names to update when the password is updated.
 
 LocalPasswordSync - Bool - Determines if the network password is synced to the local password
 LocalPasswordSyncMessage - String - Text to display in the password sync window
 
 -- rename menus --
 
 MenuChangePassword - String - Title of the Change Password menu
 MenuGetHelp - String - Title of the Get Help menu
 MenuGetSoftware - String - Title of the Get Software menu
 MenuLockScreen - String - Title of the Lock Screen menu
 MenuSignIn - String - Title of the Sign In menu
 
 SelfServicePath - String - Path to Self Service app if not using one of the supported apps already
 SignInCommand - String - Script to be executed on successful sign in
 TitleSignIn - String - Title of the Sign In window
 UseKeychain - Bool - Determines if the password is stored in the user's keychain or not
 UserFirstName - String - First name of the user
 UserLastName - String - Last name of the user
 UserLoginName - String - Login name of the user
 WarnOnPasswordExpiration - Bool - Determines if NoMAD will warn the user that their password will expire soon
*/


enum Preferences {

    static let adDomain = "ADDomain"
    static let allowTokend = "AllowTokend"
    static let allowSoftCerts = "AllowSoftCerts"
    static let authServer = "AuthServer"
    static let authType = "AuthType"
    static let automaticRenew = "AutomaticRenew"
    static let automaticRenewTime = "AutomaticRenewTime"
    
    static let changePasswordCommand = "ChangePasswordCommand"
    static let cnFilterString = "CNFilterString"

    static let defaultKerberosDomain = "DefaultKerberosDomain"
    static let dontShowWelcome = "DontShowWelcome"
    
    static let firstRunDone = "FirstRunDone"
    static let forceTokend = "ForceTokend"

    static let getHelpType = "GetHelpType"
    static let getHelpOptions = "GetHelpOptions"

    static let hideAbout = "HideAbout"
    static let hideAccounts = "HideAccounts"
    static let hideAdminCheckout = "HideAdminCheckout"
    static let hideChangePassword = "HideChangePassword"
    static let hideGetSoftware = "HideGetSoftware"
    static let hideGetHelp = "HideGetHelp"
    static let hideLockScreen = "HideLockScreen"
    static let hidePreferences = "HidePreferences"
    static let hideQuit = "HideQuit"

    static let identities = "Identities"

    static let kerberosRealm = "KerberosRealm"
    static let keychainItems = "KeychainItems"

    static let localPasswordSync = "LocalPasswordSync"
    static let localPasswordSyncMessage = "LocalPasswordSyncMessage"
    static let localPasswordSyncOnMatchOnly = "LocalPasswordSyncOnMatchOnly"

    static let menuAbout = "MenuAbout"
    static let menuAccounts = "MenuAccounts"
    static let menuAdminCheckout = "MenuAdminCheckout"
    static let menuChangePassword = "MenuChangePassword"
    static let menuGetHelp = "MenuGetHelp"
    static let menuGetSoftware = "MenuGetSoftware"
    static let menuLockScreen = "MenuLockScreen"
    static let menuPreferences = "MenuPreferences"
    static let menuSignIn = "MenuSignIn"
    static let messagePasswordChangePolicy = "MessagePasswordChangePolicy"
    
    static let nomadLEURL = "NoMADLEURL"

    static let passwordChangeCommand = "PasswordChangeCommand"
    static let passwordPolicy = "PasswordPolicy"
    static let periodicUpdateTime = "PeriodicUpdateTime"
    static let principalList = "PrincipalList"

    static let redirectURL = "RedirectURL"

    static let selfServicePath = "SelfServicePath"
    
    static let signedIn = "SignedIn"
    static let signInCommand = "SignInCommand"

    static let ticketsOnSignIn = "TicketsOnSignIn"
    static let titleSignIn = "TitleSignIn"

    static let useKeychain = "UseKeychain"
    static let userFirstName = "UserFirstName"
    static let userLastName = "UserLastName"
    static let userLoginName = "UserLoginName"

    static let warnOnPasswordExpiration = "WarnOnPasswordExpiration"
    static let warnOnCardRemoval = "WarnOnCardRemoval"
    static let warnonCardRemovalTime = "WarnOnCardRemovalTime"

    static let allKeys = [ Preferences.adDomain, Preferences.authServer, Preferences.authType, Preferences.getHelpOptions, Preferences.getHelpType, Preferences.hideChangePassword, Preferences.hideGetHelp, Preferences.hideGetSoftware, Preferences.hideLockScreen, Preferences.hidePreferences, Preferences.hideQuit, Preferences.identities, Preferences.kerberosRealm, Preferences.keychainItems, Preferences.localPasswordSync, Preferences.menuChangePassword, Preferences.menuGetHelp, Preferences.menuGetSoftware, Preferences.menuLockScreen, Preferences.menuPreferences, Preferences.menuSignIn, Preferences.passwordChangeCommand, Preferences.passwordPolicy, Preferences.redirectURL, Preferences.selfServicePath, Preferences.selfServicePath, Preferences.signInCommand, Preferences.ticketsOnSignIn, Preferences.titleSignIn, Preferences.useKeychain, Preferences.userFirstName, Preferences.userLastName, Preferences.userLoginName, Preferences.warnOnPasswordExpiration, Preferences.warnOnCardRemoval, Preferences.warnonCardRemovalTime]

}

func printAllPrefs() {
    for key in Preferences.allKeys {
        print("\t" + key + ": " + (defaults.string(forKey: key) ?? "Unset"))
    }
}
