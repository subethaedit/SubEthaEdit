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
        if (sscanf(aHeaderString,"%3s %d %d %1s %d %d\r",
                    I_messageType, &I_channelNumber, &I_messageNumber,
                    I_continuationIndicator, &I_sequenceNumber, &I_length) == 6) {
            
        } else {
            [super dealloc];
            self=nil;
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
-(int32_t) sequenceNumber {
    return I_sequenceNumber;
}
-(int32_t) length {
    return I_length;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"TCMBEEPFrame: %3s %d %d %1s %d %d\n%@",I_messageType, I_channelNumber, I_messageNumber,
                    I_continuationIndicator, I_sequenceNumber, I_length, [I_content description]];
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
