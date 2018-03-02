# NoMAD Login AD

Hi everyone! You have found your way to the repo for **NoMAD Login AD**, or NoLoAD for short. This project can be seen as a companion to our other AD authentication product for macOS, [NoMAD](https://nomad.menu). You can use either one independently from each other, and both contain all the bits and pieces you need to talk to AD.

NoLoAD is a replacement login window for macOS 10.12 and higher. **(Currently there are known performance issues with 10.12)** It allows you to login to a Mac using Active Directory accounts, without the need to bind the Mac to AD and suffer all the foibles that brings.

## About this release
The current production version of NoLoAD is 1.0.0. There are several enhancements we are working on for the 1.1 release and you can see those in the [1.1 Milestone](https://gitlab.com/orchardandgrove-oss/NoMADLogin-AD/milestones/5).

For those of you that are new here the basic features are:

* You can login to a Mac using AD without being bound
* Just-in-time provisioning user provisioning to create a local account
* "Demobilization" of previously cached AD accounts
* Local accounts can always login
* Ability to enable FileVault2 on APFS without a logout.

Please file any issues, or requested features, in the [project issue tracker](https://gitlab.com/orchardandgrove-oss/NoMADLogin-AD/issues).

## How to get started
Getting started with NoLoAD is easy, but currently it takes a few steps.  It's also easy to revert to the Apple login window in case you run in to any issues.

### To install:
Currently NoLoAD is a simple manual install, but we will have a pkg install available soon if you aren't packaging it on your own.

Installing is easy!
1. Download the NoMAD Login AD 1.0 archive [NoMAD_Login_AD_1.0.zip](/uploads/6a495bcce1231161b512de9a445e5feb/NoMAD_Login_AD_1.0.zip)
2. Copy the NoMADLoginAD.bundle to the /Library/Security/SecurityAgentPlugins folder.

Now we need to configure the AuthorizationDB so that the NoLoAD bundle will load at the login window. We've provided some scripts and templates to make this easy to do and easy to undo.

1. Open a Terminal window in the evaluate-mechanisms folder of the NoLoAD archive.
2. Run `sudo ./loadAD.bash` to load in the code bundle. All this script does is run the security command to load in the `console-ad` file to AuthorizationDB.

Now you should be able to logout and find yourself staring at the majesty of NoMAD Login.

### Building from source:
Take a look in our Wiki to see how to [get started with Carthage and Xcode](https://gitlab.com/orchardandgrove-oss/NoMADLogin-AD/wikis/Development/Building-From-Source).

## Using NoLoAD
Using NoMAD Login AD is easy. Just enter your AD username and password in `username@domain` format and your password. If the domain is visible on the network, NoMAD Login AD will discover the domain details and then authenticate your account. Once that is done it will create a local account that matches the AD one and complete the login. You can then use NoMAD as you normally would from the menu bar to keep the accounts synchronized.

Since the created account is a local one, you won't suffer any network delays when logging in or unlocking your Mac. From the login window, NoLoAD will simply defer to the regular local login process for any local accounts.

## I want to get off this crazy ride!
When you decide that you've had enough it's easy to go back to the standard login window.

1. Open a Terminal window in the evaluate-mechanisms folder of the NoLoAD archive.
2. Run `sudo ./resetDB.bash` to reload the default `system.login.console` mechanisms into the AuthorizationDB.
3. If you've had to do this from a SSH session behind the NoLoAD login window you can simply run `sudo killall loginwindow` in order to restart the login window to the defaults.

## What's new in 1.0.0
* Removed Sleep button from Loginwindow (#45)
* Fixed login "arrow button" so that you can login with it. (#47)
* Added missing dsNative attributes when creating accounts. (#48)
* Adopted semantic versioning. (#49)

## Known issues
When logging in on 10.12, the first login for a newly created user may take a long time. Like several minutes long. We are working with Apple to understand why as it happens with users created with NoLoAD or System Preferences and it does not occur on 10.13.

# Thanks
Thanks to all of you for trying NoMAD Login AD! Please let us know about issues and features in the issue tracker. You can also find us on Slack in [nomad](https://macadmins.slack.com/messages/C1Y2Y14QG) and [nomad-login](https://macadmins.slack.com/messages/C88MFDLV8).