//
//  SEEWorkspace.m
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 03.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "SEEWorkspace.h"

@implementation SEEWorkspace

- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        _baseURL = url;
        documents = [NSMutableArray new];
    }
    return self;
}

-(BOOL)containsDocument:(NSDocument *)doc {
    return [documents containsObject:doc];
}

@end
