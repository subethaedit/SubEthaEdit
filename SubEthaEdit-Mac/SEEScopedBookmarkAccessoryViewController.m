//
//  SEEScopedBookmarkAccessoryViewController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 20.03.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEScopedBookmarkAccessoryViewController.h"

@interface SEEScopedBookmarkAccessoryViewController ()

@end

@implementation SEEScopedBookmarkAccessoryViewController

- (NSString *)messageString {
	NSString *localizedMessageFormat = NSLocalizedStringWithDefaultValue(@"ScopedBookmarkAllowFileMessageFormatString",
											  nil,
											  [NSBundle mainBundle],
											  @"To display your content it is neccessary that you provide access to %@. Please choose a folder that includes all files used by your source file.",
											  @"Message that gets displayed when SEE needs the user to grant access to an unopend file.");

	NSString *localizedUnknownFileName = NSLocalizedStringWithDefaultValue(@"ScopedBookmarkAllowFileMessageUnknownFileName",
																	  nil,
																	  [NSBundle mainBundle],
																	  @"its resources",
																	  @"FileName placeholder that gets displayed when SEE needs the user to grant access to an unopend file.");

	NSString *ensuredFileName = self.accessedFileName ? self.accessedFileName : localizedUnknownFileName;

	return [NSString stringWithFormat:localizedMessageFormat, ensuredFileName];
}

@end
