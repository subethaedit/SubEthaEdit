//
//  ServerConnectionWindowController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 26.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DocumentModeManager.h"
#import "TCMBEEP.h"
#import "TCMMillionMonkeys.h"

@interface ServerConnectionWindowController : NSWindowController {
    IBOutlet NSTableView *O_tableView;
    IBOutlet DocumentModePopUpButton *O_modePopUpButton;
    IBOutlet NSTextField *O_newfileNameTextField;

    TCMMMUser *_user;
    TCMBEEPSession *_BEEPSession;
}
- (id)initWithMMUser:(TCMMMUser *)aUser;
- (IBAction)newFile:(id)aSender;

@end
