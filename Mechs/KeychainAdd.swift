//
//  KeychainAdd.swift
//  NoMADLoginAD
//
//  Created by Joel Rennich on 1/30/18.
//  Copyright © 2018 Orchard & Grove Inc. All rights reserved.
//

import Security
import os.log
import OpenDirectory


// headless mech to add items to a keychain

class KeychainAdd : NoLoMechanism {
    
    let fm = FileManager.default
    var username = ""
    var userpass = ""
    let kItemName = "NoMAD"
    
    @objc func run() {
        // get username and password
        // get reference to user's keychain
        // add items
        
        username = usernameContext ?? "" //getContextString(type: kAuthorizationEnvironmentUsername) ?? ""
        userpass = passwordContext ?? "" //getContextString(type: kAuthorizationEnvironmentPassword) ?? ""
        
        // touch a file to show we're here
        
        let (uid, home) = checkUIDandHome(name: username)
        
        // TODO: find user's home directory via OD APIs
        
        var err : OSStatus? = nil
        var userKeychainTemp : SecKeychain? = nil
        var userKeychain: SecKeychain? = nil
        
        if home == nil {
            os_log("Unable to get home directory path.", log: keychainAddLog, type: .error)
            completeLogin(authResult: .allow)
            return
        }
        
        if uid == nil {
            // can't get uid
            os_log("Unable to get uid.", log: keychainAddLog, type: .error)
            completeLogin(authResult: .allow)
            return
            
        }
        
        //pthread_setugid_np(uid!, gid_t.init(Double(20)))
        
        // switch uid to user so we have access to home directory and other things
        
        seteuid(uid!)
        
        let userKeychainPath = home! + "/Library/Keychains/login.keychain-db"
        
        // check to ensure the keychain is there
        
        
        if !fm.fileExists(atPath: userKeychainPath) {
            
            // if we're not set to create a keychain, move on
            if getManagedPreference(key: .KeychainCreate) as? Bool == true {
                os_log("No login.keychain-db, creating one", log: keychainAddLog)
                SecKeychainResetLogin(UInt32(userpass.count), userpass, true)
            } else {
                os_log("No login.keychain-db, skipping KeychainAdd", log: keychainAddLog, type: .default)
                completeLogin(authResult: .allow)
                return
            }
        }
        
        // now test it we can unlock the keychain
        
        let tempPath = userKeychainPath + Date().timeIntervalSinceNow.description
        
        // need to do this on a hardlink to not prevent the keychain reset from working
        
        link(userKeychainPath, tempPath)
        
        os_log("Getting Temp Keychain reference.", log: uiLog)
        
        err = SecKeychainOpen(tempPath, &userKeychainTemp)
        
        os_log("Unlocking Temp Keychain.", log: uiLog)
        
        err = SecKeychainUnlock(userKeychainTemp, UInt32(userpass.count), userpass, true)
        
        // remove the link first
        
        unlink(tempPath)
        
        userKeychainTemp = nil
        
        if err != 0 && uid != nil {
            os_log("Unable to unlock keychain reference.", log: keychainAddLog, type: .default)
            
            // check if we should reset
            if getManagedPreference(key: .KeychainReset) as? Bool == true {
                os_log("Resetting keychain password.", log: keychainAddLog, type: .info)
                if uid != nil {
                    clearKeychain(path: home!)
                }
            } else {
                os_log("Keychain is locked, exiting.", log: keychainAddLog, type: .info)
                completeLogin(authResult: .allow)
                return
            }
        }
        
        //if let createPass = getManagedPreference(key: .CreateNoMADPasswords) as? Bool {
        //    if !createPass {
        //        completeLogin(authResult: .allow)
        //        return
        //    }
        //}
        
        if getManagedPreference(key: .KeychainAddNoMAD) as? Bool == true {
            
            // keychain unlock worked, now to get the real one
            
            os_log("Getting Keychain reference.", log: keychainAddLog)
            
            err = SecKeychainOpen(userKeychainPath, &userKeychain)
            
            os_log("Unlocking Keychain.", log: keychainAddLog)
            
            err = SecKeychainUnlock(userKeychainTemp, UInt32(userpass.count), userpass, true)
            
            var keychainItem: SecKeychainItem? = nil
            
            var kItemAccount = usernameContext ?? ""
            
            if let domain = getManagedPreference(key: .ADDomain) as? String {
                kItemAccount += "@" + domain.uppercased()
            }
            let kItemPass = passwordContext
            
            // set up an item dictionary
            
            var itemAttrs = [ String : AnyObject ]()
            
            // get app paths
            
            //var access : SecAccess? = nil
            
            var nomadTrust : SecTrustedApplication? = nil
            //var nomadProTrust : SecTrustedApplication? = nil
            
            var secApps = [ SecTrustedApplication ]()
            
            //var accountName = ""
            //var serviceName = ""
            
            if fm.fileExists(atPath: "/Applications/NoMAD.app", isDirectory: nil) {
                err = SecTrustedApplicationCreateFromPath("/Applications/NoMAD.app", &nomadTrust)
                if err == 0 {
                    secApps.append(nomadTrust!)
                }
            } else {
                os_log("NoMAD not installed.", log: keychainAddLog, type: .error)
            }
            
//            if fm.fileExists(atPath: "/Applications/NoMAD Pro.app", isDirectory: nil) {
//                err = SecTrustedApplicationCreateFromPath("/Applications/NoMAD Pro.app", &nomadProTrust)
//                if err == 0 {
//                    secApps.append(nomadProTrust!)
//                }
//            } else {
//                os_log("NoMAD Pro not installed.", log: keychainAddLog, type: .error)
//            }
            
            itemAttrs[kSecAttrType as String] = "genp" as AnyObject
            //itemAttrs[kSecValueRef as String ] = kItemPass as AnyObject
            itemAttrs[kSecAttrLabel as String] = "NoMAD" as AnyObject
            itemAttrs[kSecAttrService as String] = "NoMAD" as AnyObject
            itemAttrs[kSecAttrAccount as String] = kItemAccount as AnyObject
            
            // set up the base search dictionary
            
            var itemSearch: [String:AnyObject] = [
                kSecClass as String: kSecClassGenericPassword as AnyObject,
                kSecMatchLimit as String : kSecMatchLimitAll as AnyObject,
                kSecReturnAttributes as String: true as AnyObject,
                kSecReturnRef as String : true as AnyObject,
                ]
            
            itemSearch[kSecAttrService as String] = kItemName as AnyObject
            itemSearch[kSecAttrAccount as String] = kItemAccount as AnyObject
            
            
            // now to create
            
            err = SecKeychainAddGenericPassword(userKeychain, UInt32(kItemName.count), kItemName, UInt32((kItemAccount.count)), kItemAccount, UInt32((kItemPass?.count)!), kItemPass!, &keychainItem)
            
            if err != 0 {
                os_log("Unable to create item", log: keychainAddLog, type: .error)
                
                // this is most likely because an item is already there, so lets delete then recreate
                
                err = SecKeychainFindGenericPassword(userKeychain, UInt32(kItemName.count), kItemName, UInt32((kItemAccount.count)), kItemAccount, nil, nil, &keychainItem)
                
                err = SecKeychainItemDelete(keychainItem!)
                
                // now to create
                
                os_log("Creating new keychain item.", log: keychainAddLog, type: .default)
                
                err = SecKeychainAddGenericPassword(userKeychain, UInt32(kItemName.count), kItemName, UInt32((kItemAccount.count)), kItemAccount, UInt32((kItemPass?.count)!), kItemPass!, &keychainItem)
                
                if err != 0 {
                    os_log("Unable to create new keychain item.", log: keychainAddLog, type: .info)
                    
                    completeLogin(authResult: .allow)
                    return
                }
            }
            
            // now to set all the ACLs
            
            // Decode ACL
            
            var myACLs : CFArray? = nil
            var itemAccess: SecAccess? = nil
            
            err = SecKeychainItemCopyAccess(keychainItem!, &itemAccess)
            
            SecAccessCopyACLList(itemAccess!, &myACLs)
            
            var appList: CFArray? = nil
            var desc: CFString? = nil
            
            var prompt = SecKeychainPromptSelector()
            
            for acl in myACLs as! Array<SecACL> {
                SecACLCopyContents(acl, &appList, &desc, &prompt)
                let authArray = SecACLCopyAuthorizations(acl)
                
                if (authArray as! [String]).contains("ACLAuthorizationDecrypt") {
                    
                    os_log("Found AUTHORIZATION_CHANGE_ACL.", log: keychainAddLog, type: .info)
                    
                    SecACLSetContents(acl, secApps as CFArray, "" as CFString, prompt)
                    continue
                }
                
                if !(authArray as! [String]).contains("ACLAuthorizationPartitionID") {
                    continue
                }
                
                os_log("Found ACLAuthorizationPartitionID.", log: keychainAddLog, type: .info)
                
                // pull in the description that's really a functional plist <sigh>
                
                let rawData = Data.init(fromHexEncodedString: desc! as String)
                var format: PropertyListSerialization.PropertyListFormat = .xml
                
                var propertyListObject = [ String: [String]]()
                
                do {
                    propertyListObject = try PropertyListSerialization.propertyList(from: rawData!, options: [], format: &format) as! [ String: [String]]
                } catch {
                    os_log("No teamid in ACLAuthorizationPartitionID.", log: keychainAddLog, type: .error)
                }
                
                let teamIds = [ "teamid:AAPZK3CB24", "teamid:VRPY9KHGX6" ]
                
                propertyListObject["Partitions"] = teamIds
                
                // now serialize it back into a plist
                
                let xmlObject = try? PropertyListSerialization.data(fromPropertyList: propertyListObject as Any, format: format, options: 0)
                
                // now that all ACLs has been adjusted, we can update the item
                
                err = SecACLSetContents(acl, appList, xmlObject!.hexEncodedString() as CFString, prompt)
                
                // smack it again to set the ACL
                
                err = SecKeychainItemSetAccessWithPassword(keychainItem!, itemAccess!, UInt32((kItemPass?.count)!), kItemPass)
            }
            
            if err != 0 {
                os_log("Error setting up keychain item.", log: keychainAddLog, type: .error)
            }
        }
        
        // Always complete the login process
        
        completeLogin(authResult: .allow)
    }
    
    func clearKeychain(path: String) {
        
        // find the hardware UUID to kill the local items keychain
        
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        let hardwareRaw = IORegistryEntryCreateCFProperty(service, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
        let uuid = hardwareRaw?.takeRetainedValue() as? String ?? ""
        
        if uuid != "" {
            // we have a uuid, now delete the folder
            os_log("Removing local items keychin in order to purge it.", log: keychainAddLog)
            do {
                try fm.removeItem(atPath: path + "/Library/Keychains/" + uuid)
            } catch {
                os_log("Unable to remove Local Items folder.", log: keychainAddLog)
            }
        }
        
        os_log("Resetting keychain.", log: keychainAddLog)
        
        SecKeychainResetLogin(UInt32(userpass.count), userpass, true)
    }
    
    fileprivate func completeLogin(authResult: AuthorizationResult) {
        os_log("Complete login process", log: uiLog, type: .debug)
        seteuid(uid_t.init(Double(0)))
        let error = mech?.fPlugin.pointee.fCallbacks.pointee.SetResult((mech?.fEngine)!, authResult)
        if error != noErr {
            os_log("Got error setting authentication result", log: uiLog, type: .error)
        }
    }
    
    // Create keychain item
    
    fileprivate func createKeychainItem() {
        
    }
    
    // OD utils
    
    fileprivate func checkUIDandHome(name: String) -> (uid_t?, String?) {
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
            return (nil, nil)
        }
        
        if records.count == 1 {
            
            do {
                let home = try records.first?.values(forAttribute: kODAttributeTypeNFSHomeDirectory) as? [String] ?? nil
                let uid = try records.first?.values(forAttribute: kODAttributeTypeUniqueID) as? [String] ?? nil
                
                let uidt = uid_t.init(Double.init((uid?.first) ?? "0")! )
                return ( uidt, home?.first ?? nil)
            } catch {
                os_log("Unable to get home.", log: keychainAddLog, type: .error)
                
                return (nil, nil)
            }
            
        } else {
            os_log("More than one record. ", log: keychainAddLog, type: .error)
            
            do {
                let home = try records.first?.values(forAttribute: kODAttributeTypeNFSHomeDirectory) as? [String] ?? nil
                let uid = try records.first?.values(forAttribute: kODAttributeTypeUniqueID) as? [String] ?? nil
                
                let uidt = uid_t.init(Double.init((uid?.first) ?? "0")! )
                return ( uidt, home?.first ?? nil)
            } catch {
                os_log("Unable to get home.", log: keychainAddLog, type: .error)
                
                return (nil, nil)
            }
        }
    }
}
