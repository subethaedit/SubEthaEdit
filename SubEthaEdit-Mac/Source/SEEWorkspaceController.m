//
//  SEEWorkspaceController.m
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 03.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "SEEWorkspaceController.h"
#import "SEEWorkspaceDocument.h"
#import "SEEWorkspace.h"

@interface SEEWorkspaceController ()

@end

@implementation SEEWorkspaceController {
@private
    NSMutableArray <SEEWorkspace *> *workspaces;
}

// TODO: prune empty workspaces

- (instancetype)initWithDocumentController:(NSDocumentController *)controller;
{
    self = [super init];
    if (self) {
        _documentController = controller;
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
    return [self workspaceForURL:url createIfNeeded:NO];
}

-(SEEWorkspace *)workspaceForURL:(NSURL *)url createIfNeeded:(BOOL)create {
    SEEWorkspace *workspace = [workspaces SEE_firstObjectPassingTest:^BOOL(SEEWorkspace *ws) {
        return [ws containsURL:url];
    }];
    
    if(create && !workspace) {
        workspace = [[SEEWorkspace alloc] initWithBaseURL:url];
        [workspaces addObject:workspace];
        for (NSDocument *document in [self.documentController documents]) {
            if([document conformsToProtocol:@protocol(SEEWorkspaceDocument)]) {
                [self assignDocumentToWorkspace:(NSDocument<SEEWorkspaceDocument> *)document];
            }    
        }
        
    }
    return workspace;
}

-(void)addDocument:(NSDocument *)document {
    if([document conformsToProtocol:@protocol(SEEWorkspaceDocument)]) {
        [self assignDocumentToWorkspace:(NSDocument<SEEWorkspaceDocument> *)document];
    }    
}

-(void)removeDocument:(NSDocument *)document {
    if([document conformsToProtocol:@protocol(SEEWorkspaceDocument)]) {
        [[self workspaceForDocument:document] removeDocument:(NSDocument<SEEWorkspaceDocument> *)document];
    }
}

-(void)assignDocumentToWorkspace:(NSDocument<SEEWorkspaceDocument> *)document {
    SEEWorkspace *currentWorkspace = [self workspaceForDocument:document];
    if(!currentWorkspace) {
        BOOL createIfNeeded = [document respondsToSelector:@selector(requiresWorkspace)] &&
            document.requiresWorkspace;
        SEEWorkspace *desiredWorkspace = [self workspaceForURL:document.fileURL createIfNeeded:createIfNeeded];
        [desiredWorkspace addDocument:document];
    }
}

@end
