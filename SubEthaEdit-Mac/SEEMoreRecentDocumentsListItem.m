//
//  SEEMoreRecentDocumentsListItem.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 22.05.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

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

- (IBAction)itemAction:(id)sender {
	NSLog(@"%s - Show the menu!!!!", __FUNCTION__);
}

@end
