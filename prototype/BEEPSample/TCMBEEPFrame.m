//
//  TCMBEEPFrame.m
//  BEEPSample
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPFrame.h"


@implementation TCMBEEPFrame

- (id)initWithHeader:(char *)aHeaderString
{
    self = [super init];
    if (self) {
        I_answerNumber = -1;
        BOOL error = NO;
        if (sscanf(aHeaderString, "%3s %d %d %1s %d %d\r",
                    I_messageType, &I_channelNumber, &I_messageNumber,
                    I_continuationIndicator, &I_sequenceNumber, &I_length) == 6) {
            

        } else if (sscanf(aHeaderString,"%3s %d %d %1s %d %d %d\r",
                    I_messageType, &I_channelNumber, &I_messageNumber,
                    I_continuationIndicator, &I_sequenceNumber, &I_length, &I_answerNumber) == 7){
            if (!(strcmp(I_messageType, "ANS"))) {
                error = YES;
            }
        } else if (sscanf(aHeaderString, "%3s %d %d %d\r", I_messageType, &I_channelNumber, &I_sequenceNumber, &I_length) == 4) {
        
        } else {
            error = YES;
        }
        
        if (error) {
            [super dealloc];
            self = nil;
        }
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"TCMBEEPFrame: %3s %d %d %1s %d %d\nPayload length: %d", I_messageType, I_channelNumber, I_messageNumber,
                    I_continuationIndicator, I_sequenceNumber, I_length, [I_payload length]];
}

#pragma mark -

- (char *)messageType
{
    return I_messageType;
}

- (int32_t)channelNumber
{
    return I_channelNumber;
}

- (int32_t)messageNumber
{
    return I_messageNumber;
}

-(char *)continuationIndicator
{
    return I_continuationIndicator;
}

-(BOOL)isIntermediate
{
    return (I_continuationIndicator[0] == '*');
}

-(uint32_t)sequenceNumber
{
    return I_sequenceNumber;
}

- (int32_t)length
{
    return I_length;
}

- (int32_t)answerNumber
{
    return I_answerNumber;
}

- (void)setPayload:(NSData *)aData
{
    [I_payload autorelease];
    I_payload = [aData copy];
}

- (NSData *)payload
{
    return I_payload;
}

@end
