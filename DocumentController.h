//
//  DocumentController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCMMMSession;
@class EncodingPopUpButton;
@class DocumentModePopUpButton;

@interface DocumentController : NSDocumentController {
    IBOutlet NSView *O_openPanelAccessoryView;
    IBOutlet NSButton *O_goIntoBundlesCheckbox;
    IBOutlet EncodingPopUpButton *O_encodingPopUpButton;
    IBOutlet DocumentModePopUpButton *O_modePopUpButton;
    IBOutlet NSPanel *O_modeHintPanel;
    NSOpenPanel *I_openPanel;
    
    BOOL I_isOpeningUntitledDocument;
    
    NSStringEncoding I_encodingFromLastRunOpenPanel;
    NSString *I_modeIdentifierFromLastRunOpenPanel;
    NSMutableArray *I_fileNamesFromLastRunOpenPanel;
    
    NSMutableDictionary *I_propertiesForOpenedFiles;
    NSMutableDictionary *I_suspendedSeeScriptCommands;
    NSMutableDictionary *I_refCountsOfSeeScriptCommands;
    NSMutableDictionary *I_waitingDocuments;
    NSMutableArray *I_pipingSeeScriptCommands;
}

+ (DocumentController *)sharedInstance;

- (IBAction)goIntoBundles:(id)sender;

- (void)addProxyDocumentWithSession:(TCMMMSession *)aSession;

- (NSStringEncoding)encodingFromLastRunOpenPanel;
- (NSString *)modeIdentifierFromLastRunOpenPanel;
- (BOOL)isDocumentFromLastRunOpenPanel:(NSDocument *)aDocument;
- (NSDictionary *)propertiesForOpenedFile:(NSString *)fileName;

- (BOOL)isOpeningUntitledDocument;

- (id)handleOpenScriptCommand:(NSScriptCommand *)command;
- (id)handlePrintScriptCommand:(NSScriptCommand *)command;
- (id)handleSeeScriptCommand:(NSScriptCommand *)command;

@end
