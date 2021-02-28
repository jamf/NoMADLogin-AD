//
//  EULAUI.swift
//  NoMADLoginOkta
//
//  Created by Joel Rennich on 3/31/18.
//  Copyright © 2018 Orchard & Grove. All rights reserved.
//

import Foundation
import Cocoa

class EULAUI : NSWindowController {
    
    //MARK: Mech things
    var mech: MechanismRecord?
    
    //MARK: IB Outlets
    
    @IBOutlet weak var titleText: NSTextField!
    @IBOutlet weak var subTitleText: NSTextField!
    @IBOutlet weak var doneButton: NSButton!
    @IBOutlet weak var agreeButton: NSButton!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var scroller: NSScroller!
    @IBOutlet weak var cancelButton: NSButton!
    
    var backgroundWindow: NSWindow!
    var effectWindow: NSWindow!
    
    override func windowDidLoad() {
        
        os_log("Calling super.windowDidLoad", log: uiLog, type: .default)
        super.windowDidLoad()
        
        os_log("EULA window showing.", log: eulaLog, type: .default )
        // set everything to off
        
        agreeButton.state = .off
        doneButton.isEnabled = false
        
        agreeButton.becomeFirstResponder()
        
        // set the text
        
        if let titleTextPref = getManagedPreference(key: .EULATitle) as? String {
            os_log("Setting title text", log: eulaLog, type: .default )
            titleText.stringValue = titleTextPref
        }
        
        if let subTitleTextPref = getManagedPreference(key: .EULASubTitle) as? String {
            os_log("Setting subtitle text", log: eulaLog, type: .default )
            subTitleText.stringValue = subTitleTextPref
        }
        
        if let text = getManagedPreference(key: .EULAText) as? String {
            os_log("Setting eula text", log: eulaLog, type: .default )

            // We may need to do some line break things here
            textView.string = text.replacingOccurrences(of: "***", with: "\n")
        } else {
            // no text, let's move on to the next mechanism
            os_log("No EULA text, not showing EULA.", log: eulaLog, type: .default )
            completeLogin(authResult: .allow)
        }
        
        os_log("Configure EULA window", log: eulaLog, type: .default)
        loginApperance()

        os_log("create background windows", log: eulaLog, type: .default)
        createBackgroundWindow()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(displayConfigurationUpdated),
                                       name: NSApplication.didChangeScreenParametersNotification,
                                       object: nil)
    }
    
    @objc func displayConfigurationUpdated() {
        os_log("Screen Paramaters updated", log: eulaLog, type: .default)
        createBackgroundWindow()
        self.window?.makeKeyAndOrderFront(nil)
        self.window?.center()
    }
    
    @IBAction func agreeAction(_ sender: Any) {
        
        if agreeButton.state == .on {
            doneButton.isEnabled = true
        } else {
            doneButton.isEnabled = false
        }
    }
    
    @IBAction func cancelClick(_ sender: Any) {
        
        // User doesn't want to agree, stop auth
        os_log("User canceled EULA acceptance. Stopping login.", log: eulaLog, type: .default )
        
        writeResponse(accept: false)

        completeLogin(authResult: .userCanceled)
    }
    
    @IBAction func doneClick(_ sender: Any) {
        
        os_log("User accepted EULA.", log: eulaLog, type: .default )

        writeResponse(accept: true)

        // complete the auth
        
        completeLogin(authResult: .allow)
    }
    
    fileprivate func writeResponse(accept: Bool) {
        
        var kNoMADPath = "/var/db/NoMADLogin"
        
        if let newPath = getManagedPreference(key: .EULAPath) as? String {
            kNoMADPath = newPath
        }
        
        let fm = FileManager.default
        var objcB : ObjCBool? = true
        // make a folder if one doesn't exist
        
        if !fm.fileExists(atPath: kNoMADPath, isDirectory: &objcB!) {
            do {
                try fm.createDirectory(at: URL.init(fileURLWithPath: kNoMADPath), withIntermediateDirectories: true, attributes: nil)
            } catch {
                os_log("Unable to create folder.", log: eulaLog, type: .default )
            }
        }
        
        let now = Date()
        
        // Set timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        let dateInFormat = dateFormatter.string(from: now)
        
        let df2 = DateFormatter.init()
        df2.dateFormat = "yyyy-MM-dd-HHmmss"
        
        var action = "Declined"
        
        if accept {
            action = "Accepted"
        }
        
        let fileName = kNoMADPath + "/" + "\(action)-" + df2.string(from: now)
        
        // Write plist file
        var dict : [String: Any] = [
            "EULA Acceptance": accept,
            "Date": dateInFormat,
            // any other key values
        ]
        
        if let username = getContextString(type: kAuthorizationEnvironmentUsername) {
            dict["User"] = username
        }
        
        if let username = getHint(type: .noMADUser) {
            dict["User"] = username
        }
        
        let someData = NSDictionary(dictionary: dict)
        os_log("Writing user acceptance.", log: eulaLog, type: .default )
        
        let isWritten = someData.write(toFile: fileName, atomically: true)
        os_log("Writing user acceptance complete: @{public}", log: eulaLog, type: .default, String(describing: isWritten) )
    }
    //MARK: mech functions
    
    /// Complete the NoLo process and either continue to the next Authorization Plugin or reset the NoLo window.
    ///
    /// - Parameter authResult:`Authorizationresult` enum value that indicates if login should proceed.
    fileprivate func completeLogin(authResult: AuthorizationResult) {
        os_log("Complete login process", log: uiLog, type: .default)
        let error = mech?.fPlugin.pointee.fCallbacks.pointee.SetResult((mech?.fEngine)!, authResult)
        if error != noErr {
            os_log("Got error setting authentication result", log: uiLog, type: .error)
        }
        backgroundWindow.close()
        effectWindow.close()
        NSApp.stopModal()
        self.window?.close()
    }
    
    fileprivate func loginApperance() {
        os_log("Setting window level", log: uiLog, type: .default)
        self.window?.level = .screenSaver
        self.window?.orderFrontRegardless()
        self.window?.titlebarAppearsTransparent = true

        self.window?.isMovable = false
        self.window?.canBecomeVisibleWithoutLogin = true
    }
    
    fileprivate func createBackgroundWindow() {
        var image: NSImage?
        // Is a background image path set? If not just use gray.
        if let backgroundImage = getManagedPreference(key: .BackgroundImage) as? String  {
            os_log("BackgroundImage preferences found.", log: uiLog, type: .default)
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
                effectWindow.alphaValue = CGFloat(Double(backgroundImageAlpha) * 0.1)
            } else {
                effectWindow.alphaValue = 0.8
            }
            
            effectWindow.orderFrontRegardless()
            effectWindow.canBecomeVisibleWithoutLogin = true
        }
    }
}

//MARK: - ContextAndHintHandling Protocol
extension EULAUI: ContextAndHintHandling {}
