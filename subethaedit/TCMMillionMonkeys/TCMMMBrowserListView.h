//
//  TCMMMBrowserListView.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>

enum {
    TCMMMBrowserItemImageTag,
    TCMMMBrowserItemNameTag,
    TCMMMBrowserItemStatusTag,
    TCMMMBrowserItemActionImageTag,
    TCMMMBrowserChildIconImageTag,
    TCMMMBrowserChildNameTag,
    TCMMMBrowserChildStatusImageTag,
    TCMMMBrowserChildActionImageTag
};

typedef struct _ItemChildPair {
    int itemIndex;
    int childIndex;
} ItemChildPair;



@interface TCMMMBrowserListView : NSView
{
    NSBezierPath *I_itemSelectionPath;
    NSButtonCell *I_disclosureCell;
    id I_dataSource;
    id I_delegate;
    int I_clickedRow;
    id I_target;
    SEL I_action;
    SEL I_doubleAction;
    
    
    // Selection
    int I_selectedRow;
    NSMutableIndexSet *I_selectedRows;
    
    // indices
    BOOL I_indicesNeedRebuilding;
    int  I_indexNumberOfItems;
    int *I_indexNumberOfChildren;
    int *I_indexRowAtItem;
    ItemChildPair *I_indexItemChildPairAtRow;
    float I_indexMaxHeight;
    NSRange *I_indexYRangesForItem;
    int I_indexNumberOfRows;
}

- (void)setDataSource:(id)aDataSource;
- (id)dataSource;
- (void)setDelegate:(id)aDelegate;
- (id)delegate;
- (void)setTarget:(id)aTarget;
- (void)setAction:(SEL)anAction;
- (void)setDoubleAction:(SEL)anAction;
- (int)clickedRow;
- (ItemChildPair)itemChildPairAtRow:(int)aIndex;
- (int)rowForItem:(int)anItemIndex child:(int)aChildIndex;
- (void)reloadData;
- (int)numberOfItems;
- (int)numberOfChildrenOfItemAtIndex:(int)aIndex;
- (void)noteEnclosingScrollView;
- (void)resizeToFit;

/*"Selection Handling"*/
- (int)selectedRow;
- (NSIndexSet *)selectedRowIndexes;
- (void)deselectRow:(int)aRow;
- (int)numberOfSelectedRows;
- (void)selectRow:(int)aRow byExtendingSelection:(BOOL)extend;
- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend;



@end


@interface NSObject(TCMMMBrowserListViewDataSourceAdditions)

- (int)numberOfItemsInListView:(TCMMMBrowserListView *)aListView;
- (int)listView:(TCMMMBrowserListView *)aListView numberOfChildrenOfItemAtIndex:(int)anItemIndex;
- (BOOL)listView:(TCMMMBrowserListView *)aListView isItemExpandedAtIndex:(int)anItemIndex;
- (void)listView:(TCMMMBrowserListView *)aListView setExpanded:(BOOL)isExpanded itemAtIndex:(int)anItemIndex;
- (id)listView:(TCMMMBrowserListView *)aListView objectValueForTag:(int)aTag ofItemAtIndex:(int)anItemIndex;
- (id)listView:(TCMMMBrowserListView *)aListView objectValueForTag:(int)aTag atIndex:(int)anIndex ofItemAtIndex:(int)anItemIndex;

@end


@interface NSObject (TCMMMBrowserListViewDelegateAdditions)

@end