//
//  ParticipantsView.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>

enum {
    ParticipantsItemStatusImageTag,
    ParticipantsItemNameTag,
    ParticipantsChildImageTag,
    ParticipantsChildNameTag,
    ParticipantsChildImageNextToNameTag,
    ParticipantsChildStatusTag
};



@interface ParticipantsView : NSView
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

- (int)numberOfRows;

/*"Selection Handling"*/
- (int)selectedRow;
- (NSIndexSet *)selectedRowIndexes;
- (void)deselectRow:(int)aRow;
- (int)numberOfSelectedRows;
- (void)selectRow:(int)aRow byExtendingSelection:(BOOL)extend;
- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend;



@end


@interface NSObject(ParticipantsViewDataSourceAdditions)

- (int)numberOfItemsInParticipantsView:(ParticipantsView *)aListView;
- (int)participantsView:(ParticipantsView *)aListView numberOfChildrenOfItemAtIndex:(int)anItemIndex;
- (id)participantsView:(ParticipantsView *)aListView objectValueForTag:(int)aTag ofItemAtIndex:(int)anItemIndex;
- (id)participantsView:(ParticipantsView *)aListView objectValueForTag:(int)aTag atIndex:(int)anIndex ofItemAtIndex:(int)anItemIndex;

@end


@interface NSObject (ParticipantsViewDelegateAdditions)
- (void)participantsViewDidChangeSelection:(ParticipantsView *)alistView;
- (NSMenu *)contextMenuForParticipantsView:(ParticipantsView *)aListView clickedAtRow:(int)aRow;
@end