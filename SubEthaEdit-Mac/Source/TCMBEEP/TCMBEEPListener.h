//  TCMBEEPListener.h
//  TCMBEEP
//

#import <Foundation/Foundation.h>


@class TCMBEEPSession;


@interface TCMBEEPListener : NSObject 
{
    CFSocketRef I_listeningSocket;
    CFSocketRef I_listeningSocket6;
    id I_delegate;
    unsigned int I_port;
}

- (instancetype)initWithPort:(unsigned int)aPort;

- (void)setDelegate:(id)aDelegate;
- (id)delegate;

- (BOOL)listen;
- (void)close;

@end


@interface NSObject (TCMBEEPListenerDelegateAdditions)

- (BOOL)BEEPListener:(TCMBEEPListener *)aBEEPListener shouldAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession;
- (void)BEEPListener:(TCMBEEPListener *)aBEEPListener didAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession;

@end
