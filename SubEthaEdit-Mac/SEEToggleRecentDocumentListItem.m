//
//  SEEToggleRecentDocumentListItem.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 06.03.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

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

- (IBAction)itemAction:(id)sender {
	self.showRecentDocuments = !self.showRecentDocuments;
}

@end
