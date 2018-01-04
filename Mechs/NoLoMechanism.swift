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
import os.log


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
        os_log("Initializing NoLoSwiftMech", log: noLoMechlog, type: .debug)
        self.mech = mechanism.pointee
        self.mechCallbacks = mechanism.pointee.fPlugin.pointee.fCallbacks.pointee
        self.mechEngine = mechanism.pointee.fEngine
        super.init()
        os_log("Initialization of NoLoSwiftMech complete", log: noLoMechlog, type: .debug)
    }

    var nomadUser: String? {
        get {
            guard let userName = getHint(type: .noMADUser) else {
                return nil
            }
            os_log("Computed nomadUser accessed: %{public}@", log: noLoMechlog, type: .debug, userName)
            return userName
        }
    }

    var nomadPass: String? {
        get {
            guard let userPass = getHint(type: .noMADPass) else {
                return nil
            }
            os_log("Computed nomadPass accessed: %@", log: noLoMechlog, type: .debug, userPass)
            return userPass
        }
    }

    var nomadFirst: String? {
        get {
            guard let firstName = getHint(type: .noMADFirst) else {
                return nil
            }
            os_log("Computed nomadFirst accessed: %{public}@", log: noLoMechlog, type: .debug, firstName)
            return firstName
        }
    }

    var nomadLast: String? {
        get {
            guard let lastName = getHint(type: .noMADLast) else {
                return nil
            }
            os_log("Computed nomadLast accessed: %{public}@", log: noLoMechlog, type: .debug, lastName)
            return lastName
        }
    }

    //context value - create user
    func setUID(uid: Int) {
        os_log("Setting context hint for UID: %{public}@", log: noLoMechlog, type: .debug, uid)
        let flags = AuthorizationContextFlags(rawValue: AuthorizationContextFlags.RawValue(1 << 0))
        var data = uid_t.init(bitPattern: Int32(uid))
        var value = AuthorizationValue(length: MemoryLayout<uid_t>.size, data: UnsafeMutableRawPointer.init(&data))
        let error = mechCallbacks.SetContextValue(mechEngine, "uid", flags, &value)
        if error != noErr {
            logOSStatusErr(error, sender: "setUID")
        }
    }

    //context value - create user
    func setGID(gid: Int) {
        os_log("Setting context hint for GID: %{public}@", log: noLoMechlog, type: .debug, gid)
        let flags = AuthorizationContextFlags(rawValue: AuthorizationContextFlags.RawValue(1 << 0))
        var data = gid_t.init(bitPattern: Int32(gid))
        var value = AuthorizationValue(length: MemoryLayout<gid_t>.size, data: UnsafeMutableRawPointer.init(&data))
        let error = mechCallbacks.SetContextValue(self.mechEngine, "gid", flags, &value)
        if error != noErr {
            logOSStatusErr(error, sender: "setGID")
        }
    }

    // log only
    func getArguments() {
        var value : UnsafePointer<AuthorizationValueVector>? = nil
        let error = mechCallbacks.GetArguments(mechEngine, &value)
        if error != noErr {
            logOSStatusErr(error, sender: "getArguments")
        }    }

    // log only
    func getTokens() {
        if #available(OSX 10.13, *) {
            var value : Unmanaged<CFArray>? = nil
            defer {value?.release()}
            let error = mechCallbacks.GetTokenIdentities(mechEngine, "" as CFTypeRef, &value)
            if error != noErr {
                logOSStatusErr(error, sender: "getTokens")
            }
        } else {
            os_log("Tokens are not supported on this version of macOS", log: noLoMechlog, type: .default)

        }
    }

    //MARK: - Mechanism Verdicts
    // Allow the login. End of the mechanism
    func allowLogin() -> OSStatus {
        os_log("Allowing login", log: noLoMechlog, type: .default)
        let error = mechCallbacks.SetResult(mechEngine, .allow)
        if error != noErr {
            logOSStatusErr(error, sender: "allowLogin")
        }
        return error
    }
    
    // disallow login
    func denyLogin() -> OSStatus {
        os_log("Denying login", log: noLoMechlog, type: .default)
        let error = mechCallbacks.SetResult(mechEngine, .deny)
        if error != noErr {
            logOSStatusErr(error, sender: "denyLogin")
        }
        return error
    }

    func logOSStatusErr(_ error: OSStatus, sender: String) {
        os_log("Error setting %{public}@ context hint: %{public}@", log: noLoMechlog, type: .error, sender, error)
    }

    //MARK: - Directory Service Utilities

    /// Checks to see if a given user exits in the DSLocal OD node.
    ///
    /// - Parameter name: The shortname of the user to check as a `String`.
    /// - Returns: `true` if the user already exists locally. Otherwise `false`.
    class func checkForLocalUser(name: String) -> Bool {
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
            return false
        }
        return records.count > 0 ? true : false
    }
}

//MARK: - ContextAndHintHandling Protocol
extension NoLoMechanism: ContextAndHintHandling {}
