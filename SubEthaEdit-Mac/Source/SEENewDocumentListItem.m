//  SEEBrowserNewDocumentItem.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.02.14.

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEENewDocumentListItem.h"

#import "SEEDocumentController.h"
#import "DocumentModeManager.h"

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
	[[NSDocumentController sharedDocumentController] newDocumentByUserDefault:sender];
}

@end
