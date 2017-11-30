//
//  SEEMoreRecentDocumentsListItem.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 22.05.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEMoreRecentDocumentsListItem.h"

@implementation SEEMoreRecentDocumentsListItem

@dynamic uid;
@synthesize name = _name;
@synthesize image = _image;

- (id)init {
    self = [super init];
    if (self) {
        self.name = NSLocalizedString(@"DOCUMENT_LIST_MORE", @"");
    }
    return self;
}

- (NSString *)uid {
	return [NSString stringWithFormat:@"com.subethaedit.%@", NSStringFromClass(self.class)];
}

- (IBAction)openRecentDocumentForItem:(id)sender {
	if (sender && [sender isKindOfClass:[NSMenuItem  class]]) {
		NSMenuItem *item = (NSMenuItem *)sender;
		id representedObject = item.representedObject;
		if (representedObject && [representedObject isKindOfClass:[NSURL class]]) {
			NSURL *documentURL = (NSURL *)representedObject;
			if (documentURL) {
				[documentURL startAccessingSecurityScopedResource];
				[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:documentURL display:YES completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {}];
			}
		}
	}
}

- (IBAction)itemAction:(id)sender {
	NSEvent *mouseClickEvent = [NSApp currentEvent];
	[NSMenu popUpContextMenu:self.moreMenu withEvent:mouseClickEvent forView:sender];

}

@end
