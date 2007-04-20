//
//  TCMBEEPAuthenticationClient.h
//  SubEthaEdit
//
//  Created by Martin Ott on 4/20/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sasl.h"

@class TCMBEEPSession, TCMBEEPProfile;

@interface TCMBEEPAuthenticationClient : NSObject {
    TCMBEEPSession *_session;
    TCMBEEPProfile *_profile;
    sasl_conn_t *_sasl_conn_ctxt;
}

- (id)initWithSession:(TCMBEEPSession *)session;
- (void)startAuthentication;

@end
