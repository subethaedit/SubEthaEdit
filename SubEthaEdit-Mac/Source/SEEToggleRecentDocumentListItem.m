//  SEEToggleRecentDocumentListItem.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 06.03.14.

#import "SEEToggleRecentDocumentListItem.h"

@implementation SEEToggleRecentDocumentListItem

@dynamic uid;
@synthesize name = _name;
@synthesize image = _image;

- (id)init {
    self = [super init];
    if (self) {
        self.name =
		NSLocalizedStringWithDefaultValue(@"DOCUMENT_LIST_RECENT_TOGGLE", nil, [NSBundle mainBundle],
										  @"Recent Documents",
										  @"");
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
	self.showRecentDocuments = !self.showRecentDocuments;
}

@end
