//
//  SEEConnectionAddingWindowController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 28.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEConnectionAddingWindowController.h"
#import "SEEConnectionManager.h"

@interface SEEConnectionAddingWindowController ()

@end

@implementation SEEConnectionAddingWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {

    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}


#pragma mark - Actions

- (IBAction)connect:(id)sender {
	SEEConnectionManager *connectionManager = [SEEConnectionManager sharedInstance];
	[connectionManager connectToAddress:self.addressString];
	[self close];
}

- (IBAction)cancel:(id)sender {
	[self close];
}

@end
