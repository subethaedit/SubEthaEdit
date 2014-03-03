//
//  SEEFindAndReplaceViewController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 24.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEFindAndReplaceViewController.h"
#import "FindReplaceController.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@interface SEEFindAndReplaceViewController () <NSMenuDelegate>

@end

@implementation SEEFindAndReplaceViewController

- (instancetype)init {
	self = [super initWithNibName:@"SEEFindAndReplaceView" bundle:nil];
	if (self) {
		
	}
	return self;
}

- (void)updateSearchOptionsButton {
	[self.searchOptionsButton setImage:[NSImage pdfBasedImageNamed:@"SearchLoupeNormal"TCM_PDFIMAGE_SEP@"36"TCM_PDFIMAGE_SEP@""TCM_PDFIMAGE_NORMAL]];
}

- (void)loadView {
	[super loadView];
	NSView *view = self.view;
	view.layer.borderColor = [[NSColor lightGrayColor] CGColor];
	view.layer.borderWidth = 0.5;
	
	view.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.893 alpha:0.750] CGColor];

	[self updateSearchOptionsButton];
	[self.searchOptionsButton sendActionOn:NSLeftMouseDownMask | NSRightMouseDownMask];
	
	// add bindings
	[self.findTextField bind:@"value" toObject:self.findAndReplaceStateObjectController withKeyPath:@"content.findString" options:@{NSContinuouslyUpdatesValueBindingOption : @YES}];
	[self.replaceTextField bind:@"value" toObject:self.findAndReplaceStateObjectController withKeyPath:@"content.replaceString" options:@{NSContinuouslyUpdatesValueBindingOption : @YES}];
	
}

- (NSObjectController *)findAndReplaceStateObjectController {
	return [FindReplaceController sharedInstance].globalFindAndReplaceStateController;
}

- (IBAction)findAndReplaceAction:(id)aSender {
	[[FindReplaceController sharedInstance] performFindPanelAction:aSender inTargetTextView:self.delegate.textView];
}


- (IBAction)dismissAction:(id)sender {
	[self.delegate findAndReplaceViewControllerDidPressDismiss:self];
}

- (IBAction)searchOptionsDropdownAction:(id)sender {
	NSMenu *menu = [NSMenu new];
	[menu addItemWithTitle:@"testTitle" action:@selector(dismissAction:) keyEquivalent:@""].target = self;
	menu.delegate = self;
	[menu popUpMenuPositioningItem:nil atLocation:({ NSPoint result = NSZeroPoint;
		result.y = NSMaxY(self.searchOptionsButton.bounds);
		result;}) inView:self.searchOptionsButton];
	
}

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel {
	return YES;
}

@end
