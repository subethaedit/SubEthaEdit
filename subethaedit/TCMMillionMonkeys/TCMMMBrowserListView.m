//
//  TCMMMBrowserListView.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMBrowserListView.h"


#define ITEMROWHEIGHT 36.
#define CHILDROWHEIGHT 18.

static NSColor *alternateRowColor=nil;


@interface TCMMMBrowserListView (TCMBrowserListViewPrivateAdditions)

- (void)TCM_drawItemAtIndex:(int)aIndex;
- (int)TCM_indexOfItemAtPoint:(NSPoint)aPoint isChild:(BOOL *)isChild;
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
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    NSImage *image=[dataSource listView:self objectValueForTag:TCMMMBrowserChildIconImageTag atIndex:aChildIndex ofItemAtIndex:aItemIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(32.+5,1) 
                      operation:NSCompositeSourceOver];
    }
    NSString *string=[dataSource listView:self objectValueForTag:TCMMMBrowserChildNameTag atIndex:aChildIndex ofItemAtIndex:aItemIndex];
    [[NSColor blackColor] set];
    if (string) {
        [string drawAtPoint:NSMakePoint(32.+5+16.+2.,2.)
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
    
    id dataSource=[self dataSource];
    
    NSImage *image=[dataSource listView:self objectValueForTag:TCMMMBrowserItemImageTag ofItemAtIndex:aIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(2,2) 
                      operation:NSCompositeSourceOver];
    }
    NSString *string=[dataSource listView:self objectValueForTag:TCMMMBrowserItemNameTag ofItemAtIndex:aIndex];
    [[NSColor blackColor] set];
    if (string) {
        [string drawAtPoint:NSMakePoint(32.+5.,18.)
               withAttributes:mNameAttributes];
    }
    string=[dataSource listView:self objectValueForTag:TCMMMBrowserItemStatusTag ofItemAtIndex:aIndex];
    if (string) {
        [string drawAtPoint:NSMakePoint(32.+5,4.)
               withAttributes:mStatusAttributes];
    }
}

- (void)drawRect:(NSRect)rect
{
    int numberOfItems=[self numberOfItems];
    int i;
    
    [[NSColor whiteColor] set];
    NSRectFill(rect);
    [NSGraphicsContext saveGraphicsState];
    NSRect bounds=[self bounds];
    NSAffineTransform *transform=[NSAffineTransform transform];
    [transform translateXBy:0 yBy:bounds.origin.y+bounds.size.height];
    [transform concat];
    NSAffineTransform *itemStep=[NSAffineTransform transform];
    [itemStep translateXBy:0 yBy:-1*ITEMROWHEIGHT];
    NSAffineTransform *childStep=[NSAffineTransform transform];
    [childStep translateXBy:0 yBy:-1*CHILDROWHEIGHT];
    for (i=0;i<numberOfItems;i++) {
        [itemStep concat];
        [self TCM_drawItemAtIndex:i];
        int j;
        int numberOfChildren=[[self dataSource] listView:self numberOfChildrenOfItemAtIndex:i];
        for (j=0;j<numberOfChildren;j++) {
            [childStep concat];
            [self TCM_drawChildWithIndex:j ofItemAtIndex:i];
        }
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

- (int)TCM_indexOfItemAtPoint:(NSPoint)aPoint isChild:(BOOL *)isChild {
    
    *isChild = NO;
    
    return -1;
}

- (void)mouseDown:(NSEvent *)aEvent {

    NSPoint point = [self convertPoint:[aEvent locationInWindow] fromView:nil];
    NSLog(@"Clicked at: %@", NSStringFromPoint(point));
    
    BOOL isChild;
    int indexOfItem = [self TCM_indexOfItemAtPoint:point isChild:&isChild];
    NSLog(@"indexOfItem: %d, isChild: %@", indexOfItem, isChild ? @"YES" : @"NO");
}

- (int)numberOfItems {
   return [I_dataSource numberOfItemsInListView:self]; 
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
        if (frame.size.height<numberOfItems*ITEMROWHEIGHT) {
            frame.size.height=numberOfItems*ITEMROWHEIGHT;
        }
        [self setFrameSize:frame.size];
//        NSRect bounds=[self bounds];
//        if (numberOfRows>I_selectedRow) {
//            bounds.origin.y+=bounds.size.height;
//            bounds.size.height=ITEMROWHEIGHT;
//            bounds.origin.y-=(I_selectedRow+1)*ITEMROWHEIGHT;
//            [self scrollRectToVisible:bounds];
//        }
    }
    [self setNeedsDisplay:YES];
}


- (void)enclosingScrollViewFrameDidChange:(NSNotification *)aNotification {
    [self resizeToFit];
}

#pragma mark -
#pragma mark ### Accessors ###

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

@end
