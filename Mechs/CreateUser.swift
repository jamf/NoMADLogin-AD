//
//  CreateUser.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/21/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Foundation
import OpenDirectory

/// Mechanism to create a local user and homefolder.
class CreateUser: NoLoMechanism {
    
    @objc func run() {
        if nomadPass != nil && !checkForLocalUser(name: (nomadUser?.components(separatedBy: "@").first)!) {

            let cleanedUser = nomadUser?.components(separatedBy: "@").first ?? "error"

            createUser(name: cleanedUser,
                       first: "Test",
                       last: "User",
                       pass: self.nomadPass!,
                       uid: "10001",
                       gid: "20",
                       guid: nil,
                       changePass: true,
                       attributes: nil)

            //  set some user variables
            // these don't do what they should, so keeping for future use
            
            //setContextItem(value: "/Users/test", item: "home")
            //setContextItem(value: "Test User", item: "longname")
            //setContextItem(value: "/bin/bash", item: "shell")
            
            setGID(gid: 20)
            setUID(uid: 10001)

            cliTask("/usr/sbin/createhomedir -c")
            
            allowLogin()

        } else {
            // no user to create
            NSLog("Skipping account creation")
            allowLogin()
        }
    }
    
    // mark utility functions
    
    func createUser(name: String, first: String, last: String, pass: String?, uid: String?, gid: String?, guid: String?, changePass: Bool?, attributes: [String:Any]?) {
        
        let nodeName = "/Local/Default"
        let odsession = ODSession.default()
        
        var newRecord: ODRecord?
        
        // note for anyone following behind me
        // you need to specify the attribute values in an array
        // regardless of if there's more than one value or not
        
        var attrs: [AnyHashable:Any] = [
            kODAttributeTypeFirstName: [first],
            kODAttributeTypeLastName: [last],
            kODAttributeTypeFullName: [first + " " + last],
            kODAttributeTypeNFSHomeDirectory: [ "/Users/" + name ],
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
        } else {
            // TESTING
            //attrs[kODAttributeTypeGUID] = ["204F65A9-C7AF-4717-B90B-3045345E189B"]
            //uuid_generate_random(<#T##out: UnsafeMutablePointer<UInt8>!##UnsafeMutablePointer<UInt8>!#>)
        }
        
        do {
            let node = try ODNode.init(session: odsession, name: nodeName)
            newRecord = try node.createRecord(withRecordType: kODRecordTypeUsers, name: name, attributes: attrs)
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
                try newRecord?.addValue(name, toAttribute: "dsAttrTypeNative:writers_passwd")
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
}
