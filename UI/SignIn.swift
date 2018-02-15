//
//  SignIn.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/20/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Cocoa
import Security.AuthorizationPlugin
import os.log
import NoMAD_ADAuth

class SignIn: NSWindowController {
    
    //MARK: - setup properties
    var mech: MechanismRecord?
    var session: NoMADSession?
    var shortName = ""
    var domainName = ""
    var passString = ""
    var isDomainManaged = false
    var isSSLRequired = false
    
    //MARK: - IB outlets
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    @IBOutlet weak var domain: NSPopUpButton!
    @IBOutlet weak var signIn: NSButton!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var loginStack: NSStackView!
    @IBOutlet weak var passwordChangeStack: NSStackView!
    @IBOutlet weak var passwordChangeButton: NSButton!
    @IBOutlet weak var oldPassword: NSSecureTextField!
    @IBOutlet weak var newPassword: NSSecureTextField!
    @IBOutlet weak var newPasswordConfirmation: NSSecureTextField!
    
    //MARK: - UI Methods
    override func windowDidLoad() {
        os_log("Calling super.windowDidLoad", log: uiLog, type: .debug)
        super.windowDidLoad()
        self.window?.isMovable = false
        self.window?.canBecomeVisibleWithoutLogin = true
        os_log("Setting window level", log: uiLog, type: .debug)
        self.window?.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        self.window?.orderFrontRegardless()
        
        // make things look better
        os_log("Tweaking appearance", log: uiLog, type: .debug)
        self.window?.backgroundColor = NSColor.white
        self.window?.titlebarAppearsTransparent = true
        if !self.domainName.isEmpty {
            username.placeholderString = "Username"
            self.isDomainManaged = true
        }
        os_log("Become first responder", log: uiLog, type: .debug)
        username.becomeFirstResponder()
        os_log("Finsished loading loginwindow", log: uiLog, type: .debug)
    }

    /// When the sign in button is clicked we check a few things.
    ///
    /// 1. Check to see if the username field is blank, bail if it is. If not, animate the UI and process the user strings.
    ///
    /// 2. Check the user shortname and see if the account already exists in DSLocal. If so, simply set the hints and pass on.
    ///
    /// 3. Create a `NoMADSession` and see if we can authenticate as the user.
    @IBAction func signInClick(_ sender: Any) {
        os_log("Sign In button clicked", log: uiLog, type: .debug)
        if username.stringValue.isEmpty {
            os_log("No username entered", log: uiLog, type: .default)
            return
        }
        loginStartedUI()
        prepareAccountStrings()
        if NoLoMechanism.checkForLocalUser(name: shortName) {
            os_log("Allowing local user login for %{public}@", log: uiLog, type: .default, shortName)
            setPassthroughHints()
            completeLogin(authResult: .allow)
        } else {
            session = NoMADSession.init(domain: domainName, user: shortName)
            os_log("NoMAD Login User: %{public}@, Domain: %{public}@", log: uiLog, type: .default, shortName, domainName)
            guard let session = session else {
                os_log("Could not create NoMADSession from SignIn window", log: uiLog, type: .error)
                return
            }
            session.useSSL = isSSLRequired
            session.userPass = passString
            session.delegate = self
            os_log("Attempt to authenticate user", log: uiLog, type: .debug)
            session.authenticate()
        }
    }


    @IBAction func changePassowrd(_ sender: Any) {

        guard newPassword.stringValue == newPasswordConfirmation.stringValue else {
            os_log("New passwords didn't match", log: uiLog, type: .error)
            return
        }

        //TODO: Terrible hack to be fixed once AD Framework is refactored
        password.stringValue = newPassword.stringValue

        session?.oldPass = oldPassword.stringValue
        session?.newPass = newPassword.stringValue

        os_log("Attempting password change for %{public}@", log: uiLog, type: .debug, shortName)
        session?.changePassword()
    }

    func showResetUI() {
        os_log("Adjusting UI for change controls", log: uiLog, type: .debug)
        loginStack.isHidden = true
        signIn.isHidden = true
        signIn.isEnabled = false
        passwordChangeStack.isHidden = false
        passwordChangeButton.isHidden = false
        passwordChangeButton.isEnabled = true
        oldPassword.becomeFirstResponder()
    }

    /// Simple toggle to change the state of the NoLo window UI between active and inactive.
    fileprivate func loginStartedUI() {
        signIn.isEnabled = !signIn.isEnabled
        signIn.isHidden = !signIn.isHidden
        
        username.isEnabled = !username.isEnabled
        password.isEnabled = !password.isEnabled
    }

    /// Format the user and domain from the login window depending on the mode the window is in.
    ///
    /// I.e. are we picking a domain from a list, using a managed domain, or putting it on the user name with '@'.
    fileprivate func prepareAccountStrings() {
        os_log("Format user and domain strings", log: uiLog, type: .debug)
        guard isDomainManaged else {
            if !domain.isHidden {
                os_log("Using domain list", log: uiLog, type: .default)
                shortName = username.stringValue
                domainName = (domain.selectedItem?.title.uppercased())!
            } else {
                os_log("Using domain from text field", log: uiLog, type: .default)
                shortName = (username.stringValue.components(separatedBy: "@").first)!
                domainName = username.stringValue.components(separatedBy: "@").last!.uppercased()
            }
            return
        }
        os_log("Using managed domain", log: uiLog, type: .default)
        if username.stringValue.contains("@")  {
            os_log("Removing domain from username", log: uiLog, type: .default)
            shortName = (username.stringValue.components(separatedBy: "@").first)!
            return
        }
        shortName = username.stringValue
    }

    //MARK: - Login Context Functions

    /// Set the authorization and context hints. These are the basics we need to passthrough to the next mechanism.
    fileprivate func setPassthroughHints() {
        os_log("Setting hints for user: %{public}@", log: uiLog, type: .debug, shortName)
        setHint(type: .noMADUser, hint: shortName)
        setHint(type: .noMADPass, hint: password.stringValue)

        os_log("Setting context values for user: %{public}@", log: uiLog, type: .debug, shortName)
        setContext(type: kAuthorizationEnvironmentUsername, value: shortName)
        setContext(type: kAuthorizationEnvironmentPassword, value: password.stringValue)
    }

    /// Complete the NoLo process and either continue to the next Authorization Plugin or reset the NoLo window.
    ///
    /// - Parameter authResult:`Authorizationresult` enum value that indicates if login should proceed.
    fileprivate func completeLogin(authResult: AuthorizationResult) {
        os_log("Complete login process", log: uiLog, type: .debug)
        let error = mech?.fPlugin.pointee.fCallbacks.pointee.SetResult((mech?.fEngine)!, authResult)
        if error != noErr {
            os_log("Got error setting authentication result", log: uiLog, type: .error)
        }
        loginStartedUI()
        NSApp.abortModal()
        self.window?.close()
    }

    //MARK: - Sleep, Restart, and Shut Down Actions

    @IBAction func sleepClick(_ sender: Any) {
        os_log("Sleeping system isn't supported yet", log: uiLog, type: .error)
//        os_log("Setting sleep user", log: uiLog, type: .debug)
//        setHint(type: .noMADUser, hint: SpecialUsers.noloSleep.rawValue)
//        completeLogin(authResult: .allow)
    }

    @IBAction func restartClick(_ sender: Any) {
        os_log("Setting restart user", log: uiLog, type: .debug)
        setHint(type: .noMADUser, hint: SpecialUsers.noloRestart.rawValue)
        completeLogin(authResult: .allow)
    }

    @IBAction func shutdownClick(_ sender: Any) {
        os_log("Setting shutdown user", log: uiLog, type: .debug)
        setHint(type: .noMADUser, hint: SpecialUsers.noloShutdown.rawValue)
        completeLogin(authResult: .allow)
    }
}

//MARK: - NoMADUserSessionDelegate
extension SignIn: NoMADUserSessionDelegate {
    
    func NoMADAuthenticationFailed(error: NoMADSessionError, description: String) {

        os_log("NoMAD Login Authentication failed with: %{public}@", log: uiLog, type: .error, description)

        //TODO: Password change functionality
        switch error {
        case .PasswordExpired:
            os_log("Password is expired or requires change.", log: uiLog, type: .default)
            showResetUI()
            return
        default:
            os_log("NoMAD Login Authentication failed with: %{public}@", log: uiLog, type: .error, description)
            completeLogin(authResult: .deny)
        }


    }

    func NoMADAuthenticationSucceded() {
        os_log("Authentication succeded, requesting user info", log: uiLog, type: .default)
        session?.userInfo()
    }
    
    func NoMADUserInformation(user: ADUserRecord) {
        os_log("NoMAD Login Looking up info for: %{public}@", log: uiLog, type: .default, user.shortName)
        setPassthroughHints()
        setHint(type: .noMADFirst, hint: user.firstName)
        setHint(type: .noMADLast, hint: user.lastName)
        completeLogin(authResult: .allow)
    }
}

//MARK: - NSTextField Delegate
extension SignIn: NSTextFieldDelegate {
    public override func controlTextDidChange(_ obj: Notification) {
        os_log("Passtext updated", log: uiLog, type: .debug)
        let passField = obj.object as! NSTextField
        passString = passField.stringValue
    }
}

//MARK: - ContextAndHintHandling Protocol
extension SignIn: ContextAndHintHandling {}
