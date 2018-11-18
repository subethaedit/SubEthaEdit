//  SEEEditorSplitViewDelegate.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 18.03.14.

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEEditorSplitViewDelegate.h"
#import "PlainTextWindowControllerTabContext.h"
#import "SEESplitView.h"

@interface SEEEditorSplitViewDelegate ()
@property (nonatomic, weak) PlainTextWindowControllerTabContext *tabContext;
@end

@implementation SEEEditorSplitViewDelegate

- (instancetype)initWithTabContext:(PlainTextWindowControllerTabContext *)tabContext {
	self = [super init];
	if (self) {
		self.tabContext = tabContext;
	}
	return self;
}

- (NSColor *)dividerColorForSplitView:(SEESplitView *)aSplitView {
    BOOL isDark = NO;
    if (@available(macOS 10.14, *)) {
        isDark = aSplitView.effectiveAppearance.SEE_isDark;
    }
	NSColor *result = [[NSColor darkOverlaySeparatorColorBackgroundIsDark:self.tabContext.document.documentBackgroundColor.isDark appearanceIsDark:isDark] colorWithAlphaComponent:1.0];
	return result;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
	return NO;
}


- (void)splitView:(NSSplitView *)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize {
	CGFloat splitViewMinHeight = SPLITMINHEIGHTTEXT;
	NSRect frame = [aSplitView bounds];
	NSArray *subviews = [aSplitView subviews];
	
	if (subviews.count >= 2) {
		NSRect frameTop = [[subviews objectAtIndex:0] frame];
		NSRect frameBottom = [[subviews objectAtIndex:1] frame];
		CGFloat newHeight = frame.size.height - [aSplitView dividerThickness];
		CGFloat topRatio = frameTop.size.height / (oldSize.height - [aSplitView dividerThickness]);
		
		frameTop.size.height = (CGFloat)((int)(newHeight * topRatio));
		if (frameTop.size.height < splitViewMinHeight) {
			frameTop.size.height = splitViewMinHeight;
		} else if (newHeight - frameTop.size.height < splitViewMinHeight) {
			frameTop.size.height = newHeight - splitViewMinHeight;
		}
		
		frameBottom.size.height = newHeight - frameTop.size.height;
		frameBottom.size.width = frameTop.size.width = frame.size.width;
		
		frameTop.origin.x = frameBottom.origin.x = frame.origin.x;
		frameTop.origin.y = frame.origin.y;
		frameBottom.origin.y = frame.origin.y + [aSplitView dividerThickness] + frameTop.size.height;
		
		[[subviews objectAtIndex:0] setFrame:frameTop];
		[[subviews objectAtIndex:1] setFrame:frameBottom];
		
		[aSplitView setPosition:NSHeight([aSplitView.subviews.firstObject frame]) ofDividerAtIndex:0];
	}
}


- (CGFloat)splitView:(NSSplitView *)aSplitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)aDividerIndex {
	CGFloat minHeightTop = [self.tabContext.plainTextEditors.firstObject desiredMinHeight];
	CGFloat minHeightBottom = [self.tabContext.plainTextEditors.lastObject desiredMinHeight];
    CGFloat totalHeight = [aSplitView frame].size.height;

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
