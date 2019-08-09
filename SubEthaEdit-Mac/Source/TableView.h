//  TableView.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 14.10.04.

#import <Cocoa/Cocoa.h>


@interface TableView : NSTableView

@property (nonatomic, retain) NSColor *lightBackgroundColor;
@property (nonatomic, retain) NSColor *darkBackgroundColor;
@property (nonatomic, assign) BOOL disableFirstRow;

@end
