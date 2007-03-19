//
//  TCMMMUserSEEAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "TCMMillionMonkeys/TCMMMUser.h"


@interface TCMMMUser (TCMMMUserSEEAdditions) 

+ (TCMMMUser *)userWithBencodedUser:(NSData *)aData;
+ (TCMMMUser *)userWithDictionaryRepresentation:(NSDictionary *)aRepresentation;
- (NSDictionary *)dictionaryRepresentation;
- (void)prepareImages;
- (NSData *)userBencoded;
- (void)setUserHue:(NSNumber *)aHue;
- (NSColor *)changeColor;
- (NSString *)vcfRepresentation;
    
@end
