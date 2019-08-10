//  TCMBEEPListener.h
//  TCMBEEP
//

#import <Foundation/Foundation.h>


@class TCMBEEPSession;


@interface TCMBEEPListener : NSObject 
{
    CFSocketRef I_listeningSocket;
    CFSocketRef I_listeningSocket6;
    unsigned int I_port;
}

@property (nonatomic, weak) id delegate;

- (instancetype)initWithPort:(unsigned int)aPort;

- (BOOL)listen;
- (void)close;

@end


@interface NSObject (TCMBEEPListenerDelegateAdditions)

- (BOOL)BEEPListener:(TCMBEEPListener *)aBEEPListener shouldAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession;
- (void)BEEPListener:(TCMBEEPListener *)aBEEPListener didAcceptBEEPSession:(TCMBEEPSession *)aBEEPSession;

@end
