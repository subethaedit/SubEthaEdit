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
	return 	NSLocalizedStringWithDefaultValue(@"ScopedBookmarkAllowFileMessage",
											  nil,
											  [NSBundle mainBundle],
											  @"Please choose a folder that contains all referenced files, to grant access.",
											  @"");
}

@end
