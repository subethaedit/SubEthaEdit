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
    
    IBOutlet NSPanel *O_addSheetPanel;
    IBOutlet NSTextField *O_addDescriptionField;
    IBOutlet NSTextField *O_addLocalPortField;
    IBOutlet NSTextField *O_addDesiredField;
    IBOutlet NSButton    *O_addProtocolTCPButton;
    IBOutlet NSButton    *O_addProtocolUDPButton;
}

- (IBAction)refresh:(id)aSender;
- (IBAction)addMapping:(id)aSender;
- (IBAction)removeMapping:(id)aSender;
- (IBAction)addMappingEndSheet:(id)aSender;
- (IBAction)addMappingCancelSheet:(id)aSender;
- (IBAction)portTextDidChange:(id)aSender;


@end
