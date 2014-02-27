//
//  SEEBrowserOpenOtherItem.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEBrowserOpenOtherItem.h"

@implementation SEEBrowserOpenOtherItem

@synthesize name = _name;
@synthesize image = _image;

- (id)init {
    self = [super init];
    if (self) {
        self.name = NSLocalizedString(@"Open Other…", @"");
		self.image = [NSImage imageNamed:NSImageNamePathTemplate];
    }
    return self;
}

- (IBAction)itemAction:(id)sender {
	[NSApp sendAction:@selector(openNormalDocument:) to:nil from:sender];
}

@end
