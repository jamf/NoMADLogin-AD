//
//  SignIn.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/20/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Cocoa
import Security.AuthorizationPlugin
import NoMAD_ADAuth

class SignIn: NSWindowController {
    
    //MARK: - setup variables
    var mech: MechanismRecord?
    var session: NoMADSession?
    var shortName = ""
    var domainName = ""
    
    //MARK: - IB outlets
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    @IBOutlet weak var domain: NSPopUpButton!
    @IBOutlet weak var signIn: NSButton!
    @IBOutlet weak var imageView: NSImageView!

    //MARK: - UI Methods
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.isMovable = false
        self.window?.canBecomeVisibleWithoutLogin = true
        self.window?.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        self.window?.orderFrontRegardless()
        
        // make things look better
        self.window?.titlebarAppearsTransparent = true
        self.window?.backgroundColor = NSColor.white
        username.becomeFirstResponder()
    }

    /// When the sign in button is clicked we check a few things.
    ///
    /// 1. Check to see if the username field is blank, bail if it is. If not, animate the UI and process the user strings.
    ///
    /// 2. Check the user shortname and see if the account already exists in DSLocal. If so, simply set the hints and pass on.
    ///
    /// 3. Create a `NoMADSession` and see if we can authenticate as the user.
    @IBAction func signInClick(_ sender: Any) {
        if username.stringValue.isEmpty {
            NSLog("NoMAD Login %@", "No username entered")
            return
        }
        animateUI()
        prepareAccountStrings()
        if NoLoMechanism.checkForLocalUser(name: shortName) {
            setPassthroughHints()
            completeLogin(authResult: .allow)
        } else {
            NSLog("NoMAD Login User: %@, Domain: %@", shortName, domainName)
            session = NoMADSession.init(domain: domainName, user: shortName)
            guard let session = session else {
                NSLog("%@", "Could not create NoMADSession")
                return
            }
            session.userPass = password.stringValue
            session.delegate = self
            session.authenticate()
        }
    }

    /// Simple toggle to change the state of the NoLo window UI between active and inactive.
    func animateUI() {
        signIn.isEnabled = !signIn.isEnabled
        signIn.isHidden = !signIn.isHidden
        
        username.isEnabled = !username.isEnabled
        password.isEnabled = !password.isEnabled
    }

    /// Format the user and domain from the login window depending on the mode the window is in.
    ///
    /// I.e. are we picking a domain from a list or putting it on the user name with '@'.
    fileprivate func prepareAccountStrings() {
        if !domain.isHidden {
            NSLog("NoMAD Login %@", "using domain list")
            shortName = username.stringValue
            domainName = (domain.selectedItem?.title.uppercased())!
        } else {
            NSLog("NoMAD Login %@", "using domain from text field")
            shortName = (username.stringValue.components(separatedBy: "@").first)!
            domainName = username.stringValue.components(separatedBy: "@").last!.uppercased()
        }
    }

    //MARK: - Login Context Functions

    /// Set the authorization and context hints. These are the basics we need to passthrough to the next mechanism.
    fileprivate func setPassthroughHints() {
        setHint(type: .noMADUser, hint: shortName)
        setHint(type: .noMADPass, hint: password.stringValue)

        setContext(type: kAuthorizationEnvironmentUsername, value: shortName)
        setContext(type: kAuthorizationEnvironmentPassword, value: password.stringValue)
    }

    /// Complete the NoLo process and either continue to the next Authorization Plugin or reset the NoLo window.
    ///
    /// - Parameter authResult:`Authorizationresult` enum value that indicates if login should proceed.
    fileprivate func completeLogin(authResult: AuthorizationResult) {
        let _ = mech?.fPlugin.pointee.fCallbacks.pointee.SetResult((mech?.fEngine)!, authResult)
        animateUI()
        NSApp.abortModal()
        self.window?.close()
    }
}

//MARK: - NoMADUserSessionDelegate
extension SignIn: NoMADUserSessionDelegate {
    
    func NoMADAuthenticationSucceded() {
        session?.userInfo()
    }
    
    func NoMADAuthenticationFailed(error: Error, description: String) {
        NSLog("NoMAD Login Authentication failed with: %@", error.localizedDescription)
        completeLogin(authResult: .deny)
    }
    
    func NoMADUserInformation(user: ADUserRecord) {
        NSLog("NoMAD Login Looking up info for: %@", user.shortName)
        setPassthroughHints()
        completeLogin(authResult: .allow)
    }
}

//MARK: - ContextAndHintHandling Protocol
extension SignIn: ContextAndHintHandling {}
