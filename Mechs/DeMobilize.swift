//
//  DeMobilize.swift
//  NoMADLoginAD
//
//  Created by Joel Rennich on 12/20/17.
//  Copyright © 2017 NoMAD. All rights reserved.
//

import OpenDirectory
import os.log

// class to de-mobilize a mobile account

// Note: This class has no UI, and will need to be run priveleged to allow for local user account changes

// Workflow
//
// 1. take short name and find user account
// 2. if user is not a mobile account, mark auth as successful and return
// 3. if user is mobile, read in account, remove OriginalAuthAuthority and others
// 4. save account and mark auth as successful

// There is never a reason why we would stop the auth process

class DeMobilize : NoLoMechanism {
    
    // constants
    
    let kAuthAuthority = "dsAttrTypeNative:authentication_authority"
    
    let removeAttrs = [
//        "cached_groups",
//        "cached_auth_policy",
        "dsAttrTypeStandard:CopyTimestamp",
        "dsAttrTypeStandard:AltSecurityIdentities",
        "dsAttrTypeStandard:OriginalAuthenticationAuthority",
        "dsAttrTypeStandard:OriginalNodeName",
        "dsAttrTypeStandard:SMBSID",
        "dsAttrTypeStandard:SMBScriptPath",
        "dsAttrTypeStandard:SMBPasswordLastSet",
        "dsAttrTypeStandard:SMBGroupRID",
        "dsAttrTypeStandard:SMBPrimaryGroupSID",
        "dsAttrTypeStandard:PrimaryNTDomain",
        "dsAttrTypeStandard:AppleMetaRecordName",
        "dsAttrTypeStandard:MCXSettings",
        "dsAttrTypeStandard:MCXFlags",
        "dsAttrTypeNative:accountPolicyData"
    ]
    
    // globals
    var attributes : Array<String>? = nil
    
    @objc func run() {
        os_log("DeMobilize mech starting", log: demobilizeLog, type: .debug)

        // sanity check to ensure we have valid information and a local user
        os_log("Checking for password", log: demobilizeLog, type: .debug)
        if nomadPass == nil {
            os_log("Something went wrong, there is no password in user data", log: demobilizeLog, type: .error)
            // nothing to see here, most likely auth failed earlier on
            // we're just here for auditing purposes
            _ = denyLogin()
            return
        }
        
        // get local user record
        
        var records = [ODRecord]()
        let odsession = ODSession.default()
        
        do {
            os_log("Finding the DSLocal node", log: demobilizeLog, type: .debug)
            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
            os_log("Building OD query for name %{public}@", log: demobilizeLog, type: .debug, nomadUser!)
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers,
                                         attribute: kODAttributeTypeRecordName,
                                         matchType: ODMatchType(kODMatchEqualTo),
                                         queryValues: nomadUser,
                                         returnAttributes: kODAttributeTypeNativeOnly,
                                         maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            os_log("ODError while trying to check for local user: %{public}@", log: demobilizeLog, type: .error, error.localizedDescription)
            // not a local user so pass
            _ = allowLogin()
            return
        }
        
        if records.count == 0 {
            // no local user, this will most likely error out later, but not our place to say
            os_log("No local user found. Passing on demobilizing allow login.", log: demobilizeLog, type: .debug)
            _ = allowLogin()
            return
        }
        
        if records.count > 1 {
            // conflicting records, don't do anything
            os_log("More than one local user found for name. Passing on demobilizing allow login.", log: demobilizeLog, type: .debug)
            _ = allowLogin()
            return
        }
        
        // We now have a single local user, so let's put it into a variable
        
        let userRecord = records.first!
        os_log("Found local user: %{public}@", log: demobilizeLog, type: .debug, userRecord)

        var authAuthority: Any?
        
        do {
            authAuthority = try userRecord.values(forAttribute: kAuthAuthority) as Array
            os_log("Found user AuthAuthority: %{public}@", log: demobilizeLog, type: .debug, authAuthority.debugDescription)
        } catch {
            // No Auth Authorities, strange place, but we'll let other mechs decide
            os_log("No Auth Authorities, strange place, but we'll let other mechs decide. Allow login. Error: %{public}@", log: demobilizeLog, type: .error, error.localizedDescription)
            _ = allowLogin()
            return
        }
        
        var cachedAccount = false
        
        // iterate through the AuthAuthorities
        // remove the Active Directory one if you find it
        os_log("Looking for an Active Directory attribute on the account", log: demobilizeLog, type: .debug)

        if authAuthority != nil {
            attributes = authAuthority as? Array<String>
            os_log("Parsed AuthAuthority: %{public}@", log: demobilizeLog, type: .debug, attributes.debugDescription)
            for item in 0...((attributes?.count)! - 1) {
                if attributes![item].contains("Active Directory") {
                    os_log("Found an Active Directory attribute. removing it.", log: demobilizeLog, type: .debug)
                    attributes!.remove(at: item)
                    cachedAccount = true
                    break
                }
            }
        }
        
        if !cachedAccount {
            os_log("Account wasn't a cached account, but just a local one. Allow login.", log: demobilizeLog, type: .debug)
            _ = allowLogin()
            return
        }
        
        // now to clean up the account
        // first remove all the extraneous records
        // we mark the try with ? as we don't want to error just because the attribute doesn't exist
        os_log("Removing cached attributes", log: demobilizeLog, type: .debug)
        for attr in removeAttrs {
            os_log("Removing %{public}@", log: demobilizeLog, type: .debug, attr)
            try? userRecord.removeValues(forAttribute: attr)
        }
        
        // now to write back the cleansed AuthAuthority
        
        do {
            os_log("Write back the cleansed AuthAuthority", log: demobilizeLog, type: .debug)
            try userRecord.setValue(attributes!, forAttribute: kAuthAuthority)
        } catch {
            os_log("ODError while trying to write back account for user: %{public}@", log: demobilizeLog, type: .error, error.localizedDescription)
        }
        
        // group membership update?
        
        // unbind from AD?
        
        // we're done, let the user go
        os_log("Account modification complete, allow login.", log: demobilizeLog, type: .error)

        _ = allowLogin()
        os_log("DeMobilize Mech complete", log: demobilizeLog, type: .error)

    }
}
