//
//  TCMBEEPProfile.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@class TCMBEEPChannel, TCMBEEPMessage;


@interface TCMBEEPProfile : NSObject
{
    TCMBEEPChannel *I_channel;
    id I_delegate;
}

- (id)initWithChannel:(TCMBEEPChannel *)aChannel;

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage;

- (void)setDelegate:(id)aDelegate;
- (id)delegate;
- (void)setChannel:(TCMBEEPChannel *)aChannel;
- (TCMBEEPChannel *)channel;


@end
