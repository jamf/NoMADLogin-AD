//
//  NoMADLogin.h
//  NoMADLogin
//
//  Created by Joel Rennich on 9/18/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

#ifndef NoMADLogin_h
#define NoMADLogin_h

#endif /* NoMADLogin_h */

#import <Foundation/Foundation.h>
#include <CoreServices/CoreServices.h>
#include <Security/AuthorizationPlugin.h>
#include <Security/AuthSession.h>
#include <Security/AuthorizationTags.h>

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
    Boolean                         fCheckOkta;
    Boolean                         fCreateUser;
    Boolean                         fCheckOktaNonModal;
    Boolean                         fLogOnly;
    Boolean                         fFakeUser;
};

typedef struct MechanismRecord MechanismRecord;

#pragma mark
#pragma mark ObjC AuthPlugin Wrapper

@interface NoMADLogin : NSObject

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

