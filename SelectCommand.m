//
//  SelectCommand.m
//  SubEthaEdit
//
//  Created by Martin Ott on 5/6/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "SelectCommand.h"


@implementation SelectCommand

- (id)performDefaultImplementation
{
    NSLog(@"%s: %@", __FUNCTION__, [self description]);

    return [super performDefaultImplementation];
}

@end
