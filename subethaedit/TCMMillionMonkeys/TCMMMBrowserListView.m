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

static NSColor *alternateRowColor=nil;


@interface TCMMMBrowserListView (TCMBrowserListViewPrivateAdditions)

- (void)TCM_drawItemAtIndex:(int)aIndex;
- (int)TCM_indexOfRowAtPoint:(NSPoint)aPoint isChild:(BOOL *)isChild;
- (void)TCM_drawChildWithIndex:(int)aChildIndex ofItemAtIndex:(int)aIndex;

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
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    if (aIndex%2) {
        [alternateRowColor set];
    } else {
        [[NSColor whiteColor] set];
    }
    NSRectFill(itemRect);

    [[NSColor selectedTextBackgroundColor] set];
    [I_itemSelectionPath fill];
    
    id dataSource=[self dataSource];
    
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
    NSSize cellSize=[I_disclosureCell cellSize];
    [I_disclosureCell drawWithFrame:NSMakeRect(32.+10,20.,cellSize.width,cellSize.height) inView:self];
    string=[dataSource listView:self objectValueForTag:TCMMMBrowserItemStatusTag ofItemAtIndex:aIndex];
    if (string) {
        [string drawAtPoint:NSMakePoint(32.+27,20.)
               withAttributes:mStatusAttributes];
    }
}

- (void)drawRect:(NSRect)rect
{
    
    [[NSColor whiteColor] set];
    NSRectFill(rect);

    [NSGraphicsContext saveGraphicsState];
    NSAffineTransform *itemStep=[NSAffineTransform transform];
    [itemStep translateXBy:0 yBy:ITEMROWHEIGHT];
    NSAffineTransform *childStep=[NSAffineTransform transform];
    [childStep translateXBy:0 yBy:CHILDROWHEIGHT];

    int numberOfItems=[self numberOfItems];
    int i;

    for (i=0;i<numberOfItems;i++) {
        [self TCM_drawItemAtIndex:i];
        [itemStep concat];
        int j;
        int numberOfChildren=[self numberOfChildrenOfItemAtIndex:i];
        for (j=0;j<numberOfChildren;j++) {
            [self TCM_drawChildWithIndex:j ofItemAtIndex:i];
            [childStep concat];
        }
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

- (int)TCM_indexOfRowAtPoint:(NSPoint)aPoint isChild:(BOOL *)isChild {
    NSRect bounds=[self bounds];
    float verticalPosition=bounds.size.height+bounds.origin.y-aPoint.y;
    
    int numberOfItems=[self numberOfItems];
    int i;
    int result=0;

    for (i=0;i<numberOfItems;i++) {
        if (verticalPosition<=ITEMROWHEIGHT) {
            *isChild = NO;
            return result;
        }
        result++;
        verticalPosition-=ITEMROWHEIGHT;
        
        int j;
        int numberOfChildren=[[self dataSource] listView:self numberOfChildrenOfItemAtIndex:i];
        if (verticalPosition<=CHILDROWHEIGHT*numberOfChildren) {
            for (j=0;j<numberOfChildren;j++) {
                if (verticalPosition<=CHILDROWHEIGHT) {
                    *isChild = YES;
                    return result;
                }
                result++;
                verticalPosition-=CHILDROWHEIGHT;
            }
        } else {
            verticalPosition-=CHILDROWHEIGHT*numberOfChildren;
            result+=numberOfChildren;
        }
    }

    *isChild = NO;
    
    return -1;
}

- (void)mouseDown:(NSEvent *)aEvent {

    NSPoint point = [self convertPoint:[aEvent locationInWindow] fromView:nil];
    NSLog(@"Clicked at: %@", NSStringFromPoint(point));
    
    BOOL isChild;
    I_clickedRow = [self TCM_indexOfRowAtPoint:point isChild:&isChild];
    if ([aEvent clickCount]==2 && I_target && [I_target respondsToSelector:I_doubleAction]) {
        [I_target performSelector:I_doubleAction withObject:self];
    }
    NSLog(@"indexOfItem: %d, isChild: %@", I_clickedRow, isChild ? @"YES" : @"NO");
}

- (int)numberOfItems {
   return [[self dataSource] numberOfItemsInListView:self]; 
}

- (int)numberOfChildrenOfItemAtIndex:(int)aIndex {
   return [[self dataSource] listView:self numberOfChildrenOfItemAtIndex:aIndex]; 
}

- (void)reloadData {
    [self resizeToFit];
}


#pragma mark ### Scrollview Notification Handling ###

- (void)resizeToFit {
    NSScrollView *scrollView=[self enclosingScrollView];
    if (scrollView) {
        NSRect frame=[[scrollView contentView] frame];
        int numberOfItems=[self numberOfItems];
        int i;
        float desiredHeight=numberOfItems*ITEMROWHEIGHT;
        for (i=0;i<numberOfItems;i++) {
            int numberOfChildren=[self numberOfChildrenOfItemAtIndex:i];
            desiredHeight+=numberOfChildren*CHILDROWHEIGHT;
        }
        if (frame.size.height<desiredHeight) {
            frame.size.height=desiredHeight;
        }
        [self setFrameSize:frame.size];
    }
    [self setNeedsDisplay:YES];
}


- (void)enclosingScrollViewFrameDidChange:(NSNotification *)aNotification {
    [self resizeToFit];
}

#pragma mark -
- (BOOL)isFlipped {
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

- (void)setDoubleAction:(SEL)anAction
{
    I_doubleAction = anAction;
}

@end
