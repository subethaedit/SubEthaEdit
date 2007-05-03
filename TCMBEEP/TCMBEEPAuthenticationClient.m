//
//  TCMBEEPAuthenticationClient.m
//  SubEthaEdit
//
//  Created by Martin Ott on 4/20/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPAuthenticationClient.h"
#import "TCMBEEPSession.h"
#import "TCMBEEPSASLProfile.h"


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
                
                NSData *clientData = [NSData dataWithBytes:clientout length:clientoutlen];
                NSString *base64EncodedString = [clientData base64EncodedStringWithLineLength:0];
                [data appendData:[base64EncodedString dataUsingEncoding:NSUTF8StringEncoding]];

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

- (void)authenticationStepWithBlob:(NSString *)inString
{
    const char *clientout;
    unsigned clientoutlen;
    sasl_interact_t *client_interact = NULL;
    int result;
    do {
        result = sasl_client_step(_sasl_conn_ctxt,  /* our context */
                                  [inString UTF8String],    /* the data from the server */
                                  [inString length], /* it's length */
                                  &client_interact,  /* this should be unallocated and NULL */
                                  &clientout,     /* filled in on success */
                                  &clientoutlen); /* filled in on success */

        if (result == SASL_INTERACT) {
           // [deal with the interactions. See below]
           DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"[deal with the interactions. See below]");
        }

    } while (result==SASL_INTERACT || result == SASL_CONTINUE);

    if (result == SASL_OK) {
        if (clientout) {
            DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"clientout: %s", clientout);
            NSData *blob = [NSData dataWithBytes:clientout length:clientoutlen];
            NSString *base64EncodedBlobString = [blob base64EncodedStringWithLineLength:0];
            [_profile startSecondRoundtripWithBlob:[base64EncodedBlobString dataUsingEncoding:NSUTF8StringEncoding]];
        }
    } else {
        // [failure]
        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"%s", sasl_errdetail(_sasl_conn_ctxt));
    }

}

- (NSString *)contentBytesFromProfilePayload:(NSData *)inData
{
    NSString *result = nil;
    
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
                            result = (NSString *)CFXMLNodeGetString(blobTextNode);
                            [[result retain] autorelease];
                            DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"parsed blob: %@", result);
                        }
                    }
                }
            }
            CFRelease(payloadTree);
        }
    }

    return result;
}

- (void)BEEPSession:(TCMBEEPSession *)session didOpenChannelWithProfile:(TCMBEEPProfile *)profile data:(NSData *)inData
{
    DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"%s %@", __FUNCTION__, inData);
    _profile = [profile retain];
    
    // Parse blob element
    
    // Parse not only for 'blob' but also for 'error'
    // and also parse 'blob' for attribute 'status'
    
    NSString *blobContent = nil;
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
            #warning Terminate session here or send ERR frame with error 500?
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
                #warning Terminate session here or send ERR frame with error 500?
                //[[self session] terminate];
                //return;
            } else {
                CFXMLElementInfo *info = (CFXMLElementInfo *)CFXMLNodeGetInfoPtr(node);
                NSDictionary *attributes = (NSDictionary *)info->attributes;
                if ([@"blob" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
                    int childCount = CFTreeGetChildCount(xmlTree);
                    
                    if (childCount == 0 && [[attributes objectForKey:@"status"] isEqualToString:@"complete"]) {
                        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"SUCCESSFULLY AUTHENTICATED");
                    }
                    
                    if (childCount == 1) {
                        CFXMLTreeRef blobSubTree = CFTreeGetChildAtIndex(xmlTree, 0);
                        CFXMLNodeRef blobTextNode = CFXMLTreeGetNode(blobSubTree);
                        if (CFXMLNodeGetTypeCode(blobTextNode) == kCFXMLNodeTypeText) {
                            blobContent = (NSString *)CFXMLNodeGetString(blobTextNode);
                            DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"parsed blob: %@", blobContent);
                            NSData *decodedBase64String = [NSData dataWithBase64EncodedString:blobContent];
                            NSString *serverin_string = [NSString stringWithData:decodedBase64String encoding:NSUTF8StringEncoding];
                            DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"decoded blob: %@", serverin_string);
                            [self authenticationStepWithBlob:serverin_string];
                        }
                    }
                } else if ([@"error" isEqualToString:(NSString *)CFXMLNodeGetString(node)]) {
                    int childCount = CFTreeGetChildCount(xmlTree);
                    if (childCount == 1 && [attributes objectForKey:@"code"]) {
                        CFXMLTreeRef blobSubTree = CFTreeGetChildAtIndex(xmlTree, 0);
                        CFXMLNodeRef blobTextNode = CFXMLTreeGetNode(blobSubTree);
                        if (CFXMLNodeGetTypeCode(blobTextNode) == kCFXMLNodeTypeText) {
                            NSString *failureMessage = (NSString *)CFXMLNodeGetString(blobTextNode);
                            DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"Error: %@ (%@)", [attributes objectForKey:@"code"], failureMessage);
                        }
                    }
                }
            }
            CFRelease(payloadTree);
        }
    }

    
}

@end
