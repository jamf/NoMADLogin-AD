//
//  NoLoNotify.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 11/22/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Foundation
import Cocoa
import os.log

private var statusContext = 0
private var commandContext = 1

class NoLoNotify : NSWindowController, TrackerDelegate {
    
    //MARK: - setup variables
    
    var mech: MechanismRecord?
    
    //MARK: - setup statics
    
    let kNoMADUser = "NoMAD.user"
    let kNoMADPass = "NoMAD.pass"
    let kNoMADFirst = "NoMAD.first"
    let kNoMADLast = "NoMAD.last"
    
    //MARK: - IB outlets
    
    @IBOutlet weak var MainTitle: NSTextField!
    @IBOutlet weak var MainText: NSTextField!
    @IBOutlet weak var ProgressBar: NSProgressIndicator!
    @IBOutlet weak var StatusText: NSTextField!
    @IBOutlet weak var LogoCell: NSImageCell!
    @IBOutlet weak var ImageCell: NSImageCell!
    @IBOutlet var myView: NSView!
    @IBOutlet weak var helpButton: NSButton!
    //@IBOutlet weak var continueButton: NSButton!
    
    // MARK: Globals
    
    var helpURL = String()
    
    var determinate = false
    var totalItems: Double = 0
    var currentItem = 0
    
    var notify = false
    
    let tracker = TrackProgress()
    
    var logo: NSImage?
    var maintextImage: NSImage?
    var notificationImage: NSImage?
    
    var activateEachStep = false
    
    var killCommandFile = false
    
    var quitKey = "x"
    var demoKey = "d"
    
    let myWorkQueue = DispatchQueue(label: "menu.nomad.DEPNotify.background_work_queue", attributes: [])
    
    // Tracker parts
    
    let task = Process()
    let fm = FileManager()
    var additionalPath = OtherLogs.none
    var fwDownloadsStarted = false
    var filesets = Set<String>()
    let path = "/var/tmp/depnotify.log"
    
    var backgroundWindow: NSWindow!
    var effectWindow: NSWindow!
    
    //MARK: - UI Methods
    override func windowDidLoad() {
        
        os_log("Calling super.windowDidLoad", log: notifyLog, type: .default)
        super.windowDidLoad()
        
        // get an image
        //_ = Bundle.init(identifier: "menu.nomad.login.okta")?.bundleURL
        
        //imageView.image = logoImage
        
        self.window?.isMovable = false
        self.window?.canBecomeVisibleWithoutLogin = true
        self.window?.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        self.window?.orderFrontRegardless()

        os_log("Creating background window.", log: notifyLog, type: .default)
        createBackgroundWindow()
        
        // make things look better
        self.window?.titlebarAppearsTransparent = true
        self.window?.backgroundColor = NSColor.white
        NSApp.activate(ignoringOtherApps: true)

        self.window?.orderFrontRegardless()
        self.window?.center()
        ProgressBar.startAnimation(nil)
        
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) {
            self.flagsChanged(with: $0)
            return $0
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            self.keyDown(with: $0)
            return $0
        }
        
        tracker.delegate = self
        
        // start the tracker with the right log set
        // TODO: Pull this in from a plist
        
        tracker.start(argument: "")
        
        os_log("Starting tracker.", log: notifyLog, type: .default)
        tracker.run()
    }
        
    /// - DEPNotify Bits
    
    func statusChange(status: String) {
        
        NSLog("Status changed: \(status)")
        
        if status == "Quit" {
            completeLogin(authResult: .allow)
            NSApp.abortModal()
        } else {
        
        self.StatusText.stringValue = status
        
        if determinate {
            currentItem += 1
            ProgressBar.increment(by: 1)
            if activateEachStep {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows[0].makeKeyAndOrderFront(self)
            }
        }
        }
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
            effectWindow.alphaValue = 0.8
            effectWindow.orderFrontRegardless()
            effectWindow.canBecomeVisibleWithoutLogin = true
        }
    }
    
    
    func commandChange(command: String) {
        
        NSLog("Command changed: \(command)")
        
        switch command.components(separatedBy: " ").first! {
            
        case "Alert:" :
            let alertController = NSAlert()
            alertController.messageText = command.replacingOccurrences(of: "Alert: ", with: "")
            alertController.addButton(withTitle: "Ok")
            alertController.beginSheetModal(for: NSApp.windows[0])
            
        case "Determinate:" :
            
            determinate = true
            ProgressBar.isIndeterminate = false
            
            // default to 1 if we can't make a number
            totalItems = Double(command.replacingOccurrences(of: "Determinate: ", with: "")) ?? 1
            ProgressBar.maxValue = totalItems
            currentItem = 0
            ProgressBar.startAnimation(nil)
            
        case "DeterminateManual:" :
            
            determinate = false
            ProgressBar.isIndeterminate = false
            
            // default to 1 if we can't make a number
            totalItems = Double(command.replacingOccurrences(of: "DeterminateManual: ", with: "")) ?? 1
            ProgressBar.maxValue = totalItems
            currentItem = 0
            ProgressBar.startAnimation(nil)
            
        case "DeterminateManualStep:" :
            
            // default to 1 if we can't make a number
            let stepMove = Int(Double(command.replacingOccurrences(of: "DeterminateManualStep: ", with: "")) ?? 1 )
            currentItem += stepMove
            ProgressBar.increment(by: 1)
            if activateEachStep {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows[0].makeKeyAndOrderFront(self)
            }
            
        case "DeterminateOff:" :
            
            determinate = false
            ProgressBar.isIndeterminate = true
            ProgressBar.stopAnimation(nil)
            
        case "DeterminateOffReset:" :
            
            determinate = false
            currentItem = 0
            ProgressBar.increment(by: -1000)
            ProgressBar.isIndeterminate = true
            ProgressBar.stopAnimation(nil)
            
        case "Help:" :
            helpButton.isHidden = false
            helpURL = command.replacingOccurrences(of: "Help: ", with: "")
            
        case "ContinueButton" :
            break
            //continueButton.isHidden = false
            
        case "EULA:" :
            break
        case "Image:" :
            logo = NSImage.init(byReferencingFile: command.replacingOccurrences(of: "Image: ", with: ""))
            LogoCell.image = logo
            LogoCell.imageScaling = .scaleProportionallyUpOrDown
            LogoCell.imageAlignment = .alignCenter
            
        case "KillCommandFile:" :
            killCommandFile = true
            
        case "Logout:" :
            completeLogin(authResult: .allow)
            
        case "LogoutNow:":
            completeLogin(authResult: .allow)
            
        case "MainText:":
            // Need to do two replacingOccurrences since we are replacing with different values
            let newlinecommand = command.replacingOccurrences(of: "\\n", with: "\n")
            MainText.stringValue = newlinecommand.replacingOccurrences(of: "MainText: ", with: "")
            //ImageCell.image = NSImage.init(byReferencingFile: "")
            
        case "MainTextImage:" :
            maintextImage = NSImage.init(byReferencingFile: command.replacingOccurrences(of: "MainTextImage: ", with: ""))
            ImageCell.image = maintextImage
            ImageCell.imageScaling = .scaleProportionallyUpOrDown
            ImageCell.imageAlignment = .alignCenter
            MainText.stringValue = ""
            MainTitle.stringValue = ""
            
        case "MainTitle:" :
            // Need to do two replacingOccurrences since we are replacing with different values
            let newlinecommand = command.replacingOccurrences(of: "\\n", with: "\n")
            MainTitle.stringValue = newlinecommand.replacingOccurrences(of: "MainTitle: ", with: "")
            //ImageCell.image = NSImage.init(byReferencingFile: "")
            
        case "Notification:" :
            sendNotification(text: command.replacingOccurrences(of: "Notification: ", with: ""))
            
        case "NotificationImage:" :
            notificationImage = NSImage.init(byReferencingFile: command.replacingOccurrences(of: "NotificationImage: ", with: ""))
            
        case "NotificationOn:" :
            notify = true
            
        case "WindowStyle:" :
            switch command.replacingOccurrences(of: "WindowStyle: ", with: "") {
            case "Activate" :
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows[0].makeKeyAndOrderFront(self)
            case "ActivateOnStep" :
                activateEachStep = true
            case "NotMovable" :
                NSApp.windows[0].center()
                NSApp.windows[0].isMovable = false
            case "JoshQuick" :
                if #available(OSX 10.12, *) {
                    let windowTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: {_ in
                        NSApp.activate(ignoringOtherApps: true)
                        NSApp.windows[0].makeKeyAndOrderFront(self)
                    })
                    windowTimer.fire()
                } else {
                    // Fallback on earlier versions
                }
            default :
                break
            }
            
        case "WindowTitle:" :
            let title = command.replacingOccurrences(of: "WindowTitle: ", with: "")
            NSApp.windows[0].title = title
            
        case "Quit" :
            NSLog("Got to quit")
            completeLogin(authResult: .allow)
            
        case "Quit:" :
            NSLog("Got to quit")

            completeLogin(authResult: .allow)
            
        case "QuitKey:" :
            let quitKeyTemp = command.replacingOccurrences(of: "QuitKey: ", with: "")
            
            if quitKeyTemp.count == 1 {
                
                // exclude "q" as that's the system logout chord
                
                if quitKeyTemp != "q" {
                    quitKey = quitKeyTemp
                }
            }
            
        case "Restart:" :
            completeLogin(authResult: .allow)
            
        case "RestartNow:" :
            completeLogin(authResult: .allow)
            
        default:
            NSLog("Couldn't interpret command")
            break
        }
    }
    
    func sendNotification(text: String) {
        let notification = NSUserNotification()
        
        if logo != nil {
            notification.contentImage = logo
        }
        
        notification.title = "Setup notification"
        notification.informativeText = text
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
    @IBAction func HelpClick(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: helpURL)!)
    }
    
    @IBAction func continueButton(_ sender: Any) {
        let fileMgr = FileManager()
        let pathDone = "/Users/Shared/.DEPNotifyDone"
        fileMgr.createFile(atPath: pathDone, contents: nil, attributes: nil)
        completeLogin(authResult: .allow)
    }
    
    // Key pressing
    
    override func keyDown(with event: NSEvent) {
        
        switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
        case [.command, .control] where event.charactersIgnoringModifiers == quitKey:
            NSLog("Quitting...")
            completeLogin(authResult: .allow)
        case [.command, .control] where event.charactersIgnoringModifiers == demoKey:
            NSLog("Demoing...")
            demo()
        default:
            NSLog("changing other key")
            self.StatusText.stringValue = "Other Key Pressed"
            statusChange(status: "testing")
        }
    }
    
    /// - Parameter authResult:`Authorizationresult` enum value that indicates if login should proceed.
    fileprivate func completeLogin(authResult: AuthorizationResult) {
        let _ = mech?.fPlugin.pointee.fCallbacks.pointee.SetResult((mech?.fEngine)!, authResult)
        backgroundWindow.close()
        effectWindow.close()
        NSApp.abortModal()
        self.window?.close()
    }
    
    // DEMO
    
    func demo() {
        statusChange(status: "Beginning Installation")
        commandChange(command: "Determinate: 4")
        sleep(5)
        statusChange(status: "Installing things")
        sleep(5)
        commandChange(command: "MainTitle: NoMAD Login")
        sleep(5)
        completeLogin(authResult: .allow)
    }
    
    // Tracker
    
    // watch for updates and post them
    
    @objc func run() {
        
        NSLog("Running Tracker")
        
        // check to make sure the file exists
        
        if !fm.fileExists(atPath: self.path) {
            // need to make the file
            fm.createFile(atPath: self.path, contents: nil, attributes: nil)
        }
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        let outputHandle = pipe.fileHandleForReading
        outputHandle.waitForDataInBackgroundAndNotify()
        
        var dataAvailable : NSObjectProtocol!
        dataAvailable = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable,
                                                               object: outputHandle, queue: nil) {  notification -> Void in
                                                                let data = pipe.fileHandleForReading.availableData
                                                                if data.count > 0 {
                                                                    if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                                                                        print("Task sent some data: \(str)")
                                                                        self.commandChange(command: str as String)
                                                                    }
                                                                    outputHandle.waitForDataInBackgroundAndNotify()
                                                                } else {
                                                                    NotificationCenter.default.removeObserver(dataAvailable)
                                                                }
        }
        
        var dataReady : NSObjectProtocol!
        dataReady = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification,
                                                           object: pipe.fileHandleForReading, queue: nil) { notification -> Void in
                                                            print("Task terminated!")
                                                            NotificationCenter.default.removeObserver(dataReady)
        }
        
        task.launch()
        
        statusChange(status: "Reticulating Splines ")
        
    }
}
