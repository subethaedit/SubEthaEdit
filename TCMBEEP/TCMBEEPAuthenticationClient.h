//
//  TCMBEEPAuthenticationClient.h
//  SubEthaEdit
//
//  Created by Martin Ott on 4/20/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sasl.h"
#import "TCMHost.h"

@class TCMBEEPSession, TCMBEEPSASLProfile;

@interface TCMBEEPAuthenticationClient : NSObject {
    TCMBEEPSession *_session;
    TCMBEEPSASLProfile *_profile;
    sasl_conn_t *_sasl_conn_ctxt;
    sasl_callback_t _sasl_client_callbacks[10];
    BOOL _isAuthenticated;
    NSData *_addressData;
    NSData *_peerAddressData;
    TCMHost *_peerHost;
}

- (id)initWithSession:(TCMBEEPSession *)session addressData:(NSData *)addressData peerAddressData:(NSData *)peerAddressData serverFQDN:(NSString *)serverFQDN;
- (void)startAuthentication;
- (BOOL)isAuthenticated;
- (void)setIsAuthenticated:(BOOL)flag;

@end
