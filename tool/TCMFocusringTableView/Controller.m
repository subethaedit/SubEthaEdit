#import "Controller.h"
#import "NoHighlightTextFieldCell.h"

@implementation Controller

- (void) awakeFromNib {
    [[[o_tableView tableColumns] objectAtIndex:0] setDataCell:[[NoHighlightTextFieldCell new] autorelease]];


    [o_ArrayController addObject:@"Timbuktu"];
    [o_ArrayController addObject:@"Tokyo"];
    [o_ArrayController addObject:@"Gubbingen"];
    [o_ArrayController addObject:@"Bla bla Bla"];

}

@end
