//
//  TCMMMBrowserListView.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMBrowserListView.h"


#define ITEMROWHEIGHT 35.

static NSColor *alternateRowColor=nil;

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
        [image compositeToPoint:NSMakePoint(1.5,0.5) 
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
    // Drawing code here.
    int numberOfItems=[self numberOfItems];
    int i;
    [[NSColor whiteColor] set];
    NSRectFill(rect);
    [NSGraphicsContext saveGraphicsState];
    NSRect bounds=[self bounds];
    NSAffineTransform *transform=[NSAffineTransform transform];
    [transform translateXBy:0 yBy:bounds.origin.y+bounds.size.height-ITEMROWHEIGHT];
    [transform concat];
    transform=[NSAffineTransform transform];
    [transform translateXBy:0 yBy:-1*ITEMROWHEIGHT];
    for (i=0;i<numberOfItems;i++) {
        [self TCM_drawItemAtIndex:i];
        [transform concat];
    }
    [NSGraphicsContext restoreGraphicsState];
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
