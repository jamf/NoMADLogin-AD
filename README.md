# NoMAD Login AD

Hi everyone! You have found your way to the repo for **NoMAD Login AD**, or NoLoAD for short. This project can be seen as a companion to our other AD authentication product for macOS, [NoMAD](https://nomad.menu). You can use either one independently from each other, and both contain all the bits and pieces you need to talk to AD.

NoLoAD is a replacement login window for macOS 10.12 and higher. **(Currently there are known issues with 10.12)** It allows you to login to a Mac using Active Directory accounts, without the need to bind the Mac to AD and suffer all the foibles that brings.

## About this release
This is an early release of NoLoAD and is suitable for testing. It is not the feature complete version that will eventually ship, but right now it supports the core NoLoAD features.

* You can login to a Mac using AD without being bound
* Just-in-time provisioning user provisioning to create a local account
* Local accounts can always login

Please file any issues, or requested features, in the [project issue tracker](https://gitlab.com/macshome/NoMADLogin-AD/issues).

## How to get started
Getting started with NoLoAD is easy, but currently it takes a few steps. Be sure to have ssh enabled on your test Mac or VM so that you can still connect and revert to the Apple login window in case you run in to any issues.

### To install:
1. Download the Preview 3 archive [NoMAD_Login_AD_Preview_3.zip](https://gitlab.com/macshome/NoMADLogin-AD/uploads/472edf5370df1318776f55ae09751a7c/NoMAD_Login_AD_Preview_3.zip)
2. Make sure that you have SSH enabled on your test Mac.
3. Make sure that you can login to your test Mac with SSH.
4. Copy the NoMADLoginAD.bundle to the /Library/Security/SecurityAgentPlugins folder.

Now we need to configure the AuthorizationDB so that the NoLoAD bundle will load at the login window. We've provided some scripts and templates to make this easy to do and easy to undo.

1. Open a Terminal window in the evaluate-mechanisms folder of the Preview 3 archive.
2. Run `sudo ./loadAD.bash` to load in the code bundle. All this script does is run the security command to load in the `console-ad-usercreate` file to AuthorizationDB.

Now you should be able to logout and find yourself staring at the majesty of NoMAD Login.
## Using NoLoAD
Using NoMAD Login AD is easy. Just enter your AD username and password in `username@domain` format and your password. If the domain is visible on the network, NoMAD Login AD will discover the domain details and then authenticate your account. Once that is done it will create a local account that matches the AD one and complete the login. You can then use NoMAD as you normally would from the menu bar to keep the accounts synchronized.

Since the created account is a local one, you won't suffer any network delays when logging in or unlocking your Mac. From the login window, NoLoAD will simply defer to the regular local login process for any local accounts.

## I want to get off this crazy ride!
When you decide that you've had enough it's easy to go back to the standard login window.

1. Open a Terminal window in the evaluate-mechanisms folder of the Preview 1 archive.
2. Run `sudo ./resetDB.bash` to reload the default `system.login.console` mechanisms into the AuthorizationDB.
3. If you've had to do this from a SSH session (Remember setting that up before?) you can them simply run `sudo killall loginwindow` in order to restart the login window to the defaults.

## What's new
* [Defaults domain settings for local admin creation and managed AD domain names](https://gitlab.com/macshome/NoMADLogin-AD/wikis/preferences).

## Known issues
When logging in on 10.12, the first login for a newly created user may take a long time. Like several minutes long. We are working with Apple to understand why as it happens with users created with NoLoAD or System Preferences and it does not occur on 10.13.

# Thanks
Thanks to all of you for testing NoMAD Login AD! Please let us know about issues and features in the issue tracker. You can also find us on Slack in [nomad](https://macadmins.slack.com/messages/C1Y2Y14QG) and [nomad-login](https://macadmins.slack.com/messages/C88MFDLV8).

Happy testing!
