//
//  TCMMMBrowserListView.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMBrowserListView.h"


@interface TCMMMBrowserListView (TCMBrowserListViewPrivateAdditions)
@end

#pragma mark -

@implementation TCMMMBrowserListView

+ (float)itemRowHeight {
    return 38.;
}
+ (float)childRowHeight {
    return 20.;
}
+ (float)itemRowGapHeight {
    return 0.;
}
+ (float)actionImagePadding {
    return 4.;
}

- (void)drawChildWithIndex:(int)aChildIndex ofItemAtIndex:(int)aItemIndex drawBackground:(BOOL)aDrawBackground{
    static NSMutableParagraphStyle *mNoWrapParagraphStyle = nil;
    if (!mNoWrapParagraphStyle) {
        mNoWrapParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [mNoWrapParagraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
        if ([mNoWrapParagraphStyle respondsToSelector:@selector(setTighteningFactorForTruncation:)]) {
            [mNoWrapParagraphStyle setTighteningFactorForTruncation:0.15];
        }
    }

    Class myClass=[self class];
    float childRowHeight  =[myClass childRowHeight];

    static NSMutableDictionary *mNameAttributes=nil;
    if (!mNameAttributes) {
        mNameAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSFont systemFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName,mNoWrapParagraphStyle,NSParagraphStyleAttributeName,nil] retain];
    }
    NSRect bounds=[self bounds];
    NSRect childRect=NSMakeRect(0, 0,bounds.size.width, childRowHeight);
    if (aDrawBackground) {
        if (aItemIndex%2) {
            [[myClass alternateRowColor] set];
        } else {
            [[NSColor whiteColor] set];
        }
        if ([[self selectedRowIndexes] containsIndex:[self rowForItem:aItemIndex child:aChildIndex]]) {
            [[NSColor selectedTextBackgroundColor] set];
        }    
        NSRectFill(childRect);
    }    
    id dataSource=[self dataSource];
    
    NSImage *image=[dataSource listView:self objectValueForTag:TCMMMBrowserChildStatusImageTag atChildIndex:aChildIndex ofItemAtIndex:aItemIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(32.+9-(16+2),2+16) 
                      operation:NSCompositeSourceOver];
    }

    image=[dataSource listView:self objectValueForTag:TCMMMBrowserChildIconImageTag atChildIndex:aChildIndex ofItemAtIndex:aItemIndex];
    if (image) {
        NSNumber *number=[dataSource listView:self objectValueForTag:TCMMMBrowserChildClientStatusTag atChildIndex:aChildIndex ofItemAtIndex:aItemIndex];
        float fraction=1.0;
        if (number) {
            int status=[number intValue];
            if (status==0) fraction=.5;
            else if (status<3) fraction=.75;
            else fraction=1.0;
        }
        [image compositeToPoint:NSMakePoint(32.+9,2+16) 
                      operation:NSCompositeSourceOver fraction:fraction];
    }
    NSString *string=[dataSource listView:self objectValueForTag:TCMMMBrowserChildNameTag atChildIndex:aChildIndex ofItemAtIndex:aItemIndex];
    [[NSColor blackColor] set];
    if (string) {
        [string drawInRect:NSMakeRect(32.+9+16.+3.,4.,NSWidth(bounds)-(32.+9+16+3+5),16.) withAttributes:mNameAttributes];
//        [string drawAtPoint:NSMakePoint(32.+9+16.+3.,4.)
//               withAttributes:mNameAttributes];
    }
}

- (void)drawItemAtIndex:(int)aIndex drawBackground:(BOOL)aDrawBackground{

    Class myClass=[self class];
    float itemRowHeight   =[myClass itemRowHeight];
    float actionImagePadding =[myClass actionImagePadding];

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
    NSRect itemRect=NSMakeRect(0, 0,bounds.size.width, itemRowHeight);
    if (aDrawBackground) {
        if ([I_selectedRows containsIndex:[self rowForItem:aIndex child:-1]]) {
            [[NSColor selectedTextBackgroundColor] set];
        } else if (aIndex%2) {
            [[myClass alternateRowColor] set];
        } else {
            [[NSColor whiteColor] set];
        }
        NSRectFill(itemRect);
    }

    id dataSource=[self dataSource];

    NSImage *actionImage=[dataSource listView:self objectValueForTag:TCMMMBrowserItemActionImageTag atChildIndex:-1 ofItemAtIndex:aIndex];
    if (actionImage) {
        [NSGraphicsContext saveGraphicsState];
        NSSize actionSize=[actionImage size];
        [actionImage compositeToPoint:NSMakePoint(itemRect.size.width-actionImagePadding-actionSize.width,(int)(itemRowHeight-(itemRowHeight-actionSize.height)/2.))
                     operation:NSCompositeSourceOver];
        itemRect.size.width-=actionImagePadding+actionSize.width+actionImagePadding;
        NSRectClip(itemRect);
    }
    
    NSImage *image=[dataSource listView:self objectValueForTag:TCMMMBrowserItemImageTag atChildIndex:-1 ofItemAtIndex:aIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(4,32+3) 
                      operation:NSCompositeSourceOver];
    }
    
    float nameXOrigin = 32.+11.;
    NSImage *browserStatus2Image = [dataSource listView:self objectValueForTag:TCMMMBrowserItemStatus2ImageTag atChildIndex:-1 ofItemAtIndex:aIndex];
    if (browserStatus2Image) {
        [browserStatus2Image compositeToPoint:NSMakePoint(nameXOrigin-1.,10.+[browserStatus2Image size].height/2.) 
                                   operation:NSCompositeSourceOver];
        nameXOrigin += [browserStatus2Image size].width+2.;
    }
    
    NSString *string=[dataSource listView:self objectValueForTag:TCMMMBrowserItemNameTag atChildIndex:-1 ofItemAtIndex:aIndex];
    [[NSColor blackColor] set];
    if (string) {
        [string drawAtPoint:NSMakePoint(nameXOrigin,2.)
               withAttributes:mNameAttributes];
    }
    NSSize nameSize=[string sizeWithAttributes:mNameAttributes];
    image=[dataSource listView:self objectValueForTag:TCMMMBrowserItemImageNextToNameTag atChildIndex:-1 ofItemAtIndex:aIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(nameXOrigin+(int)nameSize.width+6.,
                                            (int)(1.+nameSize.height)-(nameSize.height - [image size].height)/3.) 
                      operation:NSCompositeSourceOver];
    }
    
    
//    NSSize cellSize=[I_disclosureCell cellSize];
//    [I_disclosureCell drawWithFrame:NSMakeRect(32.+10,20.,cellSize.width,cellSize.height) inView:self];
    NSImage *browserStatusImage = [dataSource listView:self objectValueForTag:TCMMMBrowserItemStatusImageTag atChildIndex:-1 ofItemAtIndex:aIndex];
    float additionalSpace = 0.;
    if (browserStatusImage) {
        [browserStatusImage compositeToPoint:NSMakePoint(32.+10,32+3) 
                                   operation:NSCompositeSourceOver];
        additionalSpace += [browserStatusImage size].width + 4.;
    }
    
    string=[dataSource listView:self objectValueForTag:TCMMMBrowserItemStatusTag atChildIndex:-1 ofItemAtIndex:aIndex];
    if (string) {
        [string drawAtPoint:NSMakePoint(32.+11+additionalSpace,21.) //was 32.+27 for with diclosure triangle
               withAttributes:mStatusAttributes];
    }
    
    if (actionImage) {
        [NSGraphicsContext restoreGraphicsState];
    }
}


@end
