//
//  SEEWorkspaceController.m
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 03.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "SEEWorkspaceController.h"
#import "SEEWorkspace.h"

@interface SEEWorkspaceController ()

@end

@implementation SEEWorkspaceController


- (instancetype)init
{
    self = [super init];
    if (self) {
        workspaces = [NSMutableArray new];
    }
    return self;
}

-(SEEWorkspace *)workspaceForDocument:(NSDocument *)document {
    for (SEEWorkspace *ws in workspaces) {
        if ([ws containsDocument:document]) {
            return ws;
        }
    }
    return nil;
}

-(SEEWorkspace *)workspaceForURL:(NSURL *)url {
    for (SEEWorkspace *ws in workspaces) {
        if ([ws.baseURL isEqual:url]) {
            return ws;
        }
    }
    
    SEEWorkspace *workspace = [[SEEWorkspace alloc] initWithBaseURL:url];
    [workspaces addObject:workspace];
    return workspace;
}

@end
