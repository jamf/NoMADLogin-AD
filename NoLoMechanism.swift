//
//  NoLoMechanism.swift
//  NoLo
//
//  Created by Joel Rennich on 9/18/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Foundation
import Security

enum HintType : String {
    case user = "NoMAD.user"
    case pass = "NoMAD.pass"
    case first = "NoMAD.first"
    case last = "NoMAD.last"
    case full = "NoMAD.full"
}

// lots of constants for working with hints and contexts

class NoLoMechanism: NSObject {
    
    let contextDomain : NSString = "menu.nomad.NoMADLogin"
    
    var mechanism : UnsafePointer<MechanismRecord>
    
    @objc init(mechanism:UnsafePointer<MechanismRecord>) {
        self.mechanism = mechanism
    }
        
    let kNoMADUser = "NoMAD.user"
    let kNoMADPass = "NoMAD.pass"
    
    // PRAGMA: utility functions
    
    // return the username of the authenticating user
    
    var username: String? {
        get {
            var value : UnsafePointer<AuthorizationValue>? = nil
            var flags = AuthorizationContextFlags()
            var err: OSStatus = noErr
            err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.GetContextValue(
                mechanism.pointee.fEngine, kAuthorizationEnvironmentUsername, &flags, &value)
            
            if err != errSecSuccess {
                return nil
            }
            
            guard let username = NSString.init(bytes: value!.pointee.data!,
                                               length: value!.pointee.length,
                                               encoding: String.Encoding.utf8.rawValue)
                else { return nil }
            
            return username.replacingOccurrences(of: "\0", with: "") as String
        }
    }
    
    var password: String? {
        get {
            var value : UnsafePointer<AuthorizationValue>? = nil
            var flags = AuthorizationContextFlags()
            var err: OSStatus = noErr
            err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.GetContextValue(
                mechanism.pointee.fEngine, kAuthorizationEnvironmentPassword, &flags, &value)
            
            NSLog("attempted pass: " + String(describing: value.unsafelyUnwrapped))

            if err != errSecSuccess {
                return nil
            }
            guard let pass = NSString.init(bytes: value!.pointee.data!,
                                           length: value!.pointee.length,
                                           encoding: String.Encoding.utf8.rawValue)
                else { return nil }
            
            return pass.replacingOccurrences(of: "\0", with: "") as String
        }
    }
    
    var nomadUser: String? {
        get {
            var value : UnsafePointer<AuthorizationValue>? = nil
            var err: OSStatus = noErr
            err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.GetHintValue(mechanism.pointee.fEngine, kNoMADUser, &value)
            
            if err != errSecSuccess {
                NSLog("%@","couldn't retrieve hint value")
                return nil
            }
            
            let outputdata = Data.init(bytes: value!.pointee.data!, count: value!.pointee.length) //UnsafePointer<UInt8>(value!.pointee.data)
            guard let result = NSKeyedUnarchiver.unarchiveObject(with: outputdata)
                else {
                    NSLog("couldn't unpack hint value")
                    return nil
            }
            
            return (result as! String)
        }
    }
    
    var nomadPass: String? {
        get {
            var value : UnsafePointer<AuthorizationValue>? = nil
            var err: OSStatus = noErr
            err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.GetHintValue(mechanism.pointee.fEngine, kNoMADPass, &value)
            
            if err != errSecSuccess {
                NSLog("%@","couldn't retrieve hint value")
                return nil
            }
            
            let outputdata = Data.init(bytes: value!.pointee.data!, count: value!.pointee.length) //UnsafePointer<UInt8>(value!.pointee.data)
            guard let result = NSKeyedUnarchiver.unarchiveObject(with: outputdata)
                else {
                    NSLog("couldn't unpack hint value")
                    return nil
            }
            
            return (result as! String)
        }
    }
    
    var uid: uid_t {
        get {
            var value : UnsafePointer<AuthorizationValue>? = nil
            var flags = AuthorizationContextFlags()
            var uid : uid_t = 0
            if (self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.GetContextValue(
                mechanism.pointee.fEngine, ("uid" as NSString).utf8String!, &flags, &value)
                == errSecSuccess) {
                let uidData = Data.init(bytes: value!.pointee.data!, count: MemoryLayout<uid_t>.size)
                (uidData as NSData).getBytes(&uid, length: MemoryLayout<uid_t>.size)
            }
            return uid
        }
    }
    
    func setUID(uid: Int) {
        
       // var value : UnsafePointer<AuthorizationValue>? = nil
        let flags = AuthorizationContextFlags(rawValue: AuthorizationContextFlags.RawValue(1 << 0))

        var data = uid_t.init(bitPattern: Int32(uid))
        
        var value = AuthorizationValue(length: MemoryLayout<uid_t>.size, data: UnsafeMutableRawPointer.init(&data))
        
        let err : OSStatus = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.SetContextValue(
            self.mechanism.pointee.fEngine, "uid", flags, &value)
        
        NSLog("Setting context for: uid")
        NSLog(err.description)
    }
    
    func setGID(gid: Int) {
        
        // var value : UnsafePointer<AuthorizationValue>? = nil
        let flags = AuthorizationContextFlags(rawValue: AuthorizationContextFlags.RawValue(1 << 0))
        
        var data = gid_t.init(bitPattern: Int32(gid))
        
        var value = AuthorizationValue(length: MemoryLayout<gid_t>.size, data: UnsafeMutableRawPointer.init(&data))
        
        let err : OSStatus = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.SetContextValue(
            self.mechanism.pointee.fEngine, "gid", flags, &value)
        
        NSLog("Setting context for: gid")
        NSLog(err.description)
        
    }
    
    func getContext(contextType: String) -> String? {
        
        var value : UnsafePointer<AuthorizationValue>? = nil
        var flags = AuthorizationContextFlags()
        var err: OSStatus = noErr
        err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.GetContextValue(
            mechanism.pointee.fEngine, contextType, &flags, &value)
        
        if err != errSecSuccess {
            NSLog("NoMADLogin: couldn't retrieve context value: \(contextType)")
            return nil
        }
        
        if contextType == "longname" {
            let item = NSString.init(bytes: value!.pointee.data!,
                                     length: value!.pointee.length, encoding: String.Encoding.utf8.rawValue)
            return item as! String
        } else {
            let item = Data.init(bytes: value!.pointee.data!, count: value!.pointee.length)
            NSLog("\(contextType): \(String(describing: item))")
        }
        
        return nil
    }
    
    func getHint(hintType: String) -> String? {
        
        var value : UnsafePointer<AuthorizationValue>? = nil
        var err: OSStatus = noErr
        err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.GetHintValue(mechanism.pointee.fEngine, hintType, &value)
        
        if err != errSecSuccess {
            NSLog("NoMADLogin: couldn't retrieve hint value: \(hintType)")
            return nil
        }
        
        let outputdata = Data.init(bytes: value!.pointee.data!, count: value!.pointee.length)
        guard let result = NSKeyedUnarchiver.unarchiveObject(with: outputdata)
            else {
                NSLog("NoMADLogin: couldn't unpack hint value \(hintType)")
                return nil
        }
        return (result as! String)
    }
    
    func getArguments() {
        
        var value : UnsafePointer<AuthorizationValueVector>? = nil
        var err: OSStatus = noErr
        err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.GetArguments(mechanism.pointee.fEngine, &value)
        
        NSLog("Arguments: \(value.debugDescription)")
    }
    
    func getTokens() {
        
        var value : Unmanaged<CFArray>? = nil
        var err: OSStatus = noErr
        if #available(OSX 10.13, *) {
            err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.GetTokenIdentities(mechanism.pointee.fEngine, "" as CFTypeRef, &value)
        } else {
            // Fallback on earlier versions
        }
        
        NSLog("Tokens: \(value.debugDescription)")
        
    }
    
    func setHint(type: HintType, item: String) -> Bool {
        guard let data : Data = NSKeyedArchiver.archivedData(withRootObject: item)
            else {
                NSLog("NoLo:Failed to update hint: \(type)")
                return false
        }
        
        var value = AuthorizationValue(length: data.count,
                                       data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))
        
        let err : OSStatus = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.SetHintValue(
            self.mechanism.pointee.fEngine, type.rawValue, &value)
        
        return (err == errSecSuccess)
        
    }
    
    func setPassContext(pass: String) -> Bool {
        
        // silly two-step
        
        let flags = AuthorizationContextFlags(rawValue: AuthorizationContextFlags.RawValue(1 << 0))
        
        // add null byte to signify end of string
        
        let tempdata = pass + "\0"
        var data = tempdata.data(using: .utf8)
        
        //var value = AuthorizationValue(length: (data?.count)!, data: &data)
        
        var value = AuthorizationValue(length: (data?.count)!,
                                       data: UnsafeMutableRawPointer(mutating: (data as! NSData).bytes.bindMemory(to: Void.self, capacity: (data?.count)!)))
        
        let err : OSStatus =  self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.SetContextValue(
             self.mechanism.pointee.fEngine, kAuthorizationEnvironmentPassword, flags, &value)
        
        NSLog("Setting pass context")
        NSLog(err.description)
        
        return (err == errSecSuccess)
    }
    
    func setUserContext(user: String) -> Bool {
        
        // silly two-step
        
        // add null byte to signify end of string
        
        let tempdata = user + "\0"
        var data = tempdata.data(using: .utf8)
        
        let flags = AuthorizationContextFlags(rawValue: AuthorizationContextFlags.RawValue(1 << 0))
        
        var value = AuthorizationValue(length: (data?.count)!,
                                       data: UnsafeMutableRawPointer(mutating: (data! as NSData).bytes.bindMemory(to: Void.self, capacity: (data?.count)!)))
        
        let err : OSStatus =  self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.SetContextValue(
             self.mechanism.pointee.fEngine, kAuthorizationEnvironmentUsername, flags, &value)
        
        NSLog("Setting user context")
        NSLog(err.description)
        
        return (err == errSecSuccess)
    }
    
    func setPassHint(user: String) -> Bool {
        
        guard let data : Data = NSKeyedArchiver.archivedData(withRootObject: user)
            else {
                NSLog("NoLo:Failed to update user name in hint.");
                return false
        }
        
        var value = AuthorizationValue(length: data.count,
                                       data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))
        
        let err : OSStatus = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.SetHintValue(
            self.mechanism.pointee.fEngine, kNoMADPass, &value)
        
        return (err == errSecSuccess)
    }
    
    func setUserHint(user: String) -> Bool {
        
        guard let data : Data = NSKeyedArchiver.archivedData(withRootObject: user)
            else {
                NSLog("NoLo:Failed to update user name in hint.");
                return false
        }
        
        var value = AuthorizationValue(length: data.count,
                                       data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))
        
        let err : OSStatus = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.SetHintValue(
            self.mechanism.pointee.fEngine, kNoMADUser, &value)
        
        return (err == errSecSuccess)
    }
    
    func setContextItem(value: String, item: String) -> Bool {
        
        // silly two-step
        
        // add null byte to signify end of string
        
        let tempdata = value + "\0"
        var data = tempdata.data(using: .utf8)
        
        let flags = AuthorizationContextFlags(rawValue: AuthorizationContextFlags.RawValue(1 << 0))
        
        var value = AuthorizationValue(length: (data?.count)!,
                                       data: UnsafeMutableRawPointer(mutating: (data! as NSData).bytes.bindMemory(to: Void.self, capacity: (data?.count)!)))
        
        let err : OSStatus = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.SetContextValue(
            self.mechanism.pointee.fEngine, item, flags, &value)
        
        NSLog("Setting context for: \(item)")
        NSLog(err.description)
        
        return (err == errSecSuccess)
    }
    
    func setBoolHintValue(_ encryptionWasEnabled : NSNumber) -> Bool {
        // Try and unwrap the optional NSData returned from archivedDataWithRootObject
        // This can be decoded on the other side with unarchiveObjectWithData
        
        guard let data : Data = NSKeyedArchiver.archivedData(withRootObject: encryptionWasEnabled)
            else {
                NSLog("Crypt:MechanismInvoke:Check:setHintValue:[+] Failed to unwrap data");
                return false
        }
        
        // Fill the AuthorizationValue struct with our data
        var value = AuthorizationValue(length: data.count,
                                       data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))
        
        // Use the MechanismRecord SetHintValue callback to set the
        // inter-mechanism context data
        
        let err : OSStatus = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.SetHintValue(
            self.mechanism.pointee.fEngine, contextDomain.utf8String!, &value)
        
        return (err == errSecSuccess)
    }
    
    // This is how we get the inter-mechanism context data
    
    func getBoolHintValue() -> Bool {
        var value : UnsafePointer<AuthorizationValue>? = nil
        var err: OSStatus = noErr
        err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.GetHintValue(mechanism.pointee.fEngine, contextDomain.utf8String!, &value)
        if err != errSecSuccess {
            NSLog("%@","couldn't retrieve hint value")
            return false
        }
        let outputdata = Data.init(bytes: value!.pointee.data!, count: value!.pointee.length) //UnsafePointer<UInt8>(value!.pointee.data)
        guard let boolHint = NSKeyedUnarchiver.unarchiveObject(with: outputdata)
            else {
                NSLog("couldn't unpack hint value")
                return false
        }
        return (boolHint as AnyObject).boolValue
    }
    
    // Allow the login. End of the mechanism
    func allowLogin() -> OSStatus {
        NSLog("NoMADLogin: Login Allowed");
        var err: OSStatus = noErr
        err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.SetResult(
            mechanism.pointee.fEngine, AuthorizationResult.allow)
        NSLog("NoMADLogin: ", Int(err));
        return err
    }
    
    // disallow login
    
    func denyLogin() -> OSStatus {
        NSLog("NoMADLogin: Login Denied");
        var err: OSStatus = noErr
        err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.SetResult(
            mechanism.pointee.fEngine, AuthorizationResult.deny)
        NSLog("NoMADLogin: ", Int(err));
        return err
    }
    
    // functions for all mechs
    
    func checkUser(name: String) -> Bool {
        
        var records = [ODRecord]()
        let odsession = ODSession.default()
        
        // query OD local noes for the user name
        
        do {
            let node = try ODNode.init(session: odsession, type: UInt32(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: UInt32(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeNativeOnly, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            NSLog("Unable to get user account ODRecords")
            return false
        }
        
        if ( records.count > 0 ) {
            return true
        } else {
            return false
        }
    }
    
    
}
