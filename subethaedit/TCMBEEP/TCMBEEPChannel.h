//
//  TCMBEEPChannel.h
//  TCMBEEP
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@class TCMBEEPSession, TCMBEEPFrame, TCMBEEPMessage;

@interface TCMBEEPChannel : NSObject
{
    unsigned long I_number;
    uint32_t I_sequenceNumber;
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
    int32_t I_nextMessageNumber;
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

#pragma mark ### Convenience for Profiles ###
- (void)sendMSGMessageWithPayload:(NSData *)aPayload;

#pragma mark ### Accessors for session ###

- (BOOL)hasFramesAvailable;
- (NSArray *)availableFramesFittingInCurrentWindow;

- (int32_t)nextMessageNumber;

- (BOOL)acceptFrame:(TCMBEEPFrame *)aFrame;
- (void)sendMessage:(TCMBEEPMessage *)aMessage;

- (void)cleanup;

@end
