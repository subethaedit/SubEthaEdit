//
//  TCMListView.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon May 10 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMListView.h"

NSString *ListViewDidChangeSelectionNotification=
        @"ListViewDidChangeSelectionNotification";

@interface TCMListView (TCMListViewPrivateAdditions)

- (void)TCM_rebuildIndices;

- (int)indexOfRowAtPoint:(NSPoint)aPoint;

@end

#pragma mark -

@implementation TCMListView


// override this in sublcasses
+ (float)itemRowHeight {
    return 22.;
}
+ (float)childRowHeight {
    return 38.;
}
+ (float)itemRowGapHeight {
    return 22.;
}
+ (float)actionImagePadding {
    return 4.;
}

+ (NSColor *)alternateRowColor {
    static NSColor *alternateRowColor=nil;
    if (!alternateRowColor) {
        alternateRowColor=[[NSColor colorWithCalibratedRed:0.93 green:0.95 blue:1.0 alpha:1.0] retain];
    }
    return alternateRowColor;
}


- (void)TCM_sendListViewDidChangeSelectionNotification {
    [[NSNotificationQueue defaultQueue] 
    enqueueNotification:[NSNotification notificationWithName:ListViewDidChangeSelectionNotification object:self]
           postingStyle:NSPostWhenIdle 
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        I_disclosureCell=[NSButtonCell new];
        [I_disclosureCell setButtonType:NSOnOffButton];
        [I_disclosureCell setBezelStyle:NSDisclosureBezelStyle];
        [I_disclosureCell setControlSize:NSSmallControlSize];
        [I_disclosureCell setTitle:@""];
        [I_disclosureCell setState:NSOnState];
        
        I_selectedRow  = -1;
        I_selectedRows = [NSMutableIndexSet new];
        
        I_indicesNeedRebuilding = YES;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setDelegate:nil];
    if (I_indexNumberOfChildren != NULL) {
        free(I_indexNumberOfChildren);
        free(I_indexRowAtItem);
        free(I_indexYRangesForItem);
        free(I_indexItemChildPairAtRow);
    }
    [I_selectedRows release];
    [I_disclosureCell release];
    [super dealloc];
}

- (void)noteEnclosingScrollView {
    NSScrollView *scrollView=nil;
    if ((scrollView=[self enclosingScrollView])) {
        [[NSNotificationCenter defaultCenter] 
            addObserver:self selector:@selector(enclosingScrollViewFrameDidChange:) 
            name:NSViewFrameDidChangeNotification object:scrollView];
    }
    [self resizeToFit];
}

- (void)drawChildWithIndex:(int)aChildIndex ofItemAtIndex:(int)aItemIndex drawBackground:(BOOL)aDrawBackground{
    // have to be implemented in subclasses
}

- (void)drawItemAtIndex:(int)aItemIndex drawBackground:(BOOL)aDrawBackground{
    // have to be implemented in subclasses
}

- (void)drawRect:(NSRect)rect
{
    if (I_indicesNeedRebuilding) [self TCM_rebuildIndices];
    Class myClass=[self class];
    float itemRowHeight   =[myClass itemRowHeight];
    float childRowHeight  =[myClass childRowHeight];
    float itemRowGapHeight=[myClass itemRowGapHeight];
    const NSRect *rects;
    int count;
    [self getRectsBeingDrawn:&rects count:&count];
    while (count-->0) {
        NSRect smallRect=rects[count];
        
        if (NSMaxY(smallRect)>=I_indexMaxHeight) {
            [[NSColor whiteColor] set];
            NSRectFill(NSMakeRect(smallRect.origin.x,I_indexMaxHeight,smallRect.size.width, NSMaxY(smallRect)-I_indexMaxHeight));
        }
    
        int startRow = [self indexOfRowAtPoint:smallRect.origin];
    
        if (startRow!=-1 && startRow < I_indexNumberOfRows) {
            int endRow   = [self indexOfRowAtPoint:NSMakePoint(1.,NSMaxY(smallRect))];
            if (endRow==-1) endRow=I_indexNumberOfRows-1;
        
            [NSGraphicsContext saveGraphicsState];
            ItemChildPair pair=[self itemChildPairAtRow:startRow];
            NSRect startRect=[self rectForItem:pair.itemIndex child:pair.childIndex];
        
            NSAffineTransform *toStart=[NSAffineTransform transform];
            [toStart translateXBy:0 yBy:startRect.origin.y];
            [toStart concat];
        
            NSAffineTransform *itemStep=[NSAffineTransform transform];
            [itemStep translateXBy:0 yBy:itemRowHeight];
            NSAffineTransform *childStep=[NSAffineTransform transform];
            [childStep translateXBy:0 yBy:childRowHeight];
            NSAffineTransform *itemGapStep=[NSAffineTransform transform];
            [itemGapStep translateXBy:0 yBy:itemRowGapHeight];
            while (startRow<=endRow) {
                if (pair.childIndex==-1) {
                    [self drawItemAtIndex:pair.itemIndex drawBackground:YES];
                    [itemStep concat];
                } else {
                    [self drawChildWithIndex:pair.childIndex ofItemAtIndex:pair.itemIndex drawBackground:YES];
                    [childStep concat];
                }
                pair.childIndex++;
                if (!(pair.childIndex < I_indexNumberOfChildren[pair.itemIndex])) {
                    pair.itemIndex++;
                    pair.childIndex=-1;
                    if (itemRowGapHeight>=1.) {
                        [[NSColor whiteColor] set];
                        NSRectFill(NSMakeRect(smallRect.origin.x,0,smallRect.size.width,itemRowGapHeight));
                        [itemGapStep concat];
                    }
                }
                startRow++;
            }
        
            [NSGraphicsContext restoreGraphicsState];
//            [[NSColor greenColor] set];
//            NSFrameRect(NSInsetRect(rects[count],1.,1.));
        }
    }
}

- (NSRect)rectForItem:(int)anItemIndex child:(int)aChildIndex
{
    Class myClass=[self class];
    float itemRowHeight   =[myClass itemRowHeight];
    float childRowHeight  =[myClass childRowHeight];

    if (I_indicesNeedRebuilding) [self TCM_rebuildIndices];

    NSRange itemChildRange = I_indexYRangesForItem[anItemIndex];
    NSRect result;
    result.origin.x = 0.0;
    result.size.width = [self bounds].size.width;
    
    if (aChildIndex == -1) {
        result.origin.y = itemChildRange.location;
        result.size.height = itemRowHeight;
    } else {
        result.origin.y = itemChildRange.location + itemRowHeight + aChildIndex * childRowHeight;
        result.size.height = childRowHeight;
    }
    
    return result;
}

- (NSRect)rectForRow:(int)aRow {
    if (I_indicesNeedRebuilding) [self TCM_rebuildIndices];
    return [self rectForItem:I_indexItemChildPairAtRow[aRow].itemIndex
                       child:I_indexItemChildPairAtRow[aRow].childIndex];
}

- (int)indexOfRowAtPoint:(NSPoint)aPoint {

    Class myClass=[self class];
    float itemRowHeight   =[myClass itemRowHeight];
    float childRowHeight  =[myClass childRowHeight];

    if (I_indicesNeedRebuilding) [self TCM_rebuildIndices];

    if (aPoint.y >= I_indexMaxHeight || aPoint.y < 0)
        return - 1;

    int searchPosition=(int)(aPoint.y/I_indexMaxHeight)*I_indexNumberOfItems;
    NSRange testRange=I_indexYRangesForItem[searchPosition];
    if (aPoint.y < testRange.location) {
        while (aPoint.y < testRange.location) {
            searchPosition--;
            testRange=I_indexYRangesForItem[searchPosition];
        }
    } else if (aPoint.y > NSMaxRange(testRange)) {
        while (aPoint.y > NSMaxRange(testRange)) {
            searchPosition++;
            testRange=I_indexYRangesForItem[searchPosition];
        }
    }
    
    int baseRow=I_indexRowAtItem[searchPosition];
    if (aPoint.y>testRange.location+itemRowHeight) {
        baseRow+=(int)((aPoint.y-testRange.location-itemRowHeight-1)/childRowHeight)+1;
    }
    
    return baseRow;
}

- (ItemChildPair)itemChildPairAtRow:(int)aIndex {
    if (I_indicesNeedRebuilding) [self TCM_rebuildIndices];
    NSParameterAssert(aIndex>=0 && aIndex<I_indexNumberOfRows);
    return I_indexItemChildPairAtRow[aIndex];
}

- (int)rowForItem:(int)anItemIndex child:(int)aChildIndex {
    if (I_indicesNeedRebuilding) [self TCM_rebuildIndices];
    NSParameterAssert(anItemIndex>=0 && anItemIndex<I_indexNumberOfItems);
    return I_indexRowAtItem[anItemIndex]+(aChildIndex==-1?0:aChildIndex+1);
}

#pragma mark -
#pragma mark ### Selection Handling ###

- (void)TCM_setNeedsDisplayForIndexes:(NSIndexSet *)indexes {
    unsigned int indexBuffer[40];
    int indexCount;
    NSRange range=NSMakeRange([indexes firstIndex],[indexes lastIndex]-[indexes firstIndex]+1);
    while (YES) {
        indexCount=[indexes getIndexes:indexBuffer maxCount:40 inIndexRange:&range];
        int i;
        for (i=0;i<indexCount;i++) {
            [self setNeedsDisplayInRect:[self rectForRow:indexBuffer[i]]];
        }
        if (indexCount < 40 || range.length) break;
    }
}

- (int)selectedRow {
    return I_selectedRow;
}

- (NSIndexSet *)selectedRowIndexes {
    return I_selectedRows;
}

- (void)deselectAll:(id)aSender {
    unsigned int index;
    for (index=[I_selectedRows lastIndex];index!=NSNotFound;index=[I_selectedRows lastIndex]) {
        [self deselectRow:index];
    }
}

- (void)reduceSelectionToChildren {
    NSMutableIndexSet *set=[I_selectedRows mutableCopy];
    while ([set count]) {
        int index=[set lastIndex];
        if (I_indexItemChildPairAtRow[index].childIndex==-1) {
            [self deselectRow:index];
        }
        [set removeIndex:index];
    }
    [set release];
}

- (void)deselectRow:(int)aRow {
    if ([I_selectedRows containsIndex:aRow]) {
        [I_selectedRows removeIndex:aRow];
        [self TCM_sendListViewDidChangeSelectionNotification];
        [self setNeedsDisplayInRect:[self rectForRow:aRow]];
        if (I_selectedRow == aRow) {
            I_selectedRow = [I_selectedRows firstIndex];
            if (I_selectedRow==NSNotFound) {
                I_selectedRow = -1;
            }
        }
    }
}

- (void)validateSelection {
    int numberOfRows=[self numberOfRows];
    if ([I_selectedRows count]>0 && [I_selectedRows lastIndex]>=numberOfRows) {
        [I_selectedRows removeIndex:[I_selectedRows lastIndex]];
        while ([I_selectedRows count]>0 && [I_selectedRows lastIndex]>=numberOfRows) {
            [I_selectedRows removeIndex:[I_selectedRows lastIndex]];
        }
        if ([I_selectedRows count]>0) {
            I_selectedRow=[I_selectedRows lastIndex];
        } else {
            I_selectedRow=-1;
        }
    }
}

- (int)numberOfSelectedRows {
    return [I_selectedRows count];
}

- (void)shiftClickSelectoToRow:(int)aRow {
    int lesserIndex=[I_selectedRows indexLessThanOrEqualToIndex:aRow];
    int greaterIndex=[I_selectedRows indexGreaterThanOrEqualToIndex:aRow];
    NSIndexSet *set=nil;
    if (lesserIndex==NSNotFound && greaterIndex==NSNotFound) {
        [self selectRow:aRow byExtendingSelection:YES];
    } else if (lesserIndex!=NSNotFound && greaterIndex!=NSNotFound) {
        if (aRow-lesserIndex<greaterIndex-aRow) {
            set=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(aRow,greaterIndex-aRow)];
        } else {
            set=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(lesserIndex+1,aRow-lesserIndex)];
        }
    } else if (greaterIndex!=NSNotFound) {
        set=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(aRow,greaterIndex-aRow)];
    } else if (lesserIndex!=NSNotFound) {
        set=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(lesserIndex+1,aRow-lesserIndex)];
    }
    if (set) [self selectRowIndexes:set byExtendingSelection:YES];
}

- (void)selectRow:(int)aRow byExtendingSelection:(BOOL)shouldExtend {
    
    if (!shouldExtend) {
        [self TCM_setNeedsDisplayForIndexes:I_selectedRows];
        [I_selectedRows removeAllIndexes];
    }
    I_selectedRow = aRow;
    [I_selectedRows addIndex:aRow];
    [self setNeedsDisplayInRect:[self rectForRow:aRow]];
    [self TCM_sendListViewDidChangeSelectionNotification];
}

- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend {
    if (!extend) {
        [self TCM_setNeedsDisplayForIndexes:I_selectedRows];
        [I_selectedRows removeAllIndexes];
    }
    [I_selectedRows addIndexes:indexes];
    [self TCM_setNeedsDisplayForIndexes:I_selectedRows];
    if ([indexes count]) {
        I_selectedRow = [indexes firstIndex];
    } else {
        I_selectedRow = -1;
    }
    [self TCM_sendListViewDidChangeSelectionNotification];
}

#pragma mark -
#pragma mark ### Event Handling ###

- (void)contextMenuMouseDown:(NSEvent *)aEvent {
    NSPoint point = [self convertPoint:[aEvent locationInWindow] fromView:nil];
    
    I_clickedRow = [self indexOfRowAtPoint:point];
    id delegate=[self delegate];
    if ([delegate respondsToSelector:@selector(contextMenuForListView:clickedAtRow:)]) {
        NSMenu *menu=[delegate contextMenuForListView:self clickedAtRow:I_clickedRow];
        if (menu) {
            [NSMenu popUpContextMenu:menu withEvent:aEvent forView:self];
        }
    }

}

- (void)rightMouseDown:(NSEvent *)aEvent {
    NSPoint point = [self convertPoint:[aEvent locationInWindow] fromView:nil];
    
    I_clickedRow = [self indexOfRowAtPoint:point];
    if (I_clickedRow != -1) {
        if (![I_selectedRows containsIndex:I_clickedRow]) {
            [self mouseDown:aEvent];
        }
        [self contextMenuMouseDown:aEvent];
    }
}

- (BOOL)acceptsFirstMouse:(NSEvent *)aEvent {
    NSPoint point = [self convertPoint:[aEvent locationInWindow] fromView:nil];
    //NSLog(@"acceptsFirstMouse at: %@ - event: %@", NSStringFromPoint(point),[aEvent description]);
    
    I_clickedRow = [self indexOfRowAtPoint:point];
    if (I_clickedRow != -1) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)aEvent {
    NSPoint point = [self convertPoint:[aEvent locationInWindow] fromView:nil];
    //NSLog(@"shouldDelay at: %@ - event: %@", NSStringFromPoint(point),[aEvent description]);
    
    I_clickedRow = [self indexOfRowAtPoint:point];
    if (I_clickedRow != -1) {
        return YES;
    } else {
        return NO;
    }
}

- (void)mouseDown:(NSEvent *)aEvent {

    NSPoint point = [self convertPoint:[aEvent locationInWindow] fromView:nil];
    //NSLog(@"Clicked at: %@", NSStringFromPoint(point));
    NSEvent *nextEvent=[[self window] nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:.1] inMode:NSEventTrackingRunLoopMode dequeue:NO];
    BOOL willBeADrag=(!nextEvent || (nextEvent && [nextEvent type]!=NSLeftMouseUp));
    
    I_clickedRow = [self indexOfRowAtPoint:point];
    if (I_clickedRow != -1) {
        ItemChildPair pair=[self itemChildPairAtRow:I_clickedRow];
        BOOL causedAction=NO;
        if (pair.childIndex==-1) {
            NSImage *actionImage=[[self dataSource] listView:self objectValueForTag:TCMListViewActionButtonImageTag atChildIndex:-1 ofItemAtIndex:pair.itemIndex];
            if (actionImage) {
                NSRect itemRect=[self rectForItem:pair.itemIndex child:pair.childIndex];
                NSRect bounds=[self bounds];
                NSSize size=[actionImage size];
                float actionImagePadding=[[self class] actionImagePadding];
                if (point.x>=bounds.size.width-actionImagePadding-size.width && point.x<=bounds.size.width-actionImagePadding) {
                    float actionImageInset=(int)((itemRect.size.height-size.height)/2.);
                    if (point.y>=itemRect.origin.y+actionImageInset && point.y<=itemRect.origin.y+itemRect.size.height-actionImageInset) {
                        causedAction=YES;
                        I_actionRow = I_clickedRow;
                        if (I_target && [I_target respondsToSelector:I_action]) {
                            [I_target performSelector:I_action withObject:self];
                        }
                    }
                }
            }
        }
        if (!causedAction) {
            if ([aEvent modifierFlags] & NSShiftKeyMask) {
                [self shiftClickSelectoToRow:I_clickedRow];
            } else if ([aEvent modifierFlags] & NSCommandKeyMask) {
                if ([I_selectedRows containsIndex:I_clickedRow] && !willBeADrag) {
                    [self deselectRow:I_clickedRow];
                } else {
                    [self selectRow:I_clickedRow byExtendingSelection:YES];
                }
            } else {
                if ([I_selectedRows containsIndex:I_clickedRow] && willBeADrag) {
                    // nix
                } else {
                    [self selectRow:I_clickedRow byExtendingSelection:NO];
                }
            }
            if ([aEvent clickCount] == 2 && I_target && [I_target respondsToSelector:I_doubleAction]) {
                [I_target performSelector:I_doubleAction withObject:self];
            } else if ([aEvent modifierFlags] & NSControlKeyMask) {
                [self contextMenuMouseDown:aEvent];
            }
        }
    } else {
        [self deselectAll:self];
    }
    //NSLog(@"indexOfRow: %d", I_clickedRow);
}

- (int)numberOfItems {
    if (I_indicesNeedRebuilding) [self TCM_rebuildIndices];
    return I_indexNumberOfItems;
}

- (int)numberOfChildrenOfItemAtIndex:(int)aIndex {
    if (I_indicesNeedRebuilding) [self TCM_rebuildIndices];
    return I_indexNumberOfChildren[aIndex]; 
}

- (int)numberOfRows {
    if (I_indicesNeedRebuilding) [self TCM_rebuildIndices];
    return I_indexNumberOfRows; 
}

- (void)reloadData {
    I_indicesNeedRebuilding=YES;
    [self validateSelection];
    [self resizeToFit];
    [self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark ### Dragging Source/Destination ###

// Dragging Source
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    //NSLog(@"draggingSourceOperationMaskForLocal: %@", isLocal ? @"YES" : @"NO");
    return NSDragOperationGeneric;
}

// Dragging Source
- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
    //NSLog(@"draggedImage:endedAt:operation: %d", operation);
}

// Dragging Destination
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return NSDragOperationNone;
}

// Dragging Destination
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    return NO;
}

- (NSImage *)dragImageSelectedRect:(NSRect *)aRect forChild:(int)aChildIndex ofItem:(int)anItemIndex {
    Class myClass=[self class];
    float itemRowHeight   =[myClass itemRowHeight];
    float childRowHeight  =[myClass childRowHeight];

    NSMutableIndexSet *rows=[[self selectedRowIndexes] mutableCopy];
    int rowIndex=-1;
    NSMutableArray *itemChildPairs=[NSMutableArray array];
    NSSize imageSize=[self bounds].size;
    imageSize.height=0;
    while ([rows count]) {
        rowIndex=[rows firstIndex];
        ItemChildPair pair=[self itemChildPairAtRow:rowIndex];
        float heightOfRow=pair.childIndex==-1?itemRowHeight:childRowHeight;
        if (pair.itemIndex==anItemIndex && pair.childIndex==aChildIndex && aRect!=NULL) {
            *aRect=NSMakeRect(0,imageSize.height,imageSize.width,heightOfRow);
        }
        imageSize.height+=heightOfRow;
        [itemChildPairs addObject:[NSValue valueWithBytes:&pair objCType:@encode(ItemChildPair)]];
        [rows removeIndex:rowIndex];
    }
    [rows release];

    NSImage *resultImage=[[NSImage alloc] initWithSize:imageSize];
    [resultImage setFlipped:YES];
    [NSGraphicsContext saveGraphicsState];
    [resultImage lockFocus];
    [[NSColor clearColor] set];
    NSRectFill(NSMakeRect(0,0,imageSize.width,imageSize.height));
    NSAffineTransform *itemStep=[NSAffineTransform transform];
    [itemStep translateXBy:0 yBy:itemRowHeight];
    NSAffineTransform *childStep=[NSAffineTransform transform];
    [childStep translateXBy:0 yBy:childRowHeight];
    NSEnumerator *pairValues=[itemChildPairs objectEnumerator];
    NSValue *value=nil;
    while ((value=[pairValues nextObject])) {
        ItemChildPair pair;
        [value getValue:&pair];
        if (pair.childIndex==-1) {
            [self drawItemAtIndex:pair.itemIndex drawBackground:NO];
            [itemStep concat];
        } else {
            [self drawChildWithIndex:pair.childIndex ofItemAtIndex:pair.itemIndex drawBackground:NO];
            [childStep concat];
        }
    }
    [resultImage unlockFocus];
    [NSGraphicsContext restoreGraphicsState];
    [resultImage setFlipped:NO];
    return [resultImage autorelease];
}

- (NSPasteboard *)currentDraggingPasteboard {
    return I_currentDragPasteboard;
}

- (void)mouseDragged:(NSEvent *)aEvent {
//    NSLog(@"mouseDragged");
    if (I_clickedRow!=-1 && [I_selectedRows count]>0) {
        NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    
        BOOL allowDrag = NO;
        id dataSource = [self dataSource];
        if ([dataSource respondsToSelector:@selector(listView:writeRows:toPasteboard:)]) {
            allowDrag = [dataSource listView:self writeRows:[self selectedRowIndexes] toPasteboard:pboard];
        }
    
        if (allowDrag) {
            I_currentDragPasteboard=pboard;
            NSPoint point = [self convertPoint:[aEvent locationInWindow] fromView:nil];
            ItemChildPair pair = [self itemChildPairAtRow:I_clickedRow];
            NSRect rectInImage=NSMakeRect(0,0,10,10);
            NSImage *image=[self dragImageSelectedRect:&rectInImage forChild:pair.childIndex ofItem:pair.itemIndex];
            NSRect rowRect=[self rectForRow:I_clickedRow];
            NSPoint imageOffset=point;
            imageOffset.x=0;
            imageOffset.y=rowRect.origin.y+rowRect.size.height+([image size].height-NSMaxY(rectInImage));
            [self dragImage:image at:imageOffset offset:NSMakeSize(0.,0.) event:aEvent pasteboard:pboard source:self slideBack:YES];
        }
    }
}

#pragma mark ### Scrollview Notification Handling ###

- (void)resizeToFit {
    NSSize oldFrameSize = [self frame].size;
    NSScrollView *scrollView=[self enclosingScrollView];
    NSRect frame=[[scrollView contentView] frame];
    if (scrollView) {
        if (I_indicesNeedRebuilding) [self TCM_rebuildIndices];
        float desiredHeight=I_indexMaxHeight;
        if (frame.size.height<desiredHeight) {
            frame.size.height=desiredHeight;
        }
        [self setFrameSize:frame.size];
    }
    if (oldFrameSize.width<frame.size.width) {
        [self setNeedsDisplayInRect:NSMakeRect(frame.origin.x+oldFrameSize.width,frame.origin.y,
                                               frame.size.width-oldFrameSize.width,frame.size.height)];
    } else if (oldFrameSize.width>frame.size.width) {
        // if action buttons are present
    }
}


- (void)enclosingScrollViewFrameDidChange:(NSNotification *)aNotification {
    [self resizeToFit];
}

#pragma mark -
#pragma mark ### index handling ###


- (void)TCM_rebuildIndices {
    [self removeAllToolTips];

    Class myClass=[self class];
    float itemRowHeight   =[myClass itemRowHeight];
    float childRowHeight  =[myClass childRowHeight];
    float itemRowGapHeight=[myClass itemRowGapHeight];

    id dataSource=[self dataSource];
    
    I_indexNumberOfItems=[dataSource listView:self numberOfEntriesOfItemAtIndex:-1];
    
    if (I_indexNumberOfChildren!=NULL) {
        free(I_indexNumberOfChildren  );
        free(I_indexRowAtItem         );
        free(I_indexYRangesForItem    );
        free(I_indexItemChildPairAtRow);
    }
    
    I_indexNumberOfChildren = (int *)malloc(sizeof(int)*I_indexNumberOfItems);
    I_indexRowAtItem        = (int *)malloc(sizeof(int)*I_indexNumberOfItems);
    I_indexYRangesForItem   = (NSRange *)malloc(sizeof(NSRange)*I_indexNumberOfItems);
    int itemIndex;
    int row=0;
    float yPosition=0;
    for (itemIndex=0;itemIndex<I_indexNumberOfItems;itemIndex++) {
        int numberOfChildren=[dataSource listView:self numberOfEntriesOfItemAtIndex:itemIndex];
        I_indexNumberOfChildren[itemIndex]=numberOfChildren;
        I_indexRowAtItem[itemIndex]=row;
        NSRange yRange=NSMakeRange(yPosition,itemRowHeight+numberOfChildren*childRowHeight);
        I_indexYRangesForItem[itemIndex]=yRange;
        yPosition=NSMaxRange(yRange);
        [self addToolTipRect:NSMakeRect(0,yRange.location,FLT_MAX,itemRowHeight) owner:self userData:nil];
        int childIndex=0;
        for (childIndex=0;childIndex<numberOfChildren;childIndex++) {
            [self addToolTipRect:NSMakeRect(0,yRange.location+itemRowHeight+childIndex*childRowHeight,FLT_MAX,childRowHeight) owner:self userData:nil];
        }
        row+=numberOfChildren+1;
        yPosition+=itemRowGapHeight;
    }
    I_indexNumberOfRows=row;
    I_indexMaxHeight=yPosition-itemRowGapHeight;
    
    I_indexItemChildPairAtRow = (ItemChildPair *)malloc(sizeof(ItemChildPair)*row);
    row=0;
    for (itemIndex=0;itemIndex<I_indexNumberOfItems;itemIndex++) {
        ItemChildPair pair;
        pair.itemIndex=itemIndex;
        for (pair.childIndex=-1;pair.childIndex<I_indexNumberOfChildren[itemIndex];pair.childIndex++) {
            I_indexItemChildPairAtRow[row++]=pair;
        }
    }
    I_indicesNeedRebuilding = NO;
}

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData {
    int index=[self indexOfRowAtPoint:point];
    if (index!=-1) {
        ItemChildPair pair=[self itemChildPairAtRow:index];
        id dataSource=[self dataSource];
        if ([dataSource respondsToSelector:@selector(listView:toolTipStringAtChildIndex:ofItemAtIndex:)]) {
            return [dataSource listView:self toolTipStringAtChildIndex:pair.childIndex ofItemAtIndex:pair.itemIndex];
        }
    }
    return nil;
}


#pragma mark -
- (BOOL)isFlipped {
    return YES;
}

- (BOOL)isOpaque {
    return YES;
}

#pragma mark -
#pragma mark ### Accessors ###

- (int)clickedRow {
    return I_clickedRow;
}

- (int)actionRow {
    return I_actionRow;
}

- (void)setDelegate:(id)aDelegate
{
    NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
    [center removeObserver:I_delegate name:ListViewDidChangeSelectionNotification object:self];
    I_delegate = aDelegate;
    if ([aDelegate respondsToSelector:@selector(listViewDidChangeSelection:)]) {
        [center addObserver:aDelegate selector:@selector(listViewDidChangeSelection:) name:ListViewDidChangeSelectionNotification object:self];
    }
}

- (id)delegate
{
    return I_delegate;
}

- (void)setDataSource:(id)aDataSource
{
    I_dataSource = aDataSource;
}

- (id)dataSource
{
    return I_dataSource;
}

- (void)setTarget:(id)aTarget
{
    I_target = aTarget;
}

- (void)setAction:(SEL)anAction
{
    I_action = anAction;
}

- (void)setDoubleAction:(SEL)anAction
{
    I_doubleAction = anAction;
}

@end
