# NoMAD Login AD

Hi everyone! You have found your way to the repo for **NoMAD Login AD**, or NoLoAD for short. This project can be seen as a companion to our other AD authentication product for macOS, [NoMAD](https://nomad.menu). You can use either one independently from each other, and both contain all the bits and pieces you need to talk to AD.

NoLoAD is a replacement login window for macOS 10.12 and higher. It allows you to login to a Mac using Active Directory accounts, without the need to bind the Mac to AD and suffer all the foibles that brings.

## About this release
The current production version of NoLoAD is 1.2.2. There are several enhancements we are working on for the 1.3 release and you can see those in the [1.3 Milestone](https://gitlab.com/orchardandgrove-oss/NoMADLogin-AD/milestones/8).

We would like to give a **huge** thanks to new contributor Joseph Rafferty. A lot of his pull requests really helped get the 1.2 release out the door.

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

1. Download [NoMAD Login AD](https://files.nomad.menu/NoMAD-Login-AD.zip).
2. You can just run the installer package that includes the `authchanger` tool and be done with it. The only reason not to do this is if you have made other changes to the `system.login.console` rights.

If you want to be more manual about the process for testing you can still use the older console scripts.

1. Copy the NoMADLoginAD.bundle to the /Library/Security/SecurityAgentPlugins folder.
2. Open a Terminal window in the evaluate-mechanisms folder of the NoLoAD archive.
3. Run `sudo ./loadAD.bash` to load in the code bundle. All this script does is run the security command to load in the `console-ad` file to AuthorizationDB.

Now you should be able to logout and find yourself staring at the majesty of NoMAD Login.

### Building from source:
Take a look in our Wiki to see how to [get started with Carthage and Xcode](https://gitlab.com/orchardandgrove-oss/NoMADLogin-AD/wikis/Development/Building-From-Source).

## Using NoLoAD
Using NoMAD Login AD is easy. Just enter your AD username and password in `username@domain` format and your password. If the domain is visible on the network, NoMAD Login AD will discover the domain details and then authenticate your account. Once that is done it will create a local account that matches the AD one and complete the login. You can then use NoMAD as you normally would from the menu bar to keep the accounts synchronized.

Since the created account is a local one, you won't suffer any network delays when logging in or unlocking your Mac. From the login window, NoLoAD will simply defer to the regular local login process for any local accounts. At this point you could even just go back to the Apple Loginwindow, but where is the fun in that?

Enticing you to stay now is the ability to customize the login experience with your own logos and background images. More info, and a gallery of options, can be found in the [wiki](https://gitlab.com/orchardandgrove-oss/NoMADLogin-AD/wikis/home).

## I want to get off this crazy ride!
When you decide that you've had enough it's easy to go back to the standard login window.

The easy way is to simply run `/usr/local/bin authchanger -reset`.

If you are testing with the console scripts, or just feel like doing it this way...
1. Open a Terminal window in the evaluate-mechanisms folder of the NoLoAD archive.
2. Run `sudo ./resetDB.bash` to reload the default `system.login.console` mechanisms into the AuthorizationDB.
3. If you've had to do this from a SSH session behind the NoLoAD login window you can simply run `sudo killall loginwindow` in order to restart the login window to the defaults.


# Thanks
Thanks to all of you for trying NoMAD Login AD! Please let us know about issues and features in the issue tracker. You can also find us on Slack in [nomad](https://macadmins.slack.com/messages/C1Y2Y14QG) and [nomad-login](https://macadmins.slack.com/messages/C88MFDLV8).
