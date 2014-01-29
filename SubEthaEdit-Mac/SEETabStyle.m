//
//  SEETabStyle.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 29.01.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


#import "SEETabStyle.h"

@implementation SEETabStyle

+ (NSString *)name {
    return @"SubEthaEdit";
}

- (NSString *)name {
	return [[self class] name];
}


@end
