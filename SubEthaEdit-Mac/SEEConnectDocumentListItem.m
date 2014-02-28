//
//  SEEBrowserConnectItem.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEConnectDocumentListItem.h"

@implementation SEEConnectDocumentListItem

@synthesize name = _name;
@synthesize image = _image;

- (id)init {
    self = [super init];
    if (self) {
        self.name = NSLocalizedString(@"Connect…", @"");
		self.image = [NSImage imageNamed:NSImageNameAddTemplate];
    }
    return self;
}

- (IBAction)itemAction:(id)sender {
	NSLog(@"%s not implemented.", __FUNCTION__);
}

@end
