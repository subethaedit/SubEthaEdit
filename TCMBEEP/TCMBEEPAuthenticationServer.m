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
        DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"setting log level");
        *result = "5"; //SASL_LOG_TRACE 6
        if (len) *len = 1;
    }
    if (!strcmp(option, "sasldb_path")) {
        DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"setting sasldb_path");
        *result = "/etc/sasldb2";
        if (len) *len = 12;
    }
    
    //if (!strcmp(option, "auxprop_plugin")) {
    //    DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"setting auxprop_plugin");
    //    *result = NULL;
    //    if (len) *len = 0;
    //}
    
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

static int sasl_server_userdb_checkpass(sasl_conn_t *conn,
					   void *context,
					   const char *user,
					   const char *pass,
					   unsigned passlen,
					   struct propctx *propctx)
{
    DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"user: %s", user);
    NSString *userString = [NSString stringWithUTF8String:user];
    NSString *passwordString = [[NSString alloc] initWithBytes:pass length:passlen encoding:NSUTF8StringEncoding];
    id delegate = [(id)context delegate];
    if ([delegate respondsToSelector:@selector(authenticationResultForServer:user:password:)]) {
        return [delegate authenticationResultForServer:(id)context user:userString password:passwordString];
    }
    
    return SASL_BADAUTH;
}

# pragma mark -

@implementation TCMBEEPAuthenticationServer

- (id)initWithSession:(TCMBEEPSession *)session addressData:(NSData *)addressData peerAddressData:(NSData *)peerAddressData
{
    self = [super init];
    if (self) {
        _session = session;
        _isAuthenticated = NO;
        _sasl_conn_ctxt = NULL;

        sasl_callback_t *callback = _sasl_server_callbacks;
        callback->id = SASL_CB_GETOPT;
        callback->proc = &sasl_getopt_session_server_cb;
        callback->context = self;
        ++callback;
        
        callback->id = SASL_CB_PROXY_POLICY;
        callback->proc = &sasl_authorize_session_server_cb;
        callback->context = self;
        ++callback;
        
        callback->id = SASL_CB_LOG;
        callback->proc = &sasl_log_session_server_cb;
        callback->context = self;
        ++callback;
        
        callback->id = SASL_CB_SERVER_USERDB_CHECKPASS;
        callback->proc = &sasl_server_userdb_checkpass;
        callback->context = self;
        ++callback;
        
        callback->id = SASL_CB_LIST_END;
        callback->proc = NULL;
        callback->context = self;

        
        const char *iplocalport = NULL;
        const char *ipremoteport = NULL;
        if (addressData) iplocalport = [[NSString stringWithAddressData:addressData cyrusSASLCompatible:YES] UTF8String];
        if (peerAddressData) ipremoteport = [[NSString stringWithAddressData:peerAddressData cyrusSASLCompatible:YES] UTF8String];
        DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"iplocalport: %s, ipremoteport: %s", iplocalport, ipremoteport);

        int result = sasl_server_new("beep",
                                     NULL,  // serverFQDN (looks up for itself)
                                     NULL,  // user_realm
                                     iplocalport,  // iplocalport
                                     ipremoteport,  // ipremoteport
                                     _sasl_server_callbacks,
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
                //if ([mechanisms containsObject:@"GSSAPI"]) [_session addProfileURIs:[NSArray arrayWithObject:TCMBEEPSASLGSSAPIProfileURI]];
                //if ([mechanisms containsObject:@"DIGEST-MD5"]) [_session addProfileURIs:[NSArray arrayWithObject:TCMBEEPSASLDIGESTMD5ProfileURI]];
                //if ([mechanisms containsObject:@"CRAM-MD5"]) [_session addProfileURIs:[NSArray arrayWithObject:TCMBEEPSASLCRAMMD5ProfileURI]];
                if ([mechanisms containsObject:@"PLAIN"]) [_session addProfileURIs:[NSArray arrayWithObject:TCMBEEPSASLPLAINProfileURI]];
                if ([mechanisms containsObject:@"ANONYMOUS"]) [_session addProfileURIs:[NSArray arrayWithObject:TCMBEEPSASLANONYMOUSProfileURI]];
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
    DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"Got profile: %@", profile);
    [_profile autorelease];
    _profile = [profile retain];
}

- (BOOL)isAuthenticated
{
    return _isAuthenticated;
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
            #warning Send ERR 500 frame
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
                #warning Send ERR 500 frame
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
                            [[clientin_string retain] autorelease];
                            DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"parsed clientin blob");
                        }
                    }
                }
            }
            CFRelease(payloadTree);
        }
    }
    
    NSString *mech_string = [profileURI substringFromIndex:[TCMBEEPSASLProfileURIPrefix length]];
    
    NSData *decodedBase64String = [NSData dataWithBase64EncodedString:clientin_string];

    const char *serverout;
    unsigned serveroutlen;
    int result = sasl_server_start(_sasl_conn_ctxt,
                                   [mech_string UTF8String],
                                   [decodedBase64String bytes],
                                   [decodedBase64String length],
                                   &serverout,
                                   &serveroutlen);
    if ((result != SASL_OK) && (result != SASL_CONTINUE)) {
        // [failure. Send protocol specific message that says authentication failed]
        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"[failure. Send protocol specific message that says authentication failed] %s", sasl_errdetail(_sasl_conn_ctxt));
        unsigned errorCode = 000;
        NSString *errorDescription = @"error description";
        if (SASL_NOUSER == result || SASL_BADAUTH == result) {
            errorCode = 535;
            errorDescription = @"authentication failure";
        }
        NSString *returnString = [NSString stringWithFormat:@"<error code='%d'>%@</error>", errorCode, errorDescription];
        [outData appendData:[returnString dataUsingEncoding:NSUTF8StringEncoding]];
    } else if (result == SASL_OK) {
        // [authentication succeeded. Send client the protocol specific message 
        // to say that authentication is complete]
        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"[authentication succeeded. Send client the protocol specific message to say that authentication is complete]");
        [outData appendData:[@"<blob status='complete' />" dataUsingEncoding:NSUTF8StringEncoding]];
        _isAuthenticated = YES;
    } else {
        // [send data 'out' with length 'outlen' over the network in protocol
        // specific format]
        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"[send data 'out' with length 'outlen' over the network in protocol specific format]");
        if (serveroutlen > 0) {        
            [outData appendData:[@"<blob>" dataUsingEncoding:NSUTF8StringEncoding]];

            NSData *serverData = [NSData dataWithBytes:serverout length:serveroutlen];
            DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"serverout: %@", [NSString stringWithData:serverData encoding:NSUTF8StringEncoding]);
            NSString *base64EncodedString = [serverData base64EncodedStringWithLineLength:0];
            [outData appendData:[base64EncodedString dataUsingEncoding:NSUTF8StringEncoding]];
            
            [outData appendData:[@"</blob>" dataUsingEncoding:NSUTF8StringEncoding]];
            DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"answer: %@", [NSString stringWithData:outData encoding:NSUTF8StringEncoding]);
        }
    }
    
    return outData;
}

- (void)authenticationStepWithBlob:(NSString *)inString message:(TCMBEEPMessage *)inMessage
{
    int result;
    const char *serverout;
    unsigned serveroutlen;
    
    result = sasl_server_step(_sasl_conn_ctxt,
                              [inString UTF8String],      /* what the client gave */
                              [inString length],   /* it's length */
                              &serverout,          /* allocated by library on success. Might not be NULL terminated */
                              &serveroutlen);

    if ((result != SASL_OK) && (result != SASL_CONTINUE)) {
        // [failure. Send protocol specific message that says authentication failed]
        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"[failure. Send protocol specific message that says authentication failed] %s", sasl_errdetail(_sasl_conn_ctxt));
        
        unsigned errorCode = 000;
        NSString *errorDescription = @"error description";
        if (SASL_NOUSER == result || SASL_BADAUTH == result) {
            errorCode = 535;
            errorDescription = @"authentication failure";
        }
        
        NSString *resultString = [NSString stringWithFormat:@"Content-Type: application/beep+xml\r\n\r\n<error code='%d'>%@</error>", errorCode, errorDescription];
        NSMutableData *payload = [NSMutableData dataWithData:[resultString dataUsingEncoding:NSUTF8StringEncoding]];
        TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"ERR" messageNumber:[inMessage messageNumber] payload:payload];
        [[_profile channel] sendMessage:message];       
    } else if (result == SASL_OK) {
        // [authentication succeeded. Send client the protocol specific message to say that authentication is complete]
        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"[authentication succeeded. Send client the protocol specific message to say that authentication is complete]");
        NSString *resultString = @"<blob status='complete' />";
        NSMutableData *payload = [NSMutableData dataWithData:[resultString dataUsingEncoding:NSUTF8StringEncoding]];
        TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[inMessage messageNumber] payload:payload];
        [[_profile channel] sendMessage:message];  
        _isAuthenticated = YES;
    } else {
        // [send data 'out' with length 'outlen' over the network in protocol specific format]
        DEBUGLOG(@"SASLLogDomain", SimpleLogLevel, @"[send data 'out' with length 'outlen' over the network in protocol specific format]");
        DEBUGLOG(@"SASLLogDomain", AllLogLevel, @"serverout: %@", [NSString stringWithData:[NSData dataWithBytes:serverout length:serveroutlen] encoding:NSUTF8StringEncoding]);
        NSMutableData *payload = [NSMutableData data];
        [payload appendData:[@"Content-Type: application/beep+xml\r\n\r\n<blob>" dataUsingEncoding:NSUTF8StringEncoding]];
        NSData *serverData = [NSData dataWithBytes:serverout length:serveroutlen];
        NSString *base64EncodedString = [serverData base64EncodedStringWithLineLength:0];
        [payload appendData:[base64EncodedString dataUsingEncoding:NSUTF8StringEncoding]];
        [payload appendData:[@"</blob>" dataUsingEncoding:NSUTF8StringEncoding]];
        TCMBEEPMessage *message = [[TCMBEEPMessage alloc] initWithTypeString:@"RPY" messageNumber:[inMessage messageNumber] payload:payload];
        [[_profile channel] sendMessage:message];  
    }
   
}

- (void)setDelegate:(id)aDelegate {
    _delegate = aDelegate;
}
- (id)delegate {
    return _delegate;
}


@end
