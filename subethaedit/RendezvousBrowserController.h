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
    IBOutlet NSImageView *I_imageView;
    IBOutlet NSTextField *I_myNameTextField;
    TCMRendezvousBrowser *I_browser;
    NSMutableSet *I_foundUserIDs;
}

-(NSMutableArray *)tableData;
-(void)setTableData:(NSMutableArray *)tableData;
- (IBAction)setVisibilityByPopUpButton:(id)aSender;

@end
