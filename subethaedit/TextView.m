//
//  TextView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TextView.h"


@implementation TextView

- (void)changeFont:(id)aSender {
    [[[[self window] windowController] document] changeFont:aSender];
}

@end
