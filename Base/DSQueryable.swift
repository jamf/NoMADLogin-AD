//
//  DSQueryable.swift
//  NoMADLogin-AD
//
//  Created by Josh Wisenbaker on 8/20/18.
//  Copyright © 2018 Orchard & Grove. All rights reserved.
//

import OpenDirectory

enum DSQueryableResults {
    case localUser
}

enum DSQueryableErrors: Error {
    case notLocalUser
    case multipleUsersFound
}

/// The `DSQueryable` protocol allows adopters to easily search and manipulate the DSLocal node of macOS.
public protocol DSQueryable {}

// MARK: - Implimentations for DSQuerable protocol
public extension DSQueryable {

    /// `ODNode` to DSLocal for queries and account manipulation.
    public var localNode: ODNode? {
        do {
            os_log("Finding the DSLocal node", type: .debug)
            return try ODNode.init(session: ODSession.default(), type: ODNodeType(kODNodeTypeLocalNodes))
        } catch {
            os_log("ODError creating local node.", type: .error, error.localizedDescription)
            return nil
        }
    }

    /// Conviennce function to discover if a shortname has an existing local account.
    ///
    /// - Parameter shortName: The name of the user to search for as a `String`.
    /// - Returns: `true` if the user exists in DSLocal, `false` if not.
    /// - Throws: Either an `ODFrameworkErrors` or a `DSQueryableErrors` if there is an error or the user is not local.
    public func isUserLocal(_ shortName: String) throws -> Bool {
        do {
            _ = try getLocalRecord(shortName)
        } catch DSQueryableErrors.notLocalUser {
            return false
        } catch {
            throw error
        }
        return true
    }

    /// Checks a local username and password to see if they are valid.
    ///
    /// - Parameters:
    ///   - userName: The name of the user to search for as a `String`.
    ///   - userPass: The password for the user being tested as a `String`.
    /// - Returns: `true` if the name and password combo are valid locally. `false` if the validation fails.
    /// - Throws: Either an `ODFrameworkErrors` or a `DSQueryableErrors` if there is an error.
    public func isLocalPasswordValid(userName: String, userPass: String) throws -> Bool {
        do {
            let userRecord = try getLocalRecord(userName)
            try userRecord.verifyPassword(userPass)
        } catch {
            let castError = error as NSError
            switch castError.code {
            case Int(kODErrorCredentialsInvalid.rawValue):
                os_log("Tested password for user account: %{public}@ is not valid.", type: .default, userName)
                return false
            default:
                throw error
            }
        }
        return true
    }

    /// Searches DSLocal for an account short name and returns the `ODRecord` for the user if found.
    ///
    /// - Parameter shortName: The name of the user to search for as a `String`.
    /// - Returns: The `ODRecord` of the user if one is found in DSLocal.
    /// - Throws: Either an `ODFrameworkErrors` or a `DSQueryableErrors` if there is an error or the user is not local.
    public func getLocalRecord(_ shortName: String) throws -> ODRecord {
        do {
            os_log("Building OD query for name %{public}@", type: .default, shortName)
            let query = try ODQuery.init(node: localNode,
                                         forRecordTypes: kODRecordTypeUsers,
                                         attribute: kODAttributeTypeRecordName,
                                         matchType: ODMatchType(kODMatchEqualTo),
                                         queryValues: shortName,
                                         returnAttributes: kODAttributeTypeNativeOnly,
                                         maximumResults: 0)
            let records = try query.resultsAllowingPartial(false) as! [ODRecord]

            if records.count > 1 {
                os_log("More than one local user found for name.", type: .default)
                throw DSQueryableErrors.multipleUsersFound
            }
            guard let record = records.first else {
                os_log("No local user found. Passing on demobilizing allow login.", type: .default)
                throw DSQueryableErrors.notLocalUser
            }
            os_log("Found local user: %{public}@", record)
            return record
        } catch {
            os_log("ODError while trying to check for local user: %{public}@", type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Finds all local user records on the Mac.
    ///
    /// - Returns: A `Array` that contains the `ODRecord` for every account in DSLocal.
    /// - Throws: An error from `ODFrameworkErrors` if something fails.
    public func getAllLocalUserRecords() throws -> [ODRecord] {
        do {
            let query = try ODQuery.init(node: localNode,
                                         forRecordTypes: kODRecordTypeUsers,
                                         attribute: kODAttributeTypeRecordName,
                                         matchType: ODMatchType(kODMatchEqualTo),
                                         queryValues: kODMatchAny,
                                         returnAttributes: kODAttributeTypeAllAttributes,
                                         maximumResults: 0)
            return try query.resultsAllowingPartial(false) as! [ODRecord]
        } catch {
            os_log("ODError while finding local users.", type: .error)
            throw error
        }
    }

    /// Returns all the non-system users on a system above UID 500.
    ///
    /// - Returns: A `Array` that contains the `ODRecord` of all the non-system user accounts in DSLocal.
    /// - Throws: An error from `ODFrameworkErrors` if something fails.
    public func getAllNonSystemUsers() throws -> [ODRecord] {
        do {
            let allRecords = try getAllLocalUserRecords()
            let nonSystem = try allRecords.filter { (record) -> Bool in
                guard let uid = try record.values(forAttribute: kODAttributeTypeUniqueID) as? [String] else {
                    return false
                }
                return Int(uid.first ?? "") ?? 0 > 500 && record.recordName.first != "_"
            }
            return nonSystem
        } catch {
            os_log("ODError while finding local users.", type: .error)
            throw error
        }
    }


    //    //MARK: - Demobilizer
    //
    //    /// Search in a given ODRecord for an Active Directory cached Authentication Authority.
    //    ///
    //    /// - Parameter userRecord: `ODRecord` to search in
    //    /// - Returns: `true` if the user is a mobile account cached from Active Directory. `false` if the user is not cached from Active Directory or an error occurs.
    //    func isCachedAD(_ userRecord: ODRecord) -> Bool {
    //        do {
    //            let authAuthority = try userRecord.values(forAttribute: kAuthAuthority) as! [String]
    //            os_log("Found user AuthAuthority: %{public}@", log: demobilizeLog, type: .debug, authAuthority.debugDescription)
    //            os_log("Looking for an Active Directory attribute on the account", log: demobilizeLog, type: .debug)
    //            return authAuthority.contains(where: {$0.contains(";LocalCachedUser;/Active Directory")})
    //        } catch {
    //            // No Auth Authorities, strange place, but we'll let other mechs decide
    //            os_log("No Auth Authorities, strange place, but we'll let other mechs decide. Allow login. Error: %{public}@", log: demobilizeLog, type: .error, error.localizedDescription)
    //            return false
    //        }
    //    }
    //
    //
    //    /// Removes the cached .account file for a mobile user that creates an external OD account.
    //    ///
    //    /// - Parameter shortname: Shortname of the user to remove. This should match the name of their homefolder.
    //    func removeExternalAccount(_ shortname: String) {
    //        let path = "/Users/" + shortname + "/.account"
    //        os_log("Removing external account file at %{public}@", log: demobilizeLog, type: .debug, path)
    //        if !FileManager.default.fileExists(atPath: path) {
    //            os_log("Could not find .account file, could be a really old mobile account?", log: demobilizeLog, type: .error)
    //            return
    //        }
    //        do {
    //            try FileManager.default.removeItem(atPath: path)
    //        } catch {
    //            os_log("FileManager error: ", log: demobilizeLog, type: .error, error.localizedDescription)
    //        }
    //        os_log("Deleted external account file", log: demobilizeLog, type: .debug)
    //    }
    //
    //    /// Remove the OD attributes that make the OS see an account as a mobile account.
    //    ///
    //    /// - Parameter userRecord: The `ODRecord` to convert.
    //    /// - Returns: Returns `true` if the conversion was a success, otherwise returns `false`.
    //    func demobilizeAccount(_ userRecord: ODRecord) -> Bool {
    //        do {
    //            var authAuthority = try userRecord.values(forAttribute: kAuthAuthority) as! [String]
    //            os_log("Found user AuthAuthority: %{public}@", log: demobilizeLog, type: .debug, authAuthority.debugDescription)
    //            os_log("Looking for an Active Directory attribute on the account", log: demobilizeLog, type: .debug)
    //            if let adAuthority = authAuthority.index(where: {$0.contains(";LocalCachedUser;/Active Directory")}) {
    //                authAuthority.remove(at: adAuthority)
    //            } else {
    //                os_log("Could not remove AD from the AuthAuthority. Bail out and allow login.", log: demobilizeLog, type: .error)
    //                return false
    //            }
    //            os_log("Write back the cleansed AuthAuthority", log: demobilizeLog, type: .debug)
    //            try userRecord.setValue(authAuthority, forAttribute: kAuthAuthority)
    //        } catch {
    //            // No Auth Authorities, strange place, but we'll let other mechs decide
    //            os_log("Ran into a problem modifying the AuthAuthority. Allow login. Error: %{public}@", log: demobilizeLog, type: .error, error.localizedDescription)
    //            return false
    //        }
    //
    //        // now to clean up the account
    //        // first remove all the extraneous records
    //        // we mark the try with ? as we don't want to error just because the attribute doesn't exist
    //        os_log("Removing cached attributes", log: demobilizeLog, type: .debug)
    //        for attr in removeAttrs {
    //            os_log("Removing %{public}@", log: demobilizeLog, type: .debug, attr)
    //            try? userRecord.removeValues(forAttribute: attr)
    //        }
    //        return true
    //    }
    //
    //    //MARK: - Account Modifications
    //
    //    /// Adds a new alias to an existing local record
    //    ///
    //    /// - Parameters:
    //    ///   - name: the shortname of the user to check as a `String`.
    //    ///   - alias: The password of the user to check as a `String`.
    //    /// - Returns: `true` if user:pass combo is valid, false if not.
    //    func addAlias(name: String, alias: String, attrOnly: Bool=false) -> Bool {
    //        os_log("Checking for local username", log: noLoMechlog, type: .debug)
    //        var records = [ODRecord]()
    //        let odsession = ODSession.default()
    //        do {
    //            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
    //            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeAllAttributes, maximumResults: 0)
    //            records = try query.resultsAllowingPartial(false) as! [ODRecord]
    //        } catch {
    //            let errorText = error.localizedDescription
    //            os_log("ODError while trying to check for local user: %{public}@", log: noLoMechlog, type: .error, errorText)
    //            return false
    //        }
    //
    //        let isLocal = records.isEmpty ? false : true
    //        os_log("Results of local user check %{public}@", log: noLoMechlog, type: .debug, isLocal.description)
    //
    //        if !isLocal {
    //            return isLocal
    //        }
    //
    //        // now to update the alias
    //        do {
    //            if !attrOnly {
    //                try records.first?.addValue(alias, toAttribute: kODAttributeTypeRecordName)
    //            }
    //
    //            try records.first?.addValue(alias, toAttribute: kODAttributeOktaUser)
    //        } catch {
    //            os_log("Unable to add alias to record", log: noLoMechlog, type: .error)
    //            return false
    //        }
    //
    //        return true
    //    }
    //
    //    func updateSignIn(name: String, time: AnyObject ) -> Bool {
    //        os_log("Checking for local username", log: noLoMechlog, type: .debug)
    //        var records = [ODRecord]()
    //        let odsession = ODSession.default()
    //        do {
    //            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
    //            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeAllAttributes, maximumResults: 0)
    //            records = try query.resultsAllowingPartial(false) as! [ODRecord]
    //        } catch {
    //            let errorText = error.localizedDescription
    //            os_log("ODError while trying to check for local user: %{public}@", log: noLoMechlog, type: .error, errorText)
    //            return false
    //        }
    //
    //        let isLocal = records.isEmpty ? false : true
    //        os_log("Results of local user check %{public}@", log: noLoMechlog, type: .debug, isLocal.description)
    //
    //        if !isLocal {
    //            return isLocal
    //        }
    //
    //        // now to update the alias
    //
    //        do {
    //            try records.first?.setValue(time, forAttribute: kODAttributeNetworkSignIn)
    //        } catch {
    //            os_log("Unable to add sign in time to record", log: noLoMechlog, type: .error)
    //            return false
    //        }
    //
    //        return true
    //    }
    //
    //    /// Gets shortname from a UUID
    //    ///
    //    /// - Parameters:
    //    ///   - uuid: the uuid of the user to check as a `String`.
    //    /// - Returns: shortname of the user or nil.
    //    func getShortname(uuid: String) -> String? {
    //
    //        os_log("Checking for username from UUID", log: noLoMechlog, type: .debug)
    //        var records = [ODRecord]()
    //        let odsession = ODSession.default()
    //        do {
    //            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
    //            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeGUID, matchType: ODMatchType(kODMatchEqualTo), queryValues: uuid, returnAttributes: kODAttributeTypeAllAttributes, maximumResults: 0)
    //            records = try query.resultsAllowingPartial(false) as! [ODRecord]
    //        } catch {
    //            let errorText = error.localizedDescription
    //            os_log("ODError while trying to check for local user: %{public}@", log: noLoMechlog, type: .error, errorText)
    //            return nil
    //        }
    //
    //        if records.count != 1 {
    //            return nil
    //        } else {
    //            return records.first?.recordName
    //        }
    //    }
    //
    //
    //
    //    //TODO: Change to throws instead of optional.
    //    /// Finds the first avaliable UID in the DSLocal domain above 500 and returns it as a `String`
    //    ///
    //    /// - Returns: `String` representing the UID
    //    func findFirstAvaliableUID() -> String? {
    //        var newUID = ""
    //        os_log("Checking for avaliable UID", log: createUserLog, type: .debug)
    //        for potentialUID in 501... {
    //            do {
    //                let node = try ODNode.init(session: session, type: ODNodeType(kODNodeTypeLocalNodes))
    //                let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeUniqueID, matchType: ODMatchType(kODMatchEqualTo), queryValues: String(potentialUID), returnAttributes: kODAttributeTypeNativeOnly, maximumResults: 0)
    //                let records = try query.resultsAllowingPartial(false) as! [ODRecord]
    //                if records.isEmpty {
    //                    newUID = String(potentialUID)
    //                    break
    //                }
    //            } catch {
    //                let errorText = error.localizedDescription
    //                os_log("ODError searching for avaliable UID: %{public}@", log: createUserLog, type: .error, errorText)
    //                return nil
    //            }
    //        }
    //        os_log("Found first avaliable UID: %{public}@", log: createUserLog, type: .default, newUID)
    //        return newUID
    //    }
    //
    //    //TODO: Convert to throws
    //    /// Finds the local homefolder template that corresponds to the locale of the system and copies it into place.
    //    ///
    //    /// - Parameter user: The shortname of the user to create a home for as a `String`.
    //    func createHomeDirFor(_ user: String) {
    //        os_log("Find system locale...", log: createUserLog, type: .debug)
    //        let currentLanguage = Locale.current.languageCode ?? "Non_localized"
    //        os_log("System language is: %{public}@", log: createUserLog, type: .debug, currentLanguage)
    //        let templateName = templateForLang(currentLanguage)
    //        let sourceURL = URL(fileURLWithPath: "/System/Library/User Template/" + templateName)
    //        let downloadsURL = URL(fileURLWithPath: "/System/Library/User Template/Non_localized/Downloads")
    //        let documentsURL = URL(fileURLWithPath: "/System/Library/User Template/Non_localized/Documents")
    //        do {
    //            os_log("Copying template to /Users", log: createUserLog, type: .debug)
    //            try FileManager.default.copyItem(at: sourceURL, to: URL(fileURLWithPath: "/Users/" + user))
    //            os_log("Copying non-localized folders to new home", log: createUserLog, type: .debug)
    //            try FileManager.default.copyItem(at: downloadsURL, to: URL(fileURLWithPath: "/Users/" + user + "/Downloads"))
    //            try FileManager.default.copyItem(at: documentsURL, to: URL(fileURLWithPath: "/Users/" + user + "/Documents"))
    //        } catch {
    //            os_log("Home template copy failed with: %{public}@", log: createUserLog, type: .error, error.localizedDescription)
    //        }
    //    }
    //
    //    // OD utils
    //
    //    func checkUIDandHome(name: String) -> (uid_t?, String?) {
    //        os_log("Checking for local username", log: noLoMechlog, type: .debug)
    //        var records = [ODRecord]()
    //        let odsession = ODSession.default()
    //        do {
    //            let node = try ODNode.init(session: odsession, type: ODNodeType(kODNodeTypeLocalNodes))
    //            let query = try ODQuery.init(node: node, forRecordTypes: kODRecordTypeUsers, attribute: kODAttributeTypeRecordName, matchType: ODMatchType(kODMatchEqualTo), queryValues: name, returnAttributes: kODAttributeTypeNativeOnly, maximumResults: 0)
    //            records = try query.resultsAllowingPartial(false) as! [ODRecord]
    //        } catch {
    //            let errorText = error.localizedDescription
    //            os_log("ODError while trying to check for local user: %{public}@", log: noLoMechlog, type: .error, errorText)
    //            return (nil, nil)
    //        }
    //
    //        if records.count == 1 {
    //
    //            do {
    //                let home = try records.first?.values(forAttribute: kODAttributeTypeNFSHomeDirectory) as? [String] ?? nil
    //                let uid = try records.first?.values(forAttribute: kODAttributeTypeUniqueID) as? [String] ?? nil
    //
    //                let uidt = uid_t.init(Double.init((uid?.first) ?? "0")! )
    //                return ( uidt, home?.first ?? nil)
    //            } catch {
    //                os_log("Unable to get home.", log: keychainAddLog, type: .error)
    //
    //                return (nil, nil)
    //            }
    //
    //        } else {
    //            os_log("More than one record. ", log: keychainAddLog, type: .error)
    //
    //            do {
    //                let home = try records.first?.values(forAttribute: kODAttributeTypeNFSHomeDirectory) as? [String] ?? nil
    //                let uid = try records.first?.values(forAttribute: kODAttributeTypeUniqueID) as? [String] ?? nil
    //
    //                let uidt = uid_t.init(Double.init((uid?.first) ?? "0")! )
    //                return ( uidt, home?.first ?? nil)
    //            } catch {
    //                os_log("Unable to get home.", log: keychainAddLog, type: .error)
    //
    //                return (nil, nil)
    //            }
    //        }
    //    }
    //
    //    /// Given an connonical ISO language code, find and return the macOS home folder template name that is appropriate.
    //    ///
    //    /// - Parameter code: The `languageCode` of the current user `Locale`.
    //    ///             You can find the current language with `Locale.current.languageCode`
    //    /// - Returns: A `String` that is the name of the localized home folder template on macOS. If the language code doesn't
    //    ///             map to one of the default macOS home templates the `Non_localized` name will be returned.
    //    func templateForLang(_ code: String) -> String {
    //        let templateName = ".lproj"
    //        switch code {
    //        case "es":
    //            return "Spanish" + templateName
    //        case "nl":
    //            return "Dutch" + templateName
    //        case "en":
    //            return "English" + templateName
    //        case "fr":
    //            return "French" + templateName
    //        case "it":
    //            return "Italian" + templateName
    //        case "ja":
    //            return "Japanese" + templateName
    //        case "ar":
    //            return "ar" + templateName
    //        case "ca":
    //            return "ca" + templateName
    //        case "cs":
    //            return "cs" + templateName
    //        case "da":
    //            return "da" + templateName
    //        case "el":
    //            return "el" + templateName
    //        case "es-419":
    //            return "es_419" + templateName
    //        case "fi":
    //            return "fi" + templateName
    //        case "he":
    //            return "he" + templateName
    //        case "hi":
    //            return "hi" + templateName
    //        case "hr":
    //            return  "hr" + templateName
    //        case "hu":
    //            return "hu" + templateName
    //        case "id":
    //            return "id" + templateName
    //        case "ko":
    //            return "ko" + templateName
    //        case "ms":
    //            return "ms" + templateName
    //        case "nb":
    //            return "no" + templateName
    //        case "pl":
    //            return "pl" + templateName
    //        case "pt":
    //            return "pt" + templateName
    //        case "pt-PT":
    //            return "pt_PT" + templateName
    //        case "ro":
    //            return "ro" + templateName
    //        case "ru":
    //            return "ru" + templateName
    //        case "sk":
    //            return "sk" + templateName
    //        case "sv":
    //            return "sv" + templateName
    //        case "th":
    //            return "th" + templateName
    //        case "tr":
    //            return "tr" + templateName
    //        case "uk":
    //            return "uk" + templateName
    //        case "vi":
    //            return "vi" + templateName
    //        case "zh-Hans":
    //            return "zh_CN" + templateName
    //        case "zh-Hant":
    //            return "zh_TW" + templateName
    //        default:
    //            return "Non_localized"
    //        }
    //    }

}
