#import <Cocoa/Cocoa.h>

/* Keys in the dictionary... */   
#define RichTextFont @"RichTextFont"
#define PlainTextFont @"PlainTextFont"
#define DeleteBackup @"DeleteBackup"
#define RichText @"RichText"
#define ShowPageBreaks @"ShowPageBreaks"
#define AddExtensionToNewPlainTextFiles @"AddExtensionToNewPlainTextFiles"
#define WindowWidth @"WidthInChars"
#define WindowHeight @"HeightInChars"
#define PlainTextEncodingForRead @"PlainTextEncoding"
#define PlainTextEncodingForWrite @"PlainTextEncodingForWrite"
#define IgnoreRichText @"IgnoreRichText"
#define IgnoreHTML @"IgnoreHTML"
#define TabWidth @"TabWidth"
#define ForegroundLayoutToIndex @"ForegroundLayoutToIndex"
#define OpenPanelFollowsMainWindow @"OpenPanelFollowsMainWindow"
#define CheckSpellingAsYouType @"CheckSpellingWhileTyping"
#define CheckGrammarWithSpelling @"CheckGrammarWithSpelling"
#define ShowRuler @"ShowRuler"
#define SmartCopyPaste @"SmartCopyPaste"
#define SmartQuotes @"SmartQuotes"
#define SmartLinks @"SmartLinks"
#define UseXHTMLDocType @"UseXHTMLDocType"
#define UseTransitionalDocType @"UseTransitionalDocType"
#define UseEmbeddedCSS @"UseEmbeddedCSS"
#define UseInlineCSS @"UseInlineCSS"
#define HTMLEncoding @"HTMLEncoding"
#define PreserveWhitespace @"PreserveWhitespace"
// Managed via NSUserDefaultsController
#define AutosaveDelay @"AutosaveDelay"
#define NumberPagesWhenPrinting @"NumberPagesWhenPrinting"
// Use different convention for the key values here, to be consistent with the keys in Document
#define AuthorProperty @"author"
#define CompanyProperty @"company"
#define CopyrightProperty @"copyright"

@interface Preferences : NSObject {
    IBOutlet id richTextFontNameField;
    IBOutlet id plainTextFontNameField;
    IBOutlet id deleteBackupButton;
    IBOutlet id addExtensionToNewPlainTextFilesButton;
    IBOutlet id richTextMatrix;
    IBOutlet id showPageBreaksButton;
    IBOutlet id windowWidthField;
    IBOutlet id windowHeightField;
    IBOutlet id plainTextEncodingForReadPopup;
    IBOutlet id plainTextEncodingForWritePopup;
    IBOutlet id tabWidthField;
    IBOutlet id ignoreRichTextButton;
    IBOutlet id ignoreHTMLButton;
    IBOutlet id checkSpellingAsYouTypeButton;
    IBOutlet id checkGrammarWithSpellingButton;
    IBOutlet id showRulerButton;
    IBOutlet id numberPagesWhenPrintingButton;
    IBOutlet id smartCopyPasteButton;
    IBOutlet id smartQuotesButton;
    IBOutlet id smartLinksButton;
    IBOutlet id authorPropertyField;
    IBOutlet id companyPropertyField;
    IBOutlet id copyrightPropertyField;
    IBOutlet id HTMLDocumentTypePopUp;
    IBOutlet id HTMLStylingPopUp;
    IBOutlet id HTMLEncodingPopUp;
    IBOutlet id preserveWhiteSpaceButton;
    IBOutlet id panel;
    
    NSDictionary *curValues;	// Current, confirmed values for the preferences
    NSDictionary *origValues;	// Values read from preferences at startup
    NSMutableDictionary *displayedValues;	// Values displayed in the UI
}

+ (id)objectForKey:(id)key;	/* Convenience for getting global preferences */
+ (void)saveDefaults;		/* Convenience for saving global preferences */
- (void)saveDefaults;		/* Save the current preferences */

+ (Preferences *)sharedInstance;

- (NSDictionary *)preferences;	/* The current preferences; contains values for the documented keys */

- (void)showPanel:(id)sender;	/* Shows the panel */

- (void)updateUI;		/* Updates the displayed values in the UI */
- (void)commitDisplayedValues;	/* The displayed values are made current */
- (void)discardDisplayedValues;	/* The displayed values are replaced with current prefs and updateUI is called */

- (void)revert:(id)sender;	/* Reverts the displayed values to the current preferences */
- (void)ok:(id)sender;		/* Calls commitUI to commit the displayed values as current */
- (void)revertToDefault:(id)sender;    

- (void)miscChanged:(id)sender;		/* Action message for most of the misc items in the UI to get displayedValues */
- (void)changeRichTextFont:(id)sender;	/* Request to change the rich text font */
- (void)changePlainTextFont:(id)sender;	/* Request to change the plain text font */
- (void)changeFont:(id)fontManager;	/* Sent by the font manager */

+ (NSDictionary *)preferencesFromDefaults;
+ (void)savePreferencesToDefaults:(NSDictionary *)dict;

@end
