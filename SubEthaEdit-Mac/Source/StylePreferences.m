//  StylePreferences.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Oct 07 2004.

#import "PlainTextDocument.h"
#import "StylePreferences.h"
#import "SyntaxStyle.h"
#import "DocumentModeManager.h"
#import "SEEDocumentController.h"
#import "TableView.h"
#import "TextFieldCell.h"
#import "GeneralPreferences.h"
#import "OverlayView.h"
#import "SyntaxHighlighter.h"

@interface StylePreferences ()
@property (nonatomic, strong) NSFont *baseFont;
@end

@implementation StylePreferences

#pragma mark - Preference Module - Basics
- (NSImage *)icon {
    if (@available(macOS 10.16, *)) {
        return [NSImage imageWithSystemSymbolName:@"paintbrush" accessibilityDescription:nil];
    } else {
        return [NSImage imageNamed:@"StylePrefs"];
    }
}

- (NSString *)iconLabel {
    return NSLocalizedString(@"StylePrefsIconLabel", @"Label displayed below tyle pref icon and used as window title.");
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.style";
}

- (NSString *)mainNibName {
    return @"StylePrefs";
}

- (void)mainViewDidLoad {
    // Initialize user interface elements to reflect current preference settings
	
	// localization
    self.O_styleSheetDefaultRadioButton.title = NSLocalizedStringWithDefaultValue(@"STYLE_PREF_SHEET_BUTTON_DEFAULT_LABEL", nil, [NSBundle mainBundle], @"Style sheet from Default Mode", @"");
    self.O_styleSheetCustomRadioButton.title = NSLocalizedStringWithDefaultValue(@"STYLE_PREF_SHEET_BUTTON_CUSTOM_LABEL", nil, [NSBundle mainBundle], @"Custom style sheet", @"");
    self.O_styleSheetCustomForLanguageContextsRadioButton.title = NSLocalizedStringWithDefaultValue(@"STYLE_PREF_SHEET_BUTTON_CUSTOM_FOR_CONTEXT_LABEL", nil, [NSBundle mainBundle], @"Custom style sheets for Language Contexts", @"");
    [self changeMode:self.O_modePopUpButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentModeListChanged:) name:@"DocumentModeListChanged" object:nil];
}

- (void)didSelect {
	PlainTextDocument *frontmostDocument = [[SEEDocumentController sharedInstance] frontmostPlainTextDocument];
	if (frontmostDocument) {
		[self selectMode:[frontmostDocument documentMode]];
	} else {
		[self highlightSyntax];
	}
	[super didSelect];
}

- (void)didUnselect {
    // Save preferences
    [[[NSFontManager sharedFontManager] fontPanel:NO] orderOut:self];
}

#pragma mark - IBActions
- (IBAction)validateDefaultsState:(id)aSender {
	[self.O_styleSheetDefaultRadioButton setState:NSControlStateValueOff];
	[self.O_styleSheetCustomRadioButton setState:NSControlStateValueOff];
	[self.O_styleSheetCustomForLanguageContextsRadioButton setState:NSControlStateValueOff];

	DocumentMode *currentMode = [self.O_modeController content];
	if ([[[currentMode defaults] objectForKey:DocumentModeUseDefaultStyleSheetPreferenceKey] boolValue]) {
		[self.O_styleSheetDefaultRadioButton setState:NSControlStateValueOn];
	} else {
		SEEStyleSheetSettings *styleSheetSettings = [currentMode styleSheetSettings];
		if (styleSheetSettings.usesMultipleStyleSheets) {
			[self.O_styleSheetCustomForLanguageContextsRadioButton setState:NSControlStateValueOn];
		} else {
			[self.O_styleSheetCustomRadioButton setState:NSControlStateValueOn];
		}
	}

    DocumentMode *baseMode = [[DocumentModeManager sharedInstance] baseMode];
    DocumentMode *selectedMode = [self.O_modePopUpButton selectedMode];
    [self.O_fontController setContent:([self.O_fontDefaultButton state]==NSControlStateValueOn)?baseMode:selectedMode];
    [self takeFontFromMode:selectedMode];
	[self highlightSyntax];
}

- (IBAction)changeDefaultState:(id)aSender {
    BOOL useDefault = ([aSender state]==NSControlStateValueOn);
    [[[self.O_modePopUpButton selectedMode] defaults] setObject:[NSNumber numberWithBool:useDefault] forKey:DocumentModeUseDefaultStylePreferenceKey];
    [self validateDefaultsState:aSender];
}

- (IBAction)changeMode:(id)aSender {
	DocumentMode *newMode=[aSender selectedMode];
	if (newMode) {
		[self selectMode:newMode];
	}
}

- (IBAction)styleRadioButtonAction:(id)aSender {
	DocumentMode *currentMode = [self.O_modeController content];
	if (aSender == self.O_styleSheetDefaultRadioButton) {
		[[currentMode defaults] setObject:@YES forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
	} else {
		[[currentMode defaults] setObject:@NO forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
		SEEStyleSheetSettings *styleSheetSettings = [currentMode styleSheetSettingsOfThisMode];
		if (aSender == self.O_styleSheetCustomRadioButton) {
			styleSheetSettings.usesMultipleStyleSheets = NO;
		} else {
			styleSheetSettings.usesMultipleStyleSheets = YES;
		}
	}
    [self validateDefaultsState:aSender];
	[self highlightSyntax];
}

- (IBAction)setDefaultStyleSheet:(id)sender {
    DocumentMode *currentMode = [self.O_modeController content];
    [[currentMode defaults] setObject:@YES forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
    [self validateDefaultsState:sender];
    [self highlightSyntax];
}

- (IBAction)changeCustomStyleSheet:(id)aSender {
	DocumentMode *currentMode = [self.O_modeController content];
	NSString *styleSheetName = [[self.O_styleSheetCustomPopUpButton selectedItem] title];
	[[currentMode defaults] setObject:@NO forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
	SEEStyleSheetSettings *styleSheetSettings = [currentMode styleSheetSettingsOfThisMode];
	styleSheetSettings.singleStyleSheetName = styleSheetName;
	styleSheetSettings.usesMultipleStyleSheets = NO;
    [self validateDefaultsState:aSender];
	[self highlightSyntax];
}


- (IBAction)revealCustomStyleSheetsFolder:(id)sender {
	NSURL *customStyleSheetFolder = [[DocumentModeManager sharedInstance] customStyleSheetFolderURL];
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[customStyleSheetFolder]];

	[self selectMode:[self.O_modePopUpButton selectedMode]];
	[self.O_styleSheetCustomPopUpButton synchronizeTitleAndSelectedItem];
	[self.O_styleSheetCustomPopUpButton synchronizeTitleAndSelectedItem];
}


- (IBAction)reloadStyleSheets:(id)sender {
	[[DocumentModeManager sharedInstance] reloadAllStyles];
	[self updateStyleSheetLists];

	[self selectMode:[self.O_modePopUpButton selectedMode]];
	[self.O_styleSheetCustomPopUpButton synchronizeTitleAndSelectedItem];
	[self highlightSyntax];
}


- (IBAction)applyToOpenDocuments:(id)aSender {
	[self highlightSyntax];
    [[NSNotificationCenter defaultCenter] postNotificationName:DocumentModeApplyStylePreferencesNotification object:[self.O_modeController content]];
}

- (IBAction)changeFontViaPanel:(id)sender {
    DocumentMode *mode = [self.O_modePopUpButton selectedMode];
    NSFont *font = mode.plainFontBase;
    [[NSFontManager sharedFontManager] setSelectedFont:font isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (IBAction)useSystemMonospacedFont:(id)sender {
    if ([self.O_fontDefaultButton state] != NSControlStateValueOn) {
        DocumentMode *mode = [self.O_modePopUpButton selectedMode];
        NSFont *font = mode.plainFontBase;
        CGFloat size = font.pointSize;
        NSString *name = DocumentModeFontNameSystemFontValue;

        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:name forKey:NSFontNameAttribute];
        [dict setObject:@(size) forKey:NSFontSizeAttribute];
        [self setFontDict:dict];
    }
}

#pragma mark
- (void)updateStyleSheetLists {
    [self.O_styleSheetCustomPopUpButton removeAllItems];
    
    if (![[self.O_modeController content] isEqual:[[DocumentModeManager sharedInstance] baseMode]]) {
        NSString *defaultModeStyleSheetTitle = NSLocalizedStringWithDefaultValue(@"STYLE_PREF_SHEET_BUTTON_DEFAULT_LABEL", nil, [NSBundle mainBundle], @"Default Style", @"");
        NSMenuItem *defaultModeStyleSheetItem = [[NSMenuItem alloc] initWithTitle:defaultModeStyleSheetTitle action:@selector(setDefaultStyleSheet:) keyEquivalent:@""];
        defaultModeStyleSheetItem.target = self;
        [[self.O_styleSheetCustomPopUpButton menu] addItem:defaultModeStyleSheetItem];
        [[self.O_styleSheetCustomPopUpButton menu] addItem:[NSMenuItem separatorItem]];
    }
    
	[self.O_styleSheetCustomPopUpButton addItemsWithTitles:[[DocumentModeManager sharedInstance] allStyleSheetNames]];

	[[self.O_styleSheetCustomPopUpButton menu] addItem:[NSMenuItem separatorItem]];
	NSString *revealUserFolderItemTitle = NSLocalizedStringWithDefaultValue(@"STYLE_PREFS_REVEAL_USER_STYLES_FOLDER", nil, [NSBundle mainBundle], @"Show User Styles Folder", @"");
	NSMenuItem *revealUserFolderItem = [[NSMenuItem alloc] initWithTitle:revealUserFolderItemTitle action:@selector(revealCustomStyleSheetsFolder:) keyEquivalent:@""];
	revealUserFolderItem.target = self;
	[[self.O_styleSheetCustomPopUpButton menu] addItem:revealUserFolderItem];

	NSString *reloadItemTitle = NSLocalizedStringWithDefaultValue(@"STYLE_PREFS_RELOAD_STYLES_TITLE", nil, [NSBundle mainBundle], @"Reload Styles", @"");
	NSMenuItem *reloadStylesItem = [[NSMenuItem alloc] initWithTitle:reloadItemTitle action:@selector(reloadStyleSheets:) keyEquivalent:@""];
	reloadStylesItem.target = self;
	[[self.O_styleSheetCustomPopUpButton menu] addItem:reloadStylesItem];


	NSPopUpButtonCell *styleSheetButtonCell = [[self.O_customStylesForLanguageContextsTableView tableColumnWithIdentifier:@"styleSheet"] dataCell];
	[styleSheetButtonCell removeAllItems];
	[styleSheetButtonCell addItemsWithTitles:[[DocumentModeManager sharedInstance] allStyleSheetNames]];
}

- (void)documentModeListChanged:(NSNotification *)aNotification {
    [self performSelector:@selector(changeMode:) withObject:self.O_modePopUpButton afterDelay:.2];
}

- (void)takeFontFromMode:(DocumentMode *)mode {
    [self setBaseFont:mode.plainFontBase];
}

- (void)selectMode:(DocumentMode *)aDocumentMode {
	[self.O_modeController setContent:aDocumentMode];
	[self.O_modePopUpButton setSelectedMode:aDocumentMode];
	[self updateStyleSheetLists];
	
    DocumentMode *baseMode = [[DocumentModeManager sharedInstance] baseMode];
    NSString *defaultStyleSheetName = baseMode.styleSheetSettings.singleStyleSheetName;
    NSString *customStyleSheetName = [[aDocumentMode styleSheetSettings] singleStyleSheetName];
    if (![aDocumentMode isEqual:baseMode] &&
        [defaultStyleSheetName isEqualToString:customStyleSheetName]) {
        [self.O_styleSheetCustomPopUpButton selectItemAtIndex:0];
    } else {
        [self.O_styleSheetCustomPopUpButton selectItemWithTitle:customStyleSheetName];
    }
	
    [self.O_customStylesForLanguageContextsTableView reloadData];
	[self.O_styleSheetDefaultRadioButton setHidden:[aDocumentMode isBaseMode]];
	// TODO: resize the style settings box
	CGFloat heightChange = 0;

// define this to show the option to select style sheets per language context
//#define SHOW_ALL_LANGUAGE_CONTEXTS
#ifdef SHOW_ALL_LANGUAGE_CONTEXTS
	BOOL shouldShow = ([[[aDocumentMode syntaxDefinition] allLanguageContexts] count] > 1);
#else
	BOOL shouldShow = NO;
#endif

	if (shouldShow && [self.O_customStyleSheetsContainerView isHidden]) {
		[self.O_customStyleSheetsContainerView setHidden:NO ];
		heightChange =  [self.O_customStyleSheetsContainerView frame].size.height;
	} else if (!shouldShow && ![self.O_customStyleSheetsContainerView isHidden]) {
		[self.O_customStyleSheetsContainerView setHidden:YES];
		heightChange = -[self.O_customStyleSheetsContainerView frame].size.height;
	}
	if (heightChange != 0) {
		NSBox *styleBox   = self.O_styleContainerBox;
		NSBox *previewBox = self.O_previewContainerBox;
		NSRect boxFrame = [styleBox frame];
		NSRect previewBoxFrame = [previewBox frame];
		boxFrame.size.height += heightChange;
		boxFrame.origin.y -= heightChange;
		previewBoxFrame.size.height -= heightChange;
		[styleBox setFrame:boxFrame];
		[previewBox setFrame:previewBoxFrame];
	}
	[self validateDefaultsState:nil];
	[[[self.O_syntaxSampleTextView textStorage] mutableString] setString:[aDocumentMode syntaxExampleString]];
	[self highlightSyntax];
}

- (void)changeFont:(id)fontManager {
//	NSLog(@"%s",__FUNCTION__);
    if ([self.O_fontDefaultButton state] != NSControlStateValueOn) {
        NSFont *newFont = [fontManager convertFont:[self.O_modePopUpButton selectedMode].plainFontBase];
        NSMutableDictionary *dict=[NSMutableDictionary dictionary];
        
        [dict setObject:[[newFont fontName] hasPrefix:@"."] ? DocumentModeFontNameSystemFontValue : newFont.fontName forKey:NSFontNameAttribute];
        [dict setObject:[NSNumber numberWithFloat:[newFont pointSize]] forKey:NSFontSizeAttribute];
        [self setFontDict:dict];
    }
}

- (void)setFontDict:(NSDictionary *)fontDict {
    [[self.O_modePopUpButton selectedMode] setValue:fontDict forKeyPath:@"defaults.FontAttributes"];
    [self changeMode:self.O_modePopUpButton];
}

- (NSArray *)languageContexts {
	return [[[self.O_modeController content] syntaxDefinition] allLanguageContexts];
}

#pragma mark - Syntax highlighting callbacks

- (NSDictionary *)styleAttributesForScope:(NSString *)aScope languageContext:(NSString *)aLanguageContext {
	DocumentMode *currentMode = [self.O_modeController content];
	SEEStyleSheet *styleSheet = [currentMode styleSheetForLanguageContext:aLanguageContext];
	NSDictionary *result = [SEEStyleSheet textAttributesForStyleAttributes:[styleSheet styleAttributesForScope:aScope] font:self.baseFont];
	return result;
}

- (void)highlightSyntax {
	DocumentMode *currentMode = [self.O_modeController content];
	SEEStyleSheetSettings *settings = [currentMode styleSheetSettings];
	[self.O_syntaxSampleTextView setBackgroundColor:settings.documentBackgroundColor];
	SyntaxHighlighter *highlighter = [currentMode syntaxHighlighter];
	NSTextStorage *textStorage = [self.O_syntaxSampleTextView textStorage];
	if (highlighter) {
		[highlighter cleanUpTextStorage:textStorage];
		while (![highlighter colorizeDirtyRanges:textStorage ofDocument:self]) {
			// go on until finished
		}
		[textStorage removeAttribute:NSLinkAttributeName range:textStorage.TCM_fullLengthRange];// remove link as a default textview displays it hardcore blue
	} else {
		SEEStyleSheet *styleSheet = [currentMode styleSheetForLanguageContext:currentMode.scriptedName];
		NSDictionary *attributes = [SEEStyleSheet textAttributesForStyleAttributes:[styleSheet styleAttributesForScope:SEEStyleSheetMetaDefaultScopeName] font:self.baseFont];
		[textStorage setAttributes:attributes range:NSMakeRange(0,textStorage.length)];
	}
}

#pragma mark - TableView DataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[[[self.O_modeController content] syntaxDefinition] allLanguageContexts] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)aRow {
	NSArray *languageContexts = [self languageContexts];
	NSString *languageContext = [languageContexts objectAtIndex:aRow];
	if ([[aTableColumn identifier] isEqualToString:@"languageContext"]) {
		return languageContext;
	} else {
		SEEStyleSheetSettings *styleSheetSettings = [[self.O_modeController content] styleSheetSettingsOfThisMode];
		NSString *styleSheetName = [styleSheetSettings styleSheetNameForLanguageContext:[languageContexts objectAtIndex:aRow]];
		if (!styleSheetName) {
			styleSheetName = [styleSheetSettings singleStyleSheetName];
		}
		return [NSNumber numberWithInteger:[[aTableColumn dataCell] indexOfItemWithTitle:styleSheetName]];
	}
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	NSArray *languageContexts = [self languageContexts];
	NSString *languageContext = [languageContexts objectAtIndex:rowIndex];
	NSString *styleSheetName = [[[aTableColumn dataCell] itemTitles] objectAtIndex:[anObject integerValue]];
	DocumentMode *currentMode = [self.O_modeController content];
	SEEStyleSheetSettings *styleSheetSettings = [currentMode styleSheetSettings];
	[styleSheetSettings setStyleSheetName:styleSheetName forLanguageContext:languageContext];
	[[currentMode defaults] setObject:@NO forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
	styleSheetSettings.usesMultipleStyleSheets = YES;
	[self highlightSyntax];
}

@end
