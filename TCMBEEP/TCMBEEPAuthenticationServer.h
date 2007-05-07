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
    BOOL _isAuthenticated;
}

- (id)initWithSession:(TCMBEEPSession *)session addressData:(NSData *)addressData peerAddressData:(NSData *)peerAddressData;

- (NSData *)answerDataForChannelStartProfileURI:(NSString *)profileURI data:(NSData *)inData;
- (void)authenticationStepWithBlob:(NSString *)inString message:(TCMBEEPMessage *)message;
- (void)setProfile:(TCMBEEPProfile *)profile;
- (BOOL)isAuthenticated;

@end
