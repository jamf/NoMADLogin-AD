//
//  CreateUser.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/21/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Foundation
import OpenDirectory
import NoMAD_ADAuth
import os.log

/// Mechanism to create a local user and homefolder.
class CreateUser: NoLoMechanism {
    let session = ODSession.default()
    @objc func run() {
        os_log("CreateUser mech starting", log: createUserLog, type: .debug)
        if nomadPass != nil && !NoLoMechanism.checkForLocalUser(name: nomadUser!) {
            guard let uid = findFirstAvaliableUID() else {
                os_log("Could not find an avaliable UID", log: createUserLog, type: .debug)
                return
            }
            createUser(shortName: nomadUser!,
                       first: nomadFirst!,
                       last: nomadLast!,
                       pass: nomadPass!,
                       uid: uid,
                       gid: "20",
                       guid: UUID().uuidString,
                       canChangePass: true,
                       attributes: nil)

            os_log("Creating local homefolder", log: createUserLog, type: .debug)
            cliTask("/usr/sbin/createhomedir -c")
            os_log("Account creation complete, allowing login", log: createUserLog, type: .debug)
        } else {
            // no user to create
            os_log("Skipping local account creation", log: createUserLog, type: .default)
            os_log("Account creation skipped, allowing login", log: createUserLog, type: .debug)
        }
        allowLogin()
        os_log("CreateUser mech complete", log: createUserLog, type: .debug)
    }
    
    // mark utility functions
    func createUser(shortName: String, first: String, last: String, pass: String?, uid: String, gid: String, guid: String, canChangePass: Bool, attributes: [String:Any]?) {
        var newRecord: ODRecord?
        os_log("Creating new local account for: %{public}@", log: createUserLog, type: .default, shortName)
        os_log("New user attributes. first: %{public}@, last: %{public}@, uid: %{public}@, gid: %{public}@, guid: %{public}@", log: createUserLog, type: .debug, first, last, uid, gid, guid)

        // note for anyone following behind me
        // you need to specify the attribute values in an array
        // regardless of if there's more than one value or not
        
        let attrs: [AnyHashable:Any] = [
            kODAttributeTypeFirstName: [first],
            kODAttributeTypeLastName: [last],
            kODAttributeTypeFullName: [first + " " + last],
            kODAttributeTypeNFSHomeDirectory: [ "/Users/" + shortName ],
            kODAttributeTypeUserShell: ["/bin/bash"],
            kODAttributeTypeUniqueID: [uid],
            kODAttributeTypePrimaryGroupID: [gid],
            kODAttributeTypeGUID: [guid]
        ]

        do {
            os_log("Creating user account in local ODNode", log: createUserLog, type: .debug)
            let node = try ODNode.init(session: session, type: ODNodeType(kODNodeTypeLocalNodes))
            newRecord = try node.createRecord(withRecordType: kODRecordTypeUsers, name: shortName, attributes: attrs)
        } catch {
            let errorText = error.localizedDescription
            os_log("Unable to create account. Error: %{public}@", log: createUserLog, type: .error, errorText)
            return
        }
        os_log("Local ODNode user created successfully", log: createUserLog, type: .debug)

        if canChangePass {
            do {
                os_log("Setting writers_passwd for new local user", log: createUserLog, type: .debug)
                try newRecord?.addValue(shortName, toAttribute: "dsAttrTypeNative:writers_passwd")
            } catch {
                os_log("Unable to set writers_passwd", log: createUserLog, type: .error)
            }
        }

        if let password = pass {
            do {
                os_log("Setting password for new local user", log: createUserLog, type: .debug)
                try newRecord?.changePassword(nil, toPassword: password)
            } catch {
                os_log("Error setting password for new local user", log: createUserLog, type: .error)
            }
        }

        if let attributes = attributes {
            os_log("Setting additional attributes for new local user", log: createUserLog, type: .debug)
            for item in attributes {
                do {
                    os_log("Setting %{public}@ attribute for new local user", log: createUserLog, type: .debug, item.key)
                    try newRecord?.addValue(item.value, toAttribute: item.key)
                } catch {
                    os_log("Failed to set additional attribute: %{public}@", log: createUserLog, type: .error, item.key)
                }
            }
        }
        os_log("User creation complete for: %{public}@", log: createUserLog, type: .debug, shortName)
    }
    
    // func to get a random string
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }

    func findFirstAvaliableUID() -> String? {
        var newUID = ""
        os_log("Checking for avaliable UID", log: createUserLog, type: .debug)
        for potentialUID in 501... {
            do {
                let node = try ODNode.init(session: session, type: ODNodeType(kODNodeTypeLocalNodes))
                let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeUniqueID, matchType: ODMatchType(kODMatchEqualTo), queryValues: String(potentialUID), returnAttributes: kODAttributeTypeNativeOnly, maximumResults: 0)
                let records = try query.resultsAllowingPartial(false) as! [ODRecord]
                if records.isEmpty {
                    newUID = String(potentialUID)
                    break
                }
            } catch {
                let errorText = error.localizedDescription
                os_log("ODError searching for avaliable UID: %{public}@", log: createUserLog, type: .error, errorText)
                return nil
            }
        }
        os_log("Found first avaliable UID: %{public}@", log: createUserLog, type: .default, newUID)
        return newUID
    }
}
