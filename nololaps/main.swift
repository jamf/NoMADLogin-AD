//
//  main.swift
//  nololaps
//
//  Created by Joel Rennich on 12/1/19.
//  Copyright © 2019 Orchard & Grove. All rights reserved.
//

import Foundation
import CryptoKit

private let kCryptoExportImportManagerPublicKeyInitialTag = "-----BEGIN RSA PUBLIC KEY-----\n"
private let kCryptoExportImportManagerPublicKeyFinalTag = "-----END RSA PUBLIC KEY-----\n"
private let kCryptoExportImportManagerPrivateKeyInitialTag = "-----BEGIN RSA PRIVATE KEY-----\n"
private let kCryptoExportImportManagerPrivateKeyFinalTag = "-----END RSA PRIVATE KEY-----\n"

private let kCryptoExportImportManagerRequestInitialTag = "-----BEGIN CERTIFICATE REQUEST-----\n"
private let kCryptoExportImportManagerRequestFinalTag = "-----END CERTIFICATE REQUEST-----\n"

private let kCryptoExportImportManagerPublicNumberOfCharactersInALine = 64
private let kKeyLabel = "NoLo LAPS Key"

enum KeyTypes {
    case rsaPublic, rsaPrivate, none
}

enum Action {
    case create, encrypt, decrypt
}

var action: Action?

// NOTE: if you want to decrypt this via openSSL see these links
// https://forums.developer.apple.com/thread/112871
// https://github.com/Andrew-Lees11/MacLinuxRSA


let tempKey = "MIIBCgKCAQEAxoR4GnSFkCH7gVkjS4y0uuHCu+HMvPtLUkicosKgrt3M/0qt1T/G1IHU+ynd/IaO3cGUvF9cf2f0rLQ8qdj1zcX5ey5aspDzLNtQOvDUsl2w7eHkG8y4mQo/68mkxwgB/CSDiTe4vfg5U9Munpc8a5aAItpDt8/mCX38hblGFFo4HsLLEyxJPF+rDsEMhj1NjkcqmtoBk0QuhEp4Uglb2HhpJE0uAoNZZ7GRP7yDHRjREwPCiza1pHwTAz6/gyUBnnz4NSvwV5rgRsR17/3jTvrIpKugf5yxRw7UPDbD3jFRIAZjjPAulkHIRv51hR8z2LZS0W+s+qi86Kcr0IzjywIDAQAB"

var inputFile: String?

func printHelp() {
    print("""
    This is a small tool to let you create key pairs for use with
    NoMAD Login as a LAPS system.

    This tool can create a RSA 2048 public and private key to be used,
    or you can use your own.

    The private key will be stored in the keychain and the public
    key can be included in the configuration profile for NoMAD Login.

    Command Options:

    -c : Creates a new keypair
    -d : Decrypts a LAPS password
    -e : Encrypts a LAPS password
    -exportable : Allows the key to be exported from the keychain
    -h : Prints this help statement
    -i : Path to a file to encrypt or decrypt
    -k : Path to a file containing the public or private key
    -keychain : Keep the private key in the current default keychain
    -p : Prints the private key in PEM format for escrow or use with
        other tools
    -w : Writes out the public key as a Base64 string for inclusion in your
        configuration profile
    """)
}

func makeKeys() {
    
    let now = Date()
    let tag = now.description.data(using: .utf8) //"NoMAD Login LAPS Encryption Key ".data(using: .utf8)
    
    var keychain = false
    
    if CommandLine.arguments.contains("-keychain") {
        keychain = true
    }
    
    var exportable = false
    
    if CommandLine.arguments.contains("-exportable") {
        exportable = true
    }
    
    let attributes: [String : Any] = [
        kSecAttrKeyType as String:            kSecAttrKeyTypeRSA,
        kSecAttrKeySizeInBits as String:      2048,
        kSecPrivateKeyAttrs as String: [
            kSecAttrIsPermanent as String: keychain,
            kSecAttrApplicationTag as String: tag as Any,
            kSecAttrLabel as String: kKeyLabel as Any,
            kSecAttrIsExtractable as String: exportable as Any
        ]
    ]
    
    var error: Unmanaged<CFError>?
    
    if let ephemeralPrivate = SecKeyCreateRandomKey(attributes as CFDictionary, &error)  {
        
        if args.contains("-p") {
            if let ephemeralPrivateData = SecKeyCopyExternalRepresentation(ephemeralPrivate, nil) as Data? {
                print(PEMKeyFromDERKey(data: ephemeralPrivateData))
            } else {
              print("Unable to write out private key")
            }
        }
        
        if let ephemeralPublic = SecKeyCopyPublicKey(ephemeralPrivate),
            let ephemeralPublicData = SecKeyCopyExternalRepresentation(ephemeralPublic, &error) as Data? {
            if args.contains("-w") {
                print(PEMKeyFromDERKey(data: ephemeralPublicData, type: .rsaPublic))
            }
        }
    }
    
    if error != nil {
        print("There was an error creating the key: \(error.debugDescription)")
    }
}

func encryptData(data: Data, key: SecKey) {
    if let result = SecKeyCreateEncryptedData(key, .rsaEncryptionOAEPSHA1, data as CFData, nil) as Data? {
        print(result.base64EncodedString())
    }
}

func findkeys() -> SecKey? {
    
    // find all possible keys
    // if more than one, let the user choose, otherwise return the private key
    
    var searchReturn: AnyObject?
    var myErr: OSStatus

    let attrs = [
        kSecClass: kSecClassKey,
        kSecAttrLabel: kKeyLabel,
        kSecReturnRef: true,
        kSecReturnAttributes: true,
        kSecMatchLimit: kSecMatchLimitAll
        ] as [CFString: Any]

    myErr = SecItemCopyMatching(attrs as CFDictionary, &searchReturn)
    
    if myErr != 0 {
        print("Error searching for keys")
        return nil
    }
    
    if let result = searchReturn as? [[String:Any]] {
        if result.count == 1 {
            if let item = result.first,
                let key = item["v_Ref"] as Any? {
                return (key as! SecKey)
            }
        }
        
        var results = [[String:SecKey]]()
        var count = 1
        print("Multiple possible keys, please pick one:")
        
        for item in result {
            if let tag = item["atag"] as? Data,
                let key = item["v_Ref"] as Any?,
                let tagString = String.init(data: tag, encoding: String.Encoding.utf8) {
                results.append([tagString:(key as! SecKey)])
                print("\(count.description) - created at \(tagString)")
                count += 1
            }
        }
        
        var finished = false
        var pickedID = ""

        while !finished {
            print("   Enter key to use", terminator: ": ")
            
            pickedID = readLine(strippingNewline: true)!
            
            // check if there's only one item and the response is blank
            
            if pickedID == "" {
                print("    Invalid selection")
                continue
            }
            
            // check for q or quit
            
            if pickedID == "q" || pickedID == "quit" {
                print("    Quitting")
                exit(0)
            }
            
            // check for text
            
            if (Int(pickedID) == nil) {
                print("    Invalid selection")
                continue
            }
            
            if Int(pickedID)! > ( results.count ) || (Int(pickedID) == 0) {
                print("    Invalid selection")
                continue
            }
            
            finished = true
        }
        
        let pickedNum = (Int(pickedID)! - 1)
        if let pickedItem =  results[pickedNum].first {
            return pickedItem.value
        }
    } else {
        print("No search results")
        return nil
    }
    
    return nil
}

func PEMKeyFromDERKey(data: Data, type: KeyTypes = .rsaPrivate) -> String {

    var resultString: String

    // base64 encode the result
    let base64EncodedString = data.base64EncodedString(options: [])

    // split in lines of 64 characters.
    var currentLine = ""
    switch type {
    case .rsaPrivate:
        resultString = kCryptoExportImportManagerPrivateKeyInitialTag
    case .rsaPublic:
        resultString = kCryptoExportImportManagerPublicKeyInitialTag
    case .none:
        resultString = ""
    }

    var charCount = 0
    for character in base64EncodedString {
        charCount += 1
        currentLine.append(character)
        if charCount == kCryptoExportImportManagerPublicNumberOfCharactersInALine {
            resultString += currentLine + "\n"
            charCount = 0
            currentLine = ""
        }
    }
    // final line (if any)
    if currentLine.count > 0 { resultString += currentLine + "\n" }
    // final tag
    switch type {
    case .rsaPrivate:
        resultString += kCryptoExportImportManagerPrivateKeyFinalTag
    case .rsaPublic:
        resultString += kCryptoExportImportManagerPublicKeyFinalTag
    case .none:
        break
    }

    return resultString
}


func decryptData(enc: Data) {
    
    if let key = findkeys() {
        var error: Unmanaged<CFError>?

        if let decryptedData = SecKeyCreateDecryptedData(key, .rsaEncryptionOAEPSHA1, enc as CFData, &error) as Data?, let result = String.init(data: decryptedData, encoding: String.Encoding.utf8) {
            print(result)
        } else {
            print("Unable to decrypt: \(error.debugDescription)")
        }
    }
}

///Mark: The Magic is here!

let args = CommandLine.arguments

if args.contains("-h") || args.count == 1 {
    printHelp()
    exit(0)
}

var argCount = 0

for arg in CommandLine.arguments {
    switch arg {
    case "-c":
        action = .create
        makeKeys()
    case "-d":
        action = .decrypt
    case "-e":
        action = .encrypt
    case "-i":
        if CommandLine.arguments.count > argCount {
            inputFile = CommandLine.arguments[argCount + 1]
        }
    default:
        break
    }
    argCount += 1
}

switch action {
case .create:
    makeKeys()
case .decrypt:
    if let filePath = inputFile {
        let fileURL = URL.init(fileURLWithPath: filePath)
        do {
            let fileb64 = try String.init(contentsOf: fileURL)
            if let fileData = Data.init(base64Encoded: fileb64, options: .ignoreUnknownCharacters) {
                decryptData(enc: fileData)
            }
        } catch {
            print("Unable to load input file")
        }
    }
case .encrypt:
    
    if let filePath = inputFile {
           let fileURL = URL.init(fileURLWithPath: filePath)
           do {
               let fileb64 = try String.init(contentsOf: fileURL)
               if let fileData = Data.init(base64Encoded: fileb64, options: .ignoreUnknownCharacters) {
                       if let key = findkeys(),
                        let publicKey = SecKeyCopyPublicKey(key) {
                       encryptData(data: fileData, key: publicKey)
                   }
               }
           } catch {
               print("Unable to load input file")
           }
       }
case .none:
    printHelp()
    exit(0)
}
