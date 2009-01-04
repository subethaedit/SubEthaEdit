/*
        Preferences.m
        Copyright (c) 1995-2007 by Apple Computer, Inc., all rights reserved.
        Author: Ali Ozer

        Preferences controller. To add new defaults search for one
        of the existing keys. Some keys have UI, others don't; 
        use one similar to the one you're adding.

        displayedValues is a mirror of the UI. These are committed by copying
        these values to curValues.

        This module allows for UI where there is or there isn't an OK button. 
        If you wish to have an OK button, connect OK to ok:,
        Revert to revert:, and don't call commitDisplayedValues from the 
        various action messages. 
	
	Note that this whole file can be dumped in favor of an NSUserDefaultsController.
	No real reason that hasn't happened yet, but we have switched over for at least
	one preference (AutosaveDelay).
*/
/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Cocoa/Cocoa.h>
#import "Preferences.h"
#import "EncodingManager.h"

static NSDictionary *defaultValues() {
    static NSDictionary *dict = nil;
    if (!dict) {
        dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                [NSNumber numberWithBool:YES], DeleteBackup, 
                [NSNumber numberWithBool:YES], RichText, 
                [NSNumber numberWithBool:NO], ShowPageBreaks,
		[NSNumber numberWithBool:NO], OpenPanelFollowsMainWindow,
		[NSNumber numberWithBool:YES], AddExtensionToNewPlainTextFiles,
                [NSNumber numberWithInteger:75], WindowWidth, 
                [NSNumber numberWithInteger:30], WindowHeight, 
                [NSNumber numberWithInt:NoStringEncoding], PlainTextEncodingForRead,
                [NSNumber numberWithInt:NoStringEncoding], PlainTextEncodingForWrite,
		[NSNumber numberWithInteger:8], TabWidth,
		[NSNumber numberWithInteger:50000], ForegroundLayoutToIndex,       
                [NSFont userFixedPitchFontOfSize:0.0], PlainTextFont, 
                [NSFont userFontOfSize:0.0], RichTextFont, 
                [NSNumber numberWithBool:NO], IgnoreRichText,
		[NSNumber numberWithBool:NO], IgnoreHTML,
                [NSNumber numberWithBool:YES], CheckSpellingAsYouType,
                [NSNumber numberWithBool:NO], CheckGrammarWithSpelling,
                [NSNumber numberWithBool:YES], ShowRuler,
                [NSNumber numberWithBool:YES], SmartCopyPaste,
                [NSNumber numberWithBool:NO], SmartQuotes,
                [NSNumber numberWithBool:NO], SmartLinks,
                @"", AuthorProperty,
                @"", CompanyProperty,
                @"", CopyrightProperty,
                [NSNumber numberWithBool:NO], UseXHTMLDocType,
                [NSNumber numberWithBool:NO], UseTransitionalDocType,
                [NSNumber numberWithBool:YES], UseEmbeddedCSS,
                [NSNumber numberWithBool:NO], UseInlineCSS,
                [NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding], HTMLEncoding,
                [NSNumber numberWithBool:YES], PreserveWhitespace,
		nil];
    }
    return dict;
}

@implementation Preferences

static Preferences *sharedInstance = nil;

+ (Preferences *)sharedInstance {
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (id)init {
    if (sharedInstance) {		// We just have one instance of the Preferences class, return that one instead
        [self release];
    } else if (self = [super init]) {
        curValues = [[[self class] preferencesFromDefaults] copyWithZone:[self zone]];
        origValues = [curValues retain];
        [self discardDisplayedValues];
        sharedInstance = self;
    }
    return sharedInstance;
}

- (void)dealloc {
    if (self != sharedInstance) [super dealloc];	// Don't free the shared instance
}


/* The next few factory methods are conveniences, working on the shared instance
*/
+ (id)objectForKey:(id)key {
    return [[[self sharedInstance] preferences] objectForKey:key];
}

+ (void)saveDefaults {
    [[self sharedInstance] saveDefaults];
}

- (void)saveDefaults {
    NSDictionary *prefs = [self preferences];
    if (![origValues isEqual:prefs]) [Preferences savePreferencesToDefaults:prefs];
}

- (NSDictionary *)preferences {
    return curValues;
}

- (void)showPanel:(id)sender {
    if (!panel) {
        if (![NSBundle loadNibNamed:@"Preferences" owner:self])  {
            NSLog(@"Failed to load Preferences.nib");
            NSBeep();
            return;
        }
	[panel setHidesOnDeactivate:NO];
	[panel setExcludedFromWindowsMenu:YES];
	[panel setMenu:nil];
        [self updateUI];
        [panel center];
    }
    [panel makeKeyAndOrderFront:nil];
}

static void showFontInField(NSFont *font, NSTextField *field) {
    [field setStringValue:font ? [NSString stringWithFormat:@"%@ %g", [font displayName], [font pointSize]] : @""];
}

- (void)updateUI {
    if (!richTextFontNameField) return;	/* UI hasn't been loaded... */

    showFontInField([displayedValues objectForKey:RichTextFont], richTextFontNameField);
    showFontInField([displayedValues objectForKey:PlainTextFont], plainTextFontNameField);

    [deleteBackupButton setState:[[displayedValues objectForKey:DeleteBackup] boolValue] ? 1 : 0];
    [addExtensionToNewPlainTextFilesButton setState:[[displayedValues objectForKey:AddExtensionToNewPlainTextFiles] boolValue]];
    [richTextMatrix selectCellWithTag:[[displayedValues objectForKey:RichText] boolValue] ? 1 : 0];
    [showPageBreaksButton setState:[[displayedValues objectForKey:ShowPageBreaks] boolValue]];
    [ignoreRichTextButton setState:[[displayedValues objectForKey:IgnoreRichText] boolValue]];
    [ignoreHTMLButton setState:[[displayedValues objectForKey:IgnoreHTML] boolValue]];
    [checkSpellingAsYouTypeButton setState:[[displayedValues objectForKey:CheckSpellingAsYouType] boolValue]];
    [checkGrammarWithSpellingButton setState:[[displayedValues objectForKey:CheckGrammarWithSpelling] boolValue]];
    [showRulerButton setState:[[displayedValues objectForKey:ShowRuler] boolValue]];
    [smartCopyPasteButton setState:[[displayedValues objectForKey:SmartCopyPaste] boolValue]];
    [smartQuotesButton setState:[[displayedValues objectForKey:SmartQuotes] boolValue]];
    [smartLinksButton setState:[[displayedValues objectForKey:SmartLinks] boolValue]];

    [windowWidthField setIntegerValue:[[displayedValues objectForKey:WindowWidth] integerValue]];
    [windowHeightField setIntegerValue:[[displayedValues objectForKey:WindowHeight] integerValue]];

    [authorPropertyField setStringValue:[displayedValues objectForKey:AuthorProperty]];
    [companyPropertyField setStringValue:[displayedValues objectForKey:CompanyProperty]];
    [copyrightPropertyField setStringValue:[displayedValues objectForKey:CopyrightProperty]];

    [(EncodingPopUpButton *)plainTextEncodingForReadPopup setEncoding:[[displayedValues objectForKey:PlainTextEncodingForRead] intValue] defaultEntry:YES];
    [(EncodingPopUpButton *)plainTextEncodingForWritePopup setEncoding:[[displayedValues objectForKey:PlainTextEncodingForWrite] intValue] defaultEntry:YES];

    [HTMLDocumentTypePopUp selectItemAtIndex:([[displayedValues objectForKey:UseXHTMLDocType] boolValue] ? 2 : 0) | ([[displayedValues objectForKey:UseTransitionalDocType] boolValue] ? 1 : 0)];
    [HTMLStylingPopUp selectItemAtIndex:[[displayedValues objectForKey:UseEmbeddedCSS] boolValue] ? 0 : ([[displayedValues objectForKey:UseInlineCSS] boolValue] ? 1 : 2)];
    [(EncodingPopUpButton *)HTMLEncodingPopUp setEncoding:[[displayedValues objectForKey:HTMLEncoding] unsignedIntegerValue] defaultEntry:NO];
    [preserveWhiteSpaceButton setState:[[displayedValues objectForKey:PreserveWhitespace] boolValue]];
}

/* Gets everything from UI except for fonts...
*/
- (void)miscChanged:(id)sender {
    static NSNumber *yes = nil;
    static NSNumber *no = nil;
    NSInteger anInt;
    
    if (!yes) {
        yes = [[NSNumber alloc] initWithBool:YES];
        no = [[NSNumber alloc] initWithBool:NO];
    }

    [displayedValues setObject:[deleteBackupButton state] ? yes : no forKey:DeleteBackup];
    [displayedValues setObject:[[richTextMatrix selectedCell] tag] ? yes : no forKey:RichText];
    [displayedValues setObject:[addExtensionToNewPlainTextFilesButton state] ? yes : no forKey:AddExtensionToNewPlainTextFiles];
    [displayedValues setObject:[showPageBreaksButton state] ? yes : no forKey:ShowPageBreaks];
    [displayedValues setObject:[NSNumber numberWithInt:[[plainTextEncodingForReadPopup selectedItem] tag]] forKey:PlainTextEncodingForRead];
    [displayedValues setObject:[NSNumber numberWithInt:[[plainTextEncodingForWritePopup selectedItem] tag]] forKey:PlainTextEncodingForWrite];
    [displayedValues setObject:[ignoreRichTextButton state] ? yes : no forKey:IgnoreRichText];
    [displayedValues setObject:[ignoreHTMLButton state] ? yes : no forKey:IgnoreHTML];
    [displayedValues setObject:[checkSpellingAsYouTypeButton state] ? yes : no forKey:CheckSpellingAsYouType];
    [displayedValues setObject:[checkGrammarWithSpellingButton state] ? yes : no forKey:CheckGrammarWithSpelling];
    [displayedValues setObject:[showRulerButton state] ? yes : no forKey:ShowRuler];
    [displayedValues setObject:[smartCopyPasteButton state] ? yes : no forKey:SmartCopyPaste];
    [displayedValues setObject:[smartQuotesButton state] ? yes : no forKey:SmartQuotes];
    [displayedValues setObject:[smartLinksButton state] ? yes : no forKey:SmartLinks];
    [displayedValues setObject:[authorPropertyField stringValue] forKey:AuthorProperty];
    [displayedValues setObject:[companyPropertyField stringValue] forKey:CompanyProperty];
    [displayedValues setObject:[copyrightPropertyField stringValue] forKey:CopyrightProperty];
    [displayedValues setObject:([HTMLDocumentTypePopUp indexOfSelectedItem] & 2) ? yes : no forKey:UseXHTMLDocType];
    [displayedValues setObject:([HTMLDocumentTypePopUp indexOfSelectedItem] & 1) ? yes : no forKey:UseTransitionalDocType];
    [displayedValues setObject:([HTMLStylingPopUp indexOfSelectedItem] == 0) ? yes : no forKey:UseEmbeddedCSS];
    [displayedValues setObject:([HTMLStylingPopUp indexOfSelectedItem] == 1) ? yes : no forKey:UseInlineCSS];
    [displayedValues setObject:[NSNumber numberWithInteger:[[HTMLEncodingPopUp selectedItem] tag]] forKey:HTMLEncoding];
    [displayedValues setObject:[preserveWhiteSpaceButton state] ? yes : no forKey:PreserveWhitespace];

    if ((anInt = [windowWidthField integerValue]) < 1 || anInt > 10000) {
        if ((anInt = [[displayedValues objectForKey:WindowWidth] integerValue]) < 1 || anInt > 10000) anInt = [[defaultValues() objectForKey:WindowWidth] integerValue];
	[windowWidthField setIntegerValue:anInt];
    } else {
	[displayedValues setObject:[NSNumber numberWithInteger:anInt] forKey:WindowWidth];
    }

    if ((anInt = [windowHeightField integerValue]) < 1 || anInt > 10000) {
        if ((anInt = [[displayedValues objectForKey:WindowHeight] integerValue]) < 1 || anInt > 10000) anInt = [[defaultValues() objectForKey:WindowHeight] integerValue];
        [windowHeightField setIntegerValue:[[displayedValues objectForKey:WindowHeight] integerValue]];
    } else {
	[displayedValues setObject:[NSNumber numberWithInteger:anInt] forKey:WindowHeight];
    }

    [self commitDisplayedValues];
}

/**** Font changing code ****/

static BOOL changingRTFFont = NO;

- (void)changeRichTextFont:(id)sender {
    changingRTFFont = YES;
    [panel makeFirstResponder:panel];
    [[NSFontManager sharedFontManager] setSelectedFont:[curValues objectForKey:RichTextFont] isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (void)changePlainTextFont:(id)sender {
    changingRTFFont = NO;
    [panel makeFirstResponder:panel];
    [[NSFontManager sharedFontManager] setSelectedFont:[curValues objectForKey:PlainTextFont] isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (void)changeFont:(id)fontManager {
    if (changingRTFFont) {
        [displayedValues setObject:[fontManager convertFont:[curValues objectForKey:RichTextFont]] forKey:RichTextFont];
        showFontInField([displayedValues objectForKey:RichTextFont], richTextFontNameField);
    } else {
        [displayedValues setObject:[fontManager convertFont:[curValues objectForKey:PlainTextFont]] forKey:PlainTextFont];
        showFontInField([displayedValues objectForKey:PlainTextFont], plainTextFontNameField);
    }
    [self commitDisplayedValues];
}

/**** Commit/revert etc ****/

- (void)commitDisplayedValues {
    if (curValues != displayedValues) {
        [curValues release];
        curValues = [displayedValues copyWithZone:[self zone]];
    }
}

- (void)discardDisplayedValues {
    if (curValues != displayedValues) {
        [displayedValues release];
        displayedValues = [curValues mutableCopyWithZone:[self zone]];
        [self updateUI];
    }
}

- (void)ok:(id)sender {
    [self commitDisplayedValues];
}

- (void)revertToDefault:(id)sender {
    [curValues release];
    curValues = [defaultValues() copyWithZone:[self zone]];
    [self discardDisplayedValues];
    [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:nil];    // Since some defaults are now managed by NSUserDefaultsController
}

- (void)revert:(id)sender {
    [self discardDisplayedValues];
    [[NSUserDefaultsController sharedUserDefaultsController] revert:nil];    // Since some defaults are now managed by NSUserDefaultsController
}

/**** Code to deal with defaults ****/
   
#define getStringDefault(name) \
  {id obj = [defaults stringForKey:name]; \
      [dict setObject:obj ? obj : [defaultValues() objectForKey:name] forKey:name];}

#define getBoolDefault(name) \
  {id obj = [defaults objectForKey:name]; \
      [dict setObject:obj ? [NSNumber numberWithBool:[defaults boolForKey:name]] : [defaultValues() objectForKey:name] forKey:name];}

#define getIntDefault(name) \
  {id obj = [defaults objectForKey:name]; \
      [dict setObject:obj ? [NSNumber numberWithInteger:[defaults integerForKey:name]] : [defaultValues() objectForKey:name] forKey:name];}

+ (NSDictionary *)preferencesFromDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];

    getBoolDefault(RichText);
    getBoolDefault(DeleteBackup);
    getBoolDefault(ShowPageBreaks);
    getBoolDefault(OpenPanelFollowsMainWindow);
    getBoolDefault(AddExtensionToNewPlainTextFiles);
    getIntDefault(WindowWidth);
    getIntDefault(WindowHeight);
    getIntDefault(PlainTextEncodingForRead);
    getIntDefault(PlainTextEncodingForWrite);
    getIntDefault(TabWidth);
    getIntDefault(ForegroundLayoutToIndex);
    getBoolDefault(IgnoreRichText);
    getBoolDefault(IgnoreHTML);
    getBoolDefault(CheckSpellingAsYouType);
    getBoolDefault(CheckGrammarWithSpelling);
    getBoolDefault(ShowRuler);
    getBoolDefault(SmartCopyPaste);
    getBoolDefault(SmartQuotes);
    getBoolDefault(SmartLinks);
    getStringDefault(AuthorProperty);
    getStringDefault(CompanyProperty);
    getStringDefault(CopyrightProperty);
    getBoolDefault(UseXHTMLDocType);
    getBoolDefault(UseTransitionalDocType);
    getBoolDefault(UseEmbeddedCSS);
    getBoolDefault(UseInlineCSS);
    getIntDefault(HTMLEncoding);
    getBoolDefault(PreserveWhitespace);
    [dict setObject:[NSFont userFontOfSize:0.0] forKey:RichTextFont];
    [dict setObject:[NSFont userFixedPitchFontOfSize:0.0] forKey:PlainTextFont];

    return dict;
}

#define setStringDefault(name) \
  {if ([[defaultValues() objectForKey:name] isEqual:[dict objectForKey:name]]) [defaults removeObjectForKey:name]; else [defaults setObject:[dict objectForKey:name] forKey:name];}

#define setBoolDefault(name) \
  {if ([[defaultValues() objectForKey:name] isEqual:[dict objectForKey:name]]) [defaults removeObjectForKey:name]; else [defaults setBool:[[dict objectForKey:name] boolValue] forKey:name];}

#define setIntDefault(name) \
  {if ([[defaultValues() objectForKey:name] isEqual:[dict objectForKey:name]]) [defaults removeObjectForKey:name]; else [defaults setInteger:[[dict objectForKey:name] integerValue] forKey:name];}

+ (void)savePreferencesToDefaults:(NSDictionary *)dict {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    setBoolDefault(RichText);
    setBoolDefault(DeleteBackup);
    setBoolDefault(ShowPageBreaks);
    setBoolDefault(OpenPanelFollowsMainWindow);
    setBoolDefault(AddExtensionToNewPlainTextFiles);
    setIntDefault(WindowWidth);
    setIntDefault(WindowHeight);
    setIntDefault(PlainTextEncodingForRead);
    setIntDefault(PlainTextEncodingForWrite);
    setIntDefault(TabWidth);
    setIntDefault(ForegroundLayoutToIndex);
    setBoolDefault(IgnoreRichText);
    setBoolDefault(IgnoreHTML);
    setBoolDefault(CheckSpellingAsYouType);
    setBoolDefault(CheckGrammarWithSpelling);
    setBoolDefault(ShowRuler);
    setBoolDefault(SmartCopyPaste);
    setBoolDefault(SmartQuotes);
    setBoolDefault(SmartLinks);
    setStringDefault(AuthorProperty);
    setStringDefault(CompanyProperty);
    setStringDefault(CopyrightProperty);
    setBoolDefault(UseXHTMLDocType);
    setBoolDefault(UseTransitionalDocType);
    setBoolDefault(UseEmbeddedCSS);
    setBoolDefault(UseInlineCSS);
    setIntDefault(HTMLEncoding);
    setBoolDefault(PreserveWhitespace);
    if (![[dict objectForKey:RichTextFont] isEqual:[NSFont userFontOfSize:0.0]]) [NSFont setUserFont:[dict objectForKey:RichTextFont]];
    if (![[dict objectForKey:PlainTextFont] isEqual:[NSFont userFixedPitchFontOfSize:0.0]]) [NSFont setUserFixedPitchFont:[dict objectForKey:PlainTextFont]];
}


/**** Window delegation ****/

// We do this to catch the case where the user enters a value into one of the text fields but closes the window without hitting enter or tab.

- (void)windowWillClose:(NSNotification *)notification {
    NSWindow *window = [notification object];
    (void)[window makeFirstResponder:window];
}


@end
