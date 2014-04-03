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
#import "SEEWebPreviewViewController.h"
#import "PlainTextWindowControllerTabContext.h"

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
	return NO;	
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
	if (dividerIndex == 0) {
		return SEEMinWebPreviewWidth + splitView.dividerThickness;
	}
	return proposedMinimumPosition;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
	if (dividerIndex == 0) {
		return MAX (SEEMinWebPreviewWidth + splitView.dividerThickness, NSWidth(splitView.frame) - SEEMinEditorWidth);
	}
	return  proposedMaximumPosition;
}

- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
	CGFloat dividerThickness = splitView.dividerThickness;

	NSSize newSplitViewSize = splitView.bounds.size;

	NSView *firstSubview = splitView.subviews[0];
	NSView *secondSubview = splitView.subviews[1];

	NSRect firstSubViewFrame = firstSubview.frame;
	NSRect secondSubViewFrame = secondSubview.frame;

	// calculate adjusted subview frames
	if (newSplitViewSize.width >= (SEEMinWebPreviewWidth + dividerThickness + SEEMinEditorWidth)) {
		if (NSWidth(secondSubViewFrame) < SEEMinEditorWidth) {
			secondSubViewFrame.size.width = SEEMinEditorWidth;
			firstSubViewFrame.size.width = newSplitViewSize.width - SEEMinEditorWidth;

			firstSubview.frame = firstSubViewFrame;
			secondSubview.frame = secondSubViewFrame;
		} else if (NSWidth(firstSubViewFrame) < SEEMinWebPreviewWidth) {
			firstSubViewFrame.size.width = SEEMinWebPreviewWidth;
			secondSubViewFrame.size.width = newSplitViewSize.width - SEEMinWebPreviewWidth - dividerThickness;

			firstSubview.frame = firstSubViewFrame;
			secondSubview.frame = secondSubViewFrame;
		} else {
			[splitView adjustSubviews];
		}
	} else {
		NSAssert(NO, @"%@ resized below minimum size.", splitView);
		[splitView adjustSubviews];
	}
}

@end
