//
//  TCMMMBrowserListView.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "TCMListView.h"

enum {
    TCMMMBrowserItemImageTag,
    TCMMMBrowserItemNameTag,
    TCMMMBrowserItemImageNextToNameTag,
    TCMMMBrowserItemImage2NextToNameTag,
    TCMMMBrowserItemStatusTag,
    TCMMMBrowserItemActionImageTag = TCMListViewActionButtonImageTag,
    TCMMMBrowserItemStatusImageTag,
    TCMMMBrowserItemStatus2ImageTag,
    TCMMMBrowserItemIsDisclosedTag,
    TCMMMBrowserChildIsDisclosedTag,
    TCMMMBrowserChildIconImageTag,
    TCMMMBrowserChildNameTag,
    TCMMMBrowserChildStatusImageTag,
    TCMMMBrowserChildActionImageTag,
    TCMMMBrowserChildClientStatusTag,
    TCMMMBrowserChildInsetTag
};

@interface TCMMMBrowserListView : TCMListView {
    int I_dragToItem;
}
- (void)highlightItemForDrag:(int)itemIndex; // NSNotFound highlights all for drag
- (NSRect)frameForTag:(int)aTag atChildIndex:(int)aChildIndex ofItemAtIndex:(int)anItemIndex;

@end

@interface NSObject (TCMMMBrowserListViewDelegateAdditions)
- (NSDragOperation)listView:(TCMListView *)aListView validateDrag:(id <NSDraggingInfo>)sender;
- (BOOL)listView:(TCMListView *)aListView performDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL)listView:(TCMListView *)aListView prepareForDragOperation:(id <NSDraggingInfo>)sender;
@end