//  SEEScopedBookmarkAccessoryViewController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 20.03.14.

#import "SEEScopedBookmarkAccessoryViewController.h"

@interface SEEScopedBookmarkAccessoryViewController ()

@end

@implementation SEEScopedBookmarkAccessoryViewController

- (NSString *)messageString {
	NSString *localizedMessageFormat = self.message;
	NSString *localizedUnknownFileName = NSLocalizedStringWithDefaultValue(@"ScopedBookmarkAllowFileMessageUnknownFileName",
																		   nil,
																		   [NSBundle mainBundle],
																		   @"its resources",
																		   @"FileName placeholder that gets displayed when SEE needs the user to grant access to an unopend file.");

	NSString *ensuredFileName = self.accessedFileName ? self.accessedFileName : localizedUnknownFileName;

	return [NSString stringWithFormat:localizedMessageFormat, ensuredFileName];
}

@end
