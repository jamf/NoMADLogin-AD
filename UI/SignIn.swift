//
//  SignIn.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/20/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Cocoa
import Security.AuthorizationPlugin
//import Security.AuthorizationTags

class SignIn: NSWindowController {
    
    //MARK: - setup variables
    
    var mech: MechanismRecord?
    var session: NoMADSession?
    
    //MARK: - setup statics
    
    let kNoMADUser = "NoMAD.user"
    let kNoMADPass = "NoMAD.pass"
    let kNoMADFirst = "NoMAD.first"
    let kNoMADLast = "NoMAD.last"
    
    //MARK: - IB outlets
    
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    @IBOutlet weak var domain: NSPopUpButton!
    @IBOutlet weak var signIn: NSButton!
    @IBOutlet weak var spinner: NSProgressIndicator!
    @IBOutlet weak var imageView: NSImageView!
    
    //override var windowNibName: NSNib.Name? = NSNib.Name(rawValue: "SignIn")
    
    //MARK: - UI Methods
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // get an image
        let fameworkURL = Bundle.init(identifier: "menu.nomad.NoMADLogin")?.bundleURL
        
        NSLog((fameworkURL?.absoluteString)!)
        
        //imageView.image = logoImage
        
        self.window?.isMovable = false
        self.window?.canBecomeVisibleWithoutLogin = true
        self.window?.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        //self.window?.makeKeyAndOrderFront(self)
        self.window?.orderFrontRegardless()
        
        // make things look better
        self.window?.titlebarAppearsTransparent = true
        self.window?.backgroundColor = NSColor.white
        username.becomeFirstResponder()
    }

    @IBAction func signInClick(_ sender: Any) {
        animateUI()
        if checkLocalUser(name: username.stringValue) {
            NSLog("User exists... passing on")
            setHints()
            completeLogin(authResult: .allow)
        } else if username.stringValue == "eject" {
            // need to eject
            NSLog("ejecting")
            completeLogin(authResult: .allow)
        } else if username.stringValue == "" {
            // nothing to do here
        } else {
            NSLog("%@", "Lets try to login...")

            
            NSLog("%@", "Start a NoMAD session...")
            session = NoMADSession.init(domain: (domain.selectedItem?.title.uppercased())!, user: username.stringValue)
            
            if session == nil {
                NSLog("%@", "Session was not created")
            }
            
            NSLog("%@", "Set the session pass...")
            session?.userPass = password.stringValue
            session?.delegate = self
            
            NSLog("%@", "Try to authenticate...")
            session?.authenticate()
        }
    }
    
    /// Simple toggle to change the state of the NoLo window UI between active and inactive.
    func animateUI() {
        signIn.isEnabled = !signIn.isEnabled
        signIn.isHidden = !signIn.isHidden
        
        username.isEnabled = !username.isEnabled
        password.isEnabled = !password.isEnabled
        
        spinner.isHidden = !spinner.isHidden
        spinner.isHidden ? spinner.stopAnimation(nil) : spinner.startAnimation(nil)
    }

    //MARK: - User Utility Functions

    /// Set the authorization and context hints.
    fileprivate func setHints() {
        setPassHint(user: password.stringValue)
        setUserHint(user: username.stringValue)

        setPassContext(pass: password.stringValue)
        setUserContext(user: username.stringValue)
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
    
    /// Check to see if a user is present in the DSLocal domain.
    ///
    /// - Parameter name: A `String` containing the username to check for.
    /// - Returns: A `Bool` that is true if the user is local. Otherwise false.
    func checkLocalUser(name: String) -> Bool {
        
        var records = [ODRecord]()
        let odsession = ODSession.default()
        
        // query OD local noes for the user name
        do {
            let node = try ODNode.init(session: odsession, type: UInt32(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node,
                                         forRecordTypes: kODRecordTypeUsers,
                                         attribute: kODAttributeTypeRecordName,
                                         matchType: UInt32(kODMatchEqualTo),
                                         queryValues: name,
                                         returnAttributes: kODAttributeTypeNativeOnly,
                                         maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            //TODO: # Error handling
            NSLog("Unable to get user account ODRecords")
            return false
        }
        if ( records.count > 0 ) {
            return true
        }
        return false
    }
    
    func setPassHint(user: String) -> Bool {
        NSLog("Setting passhint: %@ %i", #file, #line)
        guard let data : Data = NSKeyedArchiver.archivedData(withRootObject: user)
            else {
                NSLog("NoLo:Failed to update user pass in hint.");
                return false
        }
        var value = AuthorizationValue(length: data.count, data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))
        let err = (mech?.fPlugin.pointee.fCallbacks.pointee.SetHintValue((mech?.fEngine)!, kNoMADPass, &value))!
        return (err == errSecSuccess)
    }
    
    func setUserHint(user: String) -> Bool {
        NSLog("Setting user: %@ %i", #file, #line)
        guard let data : Data = NSKeyedArchiver.archivedData(withRootObject: user)
            else {
                NSLog("NoLo:Failed to update user name in hint.");
                return false
        }
        var value = AuthorizationValue(length: data.count, data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))
        let err : OSStatus = (mech?.fPlugin.pointee.fCallbacks.pointee.SetHintValue((mech?.fEngine)!, kNoMADUser, &value))!
        return (err == errSecSuccess)
    }
    
    func setPassContext(pass: String) -> Bool {
        
        // silly two-step
        let flags = AuthorizationContextFlags.extractable
//        let flags = AuthorizationContextFlags(rawValue: AuthorizationContextFlags.RawValue(1 << 0))

        // add null byte to signify end of string
        
        let tempdata = pass + "\0"
        var data = tempdata.data(using: .utf8)
        
        //var value = AuthorizationValue(length: (data?.count)!, data: &data)
        
        var value = AuthorizationValue(length: (data?.count)!,
                                       data: UnsafeMutableRawPointer(mutating: (data as! NSData).bytes.bindMemory(to: Void.self, capacity: (data?.count)!)))
        
        let err = mech?.fPlugin.pointee.fCallbacks.pointee.SetContextValue((mech?.fEngine)!, kAuthorizationEnvironmentPassword, flags, &value)
        
        NSLog("Setting pass context")
        
        return (err == errSecSuccess)
    }

    //TODO: # unify context settings
    func setUserContext(user: String) -> Bool {
        
        // silly two-step
        
        // add null byte to signify end of string
        
        let tempdata = user + "\0"
        var data = tempdata.data(using: .utf8)
        let flags = AuthorizationContextFlags.extractable
//        let flags = AuthorizationContextFlags(rawValue: AuthorizationContextFlags.RawValue(1 << 0))

        var value = AuthorizationValue(length: (data?.count)!,
                                       data: UnsafeMutableRawPointer(mutating: (data! as NSData).bytes.bindMemory(to: Void.self, capacity: (data?.count)!)))
        
        let err = mech?.fPlugin.pointee.fCallbacks.pointee.SetContextValue((mech?.fEngine)!, kAuthorizationEnvironmentUsername, flags, &value)
        
        NSLog("Setting user context")
        
        return (err == errSecSuccess)
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
        // user information lookup

        completeLogin(authResult: .allow)
    }
}
