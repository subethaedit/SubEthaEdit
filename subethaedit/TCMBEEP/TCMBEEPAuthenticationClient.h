//
//  TCMBEEPAuthenticationClient.h
//  SubEthaEdit
//
//  Created by Martin Ott on 4/20/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMHost.h"

extern NSString * const TCMBEEPAuthenticationClientDidAuthenticateNotification;
extern NSString * const TCMBEEPAuthenticationClientDidNotAuthenticateNotification;


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
    NSMutableSet *_availableMechanisms;
    NSString *_userName;
    NSString *_password;
}

- (id)initWithSession:(TCMBEEPSession *)session addressData:(NSData *)addressData peerAddressData:(NSData *)peerAddressData serverFQDN:(NSString *)serverFQDN;
- (NSSet *)availableAuthenticationMechanisms;
- (void)startAuthenticationWithUserName:(NSString *)aUserName password:(NSString *)aPassword;
- (BOOL)isAuthenticated;
- (void)setIsAuthenticated:(BOOL)flag;

@end
