//  TCMBEEPMessage.h
//  TCMBEEP
//

#import <Foundation/Foundation.h>


@interface TCMBEEPMessage : NSObject
{
    NSMutableData *_payload;
}

@property (nonatomic, copy) NSString *messageTypeString;
@property (nonatomic, copy) NSData *payload;
@property (nonatomic, assign) int32_t messageNumber;
@property (nonatomic, assign) int32_t channelNumber;
@property (nonatomic, assign) int32_t answerNumber;


+ (TCMBEEPMessage *)messageWithQueue:(NSArray *)aQueue;

- (instancetype)initWithTypeString:(NSString *)aType messageNumber:(int32_t)aMessageNumber payload:(NSData *)aPayload;
- (instancetype)initWithQueue:(NSArray *)aQueue;

- (void)setMessageTypeString:(NSString *)aString;
- (NSString *)messageTypeString;
- (void)setMessageNumber:(int32_t)aNumber;
- (int32_t)messageNumber;
- (void)setChannelNumber:(int32_t)aNumber;
- (int32_t)channelNumber;
- (void)setAnswerNumber:(int32_t)aNumber;
- (int32_t)answerNumber;
- (void)setPayload:(NSData *)aData;
- (NSData *)payload;
- (unsigned)payloadLength;

// convenience
- (BOOL)isMSG;
- (BOOL)isANS;
- (BOOL)isNUL;
- (BOOL)isRPY;
- (BOOL)isERR;

@end
