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
+ (TCMMMUser *)userWithDictionaryRepresentation:(NSDictionary *)aRepresentation;
- (NSDictionary *)dictionaryRepresentation;
- (void)prepareImages;
- (NSData *)userBencoded;
- (void)setUserHue:(NSNumber *)aHue;

    
@end
