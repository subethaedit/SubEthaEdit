//
//  SEEWebPreviewSplitViewDelegate.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.03.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEWebPreviewSplitViewDelegate.h"
#import "PlainTextWindowControllerTabContext.h"
#import "WebPreviewViewController.h"

@interface SEEWebPreviewSplitViewDelegate ()
@property (nonatomic, weak) PlainTextWindowControllerTabContext *tabContext;
@end

@implementation SEEWebPreviewSplitViewDelegate

- (instancetype)initWithTabContext:(PlainTextWindowControllerTabContext *)tabContext {
	self = [super init];
	if (self) {
		self.tabContext = tabContext;
	}
	return self;
}


- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
	return (self.tabContext.webPreviewViewController.view == subview);
}

@end
