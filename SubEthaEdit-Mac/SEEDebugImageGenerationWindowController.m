//
//  SEEDebugImageGenerationWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 23.04.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEDebugImageGenerationWindowController.h"

@interface SEEDebugImageGenerationWindowController ()
@property (assign) IBOutlet NSTextField *valueTextField;

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
- (IBAction)pdfBasedAction:(id)sender {
	NSImage *image = [NSImage pdfBasedImageNamed:self.valueTextField.stringValue];
	[self showImage:image];
}
- (IBAction)symbolBasedAction:(id)sender {
}

- (IBAction)namedAction:(id)sender {
	NSImage *image = [NSImage imageNamed:self.valueTextField.stringValue];
	[self showImage:image];
}

- (void)showImage:(NSImage *)anImage {
	for (NSView *view in [self.window.contentView subviews]) {
		if ([view isKindOfClass:[NSImageView class]]) {
			[(NSImageView *)view setImage:anImage];
		}
	}
}

@end
