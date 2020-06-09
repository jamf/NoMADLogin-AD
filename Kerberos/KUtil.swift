//
//  KUtil.swift
//  nomad-pkinit
//
//  Created by Joel Rennich on 10/8/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Foundation
import GSS.apple
import LocalAuthentication

class KUtil {
    
    var running = false
    var pass = ""
    var loopCount = 0
    
    func getCreds(cert: SecIdentity, user: String, pin: String="") -> String {
        
        // no idea why this constant went away... but we'll use -3 to ensure we can pass the PIN
        guard let pinCredentialType = LACredentialType.init(rawValue: -3) else { return ""}
        running = true
        
        let context = LAContext.init()
        
        context.setCredential(pin.data(using: String.Encoding.utf8), type: pinCredentialType)
        
        if #available(OSX 10.13, *) {
            context.interactionNotAllowed = true
        }
        
        var cred: gss_cred_id_t? = gss_cred_id_t.init(bitPattern: 1)
        
        var err: Unmanaged<CFError>? = nil
        let name = GSSCreateName(user as CFTypeRef, &__gss_c_nt_user_name_oid_desc, &err)
        
        let attrs: [String:AnyObject] = [
            kGSSICCertificate as String: cert as AnyObject,
            kGSSICAuthenticationContext as String: context as AnyObject,
        ]
        
        let major = gss_aapl_initial_cred(name!, &__gss_krb5_mechanism_oid_desc, attrs as CFDictionary, &cred!, &err)
        
        if loopCount > 0 {
            loopCount = loopCount - 1
        }
        
        running = false
        
        if major == 0 {
            return ""
        } else {
            return err?.takeRetainedValue().localizedDescription ?? "Unknown Error"
        }
    }
    
    func getTickets(user: String) -> String {
        running = true
        
        var cred: gss_cred_id_t? = gss_cred_id_t.init(bitPattern: 1)
        
        var err: Unmanaged<CFError>? = nil
        let name = GSSCreateName(user as CFTypeRef, &__gss_c_nt_user_name_oid_desc, &err)
        
        let attrs: [String:AnyObject] = [
            kGSSICPassword : pass as AnyObject,
            ]
        
        let major = gss_aapl_initial_cred(name!, &__gss_krb5_mechanism_oid_desc, attrs as CFDictionary, &cred!, &err)
        
        running = false
        
        pass = ""
        
        if major == 0 {
            return ""
        } else {
            return err.debugDescription
        }
    }
}
