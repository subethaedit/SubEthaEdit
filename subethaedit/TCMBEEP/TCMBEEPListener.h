//
//  TCMBEEPListener.h
//  TCMBEEP
//
//  Created by Martin Ott on Mon Feb 16 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@class TCMBEEPSession;

@interface TCMBEEPListener : NSObject 
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


@interface NSObject (TCMBEEPListenerDelegateAdditions)

- (BOOL)BEEPListener:(TCMBEEPListener *)aBEEPListener shouldAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession;
- (void)BEEPListener:(TCMBEEPListener *)aBEEPListener didAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession;

@end