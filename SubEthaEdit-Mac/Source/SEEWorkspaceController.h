//
//  SEEWorkspaceController.h
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 03.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

/*
 +-----------------------------+        +-----------------------------+
 |                             |        |                             |
 | SEEWorkspaceController      |<----1--+ SEEDocumentController       |
 |                             |        |                             |
 +-------------+---------------+        +--------------+--------------+
               *                                       *
               |                                       |
               v                                       v
 +-----------------------------+        +-----------------------------+
 |                             |        |                             |
 | SEEWorkspace                +-*----->| NSDocument                  |
 |                             |        |                             |
 +-----------------------------+        +-----------------------------+
 
 */

#import <Foundation/Foundation.h>

@class SEEWorkspace;

@interface SEEWorkspaceController : NSObject

@property (nonatomic, weak, readonly) NSDocumentController *documentController;

-(instancetype)initWithDocumentController:(NSDocumentController *)controller;

-(SEEWorkspace *)workspaceForDocument:(NSDocument *)document;

-(SEEWorkspace *)workspaceForURL:(NSURL *)url;
-(SEEWorkspace *)workspaceForURL:(NSURL *)url createIfNeeded:(BOOL)create;

-(void)addDocument:(NSDocument *)document;
-(void)removeDocument:(NSDocument *)document;

@end
