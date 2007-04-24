//
//  TCMBEEPAuthenticationServer.m
//  SubEthaEdit
//
//  Created by Martin Ott on 4/20/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPAuthenticationServer.h"
#import <CoreFoundation/CoreFoundation.h>


static int sasl_getopt_session_server_cb(void *context, const char *plugin_name, const char *option, const char **result, unsigned *len)
{
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"plugin_name: %s, option: %s", plugin_name, option);
    
    if (!strcmp(option, "log_level")) {
        NSLog(@"setting log level");
        *result = "5"; //SASL_LOG_TRACE 6
        if (len) *len = 1;
    }
    return SASL_OK;
}

static int sasl_log_session_server_cb(void *context, int level, const char *message)
{
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"level: %d, message: %s", level, message);

    return SASL_OK;
}

static int sasl_authorize_session_server_cb(sasl_conn_t *conn,
			     void *context,
			     const char *requested_user, unsigned rlen,
			     const char *auth_identity, unsigned alen,
			     const char *def_realm, unsigned urlen,
			     struct propctx *propctx)
{
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"requested_user: %d, auth_identity: %s, def_realm: %s", requested_user, auth_identity, def_realm);
    return SASL_OK;
}

static int sasl_getsimple_session_server_cb(void *context, int id, const char **result, unsigned *len)
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
        case SASL_CB_LANGUAGE:
            NSLog(@"SASL_CB_LANGUAGE");
            *result = NULL;
            if (len) *len = 0;
            break;
        default:
            return SASL_BADPARAM;
    }
    
    return SASL_OK;
}

static int sasl_server_userdb_checkpass(sasl_conn_t *conn,
					   void *context,
					   const char *user,
					   const char *pass,
					   unsigned passlen,
					   struct propctx *propctx)
{
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"user: %s", user);
    
    return SASL_OK;
}
                 
static sasl_callback_t sasl_server_callbacks[] = {
    {SASL_CB_GETOPT, &sasl_getopt_session_server_cb, NULL},
    {SASL_CB_PROXY_POLICY, &sasl_authorize_session_server_cb, NULL},
    {SASL_CB_USER, &sasl_getsimple_session_server_cb, NULL},
    {SASL_CB_LOG, &sasl_log_session_server_cb, NULL},
    {SASL_CB_SERVER_USERDB_CHECKPASS, &sasl_server_userdb_checkpass, NULL},
    {SASL_CB_LIST_END, NULL, NULL}
};

# pragma mark -

@implementation TCMBEEPAuthenticationServer

- (id)initWithSession:(TCMBEEPSession *)session
{
    self = [super init];
    if (self) {
        _session = session;
        
        _sasl_conn_ctxt = NULL;


        int result = sasl_server_new("beep",
                                     NULL,  // serverFQDN
                                     NULL,  // user_realm
                                     NULL,  // iplocalport
                                     NULL,  // ipremoteport
                                     sasl_server_callbacks,
                                     0,     // flags
                                     &_sasl_conn_ctxt);
        if (result == SASL_OK) {
            DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"sasl_server_new succeeded");
            
            const char *mech_string;
            unsigned plen;
            int pcount;
            result = sasl_listmech(_sasl_conn_ctxt,
                                   "",      // user
                                   "",      // prefix
                                   " ",     // sep
                                   NULL,    // suffix
                                   &mech_string,
                                   &plen,
                                   &pcount);
            if (SASL_OK == result) {
                NSString *mechs = [[NSString alloc] initWithBytes:mech_string length:plen encoding:NSUTF8StringEncoding];
                NSArray *mechanisms = [mechs componentsSeparatedByString:@" "];
                if ([mechanisms containsObject:@"PLAIN"]) [_session addProfileURIs:[NSArray arrayWithObject:TCMBEEPSASLPLAINProfileURI]];
                //if ([mechanisms containsObject:@"CRAM-MD5"]) [_session addProfileURIs:[NSArray arrayWithObject:TCMBEEPSASLCRAMMD5ProfileURI]];

            }
            
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

- (void)setProfile:(TCMBEEPProfile *)profile
{
    NSLog(@"Got profile: %@", profile);
    [_profile autorelease];
    _profile = [profile retain];
}

- (NSData *)answerDataForChannelStartProfileURI:(NSString *)profileURI data:(NSData *)inData
{
    NSMutableData *outData = [NSMutableData data];

    NSString *clientin_string = nil;
    
    if (inData) {        
        CFXMLTreeRef payloadTree = NULL;
        NSDictionary *errorDict;
        payloadTree = CFXMLTreeCreateFromDataWithError(kCFAllocatorDefault,
                                    (CFDataRef)inData,
                                    NULL, //sourceURL
                                    kCFXMLParserSkipWhitespace | kCFXMLParserSkipMetaData,
                                    kCFXMLNodeCurrentVersion,
                                    (CFDictionaryRef *)&errorDict);
        if (!payloadTree) {
            DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"nixe baum: %@", [errorDict description]);
            //[[self session] terminate]; 
            //return;
        } else {
            // extract top level element from tree
            CFXMLNodeRef node = NULL;
            CFXMLTreeRef xmlTree = NULL;
            int childCount = CFTreeGetChildCount(payloadTree);
            int index;
            for (index = 0; index < childCount; index++) {
                xmlTree = CFTreeGetChildAtIndex(payloadTree, index);
                node = CFXMLTreeGetNode(xmlTree);
                if (CFXMLNodeGetTypeCode(node) == kCFXMLNodeTypeElement) {
                    break;
                }
            }
            if (!xmlTree || !node || CFXMLNodeGetTypeCode(node) != kCFXMLNodeTypeElement) {
                DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"Unable to extract top level element");
                //[[self session] terminate];
                //return;
            } else {
                if ([@"blob" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
                    //CFXMLNodeRef blobNode = CFXMLTreeGetNode(xmlTree);
                    int childCount = CFTreeGetChildCount(xmlTree);
                    if (childCount == 1) {
                        CFXMLTreeRef blobSubTree = CFTreeGetChildAtIndex(xmlTree, 0);
                        CFXMLNodeRef blobTextNode = CFXMLTreeGetNode(blobSubTree);
                        if (CFXMLNodeGetTypeCode(blobTextNode) == kCFXMLNodeTypeText) {
                            clientin_string = (NSString *)CFXMLNodeGetString(blobTextNode);
                            NSLog(@"parsed clientin blob");
                        }
                    }
                }
            }
        }
    }
    
    NSString *mech_string = [profileURI substringFromIndex:[TCMBEEPSASLProfileURIPrefix length]];
    
    const char *serverout;
    unsigned serveroutlen;
    int result = sasl_server_start(_sasl_conn_ctxt,
                                   [mech_string UTF8String],
                                   [clientin_string UTF8String],
                                   [clientin_string length],
                                   &serverout,
                                   &serveroutlen);
    if ((result != SASL_OK) && (result != SASL_CONTINUE)) {
        // [failure. Send protocol specific message that says authentication failed]
        NSLog(@"[failure. Send protocol specific message that says authentication failed]");
        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"%s", sasl_errdetail(_sasl_conn_ctxt));
    } else if (result == SASL_OK) {
        // [authentication succeeded. Send client the protocol specific message 
        // to say that authentication is complete]
        NSLog(@"[authentication succeeded. Send client the protocol specific message to say that authentication is complete]");
    } else {
        // [send data 'out' with length 'outlen' over the network in protocol
        // specific format]
        NSLog(@"[send data 'out' with length 'outlen' over the network in protocol specific format]");
        if (serveroutlen > 0) {
            [outData appendData:[@"<blob>" dataUsingEncoding:NSUTF8StringEncoding]];
            [outData appendData:[NSData dataWithBytes:serverout length:serveroutlen]];
            [outData appendData:[@"</blob>" dataUsingEncoding:NSUTF8StringEncoding]];
            NSLog(@"answerData: %@", outData);
        }
    }
    
    return outData;
}


@end
