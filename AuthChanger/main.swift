//
//  main.swift
//  authchanger
//
//  Created by Joel Rennich on 12/15/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Foundation
import Security.AuthorizationDB

let kSystemRightConsole = "system.login.console"
let kloginwindow_ui = "loginwindow:login"
let kloginwindow_success = "loginwindow:success"
let klogindindow_home = "HomeDirMechanism:status"
let kmechanisms = "mechanisms"

var rights : CFDictionary? = nil
var err = OSStatus.init(0)
var authRef : AuthorizationRef? = nil

// get an authorization context to save this back
// need to be root, if we are this should return clean

err = AuthorizationCreate(nil, nil, AuthorizationFlags(rawValue: 0), &authRef)


// get the current rights for system.login.console

err = AuthorizationRightGet(kSystemRightConsole, &rights)

// Now to iterate through the list and add what we need

var rightsDict = rights as! Dictionary<String,AnyObject>
var mechs: Array = rightsDict[kmechanisms] as! Array<String>
let index = mechs.index(of: kloginwindow_ui)

if index != nil {
    mechs[index!] = "NoMADLogin:CheckOkta"
    mechs.insert("NoMADLogin:CreateUser,privileged", at: index! + 1)
    mechs.insert("NoMADLogin:Notify", at: index! - 1)
    
    rightsDict[kmechanisms] = mechs as AnyObject
    
    err = AuthorizationRightSet(authRef!, kSystemRightConsole, rightsDict as CFTypeRef, "not sure why we need this" as CFString, nil, nil)
} else {
    // nothing in the list of mechs to key off of
}

