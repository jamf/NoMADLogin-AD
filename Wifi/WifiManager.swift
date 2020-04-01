//
//  WifiManager.swift
//  JamfConnectLogin
//
//  Created by Adrian Kubisztal on 16/07/2019.
//  Copyright © 2019 Jamf. All rights reserved.
//

import Foundation
import CoreWLAN
import Cocoa
import SystemConfiguration

enum SecurityType {
    case none // show without additional fields
    case password // show password field
    case enterpriseUserPassword //show user and password
}

@objc protocol WifiManagerDelegate: AnyObject {
    func wifiManagerFullyFinishedInternetConnectionTimer()
    @objc optional func wifiManagerConnectedToNetwork()
}

class WifiManager: CWEventDelegate {
    private var error: Error?
    private var currentInterface: CWInterface?

    var timer: Timer?
    var timerCount: Int = 0
    let timerMaxRepeatCount = 14
    weak var delegate: WifiManagerDelegate?

    init() {
        let defaultInterface = CWWiFiClient.shared().interface()
        CWWiFiClient.shared().delegate = self

        do {
            try CWWiFiClient.shared().startMonitoringEvent(with: .ssidDidChange)
        } catch {
            self.error = error
        }

        let name = defaultInterface?.interfaceName
        if defaultInterface != nil && name != nil {
            currentInterface = defaultInterface
        } else {
            let names = CWWiFiClient.interfaceNames()
            if (names?.count ?? 0) >= 1 && names?.contains("en1") ?? false {
                currentInterface = CWWiFiClient.shared().interface(withName: "en1")
            }
        }
    }

    func getCurrentSSID() -> String? {
        return currentInterface?.ssid()
    }

    func findNetworks() -> Set<CWNetwork>? {
        var result: Set<CWNetwork> = []
        do {
            result = try currentInterface?.scanForNetworks(withSSID: nil) ?? []
        } catch let err {
            self.error = err
            return nil
        }
        return result
    }

    func findNetworksToSSID() -> Set<String>? {

        guard let networks = findNetworks() else {
            return nil
        }

        var result: Set<String> = []
        for network in networks {
            guard let ssid = network.ssid else {
                continue
            }
            result.insert(ssid)
        }
        return result
    }

    func connectWifi(fromName name: String, password: String?, username: String?) -> Bool {
        if let cachedScanResults = currentInterface?.cachedScanResults() {
            for network in cachedScanResults {
                let searchName = network.ssid
                if (searchName == name) {
                    return connectWifi(with: network, password: password, username: username)
                }
            }
        }

        if let networks = findNetworks() {
            for network in networks {
                let searchName = network.ssid
                if (searchName == name) {
                    return connectWifi(with: network, password: password, username: username)
                }
            }
        }
        return false
    }

    func connectWifi(with network: CWNetwork, password: String?, username: String?) -> Bool {
        var result = false
        do {
            if username != nil && username != "" {
                try currentInterface?.associate(toEnterpriseNetwork: network, identity: nil, username: username, password: password)
            } else {
                try currentInterface?.associate(to: network, password: password)
            }
            result = true
        } catch {
            self.error = error
        }
        return result
    }

    var currentNetworkName: String {
        return CWWiFiClient.shared().interface(withName: nil)?.ssid() ?? ""
    }

    /** Labels describing the IEEE 802.11 physical layer mode */
    let SecurityLabels: [CWSecurity: String] = [
        /** No authentication required */
        .none:               "None",               // 0
        /** WEP security */
        .WEP:                "WEP",                // 1
        /** WPA personal authentication */
        .wpaPersonal:        "WPAPersonal",        // 2
        /** WPA/WPA2 personal authentication */
        .wpaPersonalMixed:   "WPAPersonalMixed",   // 3
        /** WPA2 personal authentication */
        .wpa2Personal:       "WPA2Personal",       // 4
        .personal:           "Personal",           // 5
        /** Dynamic WEP security */
        .dynamicWEP:         "DynamicWEP",         // 6
        /** WPA enterprise authentication */
        .wpaEnterprise:      "WPAEnterprise",      // 7
        /** WPA/WPA2 enterprise authentication */
        .wpaEnterpriseMixed: "WPAEnterpriseMixed", // 8
        /** WPA2 enterprise authentication */
        .wpa2Enterprise:     "WPA2Enterprise",     // 9
        .enterprise:         "Enterprise",         // 10
        /** Unknown security type */
        .unknown:            "Unknown",            // Int.max
    ]

    func networkSecurityType(_ network: CWNetwork) -> SecurityType {
        for securityLabel in SecurityLabels {
            if network.supportsSecurity(securityLabel.key) {
                if(securityLabel.key == .none) {
                    return .none
                } else if securityLabel.key == .enterprise || securityLabel.key == .wpaEnterprise
                    || securityLabel.key == .wpa2Enterprise || securityLabel.key == .wpaEnterpriseMixed {
                    return .enterpriseUserPassword
                } else {
                    return .password
                }
            }
        }
        return .password
    }
    
    func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }

        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == false {
            return false
        }

        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired
        return isReachable && !needsConnection
    }

    public func internetConnected() {
        self.timer = Timer(timeInterval: 0.5, target: self, selector: #selector(self.timerCheckInternetConnection), userInfo: nil, repeats: true)
        if let timer = self.timer {
            timer.fire()
            RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
        }
    }
    
    @objc private func timerCheckInternetConnection() {
        timerCount = timerCount + 1
        if self.isConnectedToNetwork() || timerCount >= timerMaxRepeatCount {
            self.timerCount = 0
            self.timer?.invalidate()
            self.timer = nil

            delegate?.wifiManagerFullyFinishedInternetConnectionTimer()
        }

        if  self.isConnectedToNetwork() {
            delegate?.wifiManagerConnectedToNetwork?()
        }
    }
}
