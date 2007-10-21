//
//  TCMBEEPBencodingProfile.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMBEEPProfile.h"
#import "TCMBEEPBencodedMessage.h"

typedef enum TCMBEEPChannelRole {
    TCMBEEPChannelRoleInitiator=1,
    TCMBEEPChannelRoleResponder=2,
    TCMBEEPChannelRoleBoth=3
} TCMBEEPChannelRole;


@interface TCMBEEPBencodingProfile : TCMBEEPProfile {

}

+ (void)registerSelector:(SEL)aSelector forMessageType:(NSString *)aMessageType messageString:(NSString *)aMessageString channelRole:(TCMBEEPChannelRole)aRole;

@end
