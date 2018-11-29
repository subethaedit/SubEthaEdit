#import "DNDArrayController.h"
#import "DocumentModeManager.h"

NSString *MovedRowsType = @"MOVED_ROWS_TYPE";

@implementation DNDArrayController

- (void)awakeFromNib {
    // register for drag and drop
    [tableView registerForDraggedTypes:
     [NSArray arrayWithObjects:MovedRowsType, nil]];
    [tableView setAllowsMultipleSelection:NO];
}



- (BOOL)tableView:(NSTableView *)tv
        writeRows:(NSArray*)rows
     toPasteboard:(NSPasteboard*)pboard {
    // declare our own pasteboard types
    NSArray *typesArray = [NSArray arrayWithObjects:MovedRowsType, nil];
    
    /*
     If the number of rows is not 1, then we only support our own types.
     If there is just one row, then try to create an NSURL from the url
     value in that row.  If that's possible, add NSURLPboardType to the
     list of supported types, and add the NSURL to the pasteboard.
     */
    if ([rows count] != 1) {
        [pboard declareTypes:typesArray owner:self];
    }
    else {
        [pboard declareTypes:typesArray owner:self];
    }
    
    // add rows array for local move
    [pboard setPropertyList:rows forType:MovedRowsType];
    
    return YES;
}


- (NSDragOperation)tableView:(NSTableView*)tv
                validateDrop:(id <NSDraggingInfo>)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)op {
    
    NSDragOperation dragOp = NSDragOperationCopy;
    // if drag source is self, it's a move
    if ([info draggingSource] == tableView)
    {
        dragOp =  NSDragOperationMove;
    }
    // we want to put the object at, not over,
    // the current row (contrast NSTableViewDropOn)
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
    
    return dragOp;
}



- (BOOL)tableView:(NSTableView*)tv
       acceptDrop:(id <NSDraggingInfo>)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)op {
    if (row < 0)
    {
        row = 0;
    }
    
    // if drag source is self, it's a move
    if ([info draggingSource] == tableView)
    {
        NSArray *rows = [[info draggingPasteboard] propertyListForType:MovedRowsType];
        NSIndexSet  *indexSet = [self indexSetFromRows:rows];
        
        [self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];
        
        // set selected rows to those that were just moved
        // Need to work out what moved where to determine proper selection...
        NSInteger rowsAbove = [self rowsAboveRow:row inIndexSet:indexSet];
        
        NSRange range = NSMakeRange(row - rowsAbove, [indexSet count]);
        indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
        [self setSelectionIndexes:indexSet];
        
        [[tableView delegate] tableViewSelectionDidChange:[NSNotification notificationWithName:NSTableViewSelectionDidChangeNotification object:tableView]];
        [[DocumentModeManager sharedInstance] revalidatePrecedences];
        
        return YES;
    }
    
    return NO;
}



- (void)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet*)indexSet
                                        toIndex:(NSUInteger)insertIndex {
    
    NSArray		*objects = [self arrangedObjects];
    NSInteger			index = [indexSet lastIndex];
    
    NSInteger			aboveInsertIndexCount = 0;
    id			object;
    NSInteger			removeIndex;
    
    while (NSNotFound != index) {
        if (index >= insertIndex) {
            removeIndex = index + aboveInsertIndexCount;
            aboveInsertIndexCount += 1;
        }
        else
        {
            removeIndex = index;
            insertIndex -= 1;
        }
        object = [objects objectAtIndex:removeIndex];
        [self removeObjectAtArrangedObjectIndex:removeIndex];
        [self insertObject:object atArrangedObjectIndex:insertIndex];
        
        index = [indexSet indexLessThanIndex:index];
    }
}


- (NSIndexSet *)indexSetFromRows:(NSArray *)rows {
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSNumber *idx;
    for (idx in rows) {
        [indexSet addIndex:[idx intValue]];
    }
    return indexSet;
}


- (NSInteger)rowsAboveRow:(NSInteger)row inIndexSet:(NSIndexSet *)indexSet {
    NSUInteger currentIndex = [indexSet firstIndex];
    NSInteger i = 0;
    while (currentIndex != NSNotFound)
    {
        if (currentIndex < row) { i++; }
        currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
    return i;
}

- (NSUInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return nil;
}

@end
