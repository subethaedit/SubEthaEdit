//
//  TCMBEEPFrame.h
//  BEEPSample
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TCMBEEPFrame : NSObject
{
    char I_messageType[4];
    int32_t I_channelNumber;
    int32_t I_messageNumber;
    char I_continuationIndicator[2];
    uint32_t I_sequenceNumber;
    int32_t I_length;
    int32_t I_answerNumber;
    NSData *I_payload;
}

- (id)initWithHeader:(char *)aHeaderString;

- (void)setPayload:(NSData *)aData;
- (NSData *)payload;

- (char *)messageType;
- (int32_t)channelNumber;
- (int32_t)messageNumber;
- (char *)continuationIndicator;
- (BOOL)isIntermediate;
- (uint32_t)sequenceNumber;
- (int32_t)length;
- (int32_t)answerNumber;


@end
