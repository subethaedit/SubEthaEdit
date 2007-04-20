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
    sasl_conn_t *_sasl_conn_ctxt;
}

@end
