//  SEEConnectionAddingWindowController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 28.02.14.

#import "SEEConnectionAddingWindowController.h"
#import "SEEConnectionManager.h"

@implementation SEEConnectionAddingWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
	[self localizeText];
}

#pragma mark - Actions

- (IBAction)connect:(id)sender {
	SEEConnectionManager *connectionManager = [SEEConnectionManager sharedInstance];
	[connectionManager connectToAddress:self.addressString];
	if (self.window.isSheet) {
		[self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
	} else {
        [self.window close];
    }
}

- (IBAction)cancel:(id)sender {
	if (self.window.isSheet) {
		[self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
    } else {
        [self.window close];
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
