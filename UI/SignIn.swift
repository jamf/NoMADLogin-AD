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
    
    //MARK: - IB outlets
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    @IBOutlet weak var domain: NSPopUpButton!
    @IBOutlet weak var signIn: NSButton!
    @IBOutlet weak var spinner: NSProgressIndicator!
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

    @IBAction func signInClick(_ sender: Any) {
        animateUI()
        if NoLoMechanism.checkForLocalUser(name: username.stringValue) {
            setHints()
            completeLogin(authResult: .allow)
        }  else if username.stringValue == "" {
            // nothing to do here
        } else {
            session = NoMADSession.init(domain: (domain.selectedItem?.title.uppercased())!, user: username.stringValue)
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
        
        spinner.isHidden = !spinner.isHidden
        spinner.isHidden ? spinner.stopAnimation(self) : spinner.startAnimation(self)
    }

    //MARK: - Login Context Functions

    /// Set the authorization and context hints.
    fileprivate func setHints() {
        setHint(type: .noMADUser, hint: username.stringValue)
        setHint(type: .noMADPass, hint: password.stringValue)

        setContext(type: kAuthorizationEnvironmentUsername, value: username.stringValue)
        setContext(type: kAuthorizationEnvironmentPassword, value: password.stringValue)
    }

    /// Set a NoMAD Login Authorization mechanism hint.
    ///
    /// - Parameters:
    ///   - type: A value from `HintType` representing the NoMad Login value to set.
    ///   - hint: A `String` of the hint value to set.
    func setHint(type: HintType, hint: String) {
        let data = NSKeyedArchiver.archivedData(withRootObject: hint)
        var value = AuthorizationValue(length: data.count, data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))
        let err = (mech?.fPlugin.pointee.fCallbacks.pointee.SetHintValue((mech?.fEngine)!, type.rawValue, &value))!
        guard err == errSecSuccess else {
            NSLog("Set hint failed with: %@", err)
            return
        }
    }

    /// Set one of the known `AuthorizationTags` values to be used during mechanism evaluation.
    ///
    /// - Parameters:
    ///   - type: A `String` constant from AuthorizationTags.h representing the value to set.
    ///   - value: A `String` value of the context value to set.
    func setContext(type: String, value: String) {
        let tempdata = value + "\0"
        let data = tempdata.data(using: .utf8)
        var value = AuthorizationValue(length: (data?.count)!, data: UnsafeMutableRawPointer(mutating: (data! as NSData).bytes.bindMemory(to: Void.self, capacity: (data?.count)!)))
        let err = (mech?.fPlugin.pointee.fCallbacks.pointee.SetContextValue((mech?.fEngine)!, type, .extractable, &value))!
        guard err == errSecSuccess else {
            NSLog("Set context value failed with: %@", err)
            return
        }
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
        NSLog("Authentication failed with: %@", error.localizedDescription)
        completeLogin(authResult: .deny)
    }
    
    func NoMADUserInformation(user: ADUserRecord) {
        NSLog("Looking up info for: %@", user.shortName)
        setHints()
        completeLogin(authResult: .allow)
    }
}
