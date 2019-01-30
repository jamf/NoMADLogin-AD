//
//  UserInputUI.swift
//  NoMADLoginOkta
//
//  Created by Joel Rennich on 9/29/18.
//  Copyright © 2018 Orchard & Grove. All rights reserved.
//

import Foundation
import Cocoa

class UserInputUI : NSWindowController {
    
    //MARK: IB Outlets
    
    @IBOutlet weak var logo: NSImageView!
    @IBOutlet weak var logoCell: NSImageCell!
    @IBOutlet weak var title: NSTextField!
    @IBOutlet weak var mainText: NSTextField!
    @IBOutlet weak var itemOneTitle: NSTextField!
    @IBOutlet weak var itemOne: NSTextField!
    @IBOutlet weak var itemTwoTitle: NSTextField!
    @IBOutlet weak var itemTwo: NSTextField!
    @IBOutlet weak var itemThreeTitle: NSTextField!
    @IBOutlet weak var itemThree: NSTextField!
    @IBOutlet weak var itemFourTitle: NSTextField!
    @IBOutlet weak var itemFour: NSTextField!
    @IBOutlet weak var popupOneTitle: NSTextField!
    @IBOutlet weak var popupOne: NSPopUpButton!
    @IBOutlet weak var popupTwoTitle: NSTextField!
    @IBOutlet weak var popupTwo: NSPopUpButton!
    @IBOutlet weak var popupThreeTitle: NSTextField!
    @IBOutlet weak var popupThree: NSPopUpButton!
    @IBOutlet weak var popupFourTitle: NSTextField!
    @IBOutlet weak var popupFour: NSPopUpButton!
    
    @IBOutlet weak var button: NSButton!
    
    // settings
    
    var inputSettings = [ String : AnyObject]()
    
    let kTextFields = "TextFields"
    let kPopUps = "PopUps"
    let kButton = "Button"
    
    struct TextItem {
        var title : String
        var placeholder : String?
        var secure : Bool?
    }
    
    struct PopupItem {
        var title : String
        var items : [String]
    }
    
    struct ButtonItem {
        var title : String
        var enabled : Bool?
    }
    
    //MARK: Mech things
    var mech: MechanismRecord?
    
    var backgroundWindow: NSWindow!
    var effectWindow: NSWindow!
    
    override func windowDidLoad() {
        os_log("Calling super.windowDidLoad", log: uiLog, type: .default)
        super.windowDidLoad()
        
        os_log("Setup window showing.", log: eulaLog, type: .default )
        
        os_log("Configure Setup window", log: eulaLog, type: .default)
        loginApperance()
        
        os_log("create background windows", log: eulaLog, type: .default)
        createBackgroundWindow()
        
        // set up the UI text
        
        if let titleText = getManagedPreference(key: .UserInputTitle) as? String {
            title.stringValue = titleText
        }
        
        if let main = getManagedPreference(key: .UserInputMainText) as? String {
            mainText.stringValue = main
        }
        
        run()
    }
    
    func run() {
        
        // build an array to make this easy
        
        let itemTitleList = [ itemOneTitle, itemTwoTitle, itemThreeTitle, itemFourTitle]
        let itemList = [ itemOne, itemTwo, itemThree, itemFour ]
        
        let popupTitleList = [ popupOneTitle, popupTwoTitle, popupThreeTitle, popupFourTitle]
        let popupList = [ popupOne, popupTwo, popupThree, popupFour ]
        
        // configure all of the UI
        
        if let textItems = inputSettings[kTextFields] as? [ AnyObject ] {
            for x in 0...(textItems.count - 1) {
                
                os_log("Updating text item", log: userinputLog, type: .default)
                
                if let item = textItems[x] as? [ String : AnyObject] {
                    
                    os_log("Enabling text item", log: userinputLog, type: .default)

                    itemTitleList[x]?.stringValue = item["title"] as? String ?? "ERROR"
                    itemList[x]?.placeholderString = item["placeholder"] as? String ?? ""
                    itemTitleList[x]?.isHidden = false
                    itemList[x]?.isHidden = false
                }
            }
        }
        
        if let popupItems = inputSettings[kPopUps] as? [ AnyObject ] {
                for x in 0...(popupItems.count - 1 ) {
                    
                    os_log("Updating popup item", log: userinputLog, type: .default)

                    if let item = popupItems[x] as? [ String : AnyObject] {
                    popupTitleList[x]?.stringValue = item["title"] as? String ?? "ERROR"
                    popupList[x]?.removeAllItems()
                        
                    popupList[x]?.addItems(withTitles: item["items"] as? [String] ?? [String]())
                    popupList[x]?.isHidden = false
                    popupTitleList[x]?.isHidden = false
                    }
            }
        }
        
        if let buttonItem = inputSettings[kButton] as? [String : AnyObject] {
            os_log("Updating button", log: userinputLog, type: .default)

            button.title = buttonItem["title"] as? String ?? "OK"
            button.isEnabled = buttonItem["enabled"] as? Bool ?? true
        }
        
        if let logoPath = getManagedPreference(key: .UserInputLogo) as? String {
            logoCell.image = NSImage(contentsOf: URL(fileURLWithPath: logoPath))
            logoCell.imageScaling = .scaleProportionallyUpOrDown
            logoCell.imageAlignment = .alignCenter
        }
        
    }
    
    @IBAction func clickButton(_ sender: Any) {
        
        // get all the info, then write it out
        
        writeSettings()
        
        completeLogin(authResult: .allow)
    }
    
    private func writeSettings() {
        
        // build an array to make this easy
        
        let itemTitleList = [ itemOneTitle, itemTwoTitle, itemThreeTitle, itemFourTitle]
        let itemList = [ itemOne, itemTwo, itemThree, itemFour ]
        
        let popupTitleList = [ popupOneTitle, popupTwoTitle, popupThreeTitle, popupFourTitle]
        let popupList = [ popupOne, popupTwo, popupThree, popupFour ]
        
        var settings = [ String : String]()
        
        for x in 0...(itemTitleList.count - 1) {
            
            if let title = itemTitleList[x]?.stringValue as? String {
                settings[title] = itemList[x]?.stringValue ?? "BLANK"
            }
        }
        
        for x in 0...(popupTitleList.count - 1 ) {
            if let title = popupTitleList[x]?.stringValue as? String {
                settings[title] = popupList[x]?.titleOfSelectedItem ?? "BLANK"
            }
        }
        
        var userInfo : Data
        
        do {
            userInfo = try PropertyListSerialization.data(fromPropertyList: settings,
                                                          format: PropertyListSerialization.PropertyListFormat.xml,
                                                          options: 0)
            
            var outputPath = URL.init(fileURLWithPath: "/tmp/userinput.plist")
            
            if let newPath = getManagedPreference(key: .UserInputOutputPath) as? String {
                outputPath = URL.init(fileURLWithPath: newPath)
            }
            
            try userInfo.write(to: outputPath)
            
        } catch {
            os_log("Unable to create User Input arguments.", log: userinputLog, type: .error)
            return
        }
    }
    
    /// Complete the NoLo process and either continue to the next Authorization Plugin or reset the NoLo window.
    ///
    /// - Parameter authResult:`Authorizationresult` enum value that indicates if login should proceed.
    fileprivate func completeLogin(authResult: AuthorizationResult) {
        os_log("Complete login process", log: uiLog, type: .default)
        let error = mech?.fPlugin.pointee.fCallbacks.pointee.SetResult((mech?.fEngine)!, authResult)
        if error != noErr {
            os_log("Got error setting authentication result", log: uiLog, type: .error)
        }
        NSApp.abortModal()
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
            effectWindow.alphaValue = 0.8
            effectWindow.orderFrontRegardless()
            effectWindow.canBecomeVisibleWithoutLogin = true
        }
    }
}

//MARK: - ContextAndHintHandling Protocol
extension UserInputUI: ContextAndHintHandling {}
