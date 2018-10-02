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
#import "SEESplitView.h"

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
	NSArray *subviews = splitView.subviews;
	if (subviews.count >= 2) {
		CGFloat dividerThickness = splitView.dividerThickness;
		
		NSSize newSplitViewSize = splitView.bounds.size;
		
		NSView *firstSubview = subviews[0];
		NSView *secondSubview = subviews[1];
		
		NSRect firstSubviewFrame = firstSubview.frame;
		NSRect secondSubviewFrame = secondSubview.frame;
		
		// pre-resize the frames (sometimes they come in old sizes)
		firstSubviewFrame.size.height = newSplitViewSize.height;
		secondSubviewFrame.size.height = newSplitViewSize.height;
		
		CGFloat ratio = firstSubviewFrame.size.width / (firstSubviewFrame.size.width + secondSubviewFrame.size.width + dividerThickness);
		firstSubviewFrame.size.width = floor(ratio * newSplitViewSize.width);
		secondSubviewFrame.size.width = newSplitViewSize.width - dividerThickness - firstSubviewFrame.size.width;
		
		// calculate adjusted subview frames
		if (newSplitViewSize.width >= (SEEMinWebPreviewWidth + dividerThickness + SEEMinEditorWidth)) {
			if (NSWidth(secondSubviewFrame) < SEEMinEditorWidth) {
				secondSubviewFrame.size.width = SEEMinEditorWidth;
				firstSubviewFrame.size.width = newSplitViewSize.width - SEEMinEditorWidth - dividerThickness;
				secondSubviewFrame.origin.x = firstSubviewFrame.size.width + dividerThickness;
				
				firstSubview.frame = firstSubviewFrame;
				secondSubview.frame = secondSubviewFrame;
			} else if (NSWidth(firstSubviewFrame) < SEEMinWebPreviewWidth) {
				firstSubviewFrame.size.width = SEEMinWebPreviewWidth;
				secondSubviewFrame.size.width = newSplitViewSize.width - SEEMinWebPreviewWidth - dividerThickness;
				secondSubviewFrame.origin.x = firstSubviewFrame.size.width + dividerThickness;
				
				firstSubview.frame = firstSubviewFrame;
				secondSubview.frame = secondSubviewFrame;
			}
			[splitView adjustSubviews];
			
//			NSLog(@"\nold : %@\nnew : %@\nfirst : %@\nsecond : %@\n", NSStringFromSize(newSplitViewSize), NSStringFromSize(oldSize),NSStringFromRect(firstSubviewFrame), NSStringFromRect(secondSubviewFrame));
		} else {
			NSAssert(NO, @"%@ resized below minimum size.", splitView);
			[splitView adjustSubviews];
		}
	}
}

- (NSColor *)dividerColorForSplitView:(SEESplitView *)aSplitView {
	NSColor *result = [[NSColor darkOverlaySeparatorColorBackgroundIsDark:self.tabContext.document.documentBackgroundColor.isDark] colorWithAlphaComponent:1.0];
	return result;
}


@end
