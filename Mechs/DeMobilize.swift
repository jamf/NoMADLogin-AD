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

    @objc func run() {
        // Check to see if demobilize is requested
        if UserDefaults(suiteName: "menu.nomad.NoMADLoginAD")?.bool(forKey: Preferences.DemobilizeUsers.rawValue) == false {
                os_log("Preference set to not demobilize, skipping.", log: createUserLog, type: .debug)
                _ = allowLogin()
                return
        }

        os_log("DeMobilize mech starting", log: demobilizeLog, type: .debug)
        guard let shortName = nomadUser else {
            os_log("Something went wrong, there is no user here at all", log: demobilizeLog, type: .error)
            _ = allowLogin()
            return
        }

        // sanity check to ensure we have valid information and a local user
        os_log("Checking for password", log: demobilizeLog, type: .debug)
        if nomadPass == nil {
            os_log("Something went wrong, there is no password in user data", log: demobilizeLog, type: .error)
            // nothing to see here, most likely auth failed earlier on
            // we're just here for auditing purposes
            _ = allowLogin()
            return
        }
        
        // get local user record
        guard let userRecord = getLocalRecord(shortName) else {
            // User wasn't found so just pass on the whole thing and let auth continue
            _ = allowLogin()
            return
        }

        // Is the local account cached from AD?
        if !isCachedAD(userRecord) {
            os_log("Account wasn't a cached account, but just a local one. Allow login.", log: demobilizeLog, type: .debug)
            _ = allowLogin()
            return
        }

        // Remove all the mobile account attributes
        if !demobilizeAccount(userRecord) {
            os_log("Something went wrong demobilizing. Restored account. Allow login.", log: demobilizeLog, type: .error)
            _ = allowLogin()
            return
        }

        // Remove the .account file for the user
        removeExternalAccount(shortName)

        os_log("Account modification complete, allow login.", log: demobilizeLog)
        _ = allowLogin()
        os_log("DeMobilize Mech complete", log: demobilizeLog)
    }

    //MARK: - Demobilzer Functions

    /// Given a user short name, search the DSLocal domain and return the `ODRecord` of a singular matching user.
    ///
    /// - Parameter shortName: A `String` of the user short name to check for.
    /// - Returns: An `ODRecord` from DSLocal of the matching name. If there is an error, multiple matches, or no matches found returns `nil`.
    func getLocalRecord(_ shortName: String) -> ODRecord? {
        var records = [ODRecord]()
        do {
            os_log("Finding the DSLocal node", log: demobilizeLog, type: .debug)
            let node = try ODNode.init(session: ODSession.default(), type: ODNodeType(kODNodeTypeLocalNodes))
            os_log("Building OD query for name %{public}@", log: demobilizeLog, type: .debug, shortName)
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers,
                                         attribute: kODAttributeTypeRecordName,
                                         matchType: ODMatchType(kODMatchEqualTo),
                                         queryValues: shortName,
                                         returnAttributes: kODAttributeTypeNativeOnly,
                                         maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            os_log("ODError while trying to check for local user: %{public}@", log: demobilizeLog, type: .error, error.localizedDescription)
            // not a local user so pass
            return nil
        }

        if records.count == 0 {
            // no local user, this will most likely error out later, but not our place to say
            os_log("No local user found. Passing on demobilizing allow login.", log: demobilizeLog, type: .debug)
            return nil
        }

        if records.count > 1 {
            // conflicting records, don't do anything
            os_log("More than one local user found for name. Passing on demobilizing allow login.", log: demobilizeLog, type: .debug)
            return nil
        }
        os_log("Found local user: %{public}@", log: demobilizeLog, type: .debug, records.first!)
        return records.first
    }


    /// Search in a given ODRecord for an Active Directory cached Authentication Authority.
    ///
    /// - Parameter userRecord: `ODRecord` to search in
    /// - Returns: `true` if the user is a mobile account cached from Active Directory. `false` if the user is not cached from Active Directory or an error occurs.
    func isCachedAD(_ userRecord: ODRecord) -> Bool {
        do {
            let authAuthority = try userRecord.values(forAttribute: kAuthAuthority) as! [String]
            os_log("Found user AuthAuthority: %{public}@", log: demobilizeLog, type: .debug, authAuthority.debugDescription)
            os_log("Looking for an Active Directory attribute on the account", log: demobilizeLog, type: .debug)
            return authAuthority.contains(where: {$0.contains(";LocalCachedUser;/Active Directory")})
        } catch {
            // No Auth Authorities, strange place, but we'll let other mechs decide
            os_log("No Auth Authorities, strange place, but we'll let other mechs decide. Allow login. Error: %{public}@", log: demobilizeLog, type: .error, error.localizedDescription)
            return false
        }
    }


    /// Removes the cached .account file for a mobile user that creates an external OD account.
    ///
    /// - Parameter shortname: Shortname of the user to remove. This should match the name of their homefolder.
    func removeExternalAccount(_ shortname: String) {
        let path = "/Users/" + shortname + "/.account"
        os_log("Removing external account file at %{public}@", log: demobilizeLog, type: .debug, path)
        if !FileManager.default.fileExists(atPath: path) {
            os_log("Could not find .account file, could be a really old mobile account?", log: demobilizeLog, type: .error)
            return
        }
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            os_log("FileManager error: ", log: demobilizeLog, type: .error, error.localizedDescription)
        }
        os_log("Deleted external account file", log: demobilizeLog, type: .debug)
    }

    /// Remove the OD attributes that make the OS see an account as a mobile account.
    ///
    /// - Parameter userRecord: The `ODRecord` to convert.
    /// - Returns: Returns `true` if the conversion was a success, otherwise returns `false`.
    func demobilizeAccount(_ userRecord: ODRecord) -> Bool {
        do {
            var authAuthority = try userRecord.values(forAttribute: kAuthAuthority) as! [String]
            os_log("Found user AuthAuthority: %{public}@", log: demobilizeLog, type: .debug, authAuthority.debugDescription)
            os_log("Looking for an Active Directory attribute on the account", log: demobilizeLog, type: .debug)
            if let adAuthority = authAuthority.index(where: {$0.contains(";LocalCachedUser;/Active Directory")}) {
                authAuthority.remove(at: adAuthority)
            } else {
                os_log("Could not remove AD from the AuthAuthority. Bail out and allow login.", log: demobilizeLog, type: .error)
                return false
            }
            os_log("Write back the cleansed AuthAuthority", log: demobilizeLog, type: .debug)
            try userRecord.setValue(authAuthority, forAttribute: kAuthAuthority)
        } catch {
            // No Auth Authorities, strange place, but we'll let other mechs decide
            os_log("Ran into a problem modifying the AuthAuthority. Allow login. Error: %{public}@", log: demobilizeLog, type: .error, error.localizedDescription)
            return false
        }

        // now to clean up the account
        // first remove all the extraneous records
        // we mark the try with ? as we don't want to error just because the attribute doesn't exist
        os_log("Removing cached attributes", log: demobilizeLog, type: .debug)
        for attr in removeAttrs {
            os_log("Removing %{public}@", log: demobilizeLog, type: .debug, attr)
            try? userRecord.removeValues(forAttribute: attr)
        }
        return true
    }
}
