//
//  TCMBEEPManagementProfile.h
//  TCMBEEP
//
//  Created by Martin Ott on Wed Feb 18 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMBEEPProfile.h"


@class TCMBEEPChannel;


@interface TCMBEEPManagementProfile : TCMBEEPProfile
{
    BOOL I_firstMessage;
    NSMutableDictionary *I_pendingChannelRequestMessageNumbers;
    NSMutableDictionary *I_channelNumbersByCloseRequests;
    NSMutableDictionary *I_messageNumbersOfCloseRequestsByChannelsNumbers;
}

- (id)initWithChannel:(TCMBEEPChannel *)aChannel;

- (void)sendGreetingWithProfileURIs:(NSArray *)anArray featuresAttribute:(NSString *)aFeaturesString localizeAttribute:(NSString *)aLocalizeString;

#pragma mark -

- (void)startChannelNumber:(int32_t)aChannelNumber withProfileURIs:(NSArray *)aProfileURIArray andData:(NSArray *)aDataArray;
- (void)closeChannelWithNumber:(int32_t)aChannelNumber code:(int)aReplyCode;
- (void)acceptCloseRequestForChannelWithNumber:(int32_t)aChannelNumber;

@end

#pragma mark -

@interface NSObject (TCMBEEPManagementProfileDelegateAdditions)

- (void)didReceiveGreetingWithProfileURIs:(NSArray *)profileURIs featuresAttribute:(NSString *)aFeaturesAttribute localizeAttribute:(NSString *)aLocalizeAttribute;
- (NSMutableDictionary *)preferedAnswerToAcceptRequestForChannel:(int32_t)channelNumber withProfileURIs:(NSArray *)aProfileURIArray andData:(NSArray *)aDataArray;
- (void)didReceiveAcceptStartRequestForChannel:(int32_t)aNumber withProfileURI:(NSString *)aProfileURI andData:(NSData *)aData;
- (void)closedChannelWithNumber:(int32_t)aChannelNumber;

@end
