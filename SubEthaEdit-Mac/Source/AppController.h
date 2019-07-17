//  AppController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Feb 25 2004.

#define kKAHL 'KAHL'
#define kMOD 'MOD '

extern int const AppMenuTag;
extern int const EnterSerialMenuItemTag;
extern int const FileMenuTag;
extern int const EditMenuTag;
extern int const FileNewMenuItemTag;
extern int const FileNewAlternateMenuItemTag;
extern int const FileOpenMenuItemTag;
extern int const FileOpenAlternateMenuItemTag;
extern int const CutMenuItemTag;
extern int const CopyMenuItemTag;
extern int const CopyXHTMLMenuItemTag;
extern int const CopyStyledMenuItemTag;
extern int const PasteMenuItemTag;
extern int const BlockeditMenuItemTag;
extern int const SpellingMenuItemTag;
extern int const SpeechMenuItemTag;
extern int const FormatMenuTag;
extern int const FontMenuItemTag;
extern int const FileEncodingsMenuItemTag;
extern int const WindowMenuTag;
extern int const ModeMenuTag;
extern int const SwitchModeMenuTag;
extern int const ReloadModesMenuItemTag;
extern int const ScriptMenuTag;

// pasteboard types
extern NSString * const kSEEPasteBoardTypeConnection;

extern NSString * const GlobalScriptsDidReloadNotification;
extern NSString * const SEEAppEffectiveAppearanceDidChangeNotification;

@interface AppController : NSObject <NSApplicationDelegate, NSMenuDelegate> {
    NSMutableDictionary *I_scriptsByFilename;
    NSMutableDictionary *I_scriptSettingsByFilename;
    NSMutableArray      *I_scriptOrderArray;
    NSMutableArray      *I_contextMenuItemArray;
    IBOutlet NSTextView *O_licenseTextView;
    IBOutlet NSWindow *O_licenseWindow;
}

@property (nonatomic, assign) IBOutlet NSMenuItem *accessControlMenuItem;
@property (nonatomic) BOOL didShowFirstUseWindowHelp;
@property (nonatomic) BOOL lastShouldOpenUntitledFile;

@property (class, nonatomic, readonly) NSString *localizedVersionString;
@property (class, nonatomic, readonly) NSString *localizedApplicationName;

+ (AppController *)sharedInstance;

- (void)reportAppleScriptError:(NSDictionary *)anErrorDictionary;

- (IBAction)undo:(id)aSender;
- (IBAction)redo:(id)aSender;

- (IBAction)reloadDocumentModes:(id)aSender;

- (IBAction)showAcknowledgements:(id)sender;
- (IBAction)showRegExHelp:(id)sender;
- (IBAction)showReleaseNotes:(id)sender;

- (IBAction)visitFAQWebsite:(id)sender;
- (IBAction)additionalModes:(id)sender;
- (IBAction)showModeCreationDocumentation:(id)sender;

- (IBAction)showStyleSheetEditorWindow:(id)aSender;

- (NSArray *)contextMenuItemArray;
- (void)addDocumentNewSubmenuEntriesToMenu:(NSMenu *)aMenu;

- (IBAction)revealInstallCommandInFinder:(id)sender;
@property (nonatomic, readonly) NSURL *URLOfInstallCommand;
@end
