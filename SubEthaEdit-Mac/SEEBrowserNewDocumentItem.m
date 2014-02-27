//
//  SEEBrowserNewDocumentItem.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEBrowserNewDocumentItem.h"

#import "DocumentController.h"
#import "DocumentModeManager.h"

extern int const FileMenuTag;
extern int const FileNewMenuItemTag;

@implementation SEEBrowserNewDocumentItem

@synthesize name = _name;
@synthesize image = _image;

- (id)init {
    self = [super init];
    if (self) {
        self.name = NSLocalizedString(@"New Document", @"");
		self.image = [NSImage imageNamed:@"EditorAddSplit"];
    }
    return self;
}

- (IBAction)itemAction:(id)sender {
	NSMenu *menu = [[[NSApp mainMenu] itemWithTag:FileMenuTag] submenu];
	NSMenuItem *menuItem = [menu itemWithTag:FileNewMenuItemTag];
	menu = [menuItem submenu];
	NSMenuItem *item = (NSMenuItem *)[menu itemWithTag:[[DocumentModeManager sharedInstance] tagForDocumentModeIdentifier:[[[DocumentModeManager sharedInstance] modeForNewDocuments] documentModeIdentifier]]];

	[[NSDocumentController sharedDocumentController] newDocumentWithModeMenuItem:item];
}

@end
