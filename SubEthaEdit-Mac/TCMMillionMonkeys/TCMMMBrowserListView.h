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
    TCMMMBrowserItemUserNameTag,
    TCMMMBrowserItemImageNextToNameTag,
    TCMMMBrowserItemImageInFrontOfNameTag,
    TCMMMBrowserItemStatusTag,
    TCMMMBrowserItemActionImageTag = TCMListViewActionButtonImageTag,
    TCMMMBrowserItemStatusImageTag,
    TCMMMBrowserItemStatusImageOverlayTag,
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
    NSInteger I_dragToItem;
}
- (void)highlightItemForDrag:(NSInteger)itemIndex; // NSNotFound highlights all for drag
- (NSRect)frameForTag:(NSInteger)aTag atChildIndex:(NSInteger)aChildIndex ofItemAtIndex:(NSInteger)anItemIndex;

@end

@interface NSObject (TCMMMBrowserListViewDelegateAdditions)
- (NSDragOperation)listView:(TCMListView *)aListView validateDrag:(id <NSDraggingInfo>)sender;
- (BOOL)listView:(TCMListView *)aListView performDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL)listView:(TCMListView *)aListView prepareForDragOperation:(id <NSDraggingInfo>)sender;
@end