//
//  SystemInfoHelper.swift
//  NoMADLoginAD
//
//  Created by Joel Rennich on 3/31/20.
//  Copyright © 2020 Orchard & Grove. All rights reserved.
//

import Foundation
import NoMAD_ADAuth

class SystemInfoHelper {
    
    func info() -> [String] {
        var info = [String]()
        
        info.append(ProcessInfo.processInfo.operatingSystemVersionString)
        info.append("Serial: \(getSerial())")
        info.append("MAC: \(getMAC())")
        info.append(ProcessInfo.processInfo.hostName)
        return info
    }
}
