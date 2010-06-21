//
//  TCMListView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon May 10 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>

extern NSString *ListViewDidChangeSelectionNotification;

#define TCMListViewActionButtonImageTag 9999

typedef struct _ItemChildPair {
    int itemIndex;
    int childIndex;
} ItemChildPair;


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
    NSPasteboard *I_currentDragPasteboard;
    
    // Selection
    NSInteger I_selectedRow;
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
    NSAttributedString *I_emptySpaceString;
}

+ (float)itemRowHeight;
+ (float)childRowHeight;
+ (float)itemRowGapHeight;
+ (float)actionImagePadding;
+ (NSColor *)alternateRowColor;

- (void)drawChildWithIndex:(NSInteger)aChildIndex ofItemAtIndex:(NSInteger)aItemIndex drawBackground:(BOOL)aDrawBackground;
- (void)drawItemAtIndex:(NSInteger)aItemIndex drawBackground:(BOOL)aDrawBackground;

- (NSInteger)indexOfRowAtPoint:(NSPoint)aPoint;
- (NSRect)rectForItem:(NSInteger)anItemIndex child:(NSInteger)aChildIndex;
- (NSRect)rectForRow:(NSInteger)aRow;


- (void)setDataSource:(id)aDataSource;
- (id)dataSource;
- (void)setDelegate:(id)aDelegate;
- (id)delegate;
- (void)setTarget:(id)aTarget;
- (void)setAction:(SEL)anAction;
- (void)setDoubleAction:(SEL)anAction;
- (NSInteger)clickedRow;
- (NSInteger)actionRow;
- (ItemChildPair)itemChildPairAtRow:(NSInteger)aIndex;
- (NSInteger)rowForItem:(NSInteger)anItemIndex child:(NSInteger)aChildIndex;

- (void)setNeedsDisplayForItem:(NSInteger)aItemIndex;
- (void)setNeedsDisplayForItem:(NSInteger)aItemIndex child:(NSInteger)aChildIndex;

- (void)reloadData;
- (NSInteger)numberOfItems;
- (NSInteger)numberOfChildrenOfItemAtIndex:(NSInteger)aIndex;
- (void)noteEnclosingScrollView;
- (void)resizeToFit;
- (NSPasteboard *)currentDraggingPasteboard;
- (NSInteger)numberOfRows;

- (void)setEmptySpaceString:(NSAttributedString *)aEmptySpaceString;

/*"Selection Handling"*/
- (NSInteger)selectedRow;
- (NSIndexSet *)selectedRowIndexes;
- (void)deselectAll:(id)aSender;
- (void)deselectRow:(NSInteger)aRow;
- (NSInteger)numberOfSelectedRows;
- (void)selectRow:(NSInteger)aRow byExtendingSelection:(BOOL)extend;
- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend;
- (void)reduceSelectionToChildren;

@end


@interface NSObject(ListViewDataSourceAdditions)
- (NSInteger)listView:(TCMListView *)aListView numberOfEntriesOfItemAtIndex:(NSInteger)anItemIndex;
- (id) listView:(TCMListView *)aListView objectValueForTag:(NSInteger)aTag atChildIndex:(NSInteger)anIndex ofItemAtIndex:(NSInteger)anItemIndex;
- (NSString *)listView:(TCMListView *)aListView toolTipStringAtChildIndex:(NSInteger)anIndex ofItemAtIndex:(NSInteger)anItemIndex;
- (BOOL)listView:(TCMListView *)listView writeRows:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pboard;
@end


@interface NSObject (ListViewDelegateAdditions)
- (void)participantsViewDidChangeSelection:(TCMListView *)alistView;
- (NSMenu *)contextMenuForListView:(TCMListView *)aListView clickedAtRow:(NSInteger)aRow;
- (BOOL)listView:(TCMListView *)aListView performActionForClickAtPoint:(NSPoint)aPoint atItemChildPair:(ItemChildPair)aPair;
@end