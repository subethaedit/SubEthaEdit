//
//  TCMBEEPManagementProfile.h
//  BEEPSample
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TCMBEEPChannel;

@interface TCMBEEPManagementProfile : NSObject
{
    TCMBEEPChannel *I_channel;
    id I_delegate;
}

- (id)initWithChannel:(TCMBEEPChannel *)aChannel;

- (void)sendGreetingWithProfileURIs:(NSArray *)anArray featuresAttribute:(NSString *)aFeaturesString localizeAttribute:(NSString *)aLocalizeString;

#pragma mark -
#pragma mark ### Accessors ####
/*"Accessors"*/
- (void)setDelegate:(id)aDelegate;
- (id)delegate;
- (void)setChannel:(TCMBEEPChannel *)aChannel;
- (TCMBEEPChannel *)channel;



@end
