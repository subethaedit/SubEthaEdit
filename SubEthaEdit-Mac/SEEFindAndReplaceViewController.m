//
//  SEEFindAndReplaceViewController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 24.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEFindAndReplaceViewController.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation SEEFindAndReplaceViewController

- (instancetype)init {
	self = [super initWithNibName:@"SEEFindAndReplaceView" bundle:nil];
	if (self) {
		
	}
	return self;
}

- (IBAction)findTextFieldAction:(id)sender {
	[self.delegate findAndReplaceViewControllerDidPressFindNext:self];
}

- (IBAction)findPreviousAction:(id)sender {
	[self.delegate findAndReplaceViewControllerDidPressFindPrevious:self];
}

- (IBAction)findNextAction:(id)sender {
	[self.delegate findAndReplaceViewControllerDidPressFindNext:self];
}

- (IBAction)replaceAction:(id)sender {
	NSLog(@"%s",__FUNCTION__);
}

- (IBAction)replaceAllAction:(id)sender {
	NSLog(@"%s",__FUNCTION__);
}

- (IBAction)dismissAction:(id)sender {
	[self.delegate findAndReplaceViewControllerDidPressDismiss:self];
}
@end
