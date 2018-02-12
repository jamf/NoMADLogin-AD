# NoMAD Login AD

Hi everyone! You have found your way to the repo for **NoMAD Login AD**, or NoLoAD for short. This project can be seen as a companion to our other AD authentication product for macOS, [NoMAD](https://nomad.menu). You can use either one independently from each other, and both contain all the bits and pieces you need to talk to AD.

NoLoAD is a replacement login window for macOS 10.12 and higher. **(Currently there are known performance issues with 10.12)** It allows you to login to a Mac using Active Directory accounts, without the need to bind the Mac to AD and suffer all the foibles that brings.

## About this release
NoLoAD is currently at a Beta release for 1.0 feature completeness! Please test the build and report any issues you see. There are several known issues and enhancements we are working on for the 1.1 release and you can see those in the [1.1 Milestone](https://gitlab.com/orchardandgrove-oss/NoMADLogin-AD/milestones/5).

For those of you that are new here the basic features are:

* You can login to a Mac using AD without being bound
* Just-in-time provisioning user provisioning to create a local account
* "Demobilization" of previously cached AD accounts
* Local accounts can always login

Please file any issues, or requested features, in the [project issue tracker](https://gitlab.com/orchardandgrove-oss/NoMADLogin-AD/issues).

## How to get started
Getting started with NoLoAD is easy, but currently it takes a few steps. Be sure to have ssh enabled on your test Mac or VM so that you can still connect and revert to the Apple login window in case you run in to any issues.

### To install:
1. Download the Beta 1.0 archive [NoMAD_Login-AD_Beta_1.0.zip](/uploads/04329564dedcc1a291cec02915d8f1d4/NoMAD_Login-AD_Beta_1.0.zip)
2. Make sure that you have SSH enabled on your test Mac.
3. Make sure that you can login to your test Mac with SSH.
4. Copy the NoMADLoginAD.bundle to the /Library/Security/SecurityAgentPlugins folder.

Now we need to configure the AuthorizationDB so that the NoLoAD bundle will load at the login window. We've provided some scripts and templates to make this easy to do and easy to undo.

1. Open a Terminal window in the evaluate-mechanisms folder of the Beta 1.0 archive.
2. Run `sudo ./loadAD.bash` to load in the code bundle. All this script does is run the security command to load in the `console-ad` file to AuthorizationDB.

Now you should be able to logout and find yourself staring at the majesty of NoMAD Login.
## Using NoLoAD
Using NoMAD Login AD is easy. Just enter your AD username and password in `username@domain` format and your password. If the domain is visible on the network, NoMAD Login AD will discover the domain details and then authenticate your account. Once that is done it will create a local account that matches the AD one and complete the login. You can then use NoMAD as you normally would from the menu bar to keep the accounts synchronized.

Since the created account is a local one, you won't suffer any network delays when logging in or unlocking your Mac. From the login window, NoLoAD will simply defer to the regular local login process for any local accounts.

## I want to get off this crazy ride!
When you decide that you've had enough it's easy to go back to the standard login window.

1. Open a Terminal window in the evaluate-mechanisms folder of the Beta 1.0 archive.
2. Run `sudo ./resetDB.bash` to reload the default `system.login.console` mechanisms into the AuthorizationDB.
3. If you've had to do this from a SSH session (Remember setting that up before?) you can them simply run `sudo killall loginwindow` in order to restart the login window to the defaults.

## What's new
* Moved AD Framework into project for easy building.
* Added EnableFDE mech for VileVault on APFS.
* Added PowerControl mech for Sleep, Restart, and Shut down.
* Fixed user home creation and added home localization.
* Added require SSL preference.
* Adoped autolayout.
* Support for forced password change at login added.
* Fixed typo in naming of _writers_passwd attribute.


## Known issues
When logging in on 10.12, the first login for a newly created user may take a long time. Like several minutes long. We are working with Apple to understand why as it happens with users created with NoLoAD or System Preferences and it does not occur on 10.13.

# Thanks
Thanks to all of you for testing NoMAD Login AD! Please let us know about issues and features in the issue tracker. You can also find us on Slack in [nomad](https://macadmins.slack.com/messages/C1Y2Y14QG) and [nomad-login](https://macadmins.slack.com/messages/C88MFDLV8).

Happy testing!