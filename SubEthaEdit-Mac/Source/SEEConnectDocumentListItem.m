//  SEEBrowserConnectItem.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 27.02.14.

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEConnectDocumentListItem.h"
#import "SEEConnectionAddingWindowController.h"

@interface SEEConnectDocumentListItem ()
@end

@implementation SEEConnectDocumentListItem

@dynamic uid;
@synthesize name = _name;
@synthesize image = _image;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.name = NSLocalizedString(@"DOCUMENT_LIST_CONNECT", @"");
		self.image = [NSImage imageNamed:NSImageNameAddTemplate];
    }
    return self;
}

- (NSString *)uid {
	return [NSString stringWithFormat:@"com.subethaedit.%@", NSStringFromClass(self.class)];
}

- (IBAction)itemAction:(id)sender {
	SEEConnectionAddingWindowController *windowController = [[SEEConnectionAddingWindowController alloc] initWithWindowNibName:@"SEEConnectionAddingWindowController"];
	NSWindow *window = [windowController window];
	NSWindow *parentWindow = ((NSView *)sender).window;
	[parentWindow beginSheet:window completionHandler:^(NSModalResponse returnCode) {
		[windowController close];
	}];
}

@end
