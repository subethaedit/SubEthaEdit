//  TCMBEEPFrame.h
//  TCMBEEP
//

#import <Foundation/Foundation.h>


@class TCMBEEPMessage;

@interface TCMBEEPFrame : NSObject
{
    char I_messageType[4];
    int32_t I_channelNumber;
    int32_t I_messageNumber;
    char I_continuationIndicator[2];
    uint32_t I_sequenceNumber;
    int32_t I_length;
    int32_t I_answerNumber;
}

@property (nonatomic, copy) NSData *payload;

+ (TCMBEEPFrame *)SEQFrameWithChannelNumber:(int32_t)channelNumber
                      acknowledgementNumber:(uint32_t)acknowledgementNumber
                                 windowSize:(int32_t)windowSize;
                                 
+ (TCMBEEPFrame *)frameWithMessage:(TCMBEEPMessage *)aMessage 
                    sequenceNumber:(uint32_t)aSequenceNumber
                     payloadLength:(uint32_t)aLength
                      intermediate:(BOOL)aFlag;

- (instancetype)initWithMessage:(TCMBEEPMessage *)aMessage 
       sequenceNumber:(uint32_t)aSequenceNumber
        payloadLength:(uint32_t)aLength
         intermediate:(BOOL)aFlag;
         
- (instancetype)initWithChannelNumber:(int32_t)channelNumber
      acknowledgementNumber:(uint32_t)acknowledgementNumber
                 windowSize:(int32_t)windowSize;
                 
- (instancetype)initWithHeader:(char *)aHeaderString;

- (void)setPayload:(NSData *)aData;
- (NSData *)payload;

- (void)setMessageTypeString:(NSString *)aString;
- (char *)messageType;
- (int32_t)channelNumber;
- (int32_t)messageNumber;
- (char *)continuationIndicator;
- (BOOL)isIntermediate;
- (uint32_t)sequenceNumber;
- (int32_t)length;
- (int32_t)answerNumber;

- (BOOL)isMSG;
- (BOOL)isRPY;
- (BOOL)isERR;
- (BOOL)isANS;
- (BOOL)isNUL;
- (BOOL)isSEQ;

- (void)appendToMutableData:(NSMutableData *)aData;

- (NSData *)descriptionInLogFileFormatIncoming:(BOOL)aFlag;

@end
