//
//  RendezvousBrowserController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "TCMRendezvousBrowser.h"

@interface RendezvousBrowserController : NSWindowController {
    NSMutableArray *I_tableData;
    IBOutlet NSTableView *I_tableView;
    TCMRendezvousBrowser *I_browser;
}

-(NSMutableArray *)tableData;
-(void)setTableData:(NSMutableArray *)tableData;

@end
