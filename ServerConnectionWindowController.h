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
#import "EncodingManager.h"

@class ServerManagementProfile;

@interface ServerConnectionWindowController : NSWindowController {
    IBOutlet NSTableView *O_tableView;
    IBOutlet DocumentModePopUpButton *O_modePopUpButton;
    IBOutlet NSTextField *O_newfileNameTextField;
    IBOutlet EncodingPopUpButton *O_encodingPopUpButton;
    IBOutlet NSPopUpButton *O_accessStatePopUpButton;
    IBOutlet NSArrayController *O_remoteFilesController;

    ServerManagementProfile *_profile;
    TCMMMUser *_user;
    TCMBEEPSession *_BEEPSession;
}
- (id)initWithMMUser:(TCMMMUser *)aUser;
- (IBAction)newFile:(id)aSender;
- (IBAction)changeAccessState:(id)aSender;
- (IBAction)changeAnnounced:(id)aSender;

@end
