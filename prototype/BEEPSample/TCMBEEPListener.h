//
//  BEEPListener.h
//  BEEPSample
//
//  Created by Martin Ott on Mon Feb 16 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@class BEEPSession;

@interface BEEPListener : NSObject 
{
    CFSocketRef I_listeningSocket;
    id I_delegate;
    unsigned int I_port;
}

- (id)initWithPort:(unsigned int)aPort;

- (void)setDelegate:(id)aDelegate;
- (id)delegate;

- (BOOL)listen;
- (void)close;

@end


@interface NSObject (BEEPListenerDelegateAdditions)

- (BOOL)BEEPListener:(BEEPListener *)aBEEPListener shouldAcceptBEEPSession:(BEEPSession *)aBEEPSession;
- (void)BEEPListener:(BEEPListener *)aBEEPListener didAcceptBEEPSession:(BEEPSession *)aBEEPSession;

@end