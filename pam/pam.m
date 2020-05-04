//
//  pam.m
//  pam
//
//  Created by Joel Rennich on 4/25/20.
//  Copyright © 2020 Orchard & Grove. All rights reserved.
//

#import "pam.h"

@implementation pam

PAM_EXTERN int
pam_sm_authenticate(pam_handle_t * pamh, int flags, int argc, const char **argv) {
    
    int pam_code = 0;
    const char *user = NULL;
    const char *pass = NULL;
    
    pam_code = pam_get_user(pamh, &user, "Username: ");
    pam_code = pam_get_authtok(pamh, PAM_AUTHTOK, &pass, "Password: ");
    
    NSString *userString = [[NSString alloc] initWithCString:user encoding:NSUTF8StringEncoding];
    NSString *passString = [[NSString alloc] initWithCString:pass encoding:NSUTF8StringEncoding];
    
    NoMADSessionHelper *session = [[NoMADSessionHelper alloc] initWithUser:userString password:passString];
    
    if ([session authenticate]) {
        return PAM_SUCCESS;
    } else {
        return PAM_AUTHTOK;
    }
}

// Below here are pam calls we don't need to work with, so we just return PAM_IGNORE on all of them.
PAM_EXTERN int
pam_sm_setcred(pam_handle_t * pamh, int flags, int argc, const char **argv)
{
    os_log_debug(OS_LOG_DEFAULT, "pam_nomad: pam_sm_setcred ignoring unused method");
    return PAM_IGNORE;
}

PAM_EXTERN int
pam_sm_acct_mgmt(pam_handle_t * pamh, int flags, int argc, const char **argv)
{
    os_log_debug(OS_LOG_DEFAULT, "pam_nomad: pam_sm_acct_mgmt ignoring unused method");
    return PAM_IGNORE;
}

PAM_EXTERN int
pam_sm_chauthtok(pam_handle_t *pamh, int flags, int argc, const char **argv) {
    os_log_debug(OS_LOG_DEFAULT, "pam_nomad: pam_sm_chauthtok ignoring unused method");
    return PAM_IGNORE;
}

@end
