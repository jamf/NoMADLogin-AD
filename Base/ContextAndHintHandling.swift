//
//  ContextAndHintHandling.swift
//  NoMADLoginAD
//
//  Created by Josh Wisenbaker on 12/18/17.
//  Copyright © 2017 NoMAD. All rights reserved.
//

enum HintType: String {
    case noMADUser
    case noMADPass
    case noMADFirst
    case noMADLast
    case noMADFull
    case uid
    case gid
    case kerberos_principal
}

protocol ContextAndHintHandling {
    var mech: MechanismRecord? {get}
    func setContextString(type: String, value: String)
    func setHint(type: HintType, hint: Any)
    func getContextString(type: String) -> String?
    func getHint(type: HintType) -> Any?
}

extension ContextAndHintHandling {
    /// Set a NoMAD Login Authorization mechanism hint.
    ///
    /// - Parameters:
    ///   - type: A value from `HintType` representing the NoMad Login value to set.
    ///   - hint: The hint value to set. Can be `String` or `[String]`
    func setHint(type: HintType, hint: Any) {
        guard (hint is String || hint is [String]) else {
            NSLog("NoMAD Login Set hint failed: data type of hint is not supported")
            return
        }
        let data = NSKeyedArchiver.archivedData(withRootObject: hint)
        var value = AuthorizationValue(length: data.count, data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))
        let err = (mech?.fPlugin.pointee.fCallbacks.pointee.SetHintValue((mech?.fEngine)!, type.rawValue, &value))!
        guard err == errSecSuccess else {
            NSLog("NoMAD Login Set hint failed with: %@", err)
            return
        }
    }

    func getHint(type: HintType) -> Any? {
        var value : UnsafePointer<AuthorizationValue>? = nil
        var err: OSStatus = noErr
        err = (mech?.fPlugin.pointee.fCallbacks.pointee.GetHintValue((mech?.fEngine)!, type.rawValue, &value))!
        if err != errSecSuccess {
            NSLog("NoMADLogin: couldn't retrieve hint value: \(type)")
            return nil
        }
        let outputdata = Data.init(bytes: value!.pointee.data!, count: value!.pointee.length)
        guard let result = NSKeyedUnarchiver.unarchiveObject(with: outputdata)
            else {
                NSLog("NoMADLogin: couldn't unpack hint value \(type)")
                return nil
        }
        return result
    }

    /// Set one of the known `AuthorizationTags` values to be used during mechanism evaluation.
    ///
    /// - Parameters:
    ///   - type: A `String` constant from AuthorizationTags.h representing the value to set.
    ///   - value: A `String` value of the context value to set.
    func setContextString(type: String, value: String) {
        let tempdata = value + "\0"
        let data = tempdata.data(using: .utf8)
        var value = AuthorizationValue(length: (data?.count)!, data: UnsafeMutableRawPointer(mutating: (data! as NSData).bytes.bindMemory(to: Void.self, capacity: (data?.count)!)))
        let err = (mech?.fPlugin.pointee.fCallbacks.pointee.SetContextValue((mech?.fEngine)!, type, .extractable, &value))!
        guard err == errSecSuccess else {
            NSLog("NoMAD Login Set context value failed with: %@", err)
            return
        }
    }

    func getContextString(type: String) -> String? {
        var value: UnsafePointer<AuthorizationValue>?
        var flags = AuthorizationContextFlags()
        let err = mech?.fPlugin.pointee.fCallbacks.pointee.GetContextValue((mech?.fEngine)!, type, &flags, &value)
        if err != errSecSuccess {
            NSLog("NoMADLogin: couldn't retrieve context value: \(type)")
            return nil
        }
        if type == "longname" {
            return String.init(bytesNoCopy: value!.pointee.data!, length: value!.pointee.length, encoding: .utf8, freeWhenDone: false)
        } else {
            let item = Data.init(bytes: value!.pointee.data!, count: value!.pointee.length)
            NSLog("\(type): \(String(describing: item))")
        }

        return nil
    }
}
