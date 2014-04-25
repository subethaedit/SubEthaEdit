//
//  StylePreferences.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Oct 07 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

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
    return [NSImage imageNamed:@"StylePrefs"];
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
	
	{ // localization
		self.O_fontDefaultButton.title = NSLocalizedStringWithDefaultValue(@"STYLE_PREF_DEFAULT_FONT_CHECKBOX_LABEL", nil, [NSBundle mainBundle], @"use Default", @"");
		self.O_fontContainerBox.title = NSLocalizedStringWithDefaultValue(@"STYLE_PREF_FONT_BOX_LABEL", nil, [NSBundle mainBundle], @"Font", @"");
		self.O_changeFontButton.title = NSLocalizedStringWithDefaultValue(@"STYLE_PREF_CUSTOM_FONT_BUTTON", nil, [NSBundle mainBundle], @"Set...", @"");
		self.O_changeFontButton.toolTip = NSLocalizedStringWithDefaultValue(@"STYLE_PREF_CUSTOM_FONT_BUTTON_TOOL_TIP", nil, [NSBundle mainBundle], @"Change the document's default font", @"");
		self.O_styleContainerBox.title = NSLocalizedStringWithDefaultValue(@"STYLE_PREF_SETTING_BOX_LABEL", nil, [NSBundle mainBundle], @"Style Settings", @"");
		self.O_styleSheetDefaultRadioButton.title = NSLocalizedStringWithDefaultValue(@"STYLE_PREF_SHEET_BUTTON_DEFAULT_LABEL", nil, [NSBundle mainBundle], @"Style sheet from Default Mode", @"");
		self.O_styleSheetCustomRadioButton.title = NSLocalizedStringWithDefaultValue(@"STYLE_PREF_SHEET_BUTTON_CUSTOM_LABEL", nil, [NSBundle mainBundle], @"Custom style sheet", @"");
		self.O_styleSheetCustomForLanguageContextsRadioButton.title = NSLocalizedStringWithDefaultValue(@"STYLE_PREF_SHEET_BUTTON_CUSTOM_FOR_CONTEXT_LABEL", nil, [NSBundle mainBundle], @"Custom style sheets for Language Contexts", @"");
		self.O_previewContainerBox.title = NSLocalizedStringWithDefaultValue(@"STYLE_PREF_PREVIEW_BOX_LABEL", nil, [NSBundle mainBundle], @"Preview", @"");
		self.O_applyToOpenDocumentsButton.title = NSLocalizedStringWithDefaultValue(@"STYLE_PREF_APPLY_STYLE_BUTTON", nil, [NSBundle mainBundle], @"Apply to Open Documents", @"");
	}
	
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
	[self.O_styleSheetDefaultRadioButton setState:NSOffState];
	[self.O_styleSheetCustomRadioButton setState:NSOffState];
	[self.O_styleSheetCustomForLanguageContextsRadioButton setState:NSOffState];

	DocumentMode *currentMode = [self.O_modeController content];
	if ([[[currentMode defaults] objectForKey:DocumentModeUseDefaultStyleSheetPreferenceKey] boolValue]) {
		[self.O_styleSheetDefaultRadioButton setState:NSOnState];
	} else {
		SEEStyleSheetSettings *styleSheetSettings = [currentMode styleSheetSettings];
		if (styleSheetSettings.usesMultipleStyleSheets) {
			[self.O_styleSheetCustomForLanguageContextsRadioButton setState:NSOnState];
		} else {
			[self.O_styleSheetCustomRadioButton setState:NSOnState];
		}
	}

    DocumentMode *baseMode = [[DocumentModeManager sharedInstance] baseMode];
    DocumentMode *selectedMode = [self.O_modePopUpButton selectedMode];
    [self.O_fontController setContent:([self.O_fontDefaultButton state]==NSOnState)?baseMode:selectedMode];
    [self takeFontFromMode:selectedMode];
	[self highlightSyntax];
}

- (IBAction)changeDefaultState:(id)aSender {
    BOOL useDefault = ([aSender state]==NSOnState);
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
		[[currentMode defaults] setObject:[NSNumber numberWithBool:YES] forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
	} else {
		[[currentMode defaults] setObject:[NSNumber numberWithBool:NO] forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
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

- (IBAction)changeCustomStyleSheet:(id)aSender {
	DocumentMode *currentMode = [self.O_modeController content];
	NSString *styleSheetName = [[self.O_styleSheetCustomPopUpButton selectedItem] title];
	[[currentMode defaults] setObject:[NSNumber numberWithBool:NO] forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
	SEEStyleSheetSettings *styleSheetSettings = [currentMode styleSheetSettingsOfThisMode];
	styleSheetSettings.singleStyleSheetName = styleSheetName;
	styleSheetSettings.usesMultipleStyleSheets = NO;
    [self validateDefaultsState:aSender];
	[self highlightSyntax];
}


- (IBAction)applyToOpenDocuments:(id)aSender {
	[self highlightSyntax];
    [[NSNotificationCenter defaultCenter] postNotificationName:DocumentModeApplyStylePreferencesNotification object:[self.O_modeController content]];
}

- (IBAction)changeFontViaPanel:(id)sender {
    NSDictionary *fontAttributes = [[self.O_modePopUpButton selectedMode] defaultForKey:DocumentModeFontAttributesPreferenceKey];
    NSFont *newFont = [NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
    if (!newFont) {
		newFont = [NSFont userFixedPitchFontOfSize:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
	}
    [[NSFontManager sharedFontManager] setSelectedFont:newFont isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

#pragma mark
- (void)updateStyleSheetLists {
	[self.O_styleSheetCustomPopUpButton removeAllItems];
	[self.O_styleSheetCustomPopUpButton addItemsWithTitles:[[DocumentModeManager sharedInstance] allStyleSheetNames]];
	NSPopUpButtonCell *styleSheetButtonCell = [[self.O_customStylesForLanguageContextsTableView tableColumnWithIdentifier:@"styleSheet"] dataCell];
	[styleSheetButtonCell removeAllItems];
	[styleSheetButtonCell addItemsWithTitles:[[DocumentModeManager sharedInstance] allStyleSheetNames]];
}

- (void)documentModeListChanged:(NSNotification *)aNotification {
    [self performSelector:@selector(changeMode:) withObject:self.O_modePopUpButton afterDelay:.2];
}

- (void)takeFontFromMode:(DocumentMode *)aMode {
    NSDictionary *fontAttributes = [aMode defaultForKey:DocumentModeFontAttributesPreferenceKey];
	//    NSLog(@"%s %@",__FUNCTION__, fontAttributes);
    NSFont *font = [NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
    if (!font) font = [NSFont userFixedPitchFontOfSize:11.];
    [self setBaseFont:font];
}

- (void)selectMode:(DocumentMode *)aDocumentMode {
	[self.O_modeController setContent:aDocumentMode];
	[self.O_modePopUpButton setSelectedMode:aDocumentMode];
	[self updateStyleSheetLists];
	NSString *customStyleSheetName = [[aDocumentMode styleSheetSettings] singleStyleSheetName];
	[self.O_styleSheetCustomPopUpButton selectItemWithTitle:customStyleSheetName];
	[self.O_customStylesForLanguageContextsTableView reloadData];
	[self.O_styleSheetDefaultRadioButton setHidden:[aDocumentMode isBaseMode]];
	// TODO: resize the style settings box
	CGFloat heightChange = 0;
	
	BOOL shouldShow = ([[[aDocumentMode syntaxDefinition] allLanguageContexts] count] > 1);
	shouldShow = NO; // removing this line shows the option to select style sheets per language context
	
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
    if ([self.O_fontDefaultButton state] != NSOnState) {
        NSFont *newFont = [fontManager convertFont:[NSFont userFixedPitchFontOfSize:0.0]]; // could be any font here
        NSMutableDictionary *dict=[NSMutableDictionary dictionary];
        [dict setObject:[newFont fontName] forKey:NSFontNameAttribute];
        [dict setObject:[NSNumber numberWithFloat:[newFont pointSize]] forKey:NSFontSizeAttribute];
        [[self.O_modePopUpButton selectedMode] setValue:dict forKeyPath:@"defaults.FontAttributes"];
        [self changeMode:self.O_modePopUpButton];
    }
}

- (NSArray *)languageContexts {
	return [[[self.O_modeController content] syntaxDefinition] allLanguageContexts];
}

#pragma mark - Syntax highlighting callbacks

- (NSDictionary *)styleAttributesForScope:(NSString *)aScope languageContext:(NSString *)aLanguageContext {
	DocumentMode *currentMode = [self.O_modeController content];
	SEEStyleSheet *styleSheet = [currentMode styleSheetForLanguageContext:aLanguageContext];
	return [SEEStyleSheet textAttributesForStyleAttributes:[styleSheet styleAttributesForScope:aScope] font:self.baseFont];
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
	[[currentMode defaults] setObject:[NSNumber numberWithBool:NO] forKey:DocumentModeUseDefaultStyleSheetPreferenceKey];
	styleSheetSettings.usesMultipleStyleSheets = YES;
	[self highlightSyntax];
}

@end