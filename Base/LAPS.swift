//
//  LAPS.swift
//  NoMADLoginAD
//
//  Created by Joel Rennich on 12/1/19.
//  Copyright © 2019 Orchard & Grove. All rights reserved.
//

import Foundation
import CryptoKit

class LAPS {
    
    var publicKey: SecKey
    
    init?() {
        if let keyRaw = getManagedPreference(key: .LAPSPublicKey) as? String,
            let keyData = Data.init(base64Encoded: keyRaw, options: .ignoreUnknownCharacters) {
            let options: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                          kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                                          kSecAttrKeySizeInBits as String : 2048]
            var error: Unmanaged<CFError>?
            if let tempKey = SecKeyCreateWithData(keyData as CFData,
                                                 options as CFDictionary,
                                                 &error) {
                publicKey = tempKey
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func encrypt(data: Data) -> Data? {
        if let result = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionOAEPSHA1, data as CFData, nil) as Data? {
            return result
        } else {
            return nil
        }
    }
}
