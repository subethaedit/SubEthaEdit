//  SEEDocumentListTableView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 26.05.14.

#import "SEEDocumentListTableView.h"
#import "SEEHoverTableRowView.h"
#import "SEEDocumentListItemProtocol.h"

@interface SEEDocumentListTableView ()
@property (nonatomic, strong) SEEHoverTableRowView *eventTrackingTableRowView;
@end

@implementation SEEDocumentListTableView

- (void)mouseDown:(NSEvent *)theEvent {
	//	[super mouseDown:theEvent];
	//  return;
	BOOL didHandleEvent = NO;
	//	NSLog(@"%s mouseevent:%@",__FUNCTION__,theEvent);
	if (self.window.isMainWindow &&
		theEvent.type == NSLeftMouseDown) {
		NSPoint clickPoint = [self convertPoint:theEvent.locationInWindow fromView:nil];
		NSInteger rowIndex = [self rowAtPoint:clickPoint];
		if (rowIndex > 0) { // returns -1 if no row is at point
			SEEHoverTableRowView *rowView = [self rowViewAtRow:rowIndex makeIfNecessary:NO];
			if ([rowView isKindOfClass:[SEEHoverTableRowView class]]) {
				didHandleEvent = YES;
				rowView.clickHighlight = YES;
				[rowView setNeedsDisplay:YES];
				self.eventTrackingTableRowView = rowView;
			}
		}
	}
	if (!didHandleEvent) {
		[super mouseDown:theEvent];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent {
	if (self.eventTrackingTableRowView) {
		[self.eventTrackingTableRowView TCM_updateMouseInside];
	} else {
		[super mouseDragged:theEvent];
	}
}

- (NSInteger)clickedRow {
	NSInteger result = [super clickedRow];
	if (self.eventTrackingTableRowView) {
		result = self.eventTrackingTableRowView.TCM_rowIndex;
	}
	return result;
}

- (void)mouseUp:(NSEvent *)theEvent {
	SEEHoverTableRowView *eventTrackingView = self.eventTrackingTableRowView;
	if (eventTrackingView) {
		[eventTrackingView TCM_updateMouseInside];
		if (eventTrackingView.mouseInside) {
			// get the documentlistobject and perform itemAction on it if possible
			NSTableCellView *cellView = [self viewAtColumn:0 row:eventTrackingView.TCM_rowIndex makeIfNecessary:NO];
			id documentListObject = cellView.objectValue;
			if (documentListObject && [documentListObject respondsToSelector:@selector(itemAction:)]) {
				[documentListObject itemAction:self];
			}
			eventTrackingView.clickHighlight = NO;
			[eventTrackingView setNeedsDisplay:YES];
		}
		self.eventTrackingTableRowView = nil;
	} else {
		[super mouseUp:theEvent];
	}
}


@end
