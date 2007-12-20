//
//  GeneralSASLProfile.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 17.12.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMBEEP.h"

@interface GenericSASLProfile : TCMBEEPProfile {

}

+ (NSData *)initialDataForUserName:(NSString *)aUserName password:(NSString *)aPassword profileURI:(NSString *)aProfileURI;
+ (NSDictionary *)replyForChannelRequestWithProfileURI:(NSString *)aProfileURI andData:(NSData *)aData inSession:(TCMBEEPSession *)aSession;
+ (NSDictionary *)parseBLOBData:(NSData *)aData;
+ (void)processPLAINAnswer:(NSData *)aData inSession:(TCMBEEPSession *)aSession;

@end
