//
//  ParticipantsView.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "ParticipantsView.h"


#define ITEMROWHEIGHT 22.
#define CHILDROWHEIGHT 38.

static NSColor *alternateRowColor=nil;

NSString *ParticipantsViewDidChangeSelectionNotification=
        @"ParticipantsViewDidChangeSelectionNotification";

@interface ParticipantsView (ParticipantsViewPrivateAdditions)

- (void)TCM_rebuildIndices;

- (void)TCM_drawItemAtIndex:(int)aIndex;
- (int)TCM_indexOfRowAtPoint:(NSPoint)aPoint;
- (void)TCM_drawChildWithIndex:(int)aChildIndex ofItemAtIndex:(int)aIndex;
- (NSRect)TCM_rectForItem:(int)anItemIndex child:(int)aChildIndex;
- (NSRect)TCM_rectForRow:(int)aRow;

@end

#pragma mark -

@implementation ParticipantsView

- (void)TCM_sendParticipantsViewDidChangeSelectionNotification {
    [[NSNotificationQueue defaultQueue] 
    enqueueNotification:[NSNotification notificationWithName:ParticipantsViewDidChangeSelectionNotification object:self]
           postingStyle:NSPostWhenIdle 
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if (!alternateRowColor) {
            alternateRowColor=[[NSColor colorWithCalibratedRed:0.93 green:0.95 blue:1.0 alpha:1.0] retain];
        }
        I_itemSelectionPath = [NSBezierPath new];
        [I_itemSelectionPath moveToPoint:NSMakePoint(0.,0.)];
        [I_itemSelectionPath lineToPoint:NSMakePoint(4000.,0.)];
        [I_itemSelectionPath lineToPoint:NSMakePoint(4000.,ITEMROWHEIGHT/2.)];
        [I_itemSelectionPath lineToPoint:NSMakePoint(32.+10.,ITEMROWHEIGHT/2.)];
        [I_itemSelectionPath lineToPoint:NSMakePoint(32.+6.,ITEMROWHEIGHT)];
        [I_itemSelectionPath lineToPoint:NSMakePoint(0.,ITEMROWHEIGHT)];
        [I_itemSelectionPath closePath];
        
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
    [I_itemSelectionPath release];
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

- (void)TCM_drawChildWithIndex:(int)aChildIndex ofItemAtIndex:(int)aItemIndex {
    static NSMutableDictionary *mNameAttributes=nil;
    static NSMutableDictionary *mStatusAttributes=nil;
    if (!mNameAttributes) {
        mNameAttributes = [[NSMutableDictionary dictionaryWithObject:
            [NSFont boldSystemFontOfSize:[NSFont systemFontSize]] forKey:NSFontAttributeName] retain];
    }
    if (!mStatusAttributes) {
        mStatusAttributes = [[NSMutableDictionary dictionaryWithObject:
			   [NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName] retain];
    } 
    

    NSRect bounds=[self bounds];
    NSRect childRect=NSMakeRect(0, 0,bounds.size.width, CHILDROWHEIGHT);
//    if (aItemIndex%2) {
//        [alternateRowColor set];
//    } else {
//        [[NSColor whiteColor] set];
//    }
    [[NSColor whiteColor] set];
    BOOL selected=[I_selectedRows containsIndex:[self rowForItem:aItemIndex child:aChildIndex]];
    if (selected) {
        [[NSColor selectedTextBackgroundColor] set];
    }    
    NSRectFill(childRect);

    id dataSource=[self dataSource];
    
    NSImage *image=[dataSource participantsView:self objectValueForTag:ParticipantsChildImageTag atIndex:aChildIndex ofItemAtIndex:aItemIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(4,32+3) 
                      operation:NSCompositeSourceOver];
    }
    NSString *string=[dataSource participantsView:self objectValueForTag:ParticipantsChildNameTag atIndex:aChildIndex ofItemAtIndex:aItemIndex];
    [[NSColor blackColor] set];
    if (string) {
        [string drawAtPoint:NSMakePoint(32.+11.,1.)
                withAttributes:mNameAttributes];
    }
    NSSize nameSize=[string sizeWithAttributes:mNameAttributes];
    image=[dataSource participantsView:self objectValueForTag:ParticipantsChildImageNextToNameTag atIndex:aChildIndex ofItemAtIndex:aItemIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(32.+11.+(int)nameSize.width+6.,
                                            (int)(1.+nameSize.height)-(nameSize.height - [image size].height)/3.) 
                      operation:NSCompositeSourceOver];
    }
    
    NSAttributedString *attributedString=[dataSource participantsView:self objectValueForTag:ParticipantsChildStatusTag atIndex:aChildIndex ofItemAtIndex:aItemIndex];
    if (attributedString) {
        [attributedString drawAtPoint:NSMakePoint(32.+11,20.)];
    }
}

- (void)TCM_drawItemAtIndex:(int)aItemIndex {
    static NSMutableDictionary *mNameAttributes=nil;
    if (!mNameAttributes) {
        mNameAttributes = [[NSMutableDictionary dictionaryWithObject:
            [NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName] retain];
        [mNameAttributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    }
    NSRect bounds=[self bounds];
    NSRect itemRect=NSMakeRect(0, 0,bounds.size.width, ITEMROWHEIGHT);
    NSImage *fillImage=[NSImage imageNamed:@"ParticipantBar_Fill"];
    [fillImage setFlipped:YES];
    [fillImage drawInRect:itemRect fromRect:NSMakeRect(0,0,[fillImage size].width,[fillImage size].height) operation:NSCompositeCopy fraction:1.0];
    [[NSColor lightGrayColor] set];
    itemRect.size.height-=1;
    NSFrameRect(itemRect);
    
    id dataSource=[self dataSource];
    
    NSImage *image=[dataSource participantsView:self objectValueForTag:ParticipantsItemStatusImageTag ofItemAtIndex:aItemIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(12,2+16) 
                      operation:NSCompositeSourceOver];
    }

    NSString *string=[dataSource participantsView:self objectValueForTag:ParticipantsItemNameTag ofItemAtIndex:aItemIndex];
    [[NSColor whiteColor] set];
    if (string) {
        [string drawAtPoint:NSMakePoint(16.+9+16.+3.,3.)
               withAttributes:mNameAttributes];
    }

}

- (void)drawRect:(NSRect)rect
{
    if (I_indicesNeedRebuilding) [self TCM_rebuildIndices];

    const NSRect *rects;
    int count;
    [self getRectsBeingDrawn:&rects count:&count];
    while (count-->0) {
        NSRect smallRect=rects[count];
        
        if (NSMaxY(smallRect)>=I_indexMaxHeight) {
            [[NSColor whiteColor] set];
            NSRectFill(NSMakeRect(smallRect.origin.x,I_indexMaxHeight,smallRect.size.width, NSMaxY(smallRect)-I_indexMaxHeight));
        }
    
        int startRow = [self TCM_indexOfRowAtPoint:smallRect.origin];
    
        if (startRow!=-1 && startRow < I_indexNumberOfRows) {
            int endRow   = [self TCM_indexOfRowAtPoint:NSMakePoint(1.,NSMaxY(smallRect))];
            if (endRow==-1) endRow=I_indexNumberOfRows-1;
        
            [NSGraphicsContext saveGraphicsState];
            ItemChildPair pair=[self itemChildPairAtRow:startRow];
            NSRect startRect=[self TCM_rectForItem:pair.itemIndex child:pair.childIndex];
        
            NSAffineTransform *toStart=[NSAffineTransform transform];
            [toStart translateXBy:0 yBy:startRect.origin.y];
            [toStart concat];
        
            NSAffineTransform *itemStep=[NSAffineTransform transform];
            [itemStep translateXBy:0 yBy:ITEMROWHEIGHT];
            NSAffineTransform *childStep=[NSAffineTransform transform];
            [childStep translateXBy:0 yBy:CHILDROWHEIGHT];
            while (startRow<=endRow) {
                if (pair.childIndex==-1) {
                    [self TCM_drawItemAtIndex:pair.itemIndex];
                    [itemStep concat];
                } else {
                    [self TCM_drawChildWithIndex:pair.childIndex ofItemAtIndex:pair.itemIndex];
                    [childStep concat];
                }
                pair.childIndex++;
                if (!(pair.childIndex < I_indexNumberOfChildren[pair.itemIndex])) {
                    pair.itemIndex++;
                    pair.childIndex=-1;
                    [[NSColor whiteColor] set];
                    NSRectFill(NSMakeRect(smallRect.origin.x,0,smallRect.size.width,ITEMROWHEIGHT));
                    [itemStep concat];
                }
                startRow++;
            }
        
            [NSGraphicsContext restoreGraphicsState];
//            [[NSColor greenColor] set];
//            NSFrameRect(NSInsetRect(rects[count],1.,1.));
        }
    }
}

- (NSRect)TCM_rectForItem:(int)anItemIndex child:(int)aChildIndex
{
    if (I_indicesNeedRebuilding) [self TCM_rebuildIndices];

    NSRange itemChildRange = I_indexYRangesForItem[anItemIndex];
    NSRect result;
    result.origin.x = 0.0;
    result.size.width = [self bounds].size.width;
    
    if (aChildIndex == -1) {
        result.origin.y = itemChildRange.location;
        result.size.height = ITEMROWHEIGHT;
    } else {
        result.origin.y = itemChildRange.location + ITEMROWHEIGHT + aChildIndex * CHILDROWHEIGHT;
        result.size.height = CHILDROWHEIGHT;
    }
    
    return result;
}

- (NSRect)TCM_rectForRow:(int)aRow {
    if (I_indicesNeedRebuilding) [self TCM_rebuildIndices];
    return [self TCM_rectForItem:I_indexItemChildPairAtRow[aRow].itemIndex
                           child:I_indexItemChildPairAtRow[aRow].childIndex];
}

- (int)TCM_indexOfRowAtPoint:(NSPoint)aPoint {

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
    if (aPoint.y>testRange.location+ITEMROWHEIGHT) {
        baseRow+=(int)((aPoint.y-testRange.location-ITEMROWHEIGHT-1)/CHILDROWHEIGHT)+1;
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
            [self setNeedsDisplayInRect:[self TCM_rectForRow:indexBuffer[i]]];
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

- (void)deselectRow:(int)aRow {
    if ([I_selectedRows containsIndex:aRow]) {
        [I_selectedRows removeIndex:aRow];
        [self TCM_sendParticipantsViewDidChangeSelectionNotification];
        [self setNeedsDisplayInRect:[self TCM_rectForRow:aRow]];
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

- (void)selectRow:(int)aRow byExtendingSelection:(BOOL)shouldExtend {
    
    if (!shouldExtend) {
        [self TCM_setNeedsDisplayForIndexes:I_selectedRows];
        [I_selectedRows removeAllIndexes];
    }
    I_selectedRow = aRow;
    [I_selectedRows addIndex:aRow];
    [self setNeedsDisplayInRect:[self TCM_rectForRow:aRow]];
    [self TCM_sendParticipantsViewDidChangeSelectionNotification];
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
    [self TCM_sendParticipantsViewDidChangeSelectionNotification];
}

#pragma mark -
#pragma mark ### Event Handling ###

- (void)contextMenuMouseDown:(NSEvent *)aEvent {
    NSPoint point = [self convertPoint:[aEvent locationInWindow] fromView:nil];
    
    I_clickedRow = [self TCM_indexOfRowAtPoint:point];
    id delegate=[self delegate];
    if ([delegate respondsToSelector:@selector(contextMenuForParticipantsView:clickedAtRow:)]) {
        NSMenu *menu=[delegate contextMenuForParticipantsView:self clickedAtRow:I_clickedRow];
        if (menu) {
            [NSMenu popUpContextMenu:menu withEvent:aEvent forView:self];
        }
    }

}

- (void)rightMouseDown:(NSEvent *)aEvent {
    NSPoint point = [self convertPoint:[aEvent locationInWindow] fromView:nil];
    
    I_clickedRow = [self TCM_indexOfRowAtPoint:point];
    if (I_clickedRow != -1) {
        if (![I_selectedRows containsIndex:I_clickedRow]) {
            [self mouseDown:aEvent];
        }
        [self contextMenuMouseDown:aEvent];
    }
}

- (void)mouseDown:(NSEvent *)aEvent {

    NSPoint point = [self convertPoint:[aEvent locationInWindow] fromView:nil];
    //NSLog(@"Clicked at: %@", NSStringFromPoint(point));
    
    I_clickedRow = [self TCM_indexOfRowAtPoint:point];
    if (I_clickedRow != -1) {
        if ([aEvent modifierFlags] & NSCommandKeyMask) {
            [self selectRow:I_clickedRow byExtendingSelection:YES];
        } else {
            [self selectRow:I_clickedRow byExtendingSelection:NO];
        }
        if ([aEvent clickCount] == 2 && I_target && [I_target respondsToSelector:I_doubleAction]) {
            [I_target performSelector:I_doubleAction withObject:self];
        } else if ([aEvent modifierFlags] & NSControlKeyMask) {
            [self contextMenuMouseDown:aEvent];
        }
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

    id dataSource=[self dataSource];
    
    I_indexNumberOfItems=[dataSource numberOfItemsInParticipantsView:self];
    
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
        int numberOfChildren=[dataSource participantsView:self numberOfChildrenOfItemAtIndex:itemIndex];
        I_indexNumberOfChildren[itemIndex]=numberOfChildren;
        I_indexRowAtItem[itemIndex]=row;
        NSRange yRange=NSMakeRange(yPosition,ITEMROWHEIGHT+numberOfChildren*CHILDROWHEIGHT);
        I_indexYRangesForItem[itemIndex]=yRange;
        yPosition=NSMaxRange(yRange);
        row+=numberOfChildren+1;
        yPosition+=ITEMROWHEIGHT;
    }
    I_indexNumberOfRows=row;
    I_indexMaxHeight=yPosition-ITEMROWHEIGHT;
    
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


- (void)setDelegate:(id)aDelegate
{
    NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
    [center removeObserver:I_delegate name:ParticipantsViewDidChangeSelectionNotification object:self];
    I_delegate = aDelegate;
    if ([aDelegate respondsToSelector:@selector(participantsViewDidChangeSelection:)]) {
        [center addObserver:aDelegate selector:@selector(participantsViewDidChangeSelection:) name:ParticipantsViewDidChangeSelectionNotification object:self];
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
