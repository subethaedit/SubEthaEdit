//
//  SEEBrowserNewDocumentItem.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEENewDocumentListItem.h"

#import "SEEDocumentController.h"
#import "DocumentModeManager.h"

extern int const FileMenuTag;
extern int const FileNewMenuItemTag;

@implementation SEENewDocumentListItem

@dynamic uid;
@synthesize name = _name;
@synthesize image = _image;

- (id)init {
    self = [super init];
    if (self) {
        self.name = NSLocalizedString(@"DOCUMENT_LIST_NEW", @"");
		self.image = [NSImage imageNamed:@"EditorAddSplit"];
    }
    return self;
}

- (NSString *)uid {
	return [NSString stringWithFormat:@"com.subethaedit.%@", NSStringFromClass(self.class)];
}

- (IBAction)itemAction:(id)sender {
	NSMenu *menu = [[[NSApp mainMenu] itemWithTag:FileMenuTag] submenu];
	NSMenuItem *menuItem = [menu itemWithTag:FileNewMenuItemTag];
	menu = [menuItem submenu];
	NSMenuItem *item = (NSMenuItem *)[menu itemWithTag:[[DocumentModeManager sharedInstance] tagForDocumentModeIdentifier:[[[DocumentModeManager sharedInstance] modeForNewDocuments] documentModeIdentifier]]];

	[[NSDocumentController sharedDocumentController] newDocumentWithModeMenuItem:item];
}

@end
