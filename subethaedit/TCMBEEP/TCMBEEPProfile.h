//
//  TCMBEEPProfile.h
//  TCMBEEP
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMBEEPSession.h"
#import "TCMBEEPChannel.h"
#import "TCMBEEPMessage.h"


@class TCMBEEPChannel, TCMBEEPMessage;


@interface TCMBEEPProfile : NSObject
{
    TCMBEEPChannel *I_channel;
    id I_delegate;
    NSString *I_profileURI;
    
    BOOL I_isClosing;
    BOOL I_isAbortingIncomingMessages;
}

- (id)initWithChannel:(TCMBEEPChannel *)aChannel;

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage;

- (void)setDelegate:(id)aDelegate;
- (id)delegate;
- (void)setChannel:(TCMBEEPChannel *)aChannel;
- (TCMBEEPChannel *)channel;
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
- (void)channelDidReceiveFrame:(TCMBEEPFrame *)aFrame;

@end


@interface NSObject (TCMBEEPProfileDelegateAdditions)

- (void)profile:(TCMBEEPProfile *)aProfile didFailWithError:(NSError *)anError;
- (void)profileDidClose:(TCMBEEPProfile *)aProfile;

@end
