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
        BOOL error=NO;
        if (sscanf(aHeaderString,"%3s %d %d %1s %d %d\r",
                    I_messageType, &I_channelNumber, &I_messageNumber,
                    I_continuationIndicator, &I_sequenceNumber, &I_length) == 6) {
            
            // 1ter punkt 2.2.1.1
            if (!(strcmp(I_messageType, "MSG") == 0 ||
                  strcmp(I_messageType, "RPY") == 0 ||
                  strcmp(I_messageType, "ERR") == 0 ||
                  strcmp(I_messageType, "ANS") == 0 ||
                  strcmp(I_messageType, "NUL") == 0)) {
                error = YES;
                
            // 11ter punkt 2.2.1.1
            } else if (strcmp(I_messageType, "NUL") && [self isIntermediate]) {
                error = YES;
            }
        } else if (sscanf(aHeaderString,"%3s %d %d %1s %d %d %d\r",
                    I_messageType, &I_channelNumber, &I_messageNumber,
                    I_continuationIndicator, &I_sequenceNumber, &I_length, &I_answerNumber) == 7){
            if (!(strcmp(I_messageType,"ANS"))) {
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

#pragma mark -
#pragma mark ### Accessors ###

-(char  *) messageType {
    return I_messageType;
}
-(int32_t) channelNumber {
    return I_channelNumber;
}
-(int32_t) messageNumber {
    return I_messageNumber;
}
-(char  *) continuationIndicator {
    return I_continuationIndicator;
}
-(BOOL)isIntermediate {
    return (I_continuationIndicator[0]=='*');
}
-(uint32_t) sequenceNumber {
    return I_sequenceNumber;
}
-(int32_t) length {
    return I_length;
}

- (int32_t)answerNumber
{
    return I_answerNumber;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"TCMBEEPFrame: %3s %d %d %1s %d %d\nData Lenght:%d",I_messageType, I_channelNumber, I_messageNumber,
                    I_continuationIndicator, I_sequenceNumber, I_length, [I_content length]];
}

- (void)setContent:(NSData *)aData
{
    [I_content autorelease];
    I_content = [aData copy];
}

- (NSData *)content
{
    return I_content;
}

@end
