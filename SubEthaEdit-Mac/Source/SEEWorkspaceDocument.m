//
//  SEEWorkspaceDocument.m
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 18.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "SEEWorkspaceDocument.h"
#import "SEEWorkspaceFileTreeViewController.h"

@implementation SEEWorkspaceDocument {
    SEEWorkspaceFileTreeViewController *fileTreeController;
}
@synthesize workspace;

-(BOOL)requiresWorkspace {
    return YES;
}

- (NSString *)windowNibName {
    return @"SEEWorkspaceDocument";
}

-(BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError *  __autoreleasing *)outError {
    return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    fileTreeController = [[SEEWorkspaceFileTreeViewController alloc] initWithWorkspace:self.workspace];
    
    NSView *superview = aController.window.contentView;
    NSView *contentView = fileTreeController.view;
    contentView.frame = superview.bounds;
    contentView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
    [superview addSubview:contentView];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error if you return nil.
    // Alternatively, you could remove this method and override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error if you return NO.
    // Alternatively, you could remove this method and override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you do, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return NO;
}

@end
