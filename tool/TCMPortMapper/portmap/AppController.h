//
//  AppController.h
//
//  Copyright (c) 2007-2008 TheCodingMonkeys: 
//  Martin Pittenauer, Dominik Wagner, <http://codingmonkeys.de>
//  Some rights reserved: <http://opensource.org/licenses/mit-license.php> 
//

#import <Cocoa/Cocoa.h>


@interface AppController : NSObject {
    IBOutlet NSTextField *O_currentIPTextField;
    IBOutlet NSTextField *O_taglineTextField;
    IBOutlet NSTableView *O_portMappingsTableView;
    IBOutlet NSArrayController *O_mappingsArrayController;
    IBOutlet NSProgressIndicator *O_globalProgressIndicator;
    IBOutlet NSButton    *O_refreshButton;
    IBOutlet NSView *O_invalidLocalPortView;
    IBOutlet NSView *O_invalidDesiredPortView;
    IBOutlet NSTextField *O_replacedReferenceStringTextField;
    
    IBOutlet NSWindow *O_addSheetPanel;
    IBOutlet NSTextField *O_addDescriptionField;
    IBOutlet NSTextField *O_addLocalPortField;
    IBOutlet NSTextField *O_addDesiredField;
    IBOutlet NSButton    *O_addProtocolTCPButton;
    IBOutlet NSButton    *O_addProtocolUDPButton;
    IBOutlet NSPopUpButton *O_addPresetPopupButton;
    IBOutlet NSTextField *O_addReferenceStringField;
    
    IBOutlet NSWindow *O_showUPNPMappingListWindow;
    IBOutlet NSArrayController *O_UPNPMappingListArrayController;
    IBOutlet NSTextField *O_localIPAddressTextField;
    IBOutlet NSButton *O_showUPNPMappingTableButton;
    IBOutlet NSTabViewItem *O_upnpMappingListTabItem;
    IBOutlet NSTabViewItem *O_progressIndictatorTabItem;
    IBOutlet NSProgressIndicator *O_UPNPTabItemProgressIndicator;

	IBOutlet NSWindow *O_instructionalSheetPanel;
    IBOutlet NSButton *O_dontShowInstructionsAgainButton;
    IBOutlet NSWindow *O_aboutWindow;
    
    IBOutlet NSTextField *O_aboutVersionLineTextField;
}

- (IBAction)togglePortMapper:(id)aSender;

- (IBAction)refresh:(id)aSender;
- (IBAction)addMapping:(id)aSender;
- (IBAction)removeMapping:(id)aSender;
- (IBAction)addMappingEndSheet:(id)aSender;
- (IBAction)addMappingCancelSheet:(id)aSender;
- (IBAction)choosePreset:(id)aSender;
- (IBAction)showInstructionalPanel:(id)aSender;
- (IBAction)endInstructionalSheet:(id)aSender;

- (IBAction)gotoPortMapHomepage:(id)aSender;
- (IBAction)gotoTCMPortMapperSources:(id)aSender;
- (IBAction)reportABug:(id)aSender;

- (IBAction)showAbout:(id)aSender;

- (IBAction)requestUPNPMappingTable:(id)aSender;
- (IBAction)requestUPNPMappingTableRemoveMappings:(id)aSender;
- (IBAction)requestUPNPMappingTableOKSheet:(id)aSender;

@end
