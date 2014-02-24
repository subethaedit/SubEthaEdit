//
//  SEENetworkBrowserGroupTableRowView.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 24.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEENetworkBrowserGroupTableRowView.h"

@implementation SEENetworkBrowserGroupTableRowView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
	[super drawBackgroundInRect:dirtyRect];
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
	[super drawSelectionInRect:dirtyRect];
}

- (void)drawSeparatorInRect:(NSRect)dirtyRect {
	[super drawSeparatorInRect:dirtyRect];
}

@end
