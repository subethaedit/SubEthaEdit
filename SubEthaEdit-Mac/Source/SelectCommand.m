//  SelectCommand.m
//  SubEthaEdit
//
//  Created by Martin Ott on 5/6/06.

#import "SelectCommand.h"

@implementation SelectCommand

- (id)performDefaultImplementation {
    NSLog(@"%s: %@", __FUNCTION__, [self description]);

    return [super performDefaultImplementation];
}

@end
