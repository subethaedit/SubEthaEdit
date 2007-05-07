//
//  TCMBEEPAuthenticationClient.h
//  SubEthaEdit
//
//  Created by Martin Ott on 4/20/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sasl.h"

@class TCMBEEPSession, TCMBEEPSASLProfile;

@interface TCMBEEPAuthenticationClient : NSObject {
    TCMBEEPSession *_session;
    TCMBEEPSASLProfile *_profile;
    sasl_conn_t *_sasl_conn_ctxt;
    BOOL _isAuthenticated;
}

- (id)initWithSession:(TCMBEEPSession *)session addressData:(NSData *)addressData peerAddressData:(NSData *)peerAddressData serverFQDN:(NSString *)serverFQDN;
- (void)startAuthentication;
- (BOOL)isAuthenticated;
- (void)setIsAuthenticated:(BOOL)flag;

@end
