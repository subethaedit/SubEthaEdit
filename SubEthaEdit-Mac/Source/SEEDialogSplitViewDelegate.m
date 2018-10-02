//  SEEDialogSplitViewDelegate.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.03.14.


#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEDialogSplitViewDelegate.h"
#import "PlainTextEditor.h"
#import "PlainTextWindowControllerTabContext.h"

@interface SEEDialogSplitViewDelegate ()
@property (nonatomic, weak) PlainTextWindowControllerTabContext *tabContext;
@end

@implementation SEEDialogSplitViewDelegate

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

- (void)splitView:(NSSplitView *)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize {
	NSArray *subviews = aSplitView.subviews;
	if (subviews.count >= 2) {
		CGFloat dialogSplitMinHeight = SPLITMINHEIGHTDIALOG;
		// just keep the height of the first view (dialog)
		NSView *dialogView = [[aSplitView subviews] objectAtIndex:1];
		NSSize newSize = [aSplitView bounds].size;
		NSSize frameSize = [dialogView frame].size;
		frameSize.height += newSize.height - oldSize.height;
		if (frameSize.height <= dialogSplitMinHeight) {
			frameSize.height = dialogSplitMinHeight;
		}
		[dialogView setFrameSize:frameSize];
		[aSplitView adjustSubviews];
		[aSplitView setPosition:NSHeight([aSplitView.subviews.firstObject frame]) ofDividerAtIndex:0];
	}
}


- (CGFloat)splitView:(NSSplitView *)aSplitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)aDividerIndex {
	CGFloat minHeightTop = SPLITMINHEIGHTDIALOG;
	CGFloat minHeightBottom = 0;
	for (PlainTextEditor *editor in self.tabContext.plainTextEditors) {
		minHeightBottom += editor.desiredMinHeight;
	}

	if (self.tabContext.plainTextEditors.count > 1) {
		minHeightBottom += [self.tabContext.editorSplitView dividerThickness];
	}

    CGFloat totalHeight=[aSplitView frame].size.height;
	CGFloat result = proposedPosition;

    if (proposedPosition < minHeightTop) {
        result = minHeightTop;
    } else {
		CGFloat maxPosition = totalHeight - minHeightBottom - [aSplitView dividerThickness];
		if (proposedPosition > maxPosition) {
			result = maxPosition;
		}
    }

	return result;
}

@end
