@import Cocoa;

@interface DNDArrayController : NSArrayController {
    IBOutlet __weak NSTableView *tableView;
}

// table view drag and drop support

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard;

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op;

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op;

// utility methods
- (void)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet *)indexSet
                                        toIndex:(NSUInteger)index;

- (NSIndexSet *)indexSetFromRows:(NSArray *)rows;
- (NSInteger)rowsAboveRow:(NSInteger)row inIndexSet:(NSIndexSet *)indexSet;

@end
