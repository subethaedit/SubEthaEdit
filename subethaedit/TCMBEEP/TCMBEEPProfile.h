//
//  TCMBEEPProfile.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Feb 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMBEEPSession.h"
#import "TCMBEEPChannel.h"
#import "TCMBEEPMessage.h"

@class TCMBEEPChannel, TCMBEEPMessage;


@interface TCMBEEPProfile : NSObject
{
    TCMBEEPChannel *I_channel;
    NSString *I_profileURI;
    id I_delegate;
}

- (id)initWithChannel:(TCMBEEPChannel *)aChannel;

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage;

- (void)setDelegate:(id)aDelegate;
- (id)delegate;
- (void)setChannel:(TCMBEEPChannel *)aChannel;
- (TCMBEEPChannel *)channel;
- (void)setProfileURI:(NSString *)aProfileURI;
- (NSString *)profileURI;
- (void)cleanup;

@end


@interface NSObject (TCMBEEPProfileDelegateAdditions)

- (void)profile:(TCMBEEPProfile *)aProfile didFailWithError:(NSError *)anError;

@end
