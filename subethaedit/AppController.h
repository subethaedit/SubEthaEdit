//
//  AppController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kKAHL 'KAHL'
#define kMOD 'MOD '
#define SUBETHAEDIT_DEFAULT_PORT 6942

extern int const FileMenuTag   ;
extern int const EditMenuTag   ;
extern int const FileNewMenuItemTag ;
extern int const CutMenuItemTag   ;
extern int const CopyMenuItemTag  ;
extern int const CopyXHTMLMenuItemTag ;
extern int const CopyStyledMenuItemTag ;
extern int const PasteMenuItemTag ;
extern int const BlockeditMenuItemTag ;
extern int const SpellingMenuItemTag ;
extern int const SpeechMenuItemTag   ;
extern int const FormatMenuTag ;
extern int const FontMenuItemTag ;
extern int const FileEncodingsMenuItemTag ;
extern int const WindowMenuTag ;
extern int const ModeMenuTag ;
extern int const SwitchModeMenuTag ;
extern int const HighlightSyntaxMenuTag ;
extern int const ScriptMenuTag;

extern NSString * const GlobalScriptsDidReloadNotification;

@interface AppController : NSObject {
    BOOL I_lastShouldOpenUntitledFile;
    NSMutableDictionary *I_scriptsByFilename;
    NSMutableDictionary *I_scriptSettingsByFilename;
    NSMutableArray      *I_scriptOrderArray;
    NSMutableDictionary *I_toolbarItemsByIdentifier;
    NSMutableArray      *I_toolbarItemIdentifiers;
    NSMutableArray      *I_defaultToolbarItemIdentifiers;
    
    IBOutlet NSTextView *O_licenseTextView;
    IBOutlet NSWindow *O_licenseWindow;
}

+ (AppController *)sharedInstance;

- (BOOL)lastShouldOpenUntitledFile;

- (void)reportAppleScriptError:(NSDictionary *)anErrorDictionary;

- (IBAction)undo:(id)aSender;
- (IBAction)redo:(id)aSender;

- (IBAction)purchaseSubEthaEdit:(id)sender;
- (IBAction)enterSerialNumber:(id)sender;

- (IBAction)reloadDocumentModes:(id)aSender;

- (IBAction)showAcknowledgements:(id)sender;
- (IBAction)showRegExHelp:(id)sender;
- (IBAction)showReleaseNotes:(id)sender;
- (IBAction)visitWebsite:(id)sender;
- (IBAction)reportBug:(id)sender;
- (IBAction)provideFeedback:(id)sender;

@end
