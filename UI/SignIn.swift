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
    var backgroundWindow: NSWindow!
    var effectWindow: NSWindow!
    var passChanged = false
    @objc var visible = true
    
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
        
        os_log("Configure login window", log: uiLog, type: .debug)
        loginApperance()
        
        os_log("create background windows", log: uiLog, type: .debug)
        createBackgroundWindow()

        os_log("Become first responder", log: uiLog, type: .debug)
        username.becomeFirstResponder()
        os_log("Finsished loading loginwindow", log: uiLog, type: .debug)
    }


    fileprivate func createBackgroundWindow() {
        var image: NSImage?
        // Is a background image path set? If not just use gray.
        if let backgroundImage = getManagedPreference(key: .BackgroundImage) as? String  {
            os_log("BackgroundImage preferences found.", log: uiLog, type: .debug)
            image = NSImage(contentsOf: URL(fileURLWithPath: backgroundImage))
        }

        for screen in NSScreen.screens {
            let view = NSView()
            view.wantsLayer = true
            view.layer!.contents = image
            
            backgroundWindow = NSWindow(contentRect: screen.frame,
                                        styleMask: .fullSizeContentView,
                                        backing: .buffered,
                                        defer: true)
            
            backgroundWindow.backgroundColor = .gray
            backgroundWindow.contentView = view
            backgroundWindow.makeKeyAndOrderFront(self)
            backgroundWindow.canBecomeVisibleWithoutLogin = true

            let effectView = NSVisualEffectView()
            effectView.wantsLayer = true
            effectView.blendingMode = .behindWindow
            effectView.frame = screen.frame
            
            effectWindow = NSWindow(contentRect: screen.frame,
                                    styleMask: .fullSizeContentView,
                                    backing: .buffered,
                                    defer: true)
            
            effectWindow.contentView = effectView
            
            if let backgroundImageAlpha = getManagedPreference(key: .BackgroundImageAlpha) as? Int {
                effectWindow.alphaValue = CGFloat.init((backgroundImageAlpha / 100))
            } else {
                effectWindow.alphaValue = 0.8
            }
            
            effectWindow.orderFrontRegardless()
            effectWindow.canBecomeVisibleWithoutLogin = true
        }
    }


    func loginTransition() {
        os_log("Transitioning... fade our UI away", log: uiLog, type: .debug)

        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 1.0
            context.allowsImplicitAnimation = true
            self.window?.alphaValue = 0.0
            self.backgroundWindow.alphaValue = 0.0
            self.effectWindow.alphaValue = 0.0
        }, completionHandler: {
            os_log("Close all the windows", log: uiLog, type: .debug)
            self.window?.close()
            self.backgroundWindow.close()
            self.effectWindow.close()
            self.visible = false
        })
    }
    
    fileprivate func shakeOff() {
        let origin = NSMakePoint((window?.frame.origin.x)!, (window?.frame.origin.y)!)
        let left = NSMakePoint(origin.x - 10, origin.y)
        let right = NSMakePoint(origin.x + 10, origin.y)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.04
            context.allowsImplicitAnimation = true
            self.window?.setFrameOrigin(left)
        }, completionHandler: {
            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = 0.04
                context.allowsImplicitAnimation = true
                self.window?.setFrameOrigin(right)
            }, completionHandler: {
                NSAnimationContext.runAnimationGroup({ (context) in
                    context.duration = 0.04
                    context.allowsImplicitAnimation = true
                    self.window?.setFrameOrigin(left)
                }, completionHandler: {
                    NSAnimationContext.runAnimationGroup({ context in
                        context.duration = 0.04
                        context.allowsImplicitAnimation = true
                        self.window?.setFrameOrigin(right)
                    }, completionHandler: {
                        NSAnimationContext.runAnimationGroup({ context in
                            context.duration = 0.04
                            context.allowsImplicitAnimation = true
                            self.window?.setFrameOrigin(origin)
                            self.window?.close()
                        })
                    })
                })
            })
        })
    }

    fileprivate func loginApperance() {
        os_log("Setting window level", log: uiLog, type: .debug)
        self.window?.level = .screenSaver
        self.window?.orderFrontRegardless()

        // make things look better
        os_log("Tweaking appearance", log: uiLog, type: .debug)
        if getManagedPreference(key: .LoginScreen) as? Bool == true {
            os_log("Present as login screen", log: uiLog, type: .debug)
            self.window?.isOpaque = false
            self.window?.hasShadow = false
            self.window?.backgroundColor = .clear
        } else {
            os_log("Present as login window", log: uiLog, type: .debug)
            self.window?.backgroundColor = NSColor.white
        }
        self.window?.titlebarAppearsTransparent = true
        if !self.domainName.isEmpty {
            username.placeholderString = "Username"
            self.isDomainManaged = true
        }
        if let usernamePlaceholder = getManagedPreference(key: .UsernameFieldPlaceholder) as? String {
            os_log("Username Field Placeholder preferences found.", log: uiLog, type: .debug)
            username.placeholderString = usernamePlaceholder
        }
        
        self.window?.isMovable = false
        self.window?.canBecomeVisibleWithoutLogin = true

        if let logoPath = getManagedPreference(key: .LoginLogo) as? String {
            os_log("Found logoPath: %{public}@", log: uiLog, type: .debug, logoPath)
            if logoPath == "NONE" {
                imageView.image = nil
            } else {
                imageView.image = NSImage(contentsOf: URL(fileURLWithPath: logoPath))
            }
        }
        
        if let logoData = getManagedPreference(key: .LoginLogoData) as? Data {
            os_log("Found LoginLogoData key has a value", log: uiLog, type: .debug)
            if let image = NSImage(data: logoData) as NSImage? {
                imageView.image = image
            }
        }
    }

    fileprivate func showResetUI() {
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
    
    // Sequence to perform a local login
    fileprivate func localLogin() {
        os_log("Verify local user login for %{public}@", log: uiLog, type: .default, shortName)
        if NoLoMechanism.verifyUser(name: shortName, auth: passString) {
            os_log("Allowing local user login for %{public}@", log: uiLog, type: .default, shortName)
            setRequiredHintsAndContext()
            completeLogin(authResult: .allow)
        } else {
            os_log("Could not verify %{public}@", log: uiLog, type: .default, shortName)
            completeLogin(authResult: .deny)
        }
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
        
        // With the intro of checkDomainUserEveryLogin, we need an additional check to tell if a local account should be subjected to an AD check (i.e., created by NoLo)
        if NoLoMechanism.checkIfLocalOnlyUser(name: shortName) {
            localLogin()
            return
        }
        
        // Not a local user, or a NoLo user with checkDomainUserEveryLogin turned on
        session = NoMADSession.init(domain: domainName, user: shortName)
        os_log("NoMAD Login User: %{public}@, Domain: %{public}@", log: uiLog, type: .default, shortName, domainName)
        guard let session = session else {
            os_log("Could not create NoMADSession from SignIn window", log: uiLog, type: .error)
            return
        }
        session.useSSL = isSSLRequired
        session.userPass = passString
        session.delegate = self
        if let ignoreSites = getManagedPreference(key: .IgnoreSites) as? Bool {
            session.siteIgnore = ignoreSites
        }
        os_log("Attempt to authenticate user", log: uiLog, type: .debug)
        session.authenticate()
    }


    @IBAction func changePassowrd(_ sender: Any) {
        guard newPassword.stringValue == newPasswordConfirmation.stringValue else {
            os_log("New passwords didn't match", log: uiLog, type: .error)
            return
        }
        
        // set the passChanged flag
        
        passChanged = true

        //TODO: Terrible hack to be fixed once AD Framework is refactored
        password.stringValue = newPassword.stringValue

        session?.oldPass = oldPassword.stringValue
        session?.newPass = newPassword.stringValue

        os_log("Attempting password change for %{public}@", log: uiLog, type: .debug, shortName)
        session?.changePassword()
    }


    /// Format the user and domain from the login window depending on the mode the window is in.
    ///
    /// I.e. are we picking a domain from a list, using a managed domain, or putting it on the user name with '@'.
    fileprivate func prepareAccountStrings() {
        os_log("Format user and domain strings", log: uiLog, type: .debug)
        
        var providedDomainName = ""
        
        shortName = username.stringValue
        if username.stringValue.range(of:"@") != nil {
            shortName = (username.stringValue.components(separatedBy: "@").first)!
            providedDomainName = username.stringValue.components(separatedBy: "@").last!.uppercased()
        }
        
        if !domain.isHidden {
            os_log("Using domain from picker", log: uiLog, type: .default)
            domainName = (domain.selectedItem?.title.uppercased())!
            return
        }

        if providedDomainName == domainName {
            os_log("Provided domain matches  managed domain", log: uiLog, type: .default)
            return
        }

        if !providedDomainName.isEmpty {
            os_log("Optional domain provided in text field: %{public}@", log: uiLog, type: .default, providedDomainName)
            if getManagedPreference(key: .AdditionalADDomains) as? Bool == true {
                os_log("Optional domain name allowed by AdditionalADDomains allow-all policy", log: uiLog, type: .default)
                domainName = providedDomainName
                return
            }

            if let optionalDomains = getManagedPreference(key: .AdditionalADDomains) as? [String] {
                guard optionalDomains.contains(providedDomainName) else {
                    os_log("Optional domain name not allowed by AdditionalADDomains whitelist policy", log: uiLog, type: .default)
                    return
                }
                os_log("Optional domain name allowed by AdditionalADDomains whitelist policy", log: uiLog, type: .default)
                domainName = providedDomainName
                return
            }

            os_log("Optional domain not name allowed by AdditionalADDomains policy (false or not defined)", log: uiLog, type: .default)
        }

        os_log("Using domain from managed domain", log: uiLog, type: .default)
        return
    }


    //MARK: - Login Context Functions

    /// Set the authorization and context hints. These are the basics we need to passthrough to the next mechanism.
    fileprivate func setRequiredHintsAndContext() {
        os_log("Setting hints for user: %{public}@", log: uiLog, type: .debug, shortName)
        setHint(type: .noMADUser, hint: shortName)
        setHint(type: .noMADPass, hint: passString)

        os_log("Setting context values for user: %{public}@", log: uiLog, type: .debug, shortName)
        setContextString(type: kAuthorizationEnvironmentUsername, value: shortName)
        setContextString(type: kAuthorizationEnvironmentPassword, value: passString)
    }


    /// Complete the NoLo process and either continue to the next Authorization Plugin or reset the NoLo window.
    ///
    /// - Parameter authResult:`Authorizationresult` enum value that indicates if login should proceed.
    fileprivate func completeLogin(authResult: AuthorizationResult) {
        switch authResult {
        case .allow:
            os_log("Complete login process with allow", log: uiLog, type: .debug)
        case .deny:
            os_log("Complete login process with deny", log: uiLog, type: .debug)
            window?.close()
        default:
            os_log("Complete login process with unknown", log: uiLog, type: .debug)
            window?.close()
        }
        os_log("Complete login process", log: uiLog, type: .debug)
        let error = mech?.fPlugin.pointee.fCallbacks.pointee.SetResult((mech?.fEngine)!, authResult)
        if error != noErr {
            os_log("Got error setting authentication result", log: uiLog, type: .error)
        }
        NSApp.stopModal()
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
        switch error {
        case .PasswordExpired:
            os_log("Password is expired or requires change.", log: uiLog, type: .default)
            showResetUI()
            return
        case .OffDomain:
            os_log("Network is not available, falling back to local accounts", log: uiLog, type: .default)
            localLogin()
            return
        default:
            os_log("NoMAD Login Authentication failed with: %{public}@", log: uiLog, type: .error, description)
            completeLogin(authResult: .deny)
        }
    }


    func NoMADAuthenticationSucceded() {
        
        if passChanged {
            // need to ensure the right password is stashed
            passString = newPassword.stringValue
            passChanged = false
        }
        
        os_log("Authentication succeded, requesting user info", log: uiLog, type: .default)
        session?.userInfo()
    }


    func NoMADUserInformation(user: ADUserRecord) {
        os_log("NoMAD Login Looking up info for: %{public}@", log: uiLog, type: .default, user.shortName)
        setRequiredHintsAndContext()
        setHint(type: .noMADFirst, hint: user.firstName)
        setHint(type: .noMADLast, hint: user.lastName)
        setHint(type: .noMADDomain, hint: domainName)
        setHint(type: .noMADGroups, hint: user.groups)
        completeLogin(authResult: .allow)
    }
}


//MARK: - NSTextField Delegate
extension SignIn: NSTextFieldDelegate {
    public override func controlTextDidChange(_ obj: Notification) {
        let passField = obj.object as! NSTextField
        passString = passField.stringValue
    }
}


//MARK: - ContextAndHintHandling Protocol
extension SignIn: ContextAndHintHandling {}

extension NSWindow {

    func shakeWindow(){
        let numberOfShakes      = 3
        let durationOfShake     = 0.25
        let vigourOfShake : CGFloat = 0.015

        let frame : CGRect = self.frame
        let shakeAnimation :CAKeyframeAnimation  = CAKeyframeAnimation()

        let shakePath = CGMutablePath()
        shakePath.move(to: CGPoint(x: frame.minX, y: frame.minY))

        for _ in 0...numberOfShakes-1 {
            shakePath.addLine(to: CGPoint(x: frame.minX - frame.size.width * vigourOfShake, y: frame.minY))
            shakePath.addLine(to: CGPoint(x: frame.minX + frame.size.width * vigourOfShake, y: frame.minY))
        }

        shakePath.closeSubpath()

        shakeAnimation.path = shakePath;
        shakeAnimation.duration = durationOfShake;

        self.animations = [NSAnimatablePropertyKey(rawValue: "frameOrigin"):shakeAnimation]
        self.animator().setFrameOrigin(self.frame.origin)
    }

}

