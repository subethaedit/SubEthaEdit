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
}

- (void)setDataSource:(id)aDataSource;
- (id)dataSource;
- (void)setDelegate:(id)aDelegate;
- (id)delegate;
- (void)setTarget:(id)aTarget;
- (void)setAction:(SEL)anAction;
- (void)setDoubleAction:(SEL)anAction;

- (int)clickedRow;

- (void)reloadData;
- (int)numberOfItems;
- (int)numberOfChildrenOfItemAtIndex:(int)aIndex;
- (void)noteEnclosingScrollView;
- (void)resizeToFit;

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