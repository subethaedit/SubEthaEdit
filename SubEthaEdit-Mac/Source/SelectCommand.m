//  SelectCommand.m
//  SubEthaEdit
//
//  Created by Martin Ott on 5/6/06.

#import "SelectCommand.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation SelectCommand

- (id)performDefaultImplementation {
    NSLog(@"%s: %@", __FUNCTION__, [self description]);

    return [super performDefaultImplementation];
}

@end
