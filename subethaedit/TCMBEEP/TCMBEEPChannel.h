//
//  TCMBEEPChannel.h
//  TCMBEEP
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
   TCMBEEPChannelStatusNotOpen = 0,
   //TCMBEEPChannelStatusOpening,
   TCMBEEPChannelStatusOpen,
   TCMBEEPChannelStatusClosing,
   TCMBEEPChannelStatusClosed,
   TCMBEEPChannelStatusError
} TCMBEEPChannelStatus;


@class TCMBEEPSession, TCMBEEPFrame, TCMBEEPMessage;


@interface TCMBEEPChannel : NSObject
{
    unsigned long I_number;
    uint32_t I_sequenceNumber;
    unsigned int I_incomingBufferSize;
    unsigned int I_incomingBufferSizeAvailable;
    uint32_t I_incomingSequenceNumber;
    uint32_t I_incomingWindowSize;
    uint32_t I_outgoingWindowSize;
    TCMBEEPSession *I_session;
    NSString *I_profileURI;
    id I_profile;
    TCMBEEPFrame *I_previousReadFrame;
    TCMBEEPMessage *I_currentReadMessage;
    NSMutableIndexSet *I_messageNumbersWithPendingReplies;
    NSMutableIndexSet *I_inboundMessageNumbersWithPendingReplies;
    NSMutableArray *I_defaultReadQueue;
    NSMutableDictionary *I_answerReadQueues;
    NSMutableArray *I_messageWriteQueue;
    NSMutableArray *I_outgoingFrameQueue;
    int32_t I_nextMessageNumber;
    TCMBEEPChannelStatus I_channelStatus;
    struct {
        BOOL isInitiator;
    } I_flags;
}

+ (NSDictionary *)profileURIToClassMapping;
+ (void)setClass:(Class)aClass forProfileURI:(NSString *)aProfileURI;

- (id)initWithSession:(TCMBEEPSession *)aSession number:(unsigned long)aNumber profileURI:(NSString *)aProfileURI asInitiator:(BOOL)isInitiator;

- (BOOL)isInitiator;

- (void)setNumber:(unsigned long)aNumber;
- (unsigned long)number;

- (void)setSession:(TCMBEEPSession *)aSession;
- (TCMBEEPSession *)session;

- (void)setProfileURI:(NSString *)aProfileURI;
- (NSString *)profileURI;

- (void)setPreviousReadFrame:(TCMBEEPFrame *)aFrame;
- (TCMBEEPFrame *)previousReadFrame;

- (void)setCurrentReadMessage:(TCMBEEPMessage *)aMessage;
- (TCMBEEPMessage *)currentReadMessage;
- (id)profile;
- (TCMBEEPChannelStatus)channelStatus;
- (void)close;
- (void)terminate;

// Convenience for Profiles
- (void)sendMSGMessageWithPayload:(NSData *)aPayload;


// Accessors for session
- (BOOL)hasFramesAvailable;
- (NSArray *)availableFramesFittingInCurrentWindow;
- (int32_t)nextMessageNumber;
- (BOOL)acceptFrame:(TCMBEEPFrame *)aFrame;
- (void)sendMessage:(TCMBEEPMessage *)aMessage;
- (void)cleanup;
- (void)closed;
- (void)closeFailedWithError:(NSError *)error;

@end
