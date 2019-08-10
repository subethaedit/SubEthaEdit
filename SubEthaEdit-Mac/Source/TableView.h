//  TableView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 14.10.04.

#import <Cocoa/Cocoa.h>


@interface TableView : NSTableView

@property (nonatomic, strong) NSColor *lightBackgroundColor;
@property (nonatomic, strong) NSColor *darkBackgroundColor;
@property (nonatomic) BOOL disableFirstRow;

@end
