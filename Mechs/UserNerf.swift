//
//  UserNerf.swift
//  NoMADLoginAD
//
//  Created by Joel Rennich on 1/15/21.
//  Copyright © 2021 Orchard & Grove. All rights reserved.
//

import Foundation
import OpenDirectory

class UserNerf: NoLoMechanism {
    
    @objc func run() {
        
        guard getManagedPreference(key: .UserNerf) as? Bool ?? false else {
            allowLogin()
            return
        }
        
        let session = ODSession.default()
        
        if let user = nomadUser,
           let pass = nomadPass {
            do {
                // Save off the OD record
                os_log("Getting the ODRecord", log: userNerf, type: .debug)
                let node = try ODNode.init(session: session, type: ODNodeType(kODNodeTypeLocalNodes))
                let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: user, returnAttributes: kODAttributeTypeNativeOnly, maximumResults: 0)
                let records = try query.resultsAllowingPartial(false) as! [ODRecord]
                guard let userRecord = records.first else {
                    os_log("Error finding user account, denying login", log: userNerf)
                    denyLogin()
                    return
                }
                
                let newPass = UUID().uuidString
                try userRecord.changePassword(pass, toPassword: newPass)
                
                var path = "/var/db/usernerf.txt"
                
                if let newPath = getManagedPreference(key: .UserNerfPath) as? String {
                    path = newPath
                }
                
                if let passData = newPass.data(using: .utf8) {
                    let url = URL(fileURLWithPath: path)
                    try passData.write(to: url)
                } else {
                    os_log("Error: ", log: userNerf)
                }
            } catch {
                os_log("Error: %{public}@, denying login", log: userNerf, error.localizedDescription)
            }
            
            denyLogin()
            return
        }
    }
}
