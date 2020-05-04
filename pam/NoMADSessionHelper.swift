//
//  NoMADSessionHelper.swift
//  pam
//
//  Created by Joel Rennich on 4/25/20.
//  Copyright © 2020 Orchard & Grove. All rights reserved.
//

import Foundation
import NoMAD_ADAuth

@objc class NoMADSessionHelper: NSObject {
        
    var session: NoMADSession?
        
        @objc init?(user: String, password: String) {
            guard let name = user.components(separatedBy: "@").first,
                let domain = user.components(separatedBy: "@").last else { return nil }
            session = NoMADSession.init(domain: domain.uppercased(), user: name)
            session?.userPass = password
        }
        
        @objc func authenticate() -> Bool {
            session?.delegate = self
            session?.authenticate()
            return false
        }
    }

    extension NoMADSessionHelper: NoMADUserSessionDelegate {
        
        func NoMADAuthenticationSucceded() {
            return
        }
        
        func NoMADAuthenticationFailed(error: NoMADSessionError, description: String) {
            return
        }
        
        func NoMADUserInformation(user: ADUserRecord) {
            return
        }
    }
