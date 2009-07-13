//
//  DocumentController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TCMMMSession;
@class EncodingPopUpButton;
@class DocumentModePopUpButton;
@class DocumentMode;
@class PlainTextWindowController;
@class MAAttachedWindow;

@interface DocumentController : NSDocumentController {
    IBOutlet NSView *O_openPanelAccessoryView;
    IBOutlet NSButton *O_goIntoBundlesCheckbox;
    IBOutlet NSButton *O_showHiddenFilesCheckbox;
    IBOutlet EncodingPopUpButton *O_encodingPopUpButton;
    IBOutlet DocumentModePopUpButton *O_modePopUpButton;
    
    IBOutlet NSPanel *O_modeInstallerPanel;
    IBOutlet NSTextField *O_modeInstallerMessageTextField;
    IBOutlet NSMatrix *O_modeInstallerDomainMatrix;
    IBOutlet NSTextField *O_modeInstallerInformativeTextField;
    
    NSOpenPanel *I_openPanel;
    
    BOOL I_isOpeningUntitledDocument;
    BOOL I_isOpeningUsingAlternateMenuItem;
    
    NSStringEncoding I_encodingFromLastRunOpenPanel;
    NSString *I_modeIdentifierFromLastRunOpenPanel;
    NSMutableArray *I_fileNamesFromLastRunOpenPanel;
    
    NSMutableDictionary *I_propertiesForOpenedFiles;
    NSMutableDictionary *I_suspendedSeeScriptCommands;
    NSMutableDictionary *I_refCountsOfSeeScriptCommands;
    NSMutableDictionary *I_waitingDocuments;
    NSMutableArray *I_pipingSeeScriptCommands;
    
    NSString *I_currentModeFileName;
    NSURL *I_locationForNextOpenPanel;
        
    @private
    NSMutableArray *I_documentsWithPendingDisplay;
    NSMutableArray *I_windowControllers;
}

+ (DocumentController *)sharedInstance;

- (NSMenu *)documentMenu;

#if !defined(CODA)
- (IBAction)alwaysShowTabBar:(id)sender;
#endif //!defined(CODA)

- (IBAction)goIntoBundles:(id)sender;
- (IBAction)changeModeInstallationDomain:(id)sender;
- (IBAction)showHiddenFiles:(id)sender;

- (IBAction)installMode:(id)sender;
- (IBAction)cancelModeInstallation:(id)sender;
- (IBAction)openNormalDocument:(id)aSender;
- (IBAction)openAlternateDocument:(id)aSender;

- (void)addProxyDocumentWithSession:(TCMMMSession *)aSession;

- (NSArray *)documentsInMode:(DocumentMode *)aDocumentMode;

- (IBAction)menuValidationNoneAction:(id)aSender;

- (NSStringEncoding)encodingFromLastRunOpenPanel;
- (NSString *)modeIdentifierFromLastRunOpenPanel;
- (BOOL)isDocumentFromLastRunOpenPanel:(NSDocument *)aDocument;
- (NSDictionary *)propertiesForOpenedFile:(NSString *)fileName;

#if defined(CODA)
- (void)setDocumentsFromLastRunOpenPanel:(NSArray*)filenames;
#endif //defined(CODA)

- (BOOL)isOpeningUntitledDocument;
- (void)setIsOpeningUsingAlternateMenuItem:(BOOL)aFlag;
- (BOOL)isOpeningUsingAlternateMenuItem;

- (id)handleOpenScriptCommand:(NSScriptCommand *)command;
- (id)handlePrintScriptCommand:(NSScriptCommand *)command;
- (id)handleSeeScriptCommand:(NSScriptCommand *)command;

- (PlainTextWindowController *)activeWindowController;
- (void)addWindowController:(id)aWindowController;
- (void)removeWindowController:(id)aWindowController;

- (void)updateTabMenu;


@end
