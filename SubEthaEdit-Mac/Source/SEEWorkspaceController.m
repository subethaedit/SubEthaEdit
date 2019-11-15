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
#import "PlainTextDocument.h"

@interface SEEWorkspaceController ()

@end

@implementation SEEWorkspaceController {
@private
    NSMutableSet <SEEWorkspace *> *workspaces;
}

- (instancetype)initWithDocumentController:(NSDocumentController *)controller;
{
    self = [super init];
    if (self) {
        _documentController = controller;
        workspaces = [NSMutableSet new];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
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
    // Choose the workspace with the longest common subpath by sorting all
    // compatible workspaces by their absolute base URL and choosing the last one
    
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"baseURL.absoluteString" ascending:YES];
    
    NSSet<SEEWorkspace *> *eligableWorkspaces = [workspaces objectsPassingTest:^BOOL(SEEWorkspace * _Nonnull ws, BOOL * _Nonnull stop) {
        return [ws containsURL:url];
    }];
    
    NSArray<SEEWorkspace *> *sortedWorkspaces = [eligableWorkspaces sortedArrayUsingDescriptors:@[sd]];
    
    SEEWorkspace *workspace = sortedWorkspaces.lastObject;
    
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
        
        [NSNotificationCenter.defaultCenter
            addObserver:self
            selector:@selector(documentDidSaveNotification:)
            name:PlainTextDocumentDidSaveNotification
            object:document];
    }
}

- (void)documentDidSaveNotification:(NSNotification *)notification {
    NSDocument<SEEWorkspaceDocument> *document = notification.object;
    [self assignDocumentToWorkspace:document];
}


-(void)removeDocument:(NSDocument *)document {
    if([document conformsToProtocol:@protocol(SEEWorkspaceDocument)]) {
        SEEWorkspace *workspace = [self workspaceForDocument:document];
        [workspace removeDocument:(NSDocument<SEEWorkspaceDocument> *)document];
        

        if (workspace && workspace.documents.count == 0) {
            [workspaces removeObject:workspace];
        }
        
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:nil
                                                    object:document];
    }
    
    
}

-(void)assignDocumentToWorkspace:(NSDocument<SEEWorkspaceDocument> *)document {
    SEEWorkspace *currentWorkspace = [self workspaceForDocument:document];
    
    // In case the document has been moved out of the workspace
    if(![currentWorkspace containsURL:document.fileURL]) {
        [currentWorkspace removeDocument:document];
        currentWorkspace = nil;
    }
    
    if(!currentWorkspace) {
        BOOL createIfNeeded = [document respondsToSelector:@selector(requiresWorkspace)] &&
            document.requiresWorkspace;
        SEEWorkspace *desiredWorkspace = [self workspaceForURL:document.fileURL createIfNeeded:createIfNeeded];
        [desiredWorkspace addDocument:document];
    }
}

@end
