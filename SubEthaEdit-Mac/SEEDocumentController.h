//
//  SEEDocumentController.h
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
@class PlainTextDocument;


extern NSString *const RecentDocumentsDidChangeNotification;

extern NSString * const kSEETypeSEEText;
extern NSString * const kSEETypeSEEMode;

@interface SEEDocumentController : NSDocumentController {
    NSMutableDictionary *I_propertiesForOpenedFiles;
    NSMutableDictionary *I_suspendedSeeScriptCommands;
    NSMutableDictionary *I_refCountsOfSeeScriptCommands;
    NSMutableDictionary *I_waitingDocuments;
    NSMutableArray *I_pipingSeeScriptCommands;
    
    @private
    NSMutableArray *I_windowControllers;
}

@property (nonatomic) BOOL isOpeningUntitledDocument;
@property (nonatomic, weak) IBOutlet NSMenu *recentDocumentMenu;
@property (nonatomic, readonly, assign) NSStringEncoding encodingFromLastRunOpenPanel;
@property (nonatomic, readonly, copy) NSString *modeIdentifierFromLastRunOpenPanel;

+ (SEEDocumentController *)sharedInstance;

+ (NSArray *)allTagsOfTagClass:(CFStringRef)aTagClass forUTI:(NSString *)aType;

- (NSWindow *)documentListWindow;
- (IBAction)showDocumentListWindow:(id)sender;

- (NSMenu *)documentMenu;

- (IBAction)alwaysShowTabBar:(id)sender;

- (IBAction)openNormalDocument:(id)aSender;
- (IBAction)openAlternateDocument:(id)aSender;

- (void)addProxyDocumentWithSession:(TCMMMSession *)aSession;

- (NSArray *)documentsInMode:(DocumentMode *)aDocumentMode;

- (IBAction)menuValidationNoneAction:(id)aSender;
- (IBAction)copyReachabilityURL:(id)aSender;

- (BOOL)isDocumentFromLastRunOpenPanel:(NSDocument *)aDocument;
- (NSDictionary *)propertiesForOpenedFile:(NSString *)fileName;

- (PlainTextDocument *)frontmostPlainTextDocument;

- (id)handleOpenScriptCommand:(NSScriptCommand *)command;
- (id)handlePrintScriptCommand:(NSScriptCommand *)command;
- (id)handleSeeScriptCommand:(NSScriptCommand *)command;

- (PlainTextWindowController *)activeWindowController;
- (void)addWindowController:(id)aWindowController;
- (void)removeWindowController:(id)aWindowController;

- (void)updateTabMenu;

- (IBAction)newDocumentInTab:(id)sender;
- (IBAction)newDocumentByUserDefault:(id)sender;
- (IBAction)newDocumentWithModeMenuItem:(id)aSender;

@end
