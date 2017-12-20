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



// lots of constants for working with hints and contexts


/// Base class for authorization plugin mechanisms.
class NoLoMechanism: NSObject {

    ///  `string` is used to identify the authorization plugin context uniquely to this plugin
    let contextDomain: NSString = "menu.nomad.NoMADLoginAD"

    /// A pointer to the MechanismRecord `struct`
    let mech: MechanismRecord?

    /// A convience property to access the `AuthorizationCallbacks` of the Authorization plug-in.
    let mechCallbacks: AuthorizationCallbacks

    /// A convience property to access the `AuthorizationEngineRef` of the Authorization Mechanism.
    let mechEngine: AuthorizationEngineRef

    //MARK: - Initializer

    /// Initializer that simply sets up the convience properties to access parts of the authorization plug-in.
    ///
    /// - Parameter mechanism: The base `AuthorizationPlugin` to be used.
    @objc init(mechanism: UnsafePointer<MechanismRecord>) {
        self.mech = mechanism.pointee
        self.mechCallbacks = mechanism.pointee.fPlugin.pointee.fCallbacks.pointee
        self.mechEngine = mechanism.pointee.fEngine
        super.init()
    }

    var nomadUser: String? {
        get {
            guard let userName = getHint(type: .noMADUser) else {
                return nil
            }
            return userName
        }
    }

    var nomadPass: String? {
        get {
            guard let userPass = getHint(type: .noMADPass) else {
                return nil
            }
            return userPass
        }
    }

    var nomadFirst: String? {
        get {
            guard let firstName = getHint(type: .noMADFirst) else {
                return nil
            }
            return firstName
        }
    }

    var nomadLast: String? {
        get {
            guard let lastName = getHint(type: .noMADLast) else {
                return nil
            }
            return lastName
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
        let err : OSStatus = mechCallbacks.SetContextValue(self.mechEngine, "gid", flags, &value)
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
        if #available(OSX 10.13, *) {
            var value : Unmanaged<CFArray>? = nil
            defer {value?.release()}
            var err: OSStatus = noErr
            err = mechCallbacks.GetTokenIdentities(mechEngine, "" as CFTypeRef, &value)
            NSLog("Tokens: \(value.debugDescription)")
        } else {
            NSLog("%@", "LATokens are not supported on this version of macOS")
            return
        }
    }

    //MARK: - Mechanism Verdicts
    // Allow the login. End of the mechanism
    func allowLogin() -> OSStatus {
        NSLog("NoMADLogin: Login Allowed");
        let err = mechCallbacks.SetResult(mechEngine, .allow)
        NSLog("NoMADLogin: %i", Int(err));
        return err
    }
    
    // disallow login
    func denyLogin() -> OSStatus {
        NSLog("NoMADLogin: Login Denied");
        var err: OSStatus = noErr
        err = mechCallbacks.SetResult(mechEngine, .deny)
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
            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeNativeOnly, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            let errorText = error.localizedDescription
            NSLog("%@",  "Unable to get user account ODRecord: \(errorText)")
            return false
        }
        return records.count > 0 ? true : false
    }
}

//MARK: - ContextAndHintHandling Protocol
extension NoLoMechanism: ContextAndHintHandling {}

