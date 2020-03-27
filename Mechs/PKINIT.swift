//
//  PKINIT.swift
//  NoMADLoginAD
//
//  Created by Joel Rennich on 3/12/20.
//  Copyright © 2020 Orchard & Grove. All rights reserved.
//

import Foundation

struct CardIdentity {
    let principal: String
    let pkhh: String
    let identity: SecIdentity
}

class PKINIT: NoLoMechanism {
    
    // small class to attempt PKINIT on login
    // first pull from Jamf Connect PKINIT identities
    // then loop through certs on the card and attempt to login
    
    func run() {
        
    }
    
    private func findCerts() -> [CardIdentity]? {
        var myErr: OSStatus
        var searchReturn: AnyObject?
        var myCert: SecCertificate?

        if #available(OSX 10.12, *) {
            let tokenSearchDict: [String:AnyObject] = [
                kSecAttrAccessGroup as String:  kSecAttrAccessGroupToken,
                kSecClass as String: kSecClassIdentity,
                kSecReturnAttributes as String: true as AnyObject,
                kSecReturnRef as String: true as AnyObject,
                kSecMatchLimit as String : kSecMatchLimitAll as AnyObject
            ]
        
            myErr = SecItemCopyMatching(tokenSearchDict as CFDictionary, &searchReturn)
            
            if myErr != 0 || searchReturn == nil {
                return nil
            }

            let foundIdentites = searchReturn as! CFArray as Array

            for identity in foundIdentites {
                myErr = SecIdentityCopyCertificate(identity["v_Ref"] as! SecIdentity, &myCert)
                if myErr != 0 {
                    continue
                }
            }
        }
        return nil
    }
}
