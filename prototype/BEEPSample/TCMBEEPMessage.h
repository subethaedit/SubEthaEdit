//
//  TCMBEEPMessage.h
//  BEEPSample
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TCMBEEPMessage : NSObject
{
    NSString *I_messageTypeString;
    int32_t I_messageNumber;
    int32_t I_channelNumber;
    int32_t I_answerNumber;
    NSMutableData *I_payload;
}

+ (TCMBEEPMessage *)messageWithQueue:(NSArray *)aQueue;

- (id)initWithQueue:(NSArray *)aQueue;

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

@end
