//
//  DocumentMode.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 22 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "DocumentMode.h"


@implementation DocumentMode

- (id)initWithBundle:(NSBundle *)aBundle {
    self = [super init];
    if (self) {
        I_bundle = [aBundle retain];
    }
    return self;
}

- (void) dealloc {
    [I_bundle release];
    [super dealloc];
}

- (NSBundle *)bundle {
    return I_bundle;
}


@end
