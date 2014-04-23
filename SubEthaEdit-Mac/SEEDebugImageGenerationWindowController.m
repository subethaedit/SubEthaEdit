//
//  SEEDebugImageGenerationWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 23.04.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEDebugImageGenerationWindowController.h"

@interface SEEDebugImageGenerationWindowController ()

@end

@implementation SEEDebugImageGenerationWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSString *)windowNibName {
	return @"SEEDebugImageGenerationWindowController";
}

@end
