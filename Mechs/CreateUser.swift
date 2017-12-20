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

/// Mechanism to create a local user and homefolder.
class CreateUser: NoLoMechanism {
    let session = ODSession.default()
    @objc func run() {
        if nomadPass != nil && !NoLoMechanism.checkForLocalUser(name: nomadUser!) {
            guard let uid = findFirstAvaliableUID() else {
                NSLog("%@", "Could not find an avaliable UID")
                return
            }
            createUser(shortName: nomadUser!,
                       first: nomadFirst!,
                       last: nomadLast!,
                       pass: nomadPass!,
                       uid: uid,
                       gid: "20",
                       guid: UUID().uuidString,
                       changePass: true,
                       attributes: nil)

            //  set some user variables
            // these don't do what they should, so keeping for future use
            
            //setContextItem(value: "/Users/test", item: "home")
            //setContextItem(value: "Test User", item: "longname")
            //setContextItem(value: "/bin/bash", item: "shell")
            
            setGID(gid: 20)
            setUID(uid: Int(uid)!)

            cliTask("/usr/sbin/createhomedir -c")
            
            allowLogin()

        } else {
            // no user to create
            NSLog("Skipping account creation")
            allowLogin()
        }
    }
    
    // mark utility functions
    
    func createUser(shortName: String, first: String, last: String, pass: String?, uid: String?, gid: String?, guid: String?, changePass: Bool?, attributes: [String:Any]?) {
        

        var newRecord: ODRecord?
        
        // note for anyone following behind me
        // you need to specify the attribute values in an array
        // regardless of if there's more than one value or not
        
        var attrs: [AnyHashable:Any] = [
            kODAttributeTypeFirstName: [first],
            kODAttributeTypeLastName: [last],
            kODAttributeTypeFullName: [first + " " + last],
            kODAttributeTypeNFSHomeDirectory: [ "/Users/" + shortName ],
            kODAttributeTypeUserShell: ["/bin/bash"],
            //"dsAttrTypeNative:writers_AvatarRepresentation" : [name],
        ]
        
        if uid != nil {
            attrs[kODAttributeTypeUniqueID] = [uid]
        }
        
        if gid != nil {
            attrs[kODAttributeTypePrimaryGroupID] = [gid]
        }
        
        if guid != nil {
            attrs[kODAttributeTypeGUID] = [guid]
        }
        
        do {
            let node = try ODNode.init(session: session, type: ODNodeType(kODNodeTypeLocalNodes))
            newRecord = try node.createRecord(withRecordType: kODRecordTypeUsers, name: shortName, attributes: attrs)
        } catch {
            print("Unable to create account.")
        }

        var password = pass

        if pass == nil || pass == "" {
            password = randomString(length: 24)
            
            // TODO: stash in system keychain
            //print("Using random password: " + password!)
        }
        
        // now to set the password, skipping this step if NONE is specified
        
        if pass != "NONE" {
            do {
                try newRecord?.changePassword(nil, toPassword: password)
            } catch {
                NSLog("Error setting password")
            }
        }
        
        if changePass! {
            do {
                try newRecord?.addValue(shortName, toAttribute: "dsAttrTypeNative:writers_passwd")
            } catch {
                print("Unable to set writers_passwd")
            }
        }
        
        // now to add any arbitrary attributes
        
        if attributes != nil {
            for item in attributes! {
                do {
                    try newRecord?.addValue(item.value, toAttribute: item.key)
                } catch {
                    print(item.key)
                }
            }
        }
        
        // add a timestamp
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
                NSLog("%@",  "Ran into an ODError: \(errorText)")
                return nil
            }
        }
        return newUID
    }
}
