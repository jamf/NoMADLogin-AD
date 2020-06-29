//
//  PKINIT.swift
//  NoMADLoginAD
//
//  Created by Joel Rennich on 3/12/20.
//  Copyright © 2020 Orchard & Grove. All rights reserved.
//

import Foundation
import LocalAuthentication
import GSS.apple
import OpenDirectory

struct CardIdentity {
    let principal: String
    let pkhh: String
    let identity: SecIdentity
}

class PKINIT: NoLoMechanism {
    
    // small class to attempt PKINIT on login
    // first pull from Jamf Connect PKINIT identities
    // then loop through certs on the card and attempt to login
    
 @objc func run() {
        let username = usernameContext ?? ""
        
        let (uid, home) = checkUIDandHome(name: username)

        guard let homeDir = home else {
            os_log("Unable to get home directory path.", log: pkinitLog, type: .error)
            allowLogin()
            return
        }

        guard let userUID = uid else {
            os_log("Unable to get uid.", log: pkinitLog, type: .error)
            allowLogin()
            return
        }
        
        // switch uid to user so we have access to home directory and other things
        //seteuid(userUID)
        
        guard var accounts = findCerts() else {
            os_log("No attached tokens, exiting", log: pkinitLog, type: .default)
            allowLogin()
            return
        }

        if let defaults = UserDefaults.init(suiteName: "com.jamf.connect.pkinit"),
            let pkinitAccounts = defaults.array(forKey: "Identities") as? [String:String] {
            var tempAccounts = [CardIdentity]()
            for identity in pkinitAccounts {
                for account in accounts {
                    if account.pkhh == identity.value {
                        os_log("Found principal: %{public}@", log: pkinitLog, type: .default, identity.key)
                        os_log("pkhh: %{public}@", log: pkinitLog, type: .default, account.pkhh)
                        tempAccounts.append(CardIdentity.init(principal: identity.key, pkhh: account.pkhh, identity: account.identity))
                    }
                }
            }
            accounts = tempAccounts
        }
        getTickets(identities: accounts)
        allowLogin()
    }
    
    private func getTickets(identities: [CardIdentity]) {
        let kutil = KUtil.init()
        guard let pin = passwordContext else { return }
        for identity in identities {
            os_log("Getting ticket for %{public}@", log: pkinitLog, type: .default, identity.principal)
            _ = kutil.getCreds(cert: identity.identity, user: identity.principal, pin: pin)
        }
    }
    
    private func findCerts() -> [CardIdentity]? {
        var myErr: OSStatus
        var searchReturn: AnyObject?
        var myCert: SecCertificate?

        var identities = [CardIdentity]()
        
        if #available(OSX 10.12, *) {
            let tokenSearchDict: [String:AnyObject] = [
                //kSecAttrAccessGroup as String:  kSecAttrAccessGroupToken,
                kSecClass as String: kSecClassIdentity,
                kSecReturnAttributes as String: true as AnyObject,
                kSecReturnRef as String: true as AnyObject,
                kSecMatchLimit as String : kSecMatchLimitAll as AnyObject
            ]
        
            myErr = SecItemCopyMatching(tokenSearchDict as CFDictionary, &searchReturn)
            os_log("Finished cert search", log: pkinitLog, type: .default)
            
            if myErr != 0 || searchReturn == nil {
                os_log("No certs found", log: pkinitLog, type: .default)
                return nil
            }

            let foundIdentites = searchReturn as! CFArray as Array
            os_log("Found identities: %{public}@", log: pkinitLog, type: .default, String(foundIdentites.count))
            
            for identity in foundIdentites {
                myErr = SecIdentityCopyCertificate(identity["v_Ref"] as! SecIdentity, &myCert)
                
                if myErr != 0 {
                    os_log("Unable to get SecIdentity", log: pkinitLog, type: .default)
                    continue
                }
                
                var pkhh = "Unknown"
                
                if let certPubKeyHash = identity["pkhh"] as? Data,
                    let pkhhString = String.init(data: certPubKeyHash, encoding: .utf8) {
                    pkhh = pkhhString
                }
                os_log("Found identity: %{public}@", log: pkinitLog, type: .default, (identity.debugDescription ?? "NO DEBUG DESCRIPTION"))
                identities.append(CardIdentity.init(principal: getPrincipal(identity: myCert!), pkhh: pkhh, identity: identity["v_Ref"] as! SecIdentity))
            }
        }
        
        if identities.count > 1 {
            return identities
        } else {
            return nil
        }
    }
    
    private func getCreds(cert: SecIdentity, user: String, pin: String="") -> String {
        
        let context = LAContext.init()
        
        context.setCredential(pin.data(using: String.Encoding.utf8), type: LACredentialType.applicationPassword)
        
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
                
        if major == 0 {
            return ""
        } else {
            os_log("Kerberos Error: %{public}@", log: pkinitLog, type: .default, err.debugDescription)
            return err.debugDescription
        }
    }
    
    fileprivate func checkUIDandHome(name: String) -> (uid_t?, String?) {
        os_log("Checking for local username", log: noLoMechlog, type: .debug)
        var records = [ODRecord]()
        let odsession = ODSession.default()
        do {
            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeNativeOnly, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            let errorText = error.localizedDescription
            os_log("ODError while trying to check for local user: %{public}@", log: noLoMechlog, type: .error, errorText)
            return (nil, nil)
        }

        if records.count > 1 {
            os_log("More than one record. ", log: keychainAddLog, type: .info)
        }
            do {
                let home = try records.first?.values(forAttribute: kODAttributeTypeNFSHomeDirectory) as? [String] ?? nil
                let uid = try records.first?.values(forAttribute: kODAttributeTypeUniqueID) as? [String] ?? nil
                
                let uidt = uid_t.init(Double.init((uid?.first) ?? "0")! )
                return ( uidt, home?.first ?? nil)
            } catch {
                os_log("Unable to get home.", log: keychainAddLog, type: .error)
                return (nil, nil)
            }
    }
    
    fileprivate func getPrincipal(identity: SecCertificate) -> String {

        let noPrincipal = "none"

        // get all the OIDS

        guard let myOIDs : NSDictionary = SecCertificateCopyValues(identity, nil, nil) else { return noPrincipal }

        // find which OID we want

        guard let oid = myOIDs["2.5.29.17"] else { return noPrincipal }

            if myOIDs["2.5.29.17"] == nil {
                return noPrincipal
            }

            guard let myUPNRaw = myOIDs["2.5.29.17"] as? NSDictionary else { return noPrincipal }
            guard let myUPNValues = myUPNRaw["value"] as? NSArray else { return noPrincipal }
            for item in myUPNValues {
                // cast to dictionary
                guard let itemDict = item as? NSDictionary else { return noPrincipal }
                guard let itemValue = itemDict["value"] as? String else { return noPrincipal }
                if itemValue.contains("@") {
                    //print(itemValue)
                    return itemValue
                }
            }

        // return the principal that we think we want

        return noPrincipal
    }
}
