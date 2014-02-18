//
//  SEENetworkDocumentRepresentation.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEENetworkDocumentRepresentation.h"

@implementation SEENetworkDocumentRepresentation

- (id)init
{
    self = [super init];
    if (self) {
        self.fileIcon = [NSImage imageNamed:@"NSApplicationIcon"];
    }
    return self;
}

@end
