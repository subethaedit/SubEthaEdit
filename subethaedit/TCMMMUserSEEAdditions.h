//
//  TCMMMUserSEEAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMMMUser.h"

@class TCMMMUser;

@interface TCMMMUser (TCMMMUserSEEAdditions) 

+ (TCMMMUser *)userWithBencodedUser:(NSData *)aData;
- (NSData *)userBencoded;
    
@end
