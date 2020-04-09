# NoMAD Login AD

Hi everyone! You have found your way to the repo for **NoMAD Login AD**, or NoLoAD for short. This project can be seen as a companion to our other AD authentication product for macOS, [NoMAD](https://nomad.menu). You can use either one independently from each other, and both contain all the bits and pieces you need to talk to AD.

NoLoAD is a replacement login window for macOS 10.12 and higher. It allows you to login to a Mac using Active Directory accounts, without the need to bind the Mac to AD and suffer all the foibles that brings.

## About this release
The current production version of NoLoAD is 1.4.0

For those of you that are new to NoLo, the basic features are:

* You can login to a Mac using AD without being bound
* Just-in-time provisioning user provisioning to create a local account
* "Demobilization" of previously cached AD accounts
* Local accounts can always login
* Ability to enable FileVault on APFS without a logout
* Choose between a macOS-style loginscreen, or the older loginwindow types
* Customize the login screen with your own art and background
* Display a EULA for users to accept on login
* Create a keychain item for NoMAD

## What's new in 1.4.0
* `PasswordOverwriteSilent` a Boolean to determine if the password should be silently overwritten when the AD authentication succeeds, should be used in conjunction with `DenyLocal`.
* `ManageSecureTokens` a Boolean to determine if the SecureToken management capabilites should be enabled. This utilizes a service account which can be modified from default using the below optional preferences.
* `SecureTokenManagementEnableOnlyAdminUsers` a Boolean to determine if the SecureToken service account should only enable administrative users created with NoMAD Login.
* `SecureTokenManagementIconPath` a String to determine the path of the icon to be used for the user, default is `/Library/Security/SecurityAgentPlugins/NoMADLoginAD.bundle/Contents/Resources/NoMADFDEIcon.png`
* `SecureTokenManagementOnlyEnableFirstUser` a Boolean to determine if the NoMAD Login should only enable the first user that is eligable for a SecureToken, and delete the service account afterwards.
* `SecureTokenManagementFullName` a String to define a custom Full Name for the SecureToken service account, default is `NoMAD Login`
* `SecureTokenManagementUID` an Integer or String to define a custom UID for the SecureToken service account, default is `400`
* `SecureTokenManagementPasswordLocation` a String to define a custom password storage location for the SecureToken service account password, default is `/var/db/.nomadLoginSecureTokenPassword`
* `SecureTokenManagementPasswordLength` an Integer to define a custom SecureToken service account password length, default is `16`
* `SecureTokenManagementUsername` a String to define a custom username for the SecureToken service account, default is `_nomadlogin`
* Added an overwrite button to the sync password screen in the event the user does not remember their password, which bootstraps into the `PasswordOverwriteSilent` workflow - Reqest from @Ehlers299
* Fixed an extraneous password check in the user demobilization mechanism that would cause demobilizations when the user is logging in at the FV2 window to not function
* `DemobilizeSaveAltSecurityIdentities` a Boolean to determine if the `AltSecurityIdentities` user record attribute should be preserved, useful when moving from mobile accounts with smart card mapping implemented.
* `DemobilizeForcePasswordCheck` a Boolean to determine if a password input at the NoMAD login window will be required to demobilize, default is `false`
* `RecursiveGroupLookup` a Boolean to determine if group membership lookups should be done recursively, default is `false`
* `MigrateUsersHide` an array of Strings of the names of users that should be hidden from user migration canidates during selection
* `GuestUser` a Boolean to determine if guest users should be allowed to login, default is `false`
* `GuestUserAccounts` an array of Strings of names that can be entered into the username field to trigger a guest user creation, default is `["Guest", "guest"]`
* `GuestUserAccountPasswordPath` a String to define the path to write out the guest users randomly generated password, defaults is to not write it out
* `GuestUserFirst` a String to define the first name of the guest user account
* `GuestUserLast` a String to define the last name of the guest user account
* `AllowNetworkSelection` a Boolean to define if the network selection is hidden, default is `false`
* System information has been added as a hidden button in the lower left hand corner of the the NoMAD Login Window
* React to screen resolution changes better, but probably still not what it should be.
* Lowercase user supplied domain when checking against `AdditionalADDomains` so that the comparision is more sane.
* `AdditionalADDomainList` an array of Strings that will cause a pull down domain menu in the Sign In window. Users can select a domain from the menu and then only enter the shortname in the text field.
* Mapping of NT Domain to AD Domain via `NTtoADDomainMappings` a Dictionary of Strings, e.g. [ NOMAD: nomad.menu], would allow a user to sign in as "NOMAD\user" and that would be converted to "user@nomad.menu" before authenticating to AD.
* `AliasNTName` Bool to define if the user's NT style name is added as an alias to the local account during account creation.
* `AliasUPN` Bool to define if the users UPN is added as an alias to the local account during account creation.
* `DefaultSystemInformation` String to define the system information to be shown by default, options are `Serial`, `MAC`, `Hostname`, `SystemVersion`, and `IP`, default is nothing

## What's new in 1.3.1
* `UseCNForFullNameFallback` a Boolean that determines if to use CN as the fullname on the account when the givenName and sn fields are blank
* `PowerControlDisabled` a Boolean that determines if the powercontrol options should be disabled/hidden in the SignIn UI
* Updated the new user home directory creation to fully populate all expected folders in prep for Catalina
* `DisableFDEAutoLogin` now respected under the `com.apple.loginwindow` preference domain
* Fixed an issue with the German localization of the home directory

## What's new in 1.3.0
* `BackgroundImageAlpha` an Integer from 0-10 which determines the alpha value for the background image in 10% increments, i.e. a value of `3` would be a 30% alpha
This was broken before and is now fixed.
* `DenyLocal` Boolean determines if local user accounts are allowed to sign in, or if all auth is forced through AD.
* `DenyLocalExcluded` Array or strings of user shortnames that will be allowed to authenticate locally instead of via AD.
* `DenyLoginUnlessGroupMember` Array of strings of AD group names. When an AD user is authenticating, only allow login if the user is a member of one of these groups.
* `EnableFDERecoveryKeyPath` String of a folder path where the recovery key will be stored. NoLo will create this folder if it does not already exist.
* `EnableFDERekey` Boolean that determines if the FileVault personal recovery key should be rotated when a valid FileVault user signs in.
* `LDAPServers` Array of strings of LDAP servers that you would like to use for AD authentication instead of using SRV record lookup.
* `LoginLogoAlpha` an Integer from 0-10 which determines the alpha value for the logo image in 10% increments, i.e. a value of `3` would be a 30% alpha
This was broken before and is now fixed.
* `LoginLogoData` is working again.
* `NotifyLogStyle` Takes a string of `jamf`, `filewave`, `munki` or `none` and will add the appropriate log file to the the Notify mechanism.
* `ScriptPath` Path to a script for the RunScript mechanism to run.
* `ScriptArgs` Array of strings of arguments to give the script being run by the RunScript mechanism. `<<User>>` will be replaced with the current user's shortname, `<<First>>` with the current user's first name, `<<Last>>` with the current user's last name, `<<Principal>>` with the current user's Kerberos principal.
* `UseCNForFullName` Use the the user's cn from AD instead of attempting to create the user name from the first and last name attributes of the user's AD record.
* `UsernameFieldPlaceholder` text to place into the user field in the loginwindow to give a hint as to what to enter.
* `UserInputOutputPath` string determining the path where the `userinfo.plist` will be written.
* `UserInputUI` a rather complicated dictionary that contains the settings for up to 4 text fields and 4 pop up buttons that will be shown during the UserInput mechanism. Look in the ConfigSamples folder in the source for an example of this configuration profile.
* `UserInputLogo` path to a logo file to use for the UserInput mechanism.
* `UserInputTitle` string for the UserInput mechanism title.
* `UserInputMainText` string for the UserInput text.

### New Mechanisms
* `NoMADLoginAD:RunScript` will run a script of your choosing as set by the preferences. This is typically marked as `privileged` to allow the script to run as root.
* `NoMADLoginAD:Notify` runs the Notify screen. See the DEPNotify project for more information.
* `NoMADLoginAD:UserInput` displays up to 4 text fields and 4 pull down menus to allow the user to enter information during the login process.

### Other changes
* The Demobilize mechanism will work with mobile accounts from other services than just Apple's AD plugin.
* The Demobilze and Notify mechanisms can be used without the NoMAD Login login window UI.

## What's new in 1.2.2
* Built product with current Swift SDK.

## What's new in 1.2.1
* KeychainAdd mechanism also adds a `LastUser` value to the NoMAD preferences. This allows NoMAD to login on first launch. (#89)
* EULA mechanism should only run when expect now. (#108)
* authchanger updated to prevent garbage being entered into authorizationdb. (#109)

## What's new in 1.2.0
* Support for more than one managed domain (#97)
* Support for FDE passthrough from EFI unlock to the Desktop for FileVault (#74 & #82)
* KeychainAdd mechanism allows for NoLoAD to add a NoMAD Keychain item or reset the Login keychain if passwords don't match. (#79)
* EULA mechanism allows for user acceptance of terms to complete login process
* Blured effect layer over the background image at login can have alpha adjustments. (#71)
* The placeholder text in the username field can be changed. (#96)
* Admin user creation can be gated by groups. (#32)
* Users created by NoMAD Login have an account attribute added to indicate so. (#26)

Please file any issues, or requested features, in the [project issue tracker](https://gitlab.com/orchardandgrove-oss/NoMADLogin-AD/issues).

## How to get started
Getting started with NoLoAD is easy, but currently it takes a few steps.  It's also easy to revert to the Apple login window in case you run in to any issues.

### To install:

Installing is easy!

1. Download [NoMAD Login AD](https://files.nomad.menu/NoMAD-Login-AD.pkg).
2. You can just run the installer package that includes the `authchanger` tool and be done with it. The only reason not to do this is if you have made other changes to the `system.login.console` rights.
3. Define your `ADDomain` in the `menu.nomad.login.ad` preference domain.

Now you should be able to logout and find yourself staring at the majesty of NoMAD Login!

### Building from source:
Take a look in our Wiki to see how to [get started with Carthage and Xcode](https://gitlab.com/orchardandgrove-oss/NoMADLogin-AD/wikis/Development/Building-From-Source).

## Using NoLoAD
Using NoMAD Login AD is easy. Just enter your AD username and password in `username@domain` format and your password. If the domain is visible on the network, NoMAD Login AD will discover the domain details and then authenticate your account. Once that is done it will create a local account that matches the AD one and complete the login. You can then use NoMAD as you normally would from the menu bar to keep the accounts synchronized.

Since the created account is a local one, you won't suffer any network delays when logging in or unlocking your Mac. From the login window, NoLoAD will simply defer to the regular local login process for any local accounts. At this point you could even just go back to the Apple Loginwindow, but where is the fun in that?

Enticing you to stay now is the ability to customize the login experience with your own logos and background images. More info, and a gallery of options, can be found in the [wiki](https://gitlab.com/orchardandgrove-oss/NoMADLogin-AD/wikis/home).

## I want to get off this crazy ride!
When you decide that you've had enough it's easy to go back to the standard login window.

The easy way is to simply run `/usr/local/bin authchanger -reset`, followed by `killall -HUP loginwindow` to reload the login window.

# Thanks
Thanks to all of you for trying NoMAD Login AD! Please let us know about issues and features in the issue tracker. You can also find us on Slack in [nomad](https://macadmins.slack.com/messages/C1Y2Y14QG) and [nomad-login](https://macadmins.slack.com/messages/C88MFDLV8).
