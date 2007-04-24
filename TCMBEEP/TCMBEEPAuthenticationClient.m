//
//  TCMBEEPAuthenticationClient.m
//  SubEthaEdit
//
//  Created by Martin Ott on 4/20/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPAuthenticationClient.h"
#import "TCMBEEPSession.h"
#import "TCMBEEPProfile.h"


static int sasl_getopt_session_client_cb(void *context, const char *plugin_name, const char *option, const char **result, unsigned *len)
{
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"plugin_name: %s, option: %s", plugin_name, option);

    return SASL_OK;
}

static int sasl_log_session_client_cb(void *context, int level, const char *message)
{
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"level: %d, message: %s", level, message);

    return SASL_OK;
}

static int sasl_pass_session_client_cb(sasl_conn_t *conn, void *context, int id, sasl_secret_t **psecret)
{
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"get password...");

    char *password;
    unsigned len;

    if (!conn || !psecret || id != SASL_CB_PASS)
        return SASL_BADPARAM;

    password = "geheim";
    if (!password)
        return SASL_FAIL;

    len = (unsigned)strlen(password);

    *psecret = (sasl_secret_t *) malloc(sizeof(sasl_secret_t) + len);

    if (! *psecret) {
        memset(password, 0, len);
        return SASL_NOMEM;
    }

    (*psecret)->len = len;
    strcpy((char *)(*psecret)->data, password);
    //memset(password, 0, len);

    return SASL_OK;
}

static int sasl_getsimple_session_client_cb(void *context, int id, const char **result, unsigned *len)
{
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"");
    
    if (!result)
        return SASL_BADPARAM;

    switch (id) {
        case SASL_CB_USER:
            NSLog(@"SASL_CB_USER");
            *result = "mbo";
            if (len) *len = 3;         
            break;
        case SASL_CB_AUTHNAME:
            NSLog(@"SASL_CB_AUTHNAME");
            *result = "mbo";
            if (len) *len = 3;
            break;
        default:
            return SASL_BADPARAM;
    }
    
    return SASL_OK;
}

static int sasl_getrealm_session_client_cb(void *context, int id, const char **availrealms, const char **result)
{
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"");

    if (id != SASL_CB_GETREALM) return SASL_FAIL;

    *result = "myrealm";
  
    return SASL_OK;
}

static int sasl_chalprompt_session_client(void *context, int id,
			      const char *challenge,
			      const char *prompt, const char *defresult,
			      const char **result, unsigned *len)
{
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"");

    if ((id != SASL_CB_ECHOPROMPT && id != SASL_CB_NOECHOPROMPT)
        || !prompt || !result || !len)
    {
        return SASL_BADPARAM;
    }
    
    if (!defresult)
        defresult = "";
  
    /*
    fputs(prompt, stdout);
    if (challenge)
        printf(" [challenge: %s]", challenge);
    printf(" [%s]: ", defresult);
    fflush(stdout);
  
    if (id == SASL_CB_ECHOPROMPT) {
        char *original = getpassphrase("");
        if (!original)
            return SASL_FAIL;
        if (*original)
            *result = strdup(original);
        else
            *result = strdup(defresult);
        memset(original, 0L, strlen(original));
    } else {
        char buf[1024];
        fgets(buf, 1024, stdin);
        if (buf[0]) {
            *result = strdup(buf);
        } else {
            *result = strdup(defresult);
        }
        memset(buf, 0L, sizeof(buf));
    }
    */
    
    *result = strdup(defresult);
    
    if (! *result)
        return SASL_NOMEM;
    *len = (unsigned) strlen(*result);
    
    return SASL_OK;
}

static sasl_callback_t sasl_client_callbacks[] = {
    {SASL_CB_GETOPT, &sasl_getopt_session_client_cb, NULL},
    {SASL_CB_LOG, &sasl_log_session_client_cb, NULL},
    {SASL_CB_GETREALM, &sasl_getrealm_session_client_cb, NULL},
    {SASL_CB_USER, &sasl_getsimple_session_client_cb, NULL},
    {SASL_CB_AUTHNAME, &sasl_getsimple_session_client_cb, NULL}, /* A mechanism should call getauthname_func if it needs the authentication name */
    {SASL_CB_LANGUAGE, &sasl_getsimple_session_client_cb, NULL},
    {SASL_CB_PASS, &sasl_pass_session_client_cb, NULL},      /* Call getsecret_func if need secret */
    {SASL_CB_ECHOPROMPT, &sasl_chalprompt_session_client, NULL},
    {SASL_CB_NOECHOPROMPT, &sasl_chalprompt_session_client, NULL},
    {SASL_CB_LIST_END, NULL, NULL}
};

#pragma mark -

@implementation TCMBEEPAuthenticationClient

- (id)initWithSession:(TCMBEEPSession *)session
{
    self = [super init];
    if (self) {
        _session = session;
        
        _sasl_conn_ctxt = NULL;
        int result = sasl_client_new("beep",
                                     NULL,  // serverFQDN (has to  be set)
                                     NULL,  // iplocalport
                                     NULL,  // ipremoteport
                                     sasl_client_callbacks,
                                     0, // flags
                                     &_sasl_conn_ctxt);
        if (result == SASL_OK) {
            DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"sasl_client_new succeeded");
        } else {
            DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"%s", sasl_errdetail(_sasl_conn_ctxt));
        }
    }
    return self;
}

- (void)dealloc
{
    if (_sasl_conn_ctxt) sasl_dispose(&_sasl_conn_ctxt);
    [_profile release];
    _profile = nil;
    _session = nil;
    [super dealloc];
}

#pragma mark -

- (void)startAuthentication
{
    NSMutableString *mechlist_string = [[NSMutableString alloc] init];
    NSEnumerator *enumerator = [[_session peerProfileURIs] objectEnumerator];
    NSString *profileURI;
    while ((profileURI = [enumerator nextObject])) {
        if ([profileURI hasPrefix:TCMBEEPSASLProfileURIPrefix]) {
            if ([mechlist_string length] > 0) [mechlist_string appendString:@" "];
            [mechlist_string appendString:[profileURI substringFromIndex:[TCMBEEPSASLProfileURIPrefix length]]];
        }
    }
    
    if ([mechlist_string length] > 0) {
        const char *mech_using;
        const char *clientout;
        unsigned clientoutlen;
        sasl_interact_t *client_interact = NULL;
        int result;
        
        do {
            result = sasl_client_start(_sasl_conn_ctxt,
                                       [mechlist_string UTF8String],
                                       &client_interact,
                                       &clientout,
                                       &clientoutlen,
                                       &mech_using);
            if (result == SASL_INTERACT) {
                DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"deal with the interactions.");
            }
        } while (result == SASL_INTERACT);
        
        if (SASL_CONTINUE == result || SASL_OK == result) {
            DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"mech_using: %s", mech_using);
            if (client_interact) DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"client_interact has been filled");
            
            NSString *profileURI = [TCMBEEPSASLProfileURIPrefix stringByAppendingString:[NSString stringWithFormat:@"%s", mech_using]];
            
            NSArray *dataArray = nil;
            if (clientout) {
                NSMutableData *data = [NSMutableData data];
                [data appendData:[@"<blob>" dataUsingEncoding:NSUTF8StringEncoding]];
                [data appendData:[NSData dataWithBytes:clientout length:clientoutlen]];
                [data appendData:[@"</blob>" dataUsingEncoding:NSUTF8StringEncoding]];
                dataArray = [NSArray arrayWithObject:data];
            }
            [_session startChannelWithProfileURIs:[NSArray arrayWithObject:profileURI]
                                          andData:dataArray
                                           sender:self];
        } else {
            DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"%s", sasl_errdetail(_sasl_conn_ctxt));
        }
    }
}

#pragma mark -

- (void)BEEPSession:(TCMBEEPSession *)session didOpenChannelWithProfile:(TCMBEEPProfile *)profile
{
    NSLog(@"%s", __FUNCTION__);
    _profile = [profile retain];
}

@end
