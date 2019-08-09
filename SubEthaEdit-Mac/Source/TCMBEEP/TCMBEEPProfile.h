//  TCMBEEPProfile.h
//  TCMBEEP
//

#import <Foundation/Foundation.h>
#import "TCMBEEPSession.h"
#import "TCMBEEPChannel.h"
#import "TCMBEEPMessage.h"


@class TCMBEEPChannel, TCMBEEPMessage, TCMBEEPProfile;

@protocol TCMBEEPProfileDelegate <NSObject>
@optional
- (void)profile:(TCMBEEPProfile *)aProfile didFailWithError:(NSError *)anError;
- (void)profileDidClose:(TCMBEEPProfile *)aProfile;
@end


@interface TCMBEEPProfile : NSObject
{
    BOOL I_isClosing;
    BOOL I_isAbortingIncomingMessages;
}

@property (nonatomic, weak) TCMBEEPChannel *channel;
@property (nonatomic, weak) id<TCMBEEPProfileDelegate> delegate;
@property (nonatomic, copy) NSString *profileURI;

- (id)initWithChannel:(TCMBEEPChannel *)aChannel;

- (void)handleInitializationData:(NSData *)aData;
- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage;

- (TCMBEEPSession *)session;
- (BOOL)isServer;
- (void)setProfileURI:(NSString *)aProfileURI;
- (NSString *)profileURI;
- (void)channelDidReceiveCloseRequest;
- (void)channelDidClose;
- (void)channelDidNotCloseWithError:(NSError *)error;
- (void)cleanup;
- (void)close;
- (void)abortIncomingMessages;
- (void)channelDidReceivePreemptiveReplyForMessageWithNumber:(int32_t)aMessageNumber;
- (void)channelDidReceivePreemptedMessage:(TCMBEEPMessage *)aMessage;
- (void)channelDidReceiveFrame:(TCMBEEPFrame *)aFrame startingMessage:(BOOL)aFlag;

@end


