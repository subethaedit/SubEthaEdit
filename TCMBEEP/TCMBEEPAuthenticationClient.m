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
#import "TCMHost.h"

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <sys/socket.h>
#import <netdb.h>

NSString * const TCMBEEPAuthenticationClientDidAuthenticateNotification = @"TCMBEEPAuthenticationClientDidAuthenticateNotification";
NSString * const TCMBEEPAuthenticationClientDidNotAuthenticateNotification = @"TCMBEEPAuthenticationClientDidNotAuthenticateNotification";

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

    TCMBEEPAuthenticationClient *client = (TCMBEEPAuthenticationClient *)context;
    NSString *pass = [client valueForKey:@"password"];
    
    password = pass?[pass UTF8String]:"";
    if (!password)
        return SASL_FAIL;

    len = (unsigned)strlen(password);

    *psecret = (sasl_secret_t *) malloc(sizeof(sasl_secret_t) + len);

//    if (! *psecret) {
//        memset(password, 0, len);
//        return SASL_NOMEM;
//    }

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

    TCMBEEPAuthenticationClient *client = (TCMBEEPAuthenticationClient *)context;
    NSString *userName = [client valueForKey:@"userName"];

    switch (id) {
        case SASL_CB_USER:
            DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"SASL_CB_USER");
            *result = userName?[userName UTF8String]:"";
            if (len) *len = strlen(*result);
            break;
        case SASL_CB_AUTHNAME:
            DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"SASL_CB_AUTHNAME");
            *result = userName?[userName UTF8String]:"";
            if (len) *len = strlen(*result);
            break;
        default:
            DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"id: %d", id);
            return SASL_BADPARAM;
    }
    
    return SASL_OK;
}

static int sasl_getrealm_session_client_cb(void *context, int id, const char **availrealms, const char **result)
{
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"");

    if (id != SASL_CB_GETREALM) return SASL_FAIL;

    *result = "localhost";
  
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

#pragma mark -

@interface TCMBEEPAuthenticationClient (TCMBEEPAuthenticationClientPrivate)
- (void)_setupSASLContextWithServerFQDN:(NSString *)serverFQDN;
- (void)_authenticate;
@end

#pragma mark -

@implementation TCMBEEPAuthenticationClient

- (id)initWithSession:(TCMBEEPSession *)session addressData:(NSData *)addressData peerAddressData:(NSData *)peerAddressData serverFQDN:(NSString *)serverFQDN
{
    self = [super init];
    if (self) {
        _sasl_conn_ctxt = NULL;
        _session = session;
        _isAuthenticated = NO;
        _addressData = [addressData retain];
        _peerAddressData = [peerAddressData retain];
        if (serverFQDN) {
            [self _setupSASLContextWithServerFQDN:serverFQDN];
        }
    }
    return self;
}

- (void)dealloc
{
    [_availableMechanisms release];
    if (_sasl_conn_ctxt) sasl_dispose(&_sasl_conn_ctxt);
    [_profile release];
    _profile = nil;
    _session = nil;
    if (_peerHost) {
        [_peerHost setDelegate:nil];
        [_peerHost release];
    }
    [_addressData release];
    [_peerAddressData release];
    [super dealloc];
}

#pragma mark -

- (void)_setupSASLContextWithServerFQDN:(NSString *)serverFQDN
{
    sasl_callback_t *callback = _sasl_client_callbacks;
    callback->id = SASL_CB_GETOPT;
    callback->proc = &sasl_getopt_session_client_cb;
    callback->context = self;
    ++callback;

    callback->id = SASL_CB_LOG;
    callback->proc = &sasl_log_session_client_cb;
    callback->context = self;
    ++callback;
        
    callback->id = SASL_CB_GETREALM;
    callback->proc = &sasl_getrealm_session_client_cb;
    callback->context = self;
    ++callback;

    callback->id = SASL_CB_USER;
    callback->proc = &sasl_getsimple_session_client_cb;
    callback->context = self;
    ++callback;
    
    callback->id = SASL_CB_AUTHNAME;
    callback->proc = &sasl_getsimple_session_client_cb;
    callback->context = self;
    ++callback;
    
    callback->id = SASL_CB_LANGUAGE;
    callback->proc = &sasl_getsimple_session_client_cb;
    callback->context = self;
    ++callback;
    
    callback->id = SASL_CB_PASS;
    callback->proc = &sasl_pass_session_client_cb;
    callback->context = self;
    ++callback;
    
    callback->id = SASL_CB_ECHOPROMPT;
    callback->proc = &sasl_chalprompt_session_client;
    callback->context = self;
    ++callback;

    callback->id = SASL_CB_NOECHOPROMPT;
    callback->proc = &sasl_chalprompt_session_client;
    callback->context = self;
    ++callback;
    
    callback->id = SASL_CB_LIST_END;
    callback->proc = NULL;
    callback->context = self;
    
    
    const char *iplocalport = NULL;
    const char *ipremoteport = NULL;
    if (_addressData) iplocalport = [[NSString stringWithAddressData:_addressData cyrusSASLCompatible:YES] UTF8String];
    if (_peerAddressData) ipremoteport = [[NSString stringWithAddressData:_peerAddressData cyrusSASLCompatible:YES] UTF8String];
    DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"iplocalport: %s, ipremoteport: %s", iplocalport, ipremoteport);
    
    _sasl_conn_ctxt = NULL;
    int result = sasl_client_new("beep",
                                 [serverFQDN UTF8String],  // serverFQDN (has to  be set)
                                 iplocalport,  // iplocalport
                                 ipremoteport,  // ipremoteport
                                 _sasl_client_callbacks,
                                 0, // flags
                                 &_sasl_conn_ctxt);
    if (result == SASL_OK) {
        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"sasl_client_new succeeded");
    } else {
        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"%s", sasl_errdetail(_sasl_conn_ctxt));
    }
}

- (NSSet *)availableAuthenticationMechanisms {
    if (_availableMechanisms) return _availableMechanisms;
    if ([[_session peerProfileURIs] count]) {
        _availableMechanisms = [NSMutableSet new];
        NSEnumerator *enumerator = [[_session peerProfileURIs] objectEnumerator];
        NSString *profileURI;
        while ((profileURI = [enumerator nextObject])) {
            if ([profileURI hasPrefix:TCMBEEPSASLProfileURIPrefix]) {
                [_availableMechanisms addObject:[profileURI substringFromIndex:[TCMBEEPSASLProfileURIPrefix length]]];
            }
        }
        return _availableMechanisms;
    }
    return nil;
}




- (void)_authenticate
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
        DEBUGLOG(@"SASLLogDomain", DetailedLogLevel, @"offered mechs: %@", mechlist_string);
    
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

- (void)startAuthenticationWithUserName:(NSString *)aUserName password:(NSString *)aPassword
{
    [self setValue:aUserName forKey:@"userName"];
    [self setValue:aPassword forKey:@"password"];
    if (!_sasl_conn_ctxt) {
        if (_peerAddressData) {
            _peerHost = [[TCMHost alloc] initWithAddressData:_peerAddressData port:0 userInfo:nil];
            [_peerHost setDelegate:self];
            [_peerHost reverseLookup];
        } else {
            [self _setupSASLContextWithServerFQDN:nil];
            [self _authenticate];
        }
    } else {
        [self _authenticate];
    }
}

- (BOOL)isAuthenticated
{
    return _isAuthenticated;
}

- (void)setIsAuthenticated:(BOOL)flag
{
    _isAuthenticated = flag;
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
                        _isAuthenticated = YES;
                        [[NSNotificationCenter defaultCenter] postNotificationName:TCMBEEPAuthenticationClientDidAuthenticateNotification object:self];
                        [self setValue:@"" forKey:@"userName"];
                        [self setValue:@"" forKey:@"password"];
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
                            if (!failureMessage) failureMessage = @"No Failure Message";
                            [[NSNotificationCenter defaultCenter] postNotificationName:TCMBEEPAuthenticationClientDidNotAuthenticateNotification object:self userInfo:[NSDictionary dictionaryWithObject:
                                [NSError errorWithDomain:@"BEEPDomain" code:[[attributes objectForKey:@"code"] intValue] userInfo:[NSDictionary dictionaryWithObject:failureMessage forKey:NSUnderlyingErrorKey]]
                                    
                                forKey:@"NSError"]];
                            [self setValue:@"" forKey:@"userName"];
                            [self setValue:@"" forKey:@"password"];
                        }
                    }
                }
            }
            CFRelease(payloadTree);
        }
    }
}

#pragma mark -

- (void)hostDidResolveName:(TCMHost *)sender
{
    NSArray *names = [sender names];
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"reverse lookup done: %@", names);
    NSString *name = nil;
    if ([names count] > 0) name = [names objectAtIndex:0];
    [self _setupSASLContextWithServerFQDN:name];
    [self _authenticate];
}

- (void)host:(TCMHost *)sender didNotResolve:(NSError *)error
{
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"reverse lookup failed");
    [self _setupSASLContextWithServerFQDN:nil];
    [self _authenticate];
}

@end
