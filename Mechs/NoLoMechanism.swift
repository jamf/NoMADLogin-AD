//
//  NoLoMechanism.swift
//  NoLo
//
//  Created by Joel Rennich on 9/18/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Foundation
import Security
import OpenDirectory

enum HintType: String {
    case user = "NoMAD.user"
    case pass = "NoMAD.pass"
    case first = "NoMAD.first"
    case last = "NoMAD.last"
    case full = "NoMAD.full"
}

// lots of constants for working with hints and contexts


/// Base class for authorization plugin mechanisms.
class NoLoMechanism: NSObject {

    ///  `string` is used to identify the authorization plugin context uniquely to this plugin
    let contextDomain: NSString = "menu.nomad.NoMADLoginAD"
    let kNoMADUser = "NoMAD.user"
    let kNoMADPass = "NoMAD.pass"

    /// A pointer to the MechanismRecord `struct`
    let mechanism: UnsafePointer<MechanismRecord>

    /// A convience property to access the `AuthorizationCallbacks` of the Authorization plug-in.
    let mechCallbacks: AuthorizationCallbacks

    /// A convience property to access the `AuthorizationEngineRef` of the Authorization Mechanism.
    let mechEngine: AuthorizationEngineRef

    //MARK: - Initializer

    /// Initializer that simply sets up the convience properties to access parts of the authorization plug-in.
    ///
    /// - Parameter mechanism: The base `AuthorizationPlugin` to be used.
    @objc init(mechanism: UnsafePointer<MechanismRecord>) {
        self.mechanism = mechanism
        self.mechCallbacks = mechanism.pointee.fPlugin.pointee.fCallbacks.pointee
        self.mechEngine = mechanism.pointee.fEngine
        super.init()
    }

    //MARK: - Generic Context Value Functions

    //context value - log only
    func getContextValueFor(contextType: String) -> String? {

        var value: UnsafePointer<AuthorizationValue>?
        var flags = AuthorizationContextFlags()
        let err = mechCallbacks.GetContextValue(mechEngine, contextType, &flags, &value)

        if err != errSecSuccess {
            NSLog("NoMADLogin: couldn't retrieve context value: \(contextType)")
            return nil
        }

        if contextType == "longname" {
           return String.init(bytesNoCopy: value!.pointee.data!, length: value!.pointee.length, encoding: .utf8, freeWhenDone: false)
//            let item = NSString.init(bytes: value!.pointee.data!, length: value!.pointee.length, encoding: String.Encoding.utf8.rawValue)
//            return item as! String
        } else {
            let item = Data.init(bytes: value!.pointee.data!, count: value!.pointee.length)
            NSLog("\(contextType): \(String(describing: item))")
        }

        return nil
    }

    //context value - unused
    func setContextItem(value: String, contextType: String) -> Bool {

        // silly two-step

        // add null byte to signify end of string

        let tempdata = value + "\0"
        var data = tempdata.data(using: .utf8)

        let flags = AuthorizationContextFlags(rawValue: AuthorizationContextFlags.RawValue(1 << 0))

        var value = AuthorizationValue(length: (data?.count)!,
                                       data: UnsafeMutableRawPointer(mutating: (data! as NSData).bytes.bindMemory(to: Void.self, capacity: (data?.count)!)))

        let err = mechCallbacks.SetContextValue(mechEngine, contextType, flags, &value)

        NSLog("Setting context for: \(contextType)")
        NSLog(err.description)

        return (err == errSecSuccess)
    }


    //MARK: - Generic Hint Value Functions

    // hint value - log only
    func getHint(hintType: String) -> String? {

        var value : UnsafePointer<AuthorizationValue>? = nil
        var err: OSStatus = noErr
        err = mechCallbacks.GetHintValue(mechEngine, hintType, &value)

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

    // hint value  - unused
    func setHint(type: HintType, item: String) -> Bool {
        guard let data : Data = NSKeyedArchiver.archivedData(withRootObject: item)
            else {
                NSLog("NoLo:Failed to update hint: \(type)")
                return false
        }

        var value = AuthorizationValue(length: data.count,
                                       data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))

        let err : OSStatus = mechCallbacks.SetHintValue(mechEngine, type.rawValue, &value)

        return (err == errSecSuccess)
    }

    //context value - log only
    var username: String? {
        get {
            var value : UnsafePointer<AuthorizationValue>? = nil
            var flags = AuthorizationContextFlags()
            var err: OSStatus = noErr
            err = mechCallbacks.GetContextValue(mechEngine, kAuthorizationEnvironmentUsername, &flags, &value)
            
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

    //context value  - unused
    var password: String? {
        get {
            var value : UnsafePointer<AuthorizationValue>? = nil
            var flags = AuthorizationContextFlags()
            var err: OSStatus = noErr
            err = mechCallbacks.GetContextValue(mechEngine, kAuthorizationEnvironmentPassword, &flags, &value)
            
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

    // hint value - create user
    var nomadUser: String? {
        get {
            var value : UnsafePointer<AuthorizationValue>? = nil
            var err: OSStatus = noErr
            err = mechCallbacks.GetHintValue(mechEngine, kNoMADUser, &value)
            
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

    // hint value - create user
    var nomadPass: String? {
        get {
            var value : UnsafePointer<AuthorizationValue>? = nil
            var err: OSStatus = noErr
            err = mechCallbacks.GetHintValue(mechEngine, kNoMADPass, &value)
            
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

    //context value - log only
    var uid: uid_t {
        get {
            var value : UnsafePointer<AuthorizationValue>? = nil
            var flags = AuthorizationContextFlags()
            var uid : uid_t = 0
            if mechCallbacks.GetContextValue(mechEngine, ("uid" as NSString).utf8String!, &flags, &value) == errSecSuccess {
                let uidData = Data.init(bytes: value!.pointee.data!, count: MemoryLayout<uid_t>.size)
                (uidData as NSData).getBytes(&uid, length: MemoryLayout<uid_t>.size)
            }
            return uid
        }
    }

    //context value - create user
    func setUID(uid: Int) {
        
       // var value : UnsafePointer<AuthorizationValue>? = nil
        let flags = AuthorizationContextFlags(rawValue: AuthorizationContextFlags.RawValue(1 << 0))

        var data = uid_t.init(bitPattern: Int32(uid))
        
        var value = AuthorizationValue(length: MemoryLayout<uid_t>.size, data: UnsafeMutableRawPointer.init(&data))
        
        let err : OSStatus = mechCallbacks.SetContextValue(mechEngine, "uid", flags, &value)
        
        NSLog("Setting context for: uid")
        NSLog(err.description)
    }

    //context value - create user
    func setGID(gid: Int) {
        
        // var value : UnsafePointer<AuthorizationValue>? = nil
        let flags = AuthorizationContextFlags(rawValue: AuthorizationContextFlags.RawValue(1 << 0))
        
        var data = gid_t.init(bitPattern: Int32(gid))
        
        var value = AuthorizationValue(length: MemoryLayout<gid_t>.size, data: UnsafeMutableRawPointer.init(&data))
        
        let err : OSStatus = mechCallbacks.SetContextValue(
            self.mechEngine, "gid", flags, &value)
        
        NSLog("Setting context for: gid")
        NSLog(err.description)
        
    }


    // log only
    func getArguments() {
        
        var value : UnsafePointer<AuthorizationValueVector>? = nil
        var err: OSStatus = noErr
        err = mechCallbacks.GetArguments(mechEngine, &value)
        
        NSLog("Arguments: \(value.debugDescription)")
    }

    // log only
    func getTokens() {
        
        var value : Unmanaged<CFArray>? = nil
        var err: OSStatus = noErr
        if #available(OSX 10.13, *) {
            err = mechCallbacks.GetTokenIdentities(mechEngine, "" as CFTypeRef, &value)
        } else {
            // Fallback on earlier versions
        }
        
        NSLog("Tokens: \(value.debugDescription)")
        
    }



    //context value  - unused
    func setPassContext(pass: String) -> Bool {
        
        // silly two-step
        
        let flags = AuthorizationContextFlags(rawValue: AuthorizationContextFlags.RawValue(1 << 0))
        
        // add null byte to signify end of string
        
        let tempdata = pass + "\0"
        var data = tempdata.data(using: .utf8)
        
        //var value = AuthorizationValue(length: (data?.count)!, data: &data)
        
        var value = AuthorizationValue(length: (data?.count)!,
                                       data: UnsafeMutableRawPointer(mutating: (data as! NSData).bytes.bindMemory(to: Void.self, capacity: (data?.count)!)))
        
        let err : OSStatus =  mechCallbacks.SetContextValue(
             mechEngine, kAuthorizationEnvironmentPassword, flags, &value)
        
        NSLog("Setting pass context")
        NSLog(err.description)
        
        return (err == errSecSuccess)
    }

    //context value  - unused
    func setUserContext(user: String) -> Bool {
        
        // silly two-step
        
        // add null byte to signify end of string
        
        let tempdata = user + "\0"
        var data = tempdata.data(using: .utf8)
        
        let flags = AuthorizationContextFlags(rawValue: AuthorizationContextFlags.RawValue(1 << 0))
        
        var value = AuthorizationValue(length: (data?.count)!,
                                       data: UnsafeMutableRawPointer(mutating: (data! as NSData).bytes.bindMemory(to: Void.self, capacity: (data?.count)!)))
        
        let err : OSStatus =  mechCallbacks.SetContextValue(
             mechEngine, kAuthorizationEnvironmentUsername, flags, &value)
        
        NSLog("Setting user context")
        NSLog(err.description)
        
        return (err == errSecSuccess)
    }

    // hint value  - unused
    func setPassHint(user: String) -> Bool {
        
        guard let data : Data = NSKeyedArchiver.archivedData(withRootObject: user)
            else {
                NSLog("NoLo:Failed to update user name in hint.");
                return false
        }
        
        var value = AuthorizationValue(length: data.count,
                                       data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))
        
        let err : OSStatus = mechCallbacks.SetHintValue(
            mechEngine, kNoMADPass, &value)
        
        return (err == errSecSuccess)
    }

    // hint value - - unused
    func setUserHint(user: String) -> Bool {
        
        guard let data : Data = NSKeyedArchiver.archivedData(withRootObject: user)
            else {
                NSLog("NoLo:Failed to update user name in hint.");
                return false
        }
        
        var value = AuthorizationValue(length: data.count,
                                       data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))
        
        let err : OSStatus = mechCallbacks.SetHintValue(
            mechEngine, kNoMADUser, &value)
        
        return (err == errSecSuccess)
    }



    // hint value  - unused
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
        
        let err : OSStatus = mechCallbacks.SetHintValue(
            mechEngine, contextDomain.utf8String!, &value)
        
        return (err == errSecSuccess)
    }
    
    // This is how we get the inter-mechanism context data

    //context value  - unused
    func getBoolHintValue() -> Bool {
        var value : UnsafePointer<AuthorizationValue>? = nil
        var err: OSStatus = noErr
        err = mechCallbacks.GetHintValue(mechEngine, contextDomain.utf8String!, &value)
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

    //MARK: - Mechanism Verdicts
    // Allow the login. End of the mechanism
    func allowLogin() -> OSStatus {
        NSLog("NoMADLogin: Login Allowed");
        let err = mechCallbacks.SetResult(mechEngine, AuthorizationResult.allow)
        NSLog("NoMADLogin: %i", Int(err));
        return err
    }
    
    // disallow login
    func denyLogin() -> OSStatus {
        NSLog("NoMADLogin: Login Denied");
        var err: OSStatus = noErr
        err = mechCallbacks.SetResult(mechEngine, AuthorizationResult.deny)
        NSLog("NoMADLogin: %i", Int(err));
        return err
    }

    //MARK: - Directory Service Utilities

    /// Checks to see if a given user exits in the DSLocal OD node.
    ///
    /// - Parameter name: The shortname of the user to check as a `String`.
    /// - Returns: `true` if the user already exists locally. Otherwise `false`.
    class func checkForLocalUser(name: String) -> Bool {
        var records = [ODRecord]()
        let odsession = ODSession.default()

        do {
            let node = try ODNode.init(session: odsession, type: UInt32(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: UInt32(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeNativeOnly, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            let errorText = error.localizedDescription
            myLogger.logit(.base, message: "Unable to get user account ODRecord: \(errorText)")
            return false
        }
        return records.count > 0 ? true : false
    }
}
