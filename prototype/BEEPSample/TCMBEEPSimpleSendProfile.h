//
//  TCMBEEPSimpleSendProfile.h
//  BEEPSample
//
//  Created by Dominik Wagner on Tue Feb 24 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMBEEPProfile.h"

@class TCMBEEPChannel;

@interface TCMBEEPSimpleSendProfile : NSObject <TCMBEEPProfile> {
    TCMBEEPChannel *I_channel;
    id I_delegate;
}

- (id)initWithChannel:(TCMBEEPChannel *)aChannel;
- (void)setDelegate:(id)aDelegate;
- (id)delegate;
- (void)setChannel:(TCMBEEPChannel *)aChannel;
- (TCMBEEPChannel *)channel;

#pragma mark ### Simple API ###
- (void)sendData:(NSData *)aData;
- (void)close;

@end

@interface NSObject (TCMBEEPSimpleSendProfileDelegateAdditions)

- (void)profile:(TCMBEEPSimpleSendProfile *)aProfile didReceiveData:(NSData *)aData;

@end

