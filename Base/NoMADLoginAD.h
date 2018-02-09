//
//  NoMADLogin.h
//  NoMADLogin
//
//  Created by Joel Rennich on 9/18/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

#ifndef NoMADLoginAD_h
#define NoMADLoginAD_h

#endif /* NoMADLoginAD_h */

@import Foundation;
@import Security.AuthorizationPlugin;
@import Security.AuthSession;
@import DirectoryService;
@import os.log;

// Plugin constants

enum {
    kPluginMagic = 'PlgN'
};

struct PluginRecord {
    OSType fMagic;
    const AuthorizationCallbacks *fCallbacks;
};

typedef struct PluginRecord PluginRecord;

#pragma mark - Mechanism

enum {
    kMechanismMagic = 'Mchn'
};

struct MechanismRecord {
    OSType                          fMagic;
    AuthorizationEngineRef          fEngine;
    const PluginRecord *            fPlugin;
    Boolean                         fCheckAD;
    Boolean                         fCreateUser;
    Boolean                         fLogOnly;
    Boolean                         fDeMobilize;
    Boolean                         fPowerControl;
};

typedef struct MechanismRecord MechanismRecord;

#pragma mark
#pragma mark ObjC AuthPlugin Wrapper

@interface NoMADLoginAD : NSObject

// Mechanism parts

// Create Mechanism

- (OSStatus)MechanismCreate:(AuthorizationPluginRef)inPlugin
                  EngineRef:(AuthorizationEngineRef)inEngine
                MechanismId:(AuthorizationMechanismId)mechanismId
               MechanismRef:(AuthorizationMechanismRef *)outMechanism;

// Starts authentication

- (OSStatus)MechanismInvoke:(AuthorizationMechanismRef)inMechanism;

// Decactive mechanism

- (OSStatus)MechanismDeactivate:(AuthorizationMechanismRef)inMechanism;

// Destroys mechanism

- (OSStatus)MechanismDestroy:(AuthorizationMechanismRef)inMechanism;

// Plugin parts

// Destroy plugin

- (OSStatus)PluginDestroy:(AuthorizationPluginRef)inPlugin;

// Creates plugin

- (OSStatus)AuthorizationPluginCreate:(const AuthorizationCallbacks *)callbacks
                            PluginRef:(AuthorizationPluginRef *)outPlugin
                      PluginInterface:(const AuthorizationPluginInterface **)outPluginInterface;

@end

