//  TCMBEEPChannel.h
//  TCMBEEP
//

#import <Foundation/Foundation.h>


typedef enum {
   TCMBEEPChannelStatusNotOpen = 0,
   //TCMBEEPChannelStatusOpening,
   TCMBEEPChannelStatusOpen,
   TCMBEEPChannelStatusAtEnd,
   TCMBEEPChannelStatusClosing,
   TCMBEEPChannelStatusCloseRequested,
   TCMBEEPChannelStatusClosed,
   TCMBEEPChannelStatusError
} TCMBEEPChannelStatus;


@class TCMBEEPSession, TCMBEEPFrame, TCMBEEPMessage;


@interface TCMBEEPChannel : NSObject
{
    uint32_t I_sequenceNumber;
    unsigned int I_incomingBufferSize;
    unsigned int I_incomingBufferSizeAvailable;
    uint32_t I_incomingSequenceNumber;
    uint32_t I_incomingWindowSize;
    uint32_t I_outgoingWindowSize;
    id I_profile;
    NSMutableIndexSet *I_messageNumbersWithPendingReplies;
    NSMutableIndexSet *I_unacknowledgedMessageNumbers;
    NSMutableIndexSet *I_inboundMessageNumbersWithPendingReplies;
    NSMutableIndexSet *I_preemptedMessageNumbers;
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

@property (nonatomic, retain) TCMBEEPFrame *previousReadFrame;
@property (nonatomic, retain) TCMBEEPMessage *currentReadMessage;
@property (nonatomic, assign) unsigned long number;
@property (nonatomic, weak) TCMBEEPSession *session;
@property (nonatomic, copy) NSString *profileURI;

+ (NSDictionary *)profileURIToClassMapping;
+ (void)setClass:(Class)aClass forProfileURI:(NSString *)aProfileURI;

- (id)initWithSession:(TCMBEEPSession *)aSession number:(unsigned long)aNumber profileURI:(NSString *)aProfileURI asInitiator:(BOOL)isInitiator;

- (BOOL)isInitiator;

- (id)profile;
- (TCMBEEPChannelStatus)channelStatus;
- (void)close;

// Convenience for Profiles
- (int32_t)sendMSGMessageWithPayload:(NSData *)aPayload;
- (BOOL)preemptFrame:(TCMBEEPFrame *)aFrame;

// Accessors for session
- (BOOL)hasFramesAvailable;
- (NSArray *)availableFramesFittingInCurrentWindow;
- (int32_t)nextMessageNumber;
- (BOOL)acceptFrame:(TCMBEEPFrame *)aFrame;
- (void)sendMessage:(TCMBEEPMessage *)aMessage;
- (void)sendSEQFrame;
- (void)cleanup;
- (void)closed;
- (void)closeFailedWithError:(NSError *)error;
- (void)closeRequested;

@end
