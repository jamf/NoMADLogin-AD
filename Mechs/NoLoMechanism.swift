//
//  NoLoMechanism.swift
//  NoLo
//
//  Created by Joel Rennich on 9/18/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Security
import OpenDirectory
import os.log

/// Base class for authorization plugin mechanisms.
class NoLoMechanism: NSObject {

    ///  `string` is used to identify the authorization plugin context uniquely to this plugin
    let contextDomain: NSString = "menu.nomad.login"

    /// If there is an AD domain set via preferences it will be here in a `String`
    var managedDomain: String?
    
    /// If there is a SSL requirement set via preferences it will be here in a `Bool`. Defaults to `false`
    var isSSLRequired: Bool?

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
        self.managedDomain = getManagedPreference(key: .ADDomain) as? String
        self.isSSLRequired = getManagedPreference(key: .LDAPOverSSL) as? Bool
        os_log("Initialization of NoLoSwiftMech complete", log: noLoMechlog, type: .debug)
    }

    
    var nomadUser: String? {
        get {
            guard let userName = getHint(type: .noMADUser) as? String else {
                return nil
            }
            os_log("Computed nomadUser accessed: %{public}@", log: noLoMechlog, type: .debug, userName)
            return userName
        }
    }
    
    var nomadDomain: String? {
        get {
            guard let domainName = getHint(type: .noMADDomain) as? String else {
                return nil
            }
            os_log("Computed nomadDomain accessed: %{public}@", log: noLoMechlog, type: .debug, domainName)
            return domainName
        }
    }

    var nomadPass: String? {
        get {
            guard let userPass = getHint(type: .noMADPass) as? String else {
                return nil
            }
            os_log("Computed nomadPass accessed: %@", log: noLoMechlog, type: .debug, userPass)
            return userPass
        }
    }

    var nomadFirst: String? {
        get {
            guard let firstName = getHint(type: .noMADFirst) as? String else {
                return nil
            }
            os_log("Computed nomadFirst accessed: %{public}@", log: noLoMechlog, type: .debug, firstName)
            return firstName
        }
    }

    var nomadLast: String? {
        get {
            guard let lastName = getHint(type: .noMADLast) as? String else {
                return nil
            }
            os_log("Computed nomadLast accessed: %{public}@", log: noLoMechlog, type: .debug, lastName)
            return lastName
        }
    }


    var usernameContext: String? {
        get {
            var value : UnsafePointer<AuthorizationValue>? = nil
            var flags = AuthorizationContextFlags()
            var err: OSStatus = noErr
            err = mechCallbacks.GetContextValue(
                mechEngine, kAuthorizationEnvironmentUsername, &flags, &value)

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

    var passwordContext: String? {
        get {
            var value : UnsafePointer<AuthorizationValue>? = nil
            var flags = AuthorizationContextFlags()
            var err: OSStatus = noErr
            err = mechCallbacks.GetContextValue(
                mechEngine, kAuthorizationEnvironmentPassword, &flags, &value)

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

    /// A simple method to send an OSStatus Error to the os.log error log with the name of the calling function.
    ///
    /// - Parameters:
    ///   - error: The `OSStatus` error to log.
    ///   - sender: A `String` to register as the sender of the error.
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
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeAllAttributes, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            let errorText = error.localizedDescription
            os_log("ODError while trying to check for local user: %{public}@", log: noLoMechlog, type: .error, errorText)
            return false
        }
        let isLocal = records.isEmpty ? false : true
        os_log("Results of local user check %{public}@", log: noLoMechlog, type: .debug, isLocal.description)
        return isLocal
    }

    class func verifyUser(name: String, auth: String) -> Bool {
        os_log("Finding user record", log: noLoMechlog, type: .debug)
        var records = [ODRecord]()
        let odsession = ODSession.default()
        var isValid = false
        do {
            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeAllAttributes, maximumResults: 0)
            records = try query.resultsAllowingPartial(false) as! [ODRecord]
            isValid = ((try records.first?.verifyPassword(auth)) != nil)
        } catch {
            let errorText = error.localizedDescription
            os_log("ODError while trying to check for local user: %{public}@", log: noLoMechlog, type: .error, errorText)
            return false
        }
        return isValid
    }
}


//MARK: - ContextAndHintHandling Protocol
extension NoLoMechanism: ContextAndHintHandling {}
