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
    char    I_messageType[4];
    int32_t I_channelNumber;
    int32_t I_messageNumber;
    char    I_continuationIndicator[2];
    int32_t I_sequenceNumber;
    int32_t I_length;
    int32_t I_answerNumber;
    NSData *I_content;
}

- (id)initWithHeader:(char *)aHeaderString;

- (void)setContent:(NSData *)aData;
- (NSData *)content;

-(char  *) messageType;
-(int32_t) channelNumber;
-(int32_t) messageNumber;
-(char *) continuationIndicator;
- (BOOL)isIntermediate;
-(int32_t) sequenceNumber;
-(int32_t) length;


@end
