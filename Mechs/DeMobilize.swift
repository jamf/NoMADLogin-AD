//
//  DeMobilize.swift
//  NoMADLoginAD
//
//  Created by Joel Rennich on 12/20/17.
//  Copyright © 2017 NoMAD. All rights reserved.
//

import Foundation
import OpenDirectory

// class to de-mobilize a mobile account

// Note: This class has no UI, and will need to be run priveleged to allow for local user account changes

// Workflow
//
// 1. take short name and find user account
// 2. if user is not a mobile account, mark auth as successul and return
// 3. if user is mobile, read in account, remove OriginalAuthAuthority and others
// 4. save account and mark auth as successful

// There is never a reason why we would stop the auth process

class DeMobilize : NoLoMechanism {
    
    // constants
    
    //
    
    func run() {
        // sanity check to ensure we have valid information and a local user
        
        if nomadPass == nil {
            
            // nothing to see here, most likely auth failed earlier on
            // we're just here for auditing purposes
            
            _ = denyLogin()
        }
        
        // get local user record
        
        var records = [ODRecord]()
        let odsession = ODSession.default()
        
        do {
            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeNativeOnly, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            let errorText = error.localizedDescription
            NSLog("%@",  "Unable to get user account ODRecord: \(errorText)")
            // not a local user so pass
            _ = allowLogin()
        }
        
        if records.count = 0 {
            // no local user, this will most likely error out later, but not our place to say
            NSLog("%@",  "No local user record, passing on de-mobilzing.")
            _ = allowLogin()
        }
        
        if records.count > 1 {
            // conflicting records, don't do anything
            NSLog("%@",  "Multiple local user records, passing on de-mobilzing.")

            _ = allowLogin()
        }
        
        // We now have a single local user, so let's put it into a variable
        
        let userRecord = records.first!
        
        var authAuthority: Any?
        
        do {
            authAuthority = try userRecord.values(forAttribute: "dsAttrTypeNative:authentication_authority") as Array
        } catch {
            // No Auth Authorities, strange place, but we'll let other mechs decide
            NSLog("%@",  "User did not have any AuthenticationAuthorities.")
            _ = allowLogin()
        }
        
        var localAccount = false
        
        // iterate through the AuthAuthorities
        
        if authAuthority != nil && authAuthority.count > 0 {
            attributes = authAuthority as! Array<String>
            for item in attributes {
                if item.contains("Active Directory") {
                    
                }
            }
        }

    }
}
