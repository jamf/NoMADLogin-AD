//
//  WifiView.swift
//  JamfConnectLogin
//
//  Created by Adrian Kubisztal on 11/07/2019.
//  Copyright © 2019 Jamf. All rights reserved.
//

import Cocoa
import CoreWLAN

class WifiView: NSView, NibLoadable, WifiManagerDelegate {
    @IBOutlet weak var backgroundView: NonBleedingView!
    @IBOutlet weak var mainView: NonBleedingView!
    @IBOutlet weak var networkSearch: NSButton!
    @IBOutlet weak var networkPassword: NSSecureTextField!
    @IBOutlet weak var networkUsername: NSTextField!
    @IBOutlet weak var networkConnectButton: NSButton!
    @IBOutlet weak var networkstatusLabel: NSTextField!
    @IBOutlet weak var networkWifiPopup: NSPopUpButton!
    @IBOutlet weak var networkOpenStatusLabel: NSTextField!
    @IBOutlet weak var dismissButton: NSButton!
    @IBOutlet weak var networkConnectionSpinner: NSProgressIndicator!
    @IBOutlet weak var addSSIDMenuButton: NSButton!
    @IBOutlet weak var addSSIDButton: NSButton!
    @IBOutlet weak var addSSIDText: NSTextField!
    @IBOutlet weak var addSSIDLabel: NSTextField!
    

    @IBOutlet weak var networkUsernameView: NonBleedingView!
    @IBOutlet weak var networkPasswordView: NonBleedingView!

    var networks: Set<CWNetwork> = []

    private var defaultFadeDuration: TimeInterval = 0.1
    private var completionHandler: (() -> Void)?

    let wifiManager = WifiManager()

    override func awakeFromNib() {
        super.awakeFromNib()
        configureAppearance()
        networkSearch.performClick(nil)
        networkSearch.becomeFirstResponder()

        networkWifiPopup.action = #selector(networkWifiPopupChangedValue)
        networkWifiPopup.target = self
        perform(#selector(connectNetwork), with: nil, afterDelay: 0.05)

        self.networkConnectionSpinner.isHidden = true
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        fadeInBackgroundView()
    }

    @objc func connectNetwork() {
        let networks = wifiManager.findNetworks()

        os_log("Remove allItems")
        self.networkWifiPopup.removeAllItems()

        guard let allNetworks = networks else {
            os_log("Unable to find any networks", log: wifiLog, type: .debug)
            self.networkWifiPopup.addItem(withTitle: "No networks")
            return
        }

        if allNetworks.count == 0 {
            os_log("Unable to find any networks", log: wifiLog, type: .debug)
            self.networkWifiPopup.addItem(withTitle: "No networks")
        }

        for network in allNetworks {
            if let networkName = network.ssid {
                 self.networkWifiPopup.addItem(withTitle: networkName)
                 self.networks.insert(network)
            }
        }

        configCurrentNetwork()
        configureUIForSelectedNetwork()
    }


    func configCurrentNetwork() {
        if let currentNetworkName = wifiManager.getCurrentSSID() {
             self.networkstatusLabel.stringValue = "Connected to: \(currentNetworkName)"
        } else {
             self.networkstatusLabel.stringValue = "Connected via Ethernet"
        }
    }

    private func configureAppearance() {
        self.networkWifiPopup.removeAllItems()
        self.networkWifiPopup.addItem(withTitle: "Loading networks...")
        self.networkOpenStatusLabel.stringValue = "Open WiFi Networks are not supported. Find and join a secure Network to continue."
        mainView.wantsLayer = true
        mainView.layer?.backgroundColor = NSColor.white.cgColor
        mainView.layer?.cornerRadius = 5
        mainView.alphaValue = 1

        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = NSColor.lightGray.cgColor
        backgroundView.alphaValue = 0
    }

    private func fadeInBackgroundView() {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = defaultFadeDuration
        backgroundView.animator().alphaValue = 1
        NSAnimationContext.endGrouping()
    }

    func set(completionHandler: (() -> Void)?) {
        self.completionHandler = completionHandler
    }

    @IBAction func dismissButton(_ sender: Any) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = defaultFadeDuration
        animator().removeFromSuperview()
        NSAnimationContext.endGrouping()
        completionHandler?()
    }

    @IBAction func connectButton(_ sender: Any) {
        self.disableUI()
        for network in networks {
            if let networkName = network.ssid {
                if (networkName == self.networkWifiPopup.selectedItem?.title) {
                    let userPassword = self.networkPassword.stringValue
                    let username = self.networkUsername.stringValue
                    let connected = wifiManager.connectWifi(with: network, password: userPassword, username: username)
                    if connected {
                        self.networkstatusLabel.stringValue = "Connected to: \(networkName)"
                        wifiManager.delegate = self
                        wifiManager.internetConnected()
                        return
                    } else {
                        self.networkstatusLabel.stringValue = "No Internet Connection"
                        self.enableUI()
                    }
                }
            }
        }
    }


    @objc func networkWifiPopupChangedValue() {
        self.configureUIForSelectedNetwork()
    }

    func configureUIForSelectedNetwork() {
        self.networkUsername.stringValue = ""
        self.networkPassword.stringValue = ""
        self.networkOpenStatusLabel.isHidden = true
        for network in networks {
            if let networkName = network.ssid {
                if (networkName == self.networkWifiPopup.selectedItem?.title) {
                    let securityType = wifiManager.networkSecurityType(network)

                    switch securityType {
                    case .none:
                        self.networkUsernameView.isHidden = true
                        self.networkPasswordView.isHidden = true
                        self.networkOpenStatusLabel.isHidden = false
                    case .password:
                        self.networkUsernameView.isHidden = true
                        self.networkPasswordView.isHidden = false
                    case .enterpriseUserPassword:
                        self.networkUsernameView.isHidden = false
                        self.networkPasswordView.isHidden = false
                    }
                }
            }
        }
    }

    @IBAction func searchButton(_ sender: Any) {
        connectNetwork()
    }
    
    @IBAction func addSSIDMenuButton(_ sender: Any){
        // Hiding the other UI
        networkUsernameView.isHidden = true
        networkPasswordView.isHidden = true
        
        // Making the add SSID options appear
        addSSIDText.isHidden = false
        addSSIDLabel.isHidden = false
        addSSIDButton.isHidden = false
    }
    
    @IBAction func addSSIDButton(_ sender: Any){
        
        // Searching for a WiFi of that name
        let results = wifiManager.findNetworkWithSSID(ssid: addSSIDText.stringValue) ?? []
        
        // Adding the SSID to the network list
        for network in results {
            self.networkWifiPopup.addItem(withTitle: network.ssid ?? "")
        }
        networks.formUnion(results)
        
        // Making the other views accessible again
        networkUsernameView.isHidden = false
        networkPasswordView.isHidden = false
        
        // Hiding the add SSID options
        addSSIDText.isHidden = true
        addSSIDLabel.isHidden = true
        addSSIDButton.isHidden = true
    }

    // In order to prevent a NSView from bleeding it's mouse events to the parent, one must implement the empty methods.
    override func mouseDown(with event: NSEvent) {}

    override func mouseDragged(with event: NSEvent) {}

    override func mouseUp(with event: NSEvent) {}

    func disableUI() {
        DispatchQueue.main.async {
            self.networkSearch.isEnabled = false
            self.networkWifiPopup.isEnabled = false
            self.networkUsername.isEnabled = false
            self.networkPassword.isEnabled = false
            self.networkConnectButton.isEnabled = false
            self.networkConnectionSpinner.isHidden = false
            self.networkConnectionSpinner.startAnimation(self)
        }
    }

    func enableUI() {
        DispatchQueue.main.async {
            self.networkSearch.isEnabled = true
            self.networkWifiPopup.isEnabled = true
            self.networkUsername.isEnabled = true
            self.networkPassword.isEnabled = true
            self.networkConnectButton.isEnabled = true
            self.networkConnectionSpinner.isHidden = true
            self.networkConnectionSpinner.stopAnimation(self)
        }
    }

    // MARK: - WifiManager Delegates
    func wifiManagerFullyFinishedInternetConnectionTimer() {
        self.enableUI()
        self.networkUsername.stringValue = ""
        self.networkPassword.stringValue = ""
    }

    func wifiManagerConnectedToNetwork() {
        self.dismissButton(self)
    }
}
