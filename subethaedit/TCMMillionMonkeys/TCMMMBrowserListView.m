//
//  TCMMMBrowserListView.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMBrowserListView.h"


#define ITEMROWHEIGHT 38.
#define CHILDROWHEIGHT 20.
#define ACTIONIMAGEPADDING 4.

static NSColor *alternateRowColor=nil;


@interface TCMMMBrowserListView (TCMBrowserListViewPrivateAdditions)

- (void)TCM_rebuildIndices;

- (void)TCM_drawItemAtIndex:(int)aIndex;
- (int)TCM_indexOfRowAtPoint:(NSPoint)aPoint;
- (void)TCM_drawChildWithIndex:(int)aChildIndex ofItemAtIndex:(int)aIndex;
- (NSRect)TCM_rectForItem:(int)anItemIndex child:(int)aChildIndex;
- (NSRect)TCM_rectForRow:(int)aRow;

@end

#pragma mark -

@implementation TCMMMBrowserListView

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
    if (!mNameAttributes) {
        mNameAttributes = [[NSMutableDictionary dictionaryWithObject:
            [NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName] retain];
    }
    NSRect bounds=[self bounds];
    NSRect childRect=NSMakeRect(0, 0,bounds.size.width, CHILDROWHEIGHT);
    if (aItemIndex%2) {
        [alternateRowColor set];
    } else {
        [[NSColor whiteColor] set];
    }
    if ([I_selectedRows containsIndex:[self rowForItem:aItemIndex child:aChildIndex]]) {
        [[NSColor selectedTextBackgroundColor] set];
    }    
    NSRectFill(childRect);
    
    id dataSource=[self dataSource];
    
    NSImage *image=[dataSource listView:self objectValueForTag:TCMMMBrowserChildStatusImageTag atIndex:aChildIndex ofItemAtIndex:aItemIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(32.+9-(16+2),2+16) 
                      operation:NSCompositeSourceOver];
    }

    image=[dataSource listView:self objectValueForTag:TCMMMBrowserChildIconImageTag atIndex:aChildIndex ofItemAtIndex:aItemIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(32.+9,2+16) 
                      operation:NSCompositeSourceOver];
    }
    NSString *string=[dataSource listView:self objectValueForTag:TCMMMBrowserChildNameTag atIndex:aChildIndex ofItemAtIndex:aItemIndex];
    [[NSColor blackColor] set];
    if (string) {
        [string drawAtPoint:NSMakePoint(32.+9+16.+3.,4.)
               withAttributes:mNameAttributes];
    }
}

- (void)TCM_drawItemAtIndex:(int)aIndex {

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
    NSRect itemRect=NSMakeRect(0, 0,bounds.size.width, ITEMROWHEIGHT);
    if ([I_selectedRows containsIndex:[self rowForItem:aIndex child:-1]]) {
        [[NSColor selectedTextBackgroundColor] set];
    } else if (aIndex%2) {
        [alternateRowColor set];
    } else {
        [[NSColor whiteColor] set];
    }
    NSRectFill(itemRect);

//    if ([I_selectedRows containsIndex:[self rowForItem:aIndex child:-1]]) {
//        [[NSColor selectedTextBackgroundColor] set];
//        [I_itemSelectionPath fill];
//    }    
    id dataSource=[self dataSource];

    NSImage *actionImage=[dataSource listView:self objectValueForTag:TCMMMBrowserItemActionImageTag ofItemAtIndex:aIndex];
    if (actionImage) {
        [NSGraphicsContext saveGraphicsState];
        NSSize actionSize=[actionImage size];
        [actionImage compositeToPoint:NSMakePoint(itemRect.size.width-ACTIONIMAGEPADDING-actionSize.width,(int)(ITEMROWHEIGHT-(ITEMROWHEIGHT-actionSize.height)/2.))
                     operation:NSCompositeSourceOver];
        itemRect.size.width-=ACTIONIMAGEPADDING+actionSize.width+ACTIONIMAGEPADDING;
        NSRectClip(itemRect);
    }
    
    NSImage *image=[dataSource listView:self objectValueForTag:TCMMMBrowserItemImageTag ofItemAtIndex:aIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(4,32+3) 
                      operation:NSCompositeSourceOver];
    }
    NSString *string=[dataSource listView:self objectValueForTag:TCMMMBrowserItemNameTag ofItemAtIndex:aIndex];
    [[NSColor blackColor] set];
    if (string) {
        [string drawAtPoint:NSMakePoint(32.+11.,1.)
               withAttributes:mNameAttributes];
    }
    NSSize nameSize=[string sizeWithAttributes:mNameAttributes];
    image=[dataSource listView:self objectValueForTag:TCMMMBrowserItemImageNextToNameTag ofItemAtIndex:aIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(32.+11.+(int)nameSize.width+6.,
                                            (int)(1.+nameSize.height)-(nameSize.height - [image size].height)/3.) 
                      operation:NSCompositeSourceOver];
    }
    
    
//    NSSize cellSize=[I_disclosureCell cellSize];
//    [I_disclosureCell drawWithFrame:NSMakeRect(32.+10,20.,cellSize.width,cellSize.height) inView:self];
    string=[dataSource listView:self objectValueForTag:TCMMMBrowserItemStatusTag ofItemAtIndex:aIndex];
    if (string) {
        [string drawAtPoint:NSMakePoint(32.+11,20.) //was 32.+27 for with diclosure triangle
               withAttributes:mStatusAttributes];
    }
    
    if (actionImage) {
        [NSGraphicsContext restoreGraphicsState];
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
}

#pragma mark -
#pragma mark ### Event Handling ###

- (void)mouseDown:(NSEvent *)aEvent {

    NSPoint point = [self convertPoint:[aEvent locationInWindow] fromView:nil];
    //NSLog(@"Clicked at: %@", NSStringFromPoint(point));
    
    I_clickedRow = [self TCM_indexOfRowAtPoint:point];
    if (I_clickedRow != -1) {
        ItemChildPair pair=[self itemChildPairAtRow:I_clickedRow];
        BOOL causedAction=NO;
        if (pair.childIndex==-1) {
            NSImage *actionImage=[[self dataSource] listView:self objectValueForTag:TCMMMBrowserItemActionImageTag ofItemAtIndex:pair.itemIndex];
            if (actionImage) {
                NSRect itemRect=[self TCM_rectForItem:pair.itemIndex child:pair.childIndex];
                NSRect bounds=[self bounds];
                NSSize size=[actionImage size];
                if (point.x>=bounds.size.width-ACTIONIMAGEPADDING-size.width && point.x<=bounds.size.width-ACTIONIMAGEPADDING) {
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
            if ([aEvent modifierFlags] & NSCommandKeyMask) {
                [self selectRow:I_clickedRow byExtendingSelection:YES];
            } else {
                [self selectRow:I_clickedRow byExtendingSelection:NO];
            }
            if ([aEvent clickCount] == 2 && I_target && [I_target respondsToSelector:I_doubleAction]) {
                [I_target performSelector:I_doubleAction withObject:self];
            }
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
    [self removeAllToolTips];

    id delegate=[self delegate];
    
    I_indexNumberOfItems=[delegate numberOfItemsInListView:self];
    
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
        int numberOfChildren=[delegate listView:self numberOfChildrenOfItemAtIndex:itemIndex];
        I_indexNumberOfChildren[itemIndex]=numberOfChildren;
        I_indexRowAtItem[itemIndex]=row;
        NSRange yRange=NSMakeRange(yPosition,ITEMROWHEIGHT+numberOfChildren*CHILDROWHEIGHT);
        I_indexYRangesForItem[itemIndex]=yRange;
        yPosition=NSMaxRange(yRange);
        [self addToolTipRect:NSMakeRect(0,yRange.location,FLT_MAX,ITEMROWHEIGHT) owner:self userData:nil];
        int childIndex=0;
        for (childIndex=0;childIndex<numberOfChildren;childIndex++) {
            [self addToolTipRect:NSMakeRect(0,yRange.location+ITEMROWHEIGHT+childIndex*CHILDROWHEIGHT,FLT_MAX,CHILDROWHEIGHT) owner:self userData:nil];
        }
        row+=numberOfChildren+1;
    }
    I_indexNumberOfRows=row;
    I_indexMaxHeight=yPosition;
    
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
    int index=[self TCM_indexOfRowAtPoint:point];
    if (index!=-1) {
        ItemChildPair pair=[self itemChildPairAtRow:index];
        id dataSource=[self dataSource];
        if ([dataSource respondsToSelector:@selector(listView:toolTipStringAtIndex:ofItemAtIndex:)]) {
            return [dataSource listView:self toolTipStringAtIndex:pair.childIndex ofItemAtIndex:pair.itemIndex];
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


- (void)setDelegate:(id)aDelegate
{
    I_delegate = aDelegate;
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

- (int)actionRow {
    return I_actionRow;
}


- (void)setDoubleAction:(SEL)anAction
{
    I_doubleAction = anAction;
}

@end
