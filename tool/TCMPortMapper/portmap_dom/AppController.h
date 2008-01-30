//
//  AppController.h
//  PortMap
//
//  Created by Dominik Wagner on 25.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
    IBOutlet NSTextField *O_currentIPTextField;
    IBOutlet NSTextField *O_taglineTextField;
    IBOutlet NSTableView *O_portMappingsTableView;
    IBOutlet NSArrayController *O_mappingsArrayController;
    IBOutlet NSProgressIndicator *O_globalProgressIndicator;
    IBOutlet NSButton    *O_refreshButton;
}

- (IBAction)refresh:(id)aSender;

@end
