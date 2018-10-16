//
//  NoMADLogin.m
//  NoMADLogin
//
//  Created by Joel Rennich on 9/18/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

#import "NoMADLoginAD.h"
#import "NoMADLoginAD-Swift.h"


NoMADLoginAD *authorizationPlugin = nil;
os_log_t pluginLog = nil;
CheckAD *checkAD = nil;

static OSStatus PluginDestroy(AuthorizationPluginRef inPlugin) {
    return [authorizationPlugin PluginDestroy:inPlugin];
}

static OSStatus MechanismCreate(AuthorizationPluginRef inPlugin,
                                AuthorizationEngineRef inEngine,
                                AuthorizationMechanismId mechanismId,
                                AuthorizationMechanismRef *outMechanism) {
    return [authorizationPlugin MechanismCreate:inPlugin
                                      EngineRef:inEngine
                                    MechanismId:mechanismId
                                   MechanismRef:outMechanism];
}

static OSStatus MechanismInvoke(AuthorizationMechanismRef inMechanism) {
    return [authorizationPlugin MechanismInvoke:inMechanism];
}

static OSStatus MechanismDeactivate(AuthorizationMechanismRef inMechanism) {
    return [authorizationPlugin MechanismDeactivate:inMechanism];
}

static OSStatus MechanismDestroy(AuthorizationMechanismRef inMechanism) {
    return [authorizationPlugin MechanismDestroy:inMechanism];
}

static AuthorizationPluginInterface gPluginInterface = {
    kAuthorizationPluginInterfaceVersion,
    &PluginDestroy,
    &MechanismCreate,
    &MechanismInvoke,
    &MechanismDeactivate,
    &MechanismDestroy
};

extern OSStatus AuthorizationPluginCreate(const AuthorizationCallbacks *callbacks,
                                          AuthorizationPluginRef *outPlugin,
                                          const AuthorizationPluginInterface **outPluginInterface) {
    if (authorizationPlugin == nil) {
        authorizationPlugin = [[NoMADLoginAD alloc] init];
    }
    
    pluginLog = os_log_create("menu.nomad.noload", "Plugin");
    return [authorizationPlugin AuthorizationPluginCreate:callbacks
                                                PluginRef:outPlugin
                                          PluginInterface:outPluginInterface];
}

// Implementation

/**
 C implimentation of the actual authorization plugin since this is all a huge pain in Swift.
 */
@implementation NoMADLoginAD

- (OSStatus)AuthorizationPluginCreate:(const AuthorizationCallbacks *)callbacks
                            PluginRef:(AuthorizationPluginRef *)outPlugin
                      PluginInterface:(const AuthorizationPluginInterface **)outPluginInterface {
    PluginRecord *plugin = (PluginRecord *) malloc(sizeof(*plugin));
    if (plugin == NULL) return errSecMemoryError;
    plugin->fMagic = kPluginMagic;
    plugin->fCallbacks = callbacks;
    *outPlugin = plugin;
    *outPluginInterface = &gPluginInterface;
    return errSecSuccess;
}

- (OSStatus)MechanismCreate:(AuthorizationPluginRef)inPlugin
                  EngineRef:(AuthorizationEngineRef)inEngine
                MechanismId:(AuthorizationMechanismId)mechanismId
               MechanismRef:(AuthorizationMechanismRef *)outMechanism {
    MechanismRecord *mechanism = (MechanismRecord *)malloc(sizeof(MechanismRecord));
    if (mechanism == NULL) return errSecMemoryError;
    mechanism->fMagic = kMechanismMagic;
    mechanism->fEngine = inEngine;
    mechanism->fPlugin = (PluginRecord *)inPlugin;
    mechanism->fMechID = mechanismId;
    mechanism->fCheckAD = (strcmp(mechanismId, "CheckAD") == 0);
    mechanism->fCreateUser = (strcmp(mechanismId, "CreateUser") == 0);
    mechanism->fLogOnly = (strcmp(mechanismId, "LogOnly") == 0);
    mechanism->fDeMobilize = (strcmp(mechanismId, "DeMobilize") == 0);
    mechanism->fPowerControl = (strcmp(mechanismId, "PowerControl") == 0);
    mechanism->fKeychainAdd = (strcmp(mechanismId, "KeychainAdd") == 0);
    mechanism->fEnableFDE = (strcmp(mechanismId, "EnableFDE") == 0);
    mechanism->fSierraFixes = (strcmp(mechanismId, "SierraFixes") == 0);
    mechanism->fEULA = (strcmp(mechanismId, "EULA") == 0);
    mechanism->fUserInput = (strcmp(mechanismId, "UserInput") == 0);
    mechanism->fNotify = (strcmp(mechanismId, "Notify") == 0);
    mechanism->fRunScript = (strcmp(mechanismId, "RunScript") == 0);
    *outMechanism = mechanism;
    
    os_log_debug(pluginLog, "NoLoPlugin:MechanismCreate: inPlugin=%p, inEngine=%p, mechanismId='%{public}s'", inPlugin, inEngine, mechanismId);
    return errSecSuccess;
}

- (OSStatus)MechanismInvoke:(AuthorizationMechanismRef)inMechanism {

    MechanismRecord *mechanism = (MechanismRecord *)inMechanism;
    os_log_debug(pluginLog, "NoLoPlugin:MechanismInvoke: mechMem=%p mechanismId='%{public}s'", inMechanism, mechanism->fMechID);
    
    // Default "Allow Login". Used if none of the mechanisms above are called or don't make
    // a decision
    
    if (mechanism->fCheckAD) {
        NSLog(@"Calling CheckAD");
        checkAD = [[CheckAD alloc] initWithMechanism:mechanism];
        [checkAD run];
        
    } else if (mechanism->fCreateUser) {
        NSLog(@"Calling Create User");
        CreateUser *createUser = [[CreateUser alloc] initWithMechanism:mechanism];
        [createUser run];
    } else if (mechanism->fLogOnly) {
        NSLog(@"Calling Log Only");
        LogOnly *logOnly = [[LogOnly alloc] initWithMechanism:mechanism];
        [logOnly run];
    } else if (mechanism->fDeMobilize) {
        NSLog(@"Calling DeMobilze");
        DeMobilize *deMobilize = [[DeMobilize alloc] initWithMechanism:mechanism];
        [deMobilize run];
    } else if (mechanism->fPowerControl){
        NSLog(@"Calling PowerControl");
        PowerControl *powerControl = [[PowerControl alloc] initWithMechanism:mechanism];
        [powerControl run];
    } else if (mechanism->fEnableFDE) {
        NSLog(@"Calling EnableFDE");
        EnableFDE *enableFDE = [[EnableFDE alloc] initWithMechanism:mechanism];
        [enableFDE run];
    } else if (mechanism->fSierraFixes) {
        NSLog(@"Calling SierraFixes");
        SierraFixes *sierraFixes = [[SierraFixes alloc] initWithMechanism:mechanism];
        [sierraFixes run];
    }  else if (mechanism->fKeychainAdd) {
        NSLog(@"Calling KeychainAdd");
        KeychainAdd *keychainAdd = [[KeychainAdd alloc] initWithMechanism:mechanism];
        [keychainAdd run];
        NSLog(@"KeychainAdd done");
    } else if (mechanism->fEULA) {
        NSLog(@"Calling EULA");
        EULA * eula = [[EULA alloc] initWithMechanism:mechanism];
        [eula run];
        NSLog(@"EULA done");
    }  else if (mechanism->fRunScript) {
        NSLog(@"Calling RunScript");
        RunScript * runScript = [[RunScript alloc] initWithMechanism:mechanism];
        [runScript run];
        NSLog(@"RunScript done");
    } else if (mechanism->fNotify) {
        NSLog(@"Calling Notify");
        Notify * notify = [[Notify alloc] initWithMechanism:mechanism];
        [notify run];
        NSLog(@"Notify done");
    } else if (mechanism->fUserInput) {
        NSLog(@"Calling User Input");
        UserInput * userInput = [[UserInput alloc] initWithMechanism:mechanism];
        [userInput run];
        NSLog(@"User Input done");
    }
    
    return noErr;
}

- (OSStatus)MechanismDeactivate:(AuthorizationMechanismRef)inMechanism {
    OSStatus err;
    MechanismRecord *mechanism = (MechanismRecord *)inMechanism;
    os_log_debug(pluginLog, "NoLoPlugin:MechanismDeactivate: mechMem=%p mechanismId='%{public}s'", inMechanism, mechanism->fMechID);
    
    err = mechanism->fPlugin->fCallbacks->DidDeactivate(mechanism->fEngine);
    return err;
}

- (OSStatus)MechanismDestroy:(AuthorizationMechanismRef)inMechanism {
    MechanismRecord *mechanism = (MechanismRecord *)inMechanism;
    os_log_debug(pluginLog, "NoLoPlugin:MechanismDestroy: mechMem=%p mechanismId='%{public}s'", inMechanism, mechanism->fMechID);
    if (mechanism->fCheckAD) {
        if (checkAD.signIn.visible == true) {
            [checkAD tearDown];
        }
    }
    free(mechanism);
    return noErr;
}

- (OSStatus)PluginDestroy:(AuthorizationPluginRef)inPlugin {
    free(inPlugin);
    return noErr;
}

@end

