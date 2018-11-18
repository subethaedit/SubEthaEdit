//  SEEConnectionAddingWindowController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 28.02.14.

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEConnectionAddingWindowController.h"
#import "SEEConnectionManager.h"

@implementation SEEConnectionAddingWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
	[self localizeText];
}

- (void)windowWillClose:(NSNotification *)notification {
	if ([NSApp modalWindow] == notification.object) {
		[NSApp stopModalWithCode:NSModalResponseStop];
	}
}

#pragma mark - Actions

- (IBAction)connect:(id)sender {
	SEEConnectionManager *connectionManager = [SEEConnectionManager sharedInstance];
	[connectionManager connectToAddress:self.addressString];

	if ([NSApp modalWindow] == self.window) {
		[NSApp stopModalWithCode:NSModalResponseOK];
	}

	if (self.window.isSheet) {
		[self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
	}
}

- (IBAction)cancel:(id)sender {
	if ([NSApp modalWindow] == self.window) {
		[NSApp stopModalWithCode:NSModalResponseCancel];
	}

	if (self.window.isSheet) {
		[self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
	}
}

#pragma mark - Localization
- (void)localizeText {
	self.window.title =
	NSLocalizedStringWithDefaultValue(@"CONNECTION_ADD_WINDOW_TITLE", nil, [NSBundle mainBundle],
									  @"Add Connection",
									  @"");
	
	self.addressLabel.stringValue =
	NSLocalizedStringWithDefaultValue(@"CONNECTION_ADD_ADDRESS", nil, [NSBundle mainBundle],
									  @"Address:",
									  @"");
	
	self.cancelButton.title =
	NSLocalizedStringWithDefaultValue(@"Cancel", nil, [NSBundle mainBundle],
									  @"Cancel",
									  @"");

	self.connectButton.title =
	NSLocalizedStringWithDefaultValue(@"CONNECTION_ADD_CONNECT", nil, [NSBundle mainBundle],
									  @"Connect",
									  @"");
}

@end
