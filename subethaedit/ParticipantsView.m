//
//  ParticipantsView.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "ParticipantsView.h"

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
    return 22.;
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

- (void)drawItemAtIndex:(int)aItemIndex drawBackground:(BOOL)aDrawBackground{
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


@end
