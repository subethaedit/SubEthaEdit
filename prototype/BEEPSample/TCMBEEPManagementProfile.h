//
//  TCMBEEPManagementProfile.h
//  BEEPSample
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMBEEPProfile.h"

@class TCMBEEPChannel;

@interface TCMBEEPManagementProfile : NSObject <TCMBEEPProfile>
{
    TCMBEEPChannel *I_channel;
    id I_delegate;
    BOOL I_firstMessage;
}

- (id)initWithChannel:(TCMBEEPChannel *)aChannel;

- (void)sendGreetingWithProfileURIs:(NSArray *)anArray featuresAttribute:(NSString *)aFeaturesString localizeAttribute:(NSString *)aLocalizeString;

#pragma mark -

/*"Accessors"*/
- (void)setDelegate:(id)aDelegate;
- (id)delegate;
- (void)setChannel:(TCMBEEPChannel *)aChannel;
- (TCMBEEPChannel *)channel;

@end


@interface TCMBEEPManagementProfile (TCMBEEPManagementProfileDelegateAdditions)

- (void)didReceiveGreetingWithProfileURIs:(NSArray *)profileURIs featuresAttribute:(NSString *)aFeaturesAttribute localizeAttribute:(NSString *)aLocalizeAttribute;

@end
