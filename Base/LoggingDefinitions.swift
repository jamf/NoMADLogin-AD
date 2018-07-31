//
//  LoggingDefinitions.swift
//  NoMADLoginAD
//
//  Created by Josh Wisenbaker on 12/26/17.
//  Copyright © 2017 NoMAD. All rights reserved.
//

import os.log

let uiLog = OSLog(subsystem: "menu.nomad.login.ad", category: "UI")
let checkADLog = OSLog(subsystem: "menu.nomad.login.ad", category: "CheckADMech")
let createUserLog = OSLog(subsystem: "menu.nomad.login.ad", category: "CreateUserMech")
let noLoMechlog = OSLog(subsystem: "menu.nomad.login.ad", category: "NoLoSwiftMech")
let noLoBaseMechlog = OSLog(subsystem: "menu.nomad.login.ad", category: "NoLoBaseMech")
let loggerMech = OSLog(subsystem: "menu.nomad.login.ad", category: "LoggerMech")
let demobilizeLog = OSLog(subsystem: "menu.nomad.login.ad", category: "DemobilizeMech")
let powerControlLog = OSLog(subsystem: "menu.nomad.login.ad", category: "PowerControlMech")
let enableFDELog = OSLog(subsystem: "menu.nomad.login.ad", category: "EnableFDELog")
let sierraFixesLog = OSLog(subsystem: "menu.nomad.login.ad", category: "SierraFixesLog")
let keychainAddLog = OSLog(subsystem: "menu.nomad.login.ad", category: "KeychainAdd")
let eulaLog = OSLog(subsystem: "menu.nomad.login.ad", category: "EULA")
