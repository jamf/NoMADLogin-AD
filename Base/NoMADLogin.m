//
//  NoMADLogin.m
//  NoMADLogin
//
//  Created by Joel Rennich on 9/18/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

#import "NoMADLogin.h"
#import "NoMADLogin_AD-Swift.h"

NoMADLogin *authorizationPlugin = nil;

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
        authorizationPlugin = [[NoMADLogin alloc] init];
    }
    
    return [authorizationPlugin AuthorizationPluginCreate:callbacks
                                                PluginRef:outPlugin
                                          PluginInterface:outPluginInterface];
}

// Implementation

@implementation NoMADLogin

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
    mechanism->fCheckAD = (strcmp(mechanismId, "CheckAD") == 0);
    mechanism->fCheckOkta = (strcmp(mechanismId, "CheckOkta") == 0);
    mechanism->fCreateUser = (strcmp(mechanismId, "CreateUser") == 0);
    mechanism->fCheckOktaNonModal = (strcmp(mechanismId, "CheckOktaNonModal") == 0);
    mechanism->fLogOnly = (strcmp(mechanismId, "LogOnly") == 0);
    mechanism->fFakeUser = (strcmp(mechanismId, "FakeUser") == 0);
    *outMechanism = mechanism;
    return errSecSuccess;
}

- (OSStatus)MechanismInvoke:(AuthorizationMechanismRef)inMechanism {
    OSStatus err;
    
    MechanismRecord *mechanism = (MechanismRecord *)inMechanism;
    
    // Default "Allow Login". Used if none of the mechanisms above are called or don't make
    // a decision
    
    if (mechanism->fCheckAD) {
        
        NSLog(@"Calling CheckAD");
        
        CheckAD *checkAD = [[CheckAD alloc] initWithMechanism:mechanism];
        [checkAD run];
    } else if (mechanism->fCreateUser) {
        
        NSLog(@"Calling Create User");
        
        CreateUser *createUser = [[CreateUser alloc] initWithMechanism:mechanism];
        [createUser run];
        //Create *create = [[Create alloc] initWithMechanism:mechanism];
        //[create createUser];
        
        NSLog(@"Create done");
    } else if (mechanism->fLogOnly) {
        
        NSLog(@"Calling Log Only");
        
        AuthorizationContextFlags flags = kAuthorizationContextFlagExtractable;

        PrintAuthState(mechanism);
        
        NSLog(@"Log Only done");
        
        err = mechanism->fPlugin->fCallbacks->SetResult(mechanism->fEngine, kAuthorizationResultAllow);
        return kAuthorizationResultAllow;
        
    } else if (mechanism->fFakeUser) {
        // inject a user name and password
        
        NSLog(@"Making a faked login");
        
        FakeUser *fakeUser = [[FakeUser alloc] initWithMechanism:mechanism];
        [ fakeUser run];
        
        NSLog(@"Faked login done");

    }

    //err = mechanism->fPlugin->fCallbacks->SetResult(mechanism->fEngine, kAuthorizationResultAllow);
    
    //return kAuthorizationResultAllow;
    return noErr;
}

- (OSStatus)MechanismDeactivate:(AuthorizationMechanismRef)inMechanism {
    OSStatus err;
    MechanismRecord *mechanism = (MechanismRecord *)inMechanism;
    err = mechanism->fPlugin->fCallbacks->DidDeactivate(mechanism->fEngine);
    return err;
}

- (OSStatus)MechanismDestroy:(AuthorizationMechanismRef)inMechanism {
    free(inMechanism);
    return noErr;
}

- (OSStatus)PluginDestroy:(AuthorizationPluginRef)inPlugin {
    free(inPlugin);
    return noErr;
}

#pragma mark ***** Mechanism Printing Stuff

// The code in this section is used to pretty print the state of the
// authorization system when the mechanism is invoked.  This is a lot
// of code, but it's not very relevant to the authorization plugin
// mechanism itself (except insofar as it allows you to see what
// data is being passed around in the context and hints).

// As there is no way to enumerate all of the entries in the context/hints,
// I just hard-code a big table of likely entries.  The KeyInfo structure
// is used to hold information about each entry.  As the entries in the
// context/hints are not typed, I store both the name and the type.
// As I have no idea which keys pertain to which context and which pertain
// to hints, I try each key in both.  Besides, the push_hints_to_context
// mechanism implies that they share the same namespace.

enum KeyType {
    kUnknown,
    kString,                    // without null terminator
    kString0,                   // with null terminator
    kPID,                       // pid_t
    kUID,                       // uid_t
    kGID,                       // gid_t
    kOSType,
    kUInt32,
    kSInt32,
    kPlist,
    kPlistOrString              // wacky special case for AuthenticationAuthority
};
typedef enum KeyType KeyType;

struct KeyInfo {
    const char *    fKey;
    KeyType         fType;
};
typedef struct KeyInfo KeyInfo;

static const KeyInfo kStateKeys[] = {
    
    // IMPORTANT:
    // Only the keys documented in public header files are considered to be
    // part of the defined API for an authorization plug-in.  The keys that
    // are defined as literal strings are present for debugging and exploration
    // purposes only.  Do not use these strings in a 'shrink wrap' authorization
    // plug-in without first discussing the issue with Apple.  You can either
    // open a Developer Tech Support incident:
    //
    //   <http://developer.apple.com/technicalsupport/index.html>
    //
    // or ask your question on the Apple-CDSA mailing list:
    //
    //   <http://www.lists.apple.com/apple-cdsa>
    
    // hint keys documented in <Security/AuthorizationTags.h>
    
    { kAuthorizationEnvironmentUsername,    kString0 },
    { kAuthorizationEnvironmentPassword,    kString0 },
    { kAuthorizationEnvironmentIcon,        kUnknown },
    { kAuthorizationEnvironmentPrompt,      kUnknown },
    
    // context keys from a typical system (found using debugger)
    
    { "uid",                                kUID     },
    { "gid",                                kGID     },
    { "home",                               kString0 },
    { "longname",                           kString0 },
    { "shell",                              kString0 },
    
    // hint keys from a typical system (found using debugger)
    
    { "authorize-right",                    kString  },
    { "authorize-rule",                     kString  },
    { "client-path",                        kString  },
    { "client-pid",                         kPID     },
    { "client-type",                        kOSType  },
    { "client-uid",                         kUID     },
    { "creator-pid",                        kPID     },
    { "tries",                              kUInt32  },
    
    // other keys found by grovelling through source code
    
    { "suggested-user",                     kUnknown },
    { "require-user-in-group",              kUnknown },
    { "reason",                             kUnknown },
    { "token-name",                         kUnknown },
    { "afp_dir",                            kString0 },
    { "kerberos-principal",                 kUnknown },
    { "mountpoint",                         kString0 },
    { "new-password",                       kUnknown },
    { "show-add-to-keychain",               kUnknown },
    { "add-to-keychain",                    kUnknown },
    { "Home_Dir_Mount_Result",              kSInt32  },
    { "homeDirType",                        kSInt32  },
    
    // The getuserinfo authentication mechanism copies all of the user's
    // Open Directory attributes to the hints (?, or context?).  So we
    // look for the standard OD user attributes.
    //
    // AFAIK all of these are of type kString (because getuserinfo
    // only copies across string values), but I've only set the type
    // to string for those that I've seen in the wild.  The remainder
    // stay as type kUnknown until I see a concrete example.
    
    { kDS1AttrAdminLimits,                  kUnknown },
    { kDS1AttrAdminStatus,                  kUnknown },
    { kDS1AttrAlternateDatastoreLocation,   kUnknown },
    { kDS1AttrAuthenticationHint,           kUnknown },
    { kDS1AttrChange,                       kUnknown },
    { kDS1AttrComment,                      kUnknown },
    { kDS1AttrDistinguishedName,            kString  },
    { kDS1AttrExpire,                       kUnknown },
    { kDS1AttrFirstName,                    kUnknown },
    { kDS1AttrGeneratedUID,                 kString  },
    { kDS1AttrHomeDirectorySoftQuota,       kUnknown },
    { kDS1AttrHomeDirectoryQuota,           kUnknown },
    { kDS1AttrHomeLocOwner,                 kUnknown },
    { kDS1AttrInternetAlias,                kUnknown },
    { kDS1AttrLastName,                     kString  },
    { kDS1AttrMailAttribute,                kUnknown },
    { kDS1AttrMiddleName,                   kUnknown },
    { kDS1AttrNFSHomeDirectory,             kString  },
    { kDS1AttrOriginalNFSHomeDirectory,     kUnknown },
    { kDS1AttrPassword,                     kString  },
    { kDS1AttrPasswordPlus,                 kString  },
    { kDS1AttrPicture,                      kUnknown },
    { kDS1AttrPrimaryGroupID,               kString  },
    { kDS1AttrRealUserID,                   kString  },
    { kDS1AttrUniqueID,                     kString  },
    { kDS1AttrUserShell,                    kString  },
    { kDSNAttrAddressLine1,                 kUnknown },
    { kDS1StandardAttrHomeLocOwner,         kUnknown },
    { kDSNAttrAddressLine2,                 kUnknown },
    { kDSNAttrAddressLine3,                 kUnknown },
    { kDSNAttrAreaCode,                     kUnknown },
    { kDSNAttrAuthenticationAuthority,      kPlistOrString },
    { kDSNAttrBuilding,                     kUnknown },
    { kDSNAttrCity,                         kUnknown },
    { kDSNAttrCountry,                      kUnknown },
    { kDSNAttrDepartment,                   kUnknown },
    { kDSNAttrEMailAddress,                 kUnknown },
    { kDSNAttrFaxNumber,                    kUnknown },
    { kDSNAttrGroupMembers,                 kUnknown },
    { kDSNAttrGroupMembership,              kUnknown },
    { kDSNAttrHomeDirectory,                kString  },
    { kDSNAttrIMHandle,                     kUnknown },
    { kDSNAttrJobTitle,                     kUnknown },
    { kDSNAttrMobileNumber,                 kUnknown },
    { kDSNAttrNamePrefix,                   kUnknown },
    { kDSNAttrNameSuffix,                   kUnknown },
    { kDSNAttrNestedGroups,                 kUnknown },
    { kDSNAttrNetGroups,                    kUnknown },
    { kDSNAttrNickName,                     kUnknown },
    { kDSNAttrOrganizationName,             kUnknown },
    { kDSNAttrOriginalHomeDirectory,        kUnknown },
    { kDSNAttrPagerNumber,                  kUnknown },
    { kDSNAttrPhoneNumber,                  kUnknown },
    { kDSNAttrPostalAddress,                kUnknown },
    { kDSNAttrPostalCode,                   kUnknown },
    { kDSNAttrState,                        kUnknown },
    { kDSNAttrStreet,                       kUnknown }
};

static void PrintHexData(const char *scope, const char *key, const void *buf, size_t bufSize)
// Prints the specified buffer as hex.
{
    size_t                  outputSize;
    char *                  output;
    const unsigned char *   bufBase;
    size_t                  bufIndex;
    char                    tmp[16];
    
    assert(scope != NULL);
    assert(key   != NULL);
    assert( (bufSize == 0) || (buf != NULL) );
    
    // Allocate the correct size buffer.
    
    outputSize = bufSize * 3 + 1;
    output = (char *) malloc(outputSize);
    assert(output != NULL);
    
    if (output != NULL) {
        // Fill the buffer with the hex.
        
        *output = 0;
        
        bufBase = (const unsigned char *) buf;
        for (bufIndex = 0; bufIndex < bufSize; bufIndex++) {
            snprintf(tmp, sizeof(tmp), "%02x ", bufBase[bufIndex]);
            
            strlcat(output, tmp, outputSize);
        }
        
        assert(outputSize == (strlen(output) + 1));
        
        // Print it.
        
        NSLog(@"%s key='%s' value=%s", scope, key, output);
    }
    
    free(output);
}

static void PrintPlist(const char *scope, const char *key, const void *buf, size_t bufSize)
{
    CFDataRef           data;
    CFPropertyListRef   propList;
    CFDataRef           textData;
    CFMutableDataRef    mutableTextData;
    char *              dataBuf;
    CFIndex             dataSize;
    CFIndex             i;
    
    assert(scope != NULL);
    assert(key   != NULL);
    assert( (bufSize == 0) || (buf != NULL) );
    
    data = NULL;
    propList = NULL;
    textData = NULL;
    mutableTextData = NULL;
    
    dataBuf = NULL;
    
    // Create a CFData from the buffer, then a CFPropertyList from the data,
    // then a text form of the CFPropertyList, then a mutable version of that
    // ('cause I want to strip newline characters).  *phew*
    
    data = CFDataCreate(NULL, buf, bufSize);
    if (data != NULL) {
        propList = CFPropertyListCreateFromXMLData(NULL, data, kCFPropertyListImmutable, NULL);
        if (propList != NULL) {
            textData = CFPropertyListCreateXMLData(NULL, propList);
            if (textData != NULL) {
                mutableTextData = CFDataCreateMutableCopy(NULL, 0, textData);
                if (mutableTextData != NULL) {
                    dataBuf  = (char *) CFDataGetMutableBytePtr(mutableTextData);
                    dataSize = CFDataGetLength(mutableTextData);
                    for (i = 0; i < dataSize; i++) {
                        if ( (dataBuf[i] == '\r') || (dataBuf[i] == '\n') ) {
                            dataBuf[i] = ' ';
                        }
                    }
                }
            }
        }
    }
    
    // If the above mess worked, print the text, otherwise just dump hex.
    
    if (dataBuf != NULL) {
        NSLog(@"%s key='%s', value='%.*s'", scope, key, (int) dataSize, (const char *) dataBuf);
    } else {
        PrintHexData(scope, key, buf, bufSize);
        NSLog(@"%s key='%s', value='%.*s'", scope, key, (int) bufSize, (const char *) buf);
    }
    
    // Clean up.
    
    if (mutableTextData != NULL) {
        CFRelease(mutableTextData);
    }
    if (textData != NULL) {
        CFRelease(textData);
    }
    if (propList != NULL) {
        CFRelease(propList);
    }
    if (data != NULL) {
        CFRelease(data);
    }
}

static void PrintPlistOrString(const char *scope, const char *key, const void *buf, size_t bufSize)
// Sniffs the buffer and prints it as either a binary plist or a string.
// The AuthenticationAuthority context value is one of these formats
// depending on whether the mechanism runs before or after
// "builtin:getuserinfo", so I have to handle both.
{
    static const char kPlistMagic[] = "bplist00";
    
    assert(scope != NULL);
    assert(key   != NULL);
    assert( (bufSize == 0) || (buf != NULL) );
    
    // See whether the first eight bytes of the buffer are kPlistMagic.
    
    if ( (bufSize >= strlen(kPlistMagic)) && (memcmp(buf, kPlistMagic, strlen(kPlistMagic)) == 0) ) {
        // If so, go the plist route.
        
        PrintPlist(scope, key, buf, bufSize);
    } else {
        // If it doesn't look like a plist, print it as a string.
        
        NSLog(@"%s key='%s', value='%.*s'", scope, key, (int) bufSize, (const char *) buf);
    }
}

static void PrintTypedData(const char *scope, const char *key, KeyType type, const void *buf, size_t bufSize)
// Given a typed data buffer, pretty print the contents.
{
    assert(scope != NULL);
    assert(key   != NULL);
    assert( (bufSize == 0) || (buf != NULL) );
    
    switch (type) {
        default:
            assert(false);
            // fall through
        case kUnknown:
            PrintHexData(scope, key, buf, bufSize);
            break;
        case kString:
            if ( (bufSize > 0) && (((const char *) buf)[bufSize - 1] == 0)) {
                PrintHexData(scope, key, buf, bufSize);     // not expecting a null terminator here
            } else {
                NSLog(@"%s key='%s', value='%.*s'", scope, key, (int) bufSize, (const char *) buf);
            }
            break;
        case kString0:
            if ( (bufSize > 0) && (((const char *) buf)[bufSize - 1] == 0)) {
                
                // By default we log your password as "********".  If you want the real
                // password to show up in the log, change the following to 1.
                
#define kIDontCareIfMyPasswordIsLogged 0
                
                if ( (strcmp(key, "password") == 0) && ! kIDontCareIfMyPasswordIsLogged ) {
                    if (strlen(buf) == 0) {
                        NSLog(@"%s key='%s', value=''", scope, key);
                    } else {
                        NSLog(@"%s key='%s', value='********'", scope, key);
                    }
                } else {
                    NSLog(@"%s key='%s', value='%s'", scope, key, (const char *) buf);
                }
            } else {
                PrintHexData(scope, key, buf, bufSize);
            }
            break;
        case kPID:
            if (bufSize == sizeof(pid_t)) {
                NSLog(@"%s key='%s', value=%ld", scope, key, (long) *(pid_t *) buf);
            } else {
                PrintHexData(scope, key, buf, bufSize);
            }
            break;
        case kUID:
            if (bufSize == sizeof(uid_t)) {
                NSLog(@"%s key='%s', value=%ld", scope, key, (long) *(uid_t *) buf);
            } else {
                PrintHexData(scope, key, buf, bufSize);
            }
            break;
        case kGID:
            if (bufSize == sizeof(gid_t)) {
                NSLog(@"%s key='%s', value=%ld", scope, key, (long) *(gid_t *) buf);
            } else {
                PrintHexData(scope, key, buf, bufSize);
            }
            break;
        case kOSType:
            if (bufSize == sizeof(OSType)) {
                OSType tmp;
                
                // Should convert MacRoman to UTF-8 for each character, but that's
                // quite hard.
                
                tmp = *(OSType *) buf;
                NSLog(@"%s key='%s', value='%c%c%c%c'", scope, key, (UInt8) (tmp >> 24), (UInt8) (tmp >> 16), (UInt8) (tmp >> 8), (UInt8) tmp);
            } else {
                PrintHexData(scope, key, buf, bufSize);
            }
            break;
        case kUInt32:
            if (bufSize == sizeof(UInt32)) {
                NSLog(@"%s key='%s', value=%lu", scope, key, (unsigned long) *(UInt32 *) buf);
            } else {
                PrintHexData(scope, key, buf, bufSize);
            }
            break;
        case kSInt32:
            if (bufSize == sizeof(SInt32)) {
                NSLog(@"%s key='%s', value=%ld", scope, key, (long) *(SInt32 *) buf);
            } else {
                PrintHexData(scope, key, buf, bufSize);
            }
            break;
        case kPlist:
            PrintPlist(scope, key, buf, bufSize);
            break;
        case kPlistOrString:
            PrintPlistOrString(scope, key, buf, bufSize);
            break;
    }
}

static void PrintKeyedAuthState(MechanismRecord *mechanism, const char *key, KeyType type)
// For a given key, get both the content and hint value and, if successful, print them.
{
    OSStatus                    err;
    const AuthorizationValue *  value;
    AuthorizationContextFlags   flags;
    
    err = mechanism->fPlugin->fCallbacks->GetContextValue(mechanism->fEngine, key, &flags, &value);
    if (err == noErr) {
        PrintTypedData("GetContextValue", key, type, value->data, (size_t) value->length);
    }
    
    err = mechanism->fPlugin->fCallbacks->GetHintValue(mechanism->fEngine, key, &value);
    if (err == noErr) {
        PrintTypedData("GetHintValue", key, type, value->data, (size_t) value->length);
    }
}

static void PrintAuthState(MechanismRecord *mechanism)
// Dump the state of the authorization.  I try to print as much information
// as possible, but I'm open to suggestions for what also might be useful.
{
    OSStatus                            err;
    SecuritySessionId                   actualSessionID;
    SessionAttributeBits                sessionAttr;
    AuthorizationSessionId              sessionID;
    const AuthorizationValueVector *    arguments;
    UInt32                              argIndex;
    int                                 keyIndex;
    
    // Process information -- This lets you see whether the plugin is running
    // privileged (in "authorizationhost", with EUID 0) or GUI-capable
    // (in SecurityAgent, with EUID of "securityagent" (92)).
    
    NSLog(@"NullAuth:PrintAuthState: pid=%ld, ppid=%ld, euid=%ld, ruid=%ld", (long) getpid(), (long) getppid(), (long) geteuid(), (long) getuid() );
    
    // SessionGetInfo
    
    err = SessionGetInfo(callerSecuritySession, &actualSessionID, &sessionAttr);
    if (err == noErr) {
        NSLog(@"NullAuth:PrintAuthState: SessionGetInfo err=%ld, actualSessionID=%lu, sessionAttr=0x%lx", (long) err, (unsigned long) actualSessionID, (unsigned long) sessionAttr);
    } else {
        NSLog(@"NullAuth:PrintAuthState: SessionGetInfo err=%ld", (long) err);
    }
    
    // Session ID
    
    err = mechanism->fPlugin->fCallbacks->GetSessionId(mechanism->fEngine, &sessionID);
    if (err == noErr) {
        NSLog(@"NullAuth:PrintAuthState: GetSessionId err=%ld, sessionID=%p", (long) err, sessionID);
    } else {
        NSLog(@"NullAuth:PrintAuthState: GetSessionId err=%ld", (long) err);
    }
    
    // Arguments -- I have yet to find a way to actually pass arguments to my mechanism.
    // In fact, looking at the source it seems that GetArguments isn't actually
    // implemented (it always returns errAuthorizationInternal).  Still, I try to dump them
    // anyway, just in case they get implemented in the future.
    
    err = mechanism->fPlugin->fCallbacks->GetArguments(mechanism->fEngine, &arguments);
    if (err == noErr) {
        NSLog(@"NullAuth:PrintAuthState: GetArguments err=%ld, count=%lu", (long) err, (unsigned long) arguments->count);
        
        for (argIndex = 0; argIndex < arguments->count; argIndex++) {
            NSLog(@
                     "NullAuth:PrintAuthState: arg[%lu]='%.*s'",
                     (unsigned long) argIndex,
                     (int) arguments->values[argIndex].length,
                     (char *) arguments->values[argIndex].data
                     );
        }
    } else {
        NSLog(@"NullAuth:PrintAuthState: GetArguments err=%ld", (long) err);
    }
    
    // Context and Hints -- This is where things get complex.  See my notes
    // at the start of this section.
    
    for (keyIndex = 0; keyIndex < (sizeof(kStateKeys) / sizeof(kStateKeys[0])); keyIndex++) {
        PrintKeyedAuthState(mechanism, kStateKeys[keyIndex].fKey, kStateKeys[keyIndex].fType);
    }
}

@end

