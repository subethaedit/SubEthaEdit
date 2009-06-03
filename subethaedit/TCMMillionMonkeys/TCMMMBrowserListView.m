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

static NSMutableDictionary *S_itemNameAttributes=nil;
static NSMutableDictionary *S_itemUserNameAttributes=nil;
static NSMutableDictionary *S_itemStatusAttributes=nil;
static NSMutableDictionary *S_childNameAttributes=nil;

+ (void)initialize {
	if (self == [TCMMMBrowserListView class]) {
		static NSMutableParagraphStyle *mNoWrapParagraphStyle = nil;
		static NSMutableParagraphStyle *mNoWrapTruncateRightParagraphStyle = nil;
		if (!mNoWrapParagraphStyle) {
			mNoWrapParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
			[mNoWrapParagraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
			if ([mNoWrapParagraphStyle respondsToSelector:@selector(setTighteningFactorForTruncation:)]) {
				[mNoWrapParagraphStyle setTighteningFactorForTruncation:0.15];
			}
		}
		if (!mNoWrapTruncateRightParagraphStyle) {
			mNoWrapTruncateRightParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
			[mNoWrapTruncateRightParagraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
			if ([mNoWrapTruncateRightParagraphStyle respondsToSelector:@selector(setTighteningFactorForTruncation:)]) {
				[mNoWrapTruncateRightParagraphStyle setTighteningFactorForTruncation:0.15];
			}
		}
		if (!S_itemNameAttributes) {
			S_itemNameAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSFont boldSystemFontOfSize:[NSFont systemFontSize]],NSFontAttributeName,
				mNoWrapParagraphStyle,NSParagraphStyleAttributeName,
				nil] retain];
		}
		if (!S_itemUserNameAttributes) {
			S_itemUserNameAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSFont boldSystemFontOfSize:[NSFont systemFontSize]+4.],NSFontAttributeName,
				mNoWrapParagraphStyle,NSParagraphStyleAttributeName,
				nil] retain];
		}
		if (!S_itemStatusAttributes) {
			S_itemStatusAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
				   [NSFont systemFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName,
				   [NSColor colorWithCalibratedWhite:0.5 alpha:1.0],NSForegroundColorAttributeName,
					mNoWrapTruncateRightParagraphStyle,NSParagraphStyleAttributeName,
				nil] retain];
	
		} 
		if (!S_childNameAttributes) {
			S_childNameAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName,
				mNoWrapParagraphStyle,NSParagraphStyleAttributeName,
				nil] retain];
		}
	}    
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self registerForDraggedTypes:[NSArray arrayWithObjects:@"PresentityNames",@"AIListObject",@"AIListObjectUniqueIDs",nil]];
        I_dragToItem=-1;
    }
    return self;
}


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

#define CHILDBASEINSET 32.
#define CHILDVINSET    -1.

- (void)drawChildWithIndex:(int)aChildIndex ofItemAtIndex:(int)aItemIndex drawBackground:(BOOL)aDrawBackground{

    Class myClass=[self class];
    float childRowHeight  =[myClass childRowHeight];
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
    int inset = [[dataSource listView:self objectValueForTag:TCMMMBrowserChildInsetTag atChildIndex:aChildIndex ofItemAtIndex:aItemIndex] intValue];
    
    NSImage *image=[dataSource listView:self objectValueForTag:TCMMMBrowserChildStatusImageTag atChildIndex:aChildIndex ofItemAtIndex:aItemIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(CHILDBASEINSET+9-(16+2),2+16+CHILDVINSET) 
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
        [image compositeToPoint:NSMakePoint(CHILDBASEINSET+9+inset*16.,2+16+CHILDVINSET) 
                      operation:NSCompositeSourceOver fraction:fraction];
    }
    NSString *string=[dataSource listView:self objectValueForTag:TCMMMBrowserChildNameTag atChildIndex:aChildIndex ofItemAtIndex:aItemIndex];
    [[NSColor blackColor] set];
    if (string) {
        float stringPositionX = CHILDBASEINSET+9+inset*16.+16.+5.;
        [string drawInRect:NSMakeRect(stringPositionX,3.+CHILDVINSET,NSWidth(bounds)-stringPositionX,16.) withAttributes:S_childNameAttributes];
//        [string drawAtPoint:NSMakePoint(32.+9+16.+3.,4.)
//               withAttributes:S_childNameAttributes];
    }
}

- (NSRect)frameForTag:(int)aTag atChildIndex:(int)aChildIndex ofItemAtIndex:(int)anItemIndex {
    if (aTag == TCMMMBrowserItemStatusImageTag) {
        return NSMakeRect(32.+9.,32+1.-13,16.,16.);

//        id dataSource = [self dataSource];
//        float nameXOrigin = 32.+11.;
//        NSImage *browserStatus2Image = [dataSource listView:self objectValueForTag:TCMMMBrowserItemStatusImageOverlayTag atChildIndex:-1 ofItemAtIndex:anItemIndex];
//        if (browserStatus2Image) {
//            nameXOrigin += [browserStatus2Image size].width+2.;
//        }
//        
//        NSString *string=[dataSource listView:self objectValueForTag:TCMMMBrowserItemNameTag atChildIndex:-1 ofItemAtIndex:anItemIndex];
//        NSSize nameSize=[string sizeWithAttributes:S_itemNameAttributes];
//        NSImage *image=[dataSource listView:self objectValueForTag:TCMMMBrowserItemImageNextToNameTag atChildIndex:-1 ofItemAtIndex:anItemIndex];
//        if (image) {
//            NSRect result = NSMakeRect(nameXOrigin+(int)nameSize.width+6.,
//                              (int)(1.+nameSize.height)-(nameSize.height - [image size].height)/3.,
//                              [image size].width+1,
//                              [image size].height);
//            result.origin.x+=result.size.width+6;
//            image=[dataSource listView:self objectValueForTag:TCMMMBrowserItemImageInFrontOfNameTag atChildIndex:-1 ofItemAtIndex:anItemIndex];
//            result.size = [image size];
//            result.origin.y-=result.size.height-3;
//            return result;
//        }
        
    }
    return NSZeroRect;
}

- (void)drawItemAtIndex:(int)aIndex drawBackground:(BOOL)aDrawBackground{

    Class myClass=[self class];
    float itemRowHeight   =[myClass itemRowHeight];
    float actionImagePadding =[myClass actionImagePadding];

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
        [image compositeToPoint:NSMakePoint(4+(32.-[image size].width),32+3) 
                      operation:NSCompositeSourceOver];
    }

    image=[dataSource listView:self objectValueForTag:TCMMMBrowserItemStatusImageOverlayTag atChildIndex:-1 ofItemAtIndex:aIndex];
    if (image) {
        [image compositeToPoint:NSMakePoint(4+32+5-[image size].width,32+3+3) 
                      operation:NSCompositeSourceOver
                       fraction:1.0];
    }

    
    float nameXOrigin = 32.+11.;
    NSImage *browserStatus2Image = [dataSource listView:self objectValueForTag:TCMMMBrowserItemImageInFrontOfNameTag atChildIndex:-1 ofItemAtIndex:aIndex];
    if (browserStatus2Image) {
        [browserStatus2Image compositeToPoint:NSMakePoint(nameXOrigin-2,16.+3.) 
                                   operation:NSCompositeSourceOver];
        //nameXOrigin += [browserStatus2Image size].width+4.;
    }
    nameXOrigin += 16.+3.;
    
    image=[dataSource listView:self objectValueForTag:TCMMMBrowserItemImageNextToNameTag atChildIndex:-1 ofItemAtIndex:aIndex];
    float imageWidth = [image size].width;

    NSString *string=[dataSource listView:self objectValueForTag:TCMMMBrowserItemNameTag atChildIndex:-1 ofItemAtIndex:aIndex];
    [[NSColor blackColor] set];
    NSSize nameSize=[string sizeWithAttributes:S_itemNameAttributes];
    NSRect nameRect = NSMakeRect(nameXOrigin,2.,NSWidth(itemRect)-nameXOrigin-(image?imageWidth+6.:2.),16.);
    if (string) {
        [string drawInRect:nameRect withAttributes:S_itemNameAttributes];
    }

    // this one is right aligned now - and probably soon unused
    if (image) {
        [image compositeToPoint:NSMakePoint(NSMaxX(itemRect)-imageWidth-2.,
                                            (int)(1.+nameSize.height)-(nameSize.height - [image size].height)/3.) 
                      operation:NSCompositeSourceOver];
    }

    string=[dataSource listView:self objectValueForTag:TCMMMBrowserItemUserNameTag atChildIndex:-1 ofItemAtIndex:aIndex];
    [[NSColor blackColor] set];
    
    if (string) {
        nameXOrigin+=3.;
        [string drawInRect:NSMakeRect(nameXOrigin,(32.-18.)/2,NSWidth(itemRect)-nameXOrigin-(image?imageWidth+6.:2.),22.) withAttributes:S_itemUserNameAttributes];
    }

    
//    [[NSColor redColor] set];
//    NSFrameRect([self frameForTag:TCMMMBrowserItemImageNextToNameTag atChildIndex:-1 ofItemAtIndex:aIndex]);
    
    
    NSImage *browserStatusImage = [dataSource listView:self objectValueForTag:TCMMMBrowserItemStatusImageTag atChildIndex:-1 ofItemAtIndex:aIndex];
//    float additionalSpace = 21.;
    if (browserStatusImage) {
        [browserStatusImage compositeToPoint:NSMakePoint(32.+9.,32+1.) 
                                   operation:NSCompositeSourceOver];
    }

//    [[NSColor redColor] set];
//    NSFrameRect([self frameForTag:TCMMMBrowserItemStatusImageTag atChildIndex:-1 ofItemAtIndex:aIndex]);

    
//    NSSize cellSize=[I_disclosureCell cellSize];
//    [I_disclosureCell setState:[[dataSource listView:self objectValueForTag:TCMMMBrowserItemIsDisclosedTag atChildIndex:-1 ofItemAtIndex:aIndex] boolValue]?NSOnState:NSOffState];
//    [I_disclosureCell drawWithFrame:NSMakeRect(32.+11+additionalSpace-2.,21.,cellSize.width,cellSize.height) inView:self];
    string=[dataSource listView:self objectValueForTag:TCMMMBrowserItemStatusTag atChildIndex:-1 ofItemAtIndex:aIndex];
    if (string) {
        [string drawInRect:NSOffsetRect(nameRect,0,18.) withAttributes:S_itemStatusAttributes];
//        [string drawAtPoint:NSMakePoint(32.+9+additionalSpace,20.) //was 32.+27 for with diclosure triangle
//               withAttributes:S_itemStatusAttributes];
    }

    
    if (actionImage) {
        [NSGraphicsContext restoreGraphicsState];
    }
}

#pragma mark === Drag & Drop ===

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
    if (itemIndex!=I_dragToItem) {
        I_dragToItem=itemIndex;
        [self setNeedsDisplay:YES];
    }
}


- (NSDragOperation)validateDrag:(id <NSDraggingInfo>)sender {
    NSDragOperation result = NSDragOperationNone;
    if ([I_delegate respondsToSelector:@selector(listView:validateDrag:)]) {
        result = [I_delegate listView:self validateDrag:sender];
    }
    if (result != NSDragOperationNone) {
        [self highlightItemForDrag:NSNotFound];
    }
    return result;
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
    BOOL result=NO;
    if ([I_delegate respondsToSelector:@selector(listView:prepareForDragOperation:)]) {
        result = [I_delegate listView:self prepareForDragOperation:sender];
    }
    if (!result) {
        [self highlightItemForDrag:-1];
    }
    return result;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    BOOL result=NO;
    if ([I_delegate respondsToSelector:@selector(listView:performDragOperation:)]) {
        result = [I_delegate listView:self performDragOperation:sender];
    }
    [self highlightItemForDrag:-1];
    return result;
}

- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];
    if (I_dragToItem == NSNotFound) {
        [[[NSColor selectedTextBackgroundColor] colorWithAlphaComponent:0.5] set];
        NSScrollView *scrollView=[self enclosingScrollView];
        NSRect niceRect=[[scrollView contentView] documentVisibleRect];
        NSBezierPath *path=[NSBezierPath bezierPathWithRect:NSInsetRect(niceRect,2,2)];
        [path setLineWidth:4.];
        [path setLineJoinStyle:NSRoundLineCapStyle];
        [path stroke];
    } else if (I_dragToItem!=-1) {
        [[[NSColor selectedTextBackgroundColor] colorWithAlphaComponent:0.5] set];
        NSRect niceRect=[self highlightRectForItem:I_dragToItem];
        NSBezierPath *path=[NSBezierPath bezierPathWithRect:NSInsetRect(niceRect,2,2)];
        [path setLineWidth:4.];
        [path setLineJoinStyle:NSRoundLineCapStyle];
        [path stroke];
    }
}

@end
