//
//  UserStatisticsController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 21.08.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HUDStatisticGraphView;

@interface UserStatisticsController : NSWindowController {
    IBOutlet NSImageView *O_documentImageView;
    IBOutlet NSTextField *O_documentNameTextField;
    IBOutlet NSTextField *O_wordCountTextField;
    IBOutlet NSTableView *O_userTableView;
    IBOutlet HUDStatisticGraphView *O_graphView;
    IBOutlet NSArrayController *O_statEntryArrayController;
    IBOutlet NSObjectController *O_loggingStateObjectController;
    IBOutlet NSObjectController *O_documentObjectController;
    IBOutlet NSButton *O_percentageButton;
    BOOL I_wordCountUpdateScheduled;
}

- (IBAction)togglePercentage:(id)aSender;

@end
