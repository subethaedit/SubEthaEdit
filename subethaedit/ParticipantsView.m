//
//  ParticipantsView.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "ParticipantsView.h"
#import "PlainTextDocument.h"
#import "TCMMMSession.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMBEEPSessionManager.h"

@interface ParticipantsView (ParticipantsViewPrivateAdditions)
@end

#pragma mark -

@implementation ParticipantsView

// override this in sublcasses
+ (float)itemRowHeight {
    return 22.;
}
+ (float)childRowHeight {
    return 38.;
}
+ (float)itemRowGapHeight {
    return 11.;
}

- (void)setDocument:(PlainTextDocument *)aDocument {
    I_document=aDocument;
}

- (PlainTextDocument *)document {
    return I_document;
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self registerForDraggedTypes:[NSArray arrayWithObject:@"PboardTypeTBD"]];
        I_dragToItem=-1;
    }
    return self;
}

- (void)drawChildWithIndex:(int)aChildIndex ofItemAtIndex:(int)aItemIndex drawBackground:(BOOL)aDrawBackground {
    Class myClass=[self class];
    float childRowHeight  =[myClass childRowHeight];

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
    NSRect childRect=NSMakeRect(0, 0,bounds.size.width, childRowHeight);

    if (aDrawBackground) {
        [[NSColor whiteColor] set];
        BOOL selected=[I_selectedRows containsIndex:[self rowForItem:aItemIndex child:aChildIndex]];
        if (selected) {
            [[NSColor selectedTextBackgroundColor] set];
        }    
        NSRectFill(childRect);
    }
    
    id dataSource=[self dataSource];
    
    NSImage *image=[dataSource listView:self objectValueForTag:ParticipantsChildImageTag atChildIndex:aChildIndex ofItemAtIndex:aItemIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(4,32+3) 
                      operation:NSCompositeSourceOver];
    }
    NSString *string=[dataSource listView:self objectValueForTag:ParticipantsChildNameTag atChildIndex:aChildIndex ofItemAtIndex:aItemIndex];
    [[NSColor blackColor] set];
    if (string) {
        [string drawAtPoint:NSMakePoint(32.+11.,1.)
                withAttributes:mNameAttributes];
    }
    NSSize nameSize=[string sizeWithAttributes:mNameAttributes];
    image=[dataSource listView:self objectValueForTag:ParticipantsChildImageNextToNameTag atChildIndex:aChildIndex ofItemAtIndex:aItemIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(32.+11.+(int)nameSize.width+6.,
                                            (int)(1.+nameSize.height)-(nameSize.height - [image size].height)/3.) 
                      operation:NSCompositeSourceOver];
    }
    
    NSAttributedString *attributedString=[dataSource listView:self objectValueForTag:ParticipantsChildStatusTag atChildIndex:aChildIndex ofItemAtIndex:aItemIndex];
    if (attributedString) {
        [attributedString drawAtPoint:NSMakePoint(32.+11,20.)];
    }
}

- (void)drawItemAtIndex:(int)aItemIndex drawBackground:(BOOL)aDrawBackground {
    Class myClass=[self class];
    float itemRowHeight   =[myClass itemRowHeight];
    static NSMutableDictionary *mNameAttributes=nil;
    if (!mNameAttributes) {
        mNameAttributes = [[NSMutableDictionary dictionaryWithObject:
            [NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName] retain];
        [mNameAttributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    }
    NSRect bounds=[self bounds];
    NSRect itemRect=NSMakeRect(0, 0,bounds.size.width, itemRowHeight);
    NSImage *fillImage=[NSImage imageNamed:@"ParticipantBar_Fill"];
    [fillImage setFlipped:YES];
    [fillImage drawInRect:itemRect fromRect:NSMakeRect(0,0,[fillImage size].width,[fillImage size].height) operation:NSCompositeCopy fraction:1.0];
    [[NSColor lightGrayColor] set];
    itemRect.size.height-=1;
    NSFrameRect(itemRect);
    
    id dataSource=[self dataSource];
    
    NSImage *image=[dataSource listView:self objectValueForTag:ParticipantsItemStatusImageTag atChildIndex:-1 ofItemAtIndex:aItemIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(12,2+16) 
                      operation:NSCompositeSourceOver];
    }

    NSString *string=[dataSource listView:self objectValueForTag:ParticipantsItemNameTag atChildIndex:-1 ofItemAtIndex:aItemIndex];
    [[NSColor whiteColor] set];
    if (string) {
        [string drawAtPoint:NSMakePoint(16.+9+16.+3.,3.)
               withAttributes:mNameAttributes];
    }

}

#pragma mark -
#pragma mark ### drag & drop ###

- (NSRect)highlightRectForItem:(int)itemIndex {
    NSRect itemRect=[self rectForItem:I_dragToItem child:-1];
    float height=1.;
    if (itemIndex != [self numberOfItems]-1) {
        NSRect nextItemRect=[self rectForItem:I_dragToItem+1 child:-1];
        height=nextItemRect.origin.y-NSMaxY(itemRect)-1;
    } else {
        NSScrollView *scrollView=[self enclosingScrollView];
        NSRect documentVisibleRect=[[scrollView contentView] documentVisibleRect];
        height=NSMaxY(documentVisibleRect)-NSMaxY(itemRect);
    }
    return NSMakeRect(itemRect.origin.x,NSMaxY(itemRect),itemRect.size.width,height);
}

- (void)highlightItemForDrag:(int)itemIndex {
    if (itemIndex==-1) {
        if (I_dragToItem!=-1) {
            [self setNeedsDisplayInRect:[self highlightRectForItem:I_dragToItem]];
        }
        I_dragToItem=-1;
        [self setNeedsDisplay:YES];
    } else {
        if (itemIndex!=I_dragToItem) {
            if (I_dragToItem!=-1) {
                [self setNeedsDisplayInRect:[self highlightRectForItem:I_dragToItem]];
            }
            I_dragToItem=itemIndex;
            [self setNeedsDisplayInRect:[self highlightRectForItem:I_dragToItem]];
        }
    }
}

- (int)targetItemForDragPoint:(NSPoint)aPoint {
    int count=[self numberOfItems];
    int i=1;
    for (i=1;i<count;i++) {
        NSRect itemRect=[self rectForItem:i child:-1];
        if (itemRect.origin.y>aPoint.y) return i-1;
    }
    return i-1;
}

- (NSDragOperation)validateDrag:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:@"PboardTypeTBD"]) {
        NSPoint draggingLocation=[self convertPoint:[sender draggingLocation] fromView:nil];
        int itemIndex=[self targetItemForDragPoint:draggingLocation];
        if (itemIndex<2) {
            [self highlightItemForDrag:itemIndex];
            return NSDragOperationGeneric;
        } 
    }
    [self highlightItemForDrag:-1];
    return NSDragOperationNone;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return [self validateDrag:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    [self highlightItemForDrag:-1];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    return [self validateDrag:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    BOOL result=NO;
    if ([[pboard types] containsObject:@"PboardTypeTBD"]) {
        TCMMMSession *session=[[self document] session];
        //NSLog(@"prepareForDragOperation:");
        result = [session isServer];
    }
    if (!result) {
        [self highlightItemForDrag:-1];
    }
    return result;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:@"PboardTypeTBD"]) {
        NSArray *userArray=[pboard propertyListForType:@"PboardTypeTBD"];
        PlainTextDocument *document=[self document];
        TCMMMSession *session=[document session];
        NSEnumerator *userDescriptions=[userArray objectEnumerator];
        NSDictionary *userDescription=nil;
        while ((userDescription=[userDescriptions nextObject])) {
            TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:[userDescription objectForKey:@"UserID"]];
            if (user) {
                TCMBEEPSession *BEEPSession=[[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:[user userID] URLString:[userDescription objectForKey:@"URLString"]];
                [session inviteUser:user intoGroup:I_dragToItem==0?@"ReadWrite":@"ReadOnly" usingBEEPSession:BEEPSession];
            }
        }
        [self highlightItemForDrag:-1];
        return YES;
    } 
    [self highlightItemForDrag:-1];
    return NO;
}


- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];
    if (I_dragToItem!=-1) {
        [[NSColor selectedTextBackgroundColor] set];
        NSRect niceRect=[self highlightRectForItem:I_dragToItem];
        NSBezierPath *path=[NSBezierPath bezierPathWithRect:NSInsetRect(niceRect,2,2)];
        [path setLineWidth:4.];
        [path setLineJoinStyle:NSRoundLineCapStyle];
        [path stroke];
        NSFrameRect(niceRect);
    }
}

@end
