//
//  TCMListView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon May 10 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>

extern NSString *ListViewDidChangeSelectionNotification;

#define TCMListViewActionButtonImageTag 9999

@interface TCMListView : NSView
{
    NSButtonCell *I_disclosureCell;
    id I_dataSource;
    id I_delegate;
    int I_clickedRow;
    id I_target;
    SEL I_action;
    SEL I_doubleAction;
    int I_actionRow;
    
    
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

+ (float)itemRowHeight;
+ (float)childRowHeight;
+ (float)itemRowGapHeight;
+ (float)actionImagePadding;
+ (NSColor *)alternateRowColor;

- (void)drawChildWithIndex:(int)aChildIndex ofItemAtIndex:(int)aItemIndex drawBackground:(BOOL)aDrawBackground;
- (void)drawItemAtIndex:(int)aItemIndex drawBackground:(BOOL)aDrawBackground;


- (NSRect)rectForItem:(int)anItemIndex child:(int)aChildIndex;
- (NSRect)rectForRow:(int)aRow;


- (void)setDataSource:(id)aDataSource;
- (id)dataSource;
- (void)setDelegate:(id)aDelegate;
- (id)delegate;
- (void)setTarget:(id)aTarget;
- (void)setAction:(SEL)anAction;
- (void)setDoubleAction:(SEL)anAction;
- (int)clickedRow;
- (int)actionRow;
- (ItemChildPair)itemChildPairAtRow:(int)aIndex;
- (int)rowForItem:(int)anItemIndex child:(int)aChildIndex;
- (void)reloadData;
- (int)numberOfItems;
- (int)numberOfChildrenOfItemAtIndex:(int)aIndex;
- (void)noteEnclosingScrollView;
- (void)resizeToFit;

- (int)numberOfRows;

/*"Selection Handling"*/
- (int)selectedRow;
- (NSIndexSet *)selectedRowIndexes;
- (void)deselectRow:(int)aRow;
- (int)numberOfSelectedRows;
- (void)selectRow:(int)aRow byExtendingSelection:(BOOL)extend;
- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend;

@end


@interface NSObject(ListViewDataSourceAdditions)
- (int)listView:(TCMListView *)aListView numberOfEntriesOfItemAtIndex:(int)anItemIndex;
- (id) listView:(TCMListView *)aListView objectValueForTag:(int)aTag atChildIndex:(int)anIndex ofItemAtIndex:(int)anItemIndex;
- (NSString *)listView:(TCMListView *)aListView toolTipStringAtChildIndex:(int)anIndex ofItemAtIndex:(int)anItemIndex;
- (BOOL)listView:(TCMListView *)listView writeRows:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pboard;
@end


@interface NSObject (ListViewDelegateAdditions)
- (void)participantsViewDidChangeSelection:(TCMListView *)alistView;
- (NSMenu *)contextMenuForListView:(TCMListView *)aListView clickedAtRow:(int)aRow;
@end