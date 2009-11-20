//
//  TCMBEEPAuthenticationServer.h
//  SubEthaEdit
//
//  Created by Martin Ott on 4/20/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sasl.h"


@interface TCMBEEPAuthenticationServer : NSObject {
    TCMBEEPSession *_session;
    TCMBEEPProfile *_profile;
    sasl_conn_t *_sasl_conn_ctxt;
    sasl_callback_t _sasl_server_callbacks[5];
    BOOL _isAuthenticated;
    id _delegate;
}

- (id)initWithSession:(TCMBEEPSession *)session addressData:(NSData *)addressData peerAddressData:(NSData *)peerAddressData;

- (NSData *)answerDataForChannelStartProfileURI:(NSString *)profileURI data:(NSData *)inData;
- (void)authenticationStepWithBlob:(NSString *)inString message:(TCMBEEPMessage *)message;
- (void)setProfile:(TCMBEEPProfile *)profile;
- (BOOL)isAuthenticated;

- (void)setDelegate:(id)aDelegate;
- (id)delegate;

@end

@interface NSObject (TCMBEEPAuthenticationServerDelegateAdditions)
// possible results are SASL_OK, SASL_BADAUTH
- (int)authenticationResultForServer:(TCMBEEPAuthenticationServer *)aServer user:(NSString 
*)aUser password:(NSString *)aPassword;
@end
