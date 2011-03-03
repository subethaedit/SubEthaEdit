//
//  StylePreferences.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Oct 07 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "StyleSheetPreferences.h"
#import "SyntaxStyle.h"
#import "DocumentModeManager.h"
#import "DocumentController.h"
#import "TableView.h"
#import "TextFieldCell.h"
#import "GeneralPreferences.h"
#import "SyntaxHighlighter.h"

@interface StyleSheetPreferences ()
@property (nonatomic, retain) SEEStyleSheet *currentStyleSheet;
- (void)updateFontLabel;
- (void)takeFontFromMode:(DocumentMode *)aMode;
@end

@implementation StyleSheetPreferences

@synthesize currentStyleSheet;

- (id) init {
    self = [super init];
    if (self) {
        I_undoManager=[NSUndoManager new];
        SEEStyleSheet *styleSheet = [[SEEStyleSheet new] autorelease];
        [styleSheet importStyleSheetAtPath:[[NSBundle mainBundle] URLForResource:@"Default" withExtension:@"sss" subdirectory:@"Modes/Styles"]];
        self.currentStyleSheet = styleSheet;
        NSLog(@"%s %@",__FUNCTION__,styleSheet.allScopes);
    }
    return self;
}

- (void)dealloc {
    [I_undoManager release];
    self.currentStyleSheet = nil;
    [super dealloc];
}

- (NSImage *)icon {
    return [NSImage imageNamed:@"StyleSheetPrefs"];
}

- (NSString *)iconLabel {
    return NSLocalizedString(@"StyleSheetPrefsIconLabel", @"Label displayed below tyle pref icon and used as window title.");
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.stylesheet";
}

- (NSString *)mainNibName {
    return @"StyleSheetPrefs";
}

- (void)adjustTableViewColumns:(NSNotification *)aNotification {
    float width=[[[O_stylesTableView enclosingScrollView] contentView] frame].size.width;
    width-=[O_stylesTableView intercellSpacing].width;
    NSArray *columns=[O_stylesTableView tableColumns];
    [[columns objectAtIndex:0] setWidth:width];
//    [[columns objectAtIndex:1] setWidth:width2];
}

- (void)mainViewDidLoad {
	[self takeFontFromMode:[DocumentModeManager baseMode]];

    // Initialize user interface elements to reflect current preference settings
    
    // Set tableview to non highlighting cells
    [[[O_stylesTableView tableColumns] objectAtIndex:0] setDataCell:[[TextFieldCell new] autorelease]];
    
    [[O_stylesTableView enclosingScrollView] setPostsFrameChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustTableViewColumns:) name:NSViewFrameDidChangeNotification object:[O_stylesTableView enclosingScrollView]];
    NSMutableAttributedString *string=[[O_italicButton attributedTitle] mutableCopy];
    [string addAttribute:NSObliquenessAttributeName value:[NSNumber numberWithFloat:.2] range:NSMakeRange(0,[[string string] length])];
    [O_italicButton setAttributedTitle:[string autorelease]];
    
    string=[[O_underlineButton attributedTitle] mutableCopy];
    [string addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(0,[[string string] length])];
    [O_underlineButton setAttributedTitle:[string autorelease]];
    
    string=[[O_strikethroughButton attributedTitle] mutableCopy];
    [string addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(0,[[string string] length])];
    [O_strikethroughButton setAttributedTitle:[string autorelease]];
    
    [self adjustTableViewColumns:nil];
    [O_stylesTableView setLightBackgroundColor:[NSColor whiteColor]];
    [O_stylesTableView setDarkBackgroundColor:[NSColor whiteColor]];
}

- (void)didSelect {
//	NSPoint baseOrigin;
//	NSView *styleBox=[O_defaultStyleButton superview];
//	baseOrigin = [styleBox convertPoint:NSMakePoint([styleBox frame].origin.x,
//							 [styleBox frame].origin.y) toView:nil];
//	//NSPoint screenOrigin = 
//	[[styleBox window] convertBaseToScreen:baseOrigin];
//
////        NSRect windowRect=NSMakeRect(screenOrigin.x,screenOrigin.y,
////                                     [styleBox frame].size.width,[styleBox frame].size.height);
////        windowRect=NSInsetRect(windowRect,-2,-2);
//
}

- (void)updateBackgroundColor {
//    NSDictionary *baseStyle=[[[O_styleController content] syntaxStyle] styleForKey:SyntaxStyleBaseIdentifier];
//    [O_backgroundColorWell         setColor:[baseStyle objectForKey:@"background-color"]         ];
//    [O_invertedBackgroundColorWell setColor:[baseStyle objectForKey:@"inverted-background-color"]]; 
//    [O_stylesTableView setLightBackgroundColor:[baseStyle objectForKey:@"background-color"]];
//    [O_stylesTableView setDarkBackgroundColor: [baseStyle objectForKey:@"inverted-background-color"]];
//    [O_stylesTableView reloadData];
}

- (void)takeFontFromMode:(DocumentMode *)aMode {
    NSDictionary *fontAttributes = [aMode defaultForKey:DocumentModeFontAttributesPreferenceKey];
    NSFont *font=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:11.];
    if (!font) font=[NSFont userFixedPitchFontOfSize:11.];
    [self setBaseFont:font];
    [self updateFontLabel];
}

- (IBAction)validateDefaultsState:(id)aSender {
//    BOOL useDefault=[[[O_modePopUpButton selectedMode] defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue];
//    DocumentMode *baseMode=[[DocumentModeManager sharedInstance] baseMode];
//    DocumentMode *selectedMode=[O_modePopUpButton selectedMode];
//    [O_fontController setContent:([O_fontDefaultButton state]==NSOnState)?baseMode:selectedMode];
//    [O_styleController setContent:useDefault?baseMode:selectedMode];
//    [O_defaultStyleButton setHidden:[[I_currentSyntaxStyle documentMode] isBaseMode]];
//    if (O_defaultStyleButton !=aSender) {
//        [O_defaultStyleButton setState:useDefault?NSOnState:NSOffState];
//    }
//
//    [O_stylesTableView setDisableFirstRow:useDefault];
//    
//    if (useDefault) {
//        [O_stylesTableView deselectRow:0];
//    }
//    NSDictionary *baseStyle=[[[O_styleController content] syntaxStyle] styleForKey:SyntaxStyleBaseIdentifier];
//    [O_backgroundColorWell         setColor:[baseStyle objectForKey:@"background-color"]         ];
//    [O_invertedBackgroundColorWell setColor:[baseStyle objectForKey:@"inverted-background-color"]]; 
//    [self takeFontFromMode:selectedMode];
//    [self updateBackgroundColor];
//    [O_lightBackgroundButton       setEnabled:!useDefault];
//    [O_darkBackgroundButton        setEnabled:!useDefault];
//    [O_backgroundColorWell         setEnabled:!useDefault];
//    [O_invertedBackgroundColorWell setEnabled:!useDefault];
}

#define BUFFERSIZE 40

#define UNITITIALIZED -5
#define MANY  -4

- (void)updateInspector {
	NSInteger selectedRow = [O_stylesTableView selectedRow];
	if (selectedRow != -1) {
		NSString *scopeString = [self.currentStyleSheet.allScopes objectAtIndex:selectedRow];
		NSDictionary *computedStyleAttributes = [self.currentStyleSheet      styleAttributesForScope:scopeString];
		NSDictionary *directStyleAttributes   = [self.currentStyleSheet styleAttributesForExactScope:scopeString];
		
		for (NSArray *triple in [NSArray arrayWithObjects:
									[NSArray arrayWithObjects:SEEStyleSheetFontWeightKey,O_inheritBoldButton,O_boldButton,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontStyleKey,O_inheritItalicButton,O_italicButton,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontUnderlineKey,O_inheritUnderlineButton,O_underlineButton,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontStrikeThroughKey,O_inheritStrikethroughButton,O_strikethroughButton,nil],
									nil]) {
			NSString *key = [triple objectAtIndex:0];
			NSButton *inheritButton = [triple objectAtIndex:1];
			NSButton *actualButton = [triple objectAtIndex:2];
			BOOL inherit = [directStyleAttributes objectForKey:key] == 0;
			[inheritButton setState:inherit ? NSOnState : NSOffState];
			NSString *value = [computedStyleAttributes objectForKey:key];
			BOOL isSet = value && ![value isEqualToString:SEEStyleSheetValueNone] && ![value isEqualToString:SEEStyleSheetValueNormal];
			NSLog(@"%s %@ -> %d",__FUNCTION__, value, isSet);
			[actualButton setState:isSet ? NSOnState : NSOffState];
			[actualButton setEnabled:!inherit];
		}

		for (NSArray *triple in [NSArray arrayWithObjects:
									[NSArray arrayWithObjects:SEEStyleSheetFontForegroundColorKey,O_inheritColorWell,O_colorWell,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontBackgroundColorKey,O_inheritBackgroundColorWell,O_backgroundColorWell,nil],
									nil]) {
			NSString *key = [triple objectAtIndex:0];
			NSButton *inheritButton = [triple objectAtIndex:1];
			NSColorWell *well = [triple objectAtIndex:2];
			BOOL inherit = [directStyleAttributes objectForKey:key] == 0;
			[inheritButton setState:inherit ? NSOnState : NSOffState];
			NSColor *value = [computedStyleAttributes objectForKey:key];
			[well setColor:value];
			[well setEnabled:!inherit];
		}
		NSString *snippet = [self.currentStyleSheet styleSheetSnippetForScope:scopeString];
		NSTextStorage *ts = [O_sheetSnippetTextView textStorage];
		[ts setAttributedString:[[[NSAttributedString alloc] initWithString:snippet attributes:[NSDictionary dictionaryWithObject:[NSFont userFixedPitchFontOfSize:11.] forKey:NSFontNameAttribute]] autorelease]];
		
	}
}

- (IBAction)takeInheritanceState:(id)aSender {
	NSInteger selectedRow = [O_stylesTableView selectedRow];
	if (selectedRow != -1) {
		NSLog(@"%s %d",__FUNCTION__, [aSender state]);
		NSString *scopeString = [self.currentStyleSheet.allScopes objectAtIndex:selectedRow];
		NSDictionary *computedStyleAttributes = [self.currentStyleSheet      styleAttributesForScope:scopeString];
		NSMutableDictionary *directStyleAttributes   = [[[self.currentStyleSheet styleAttributesForExactScope:scopeString] mutableCopy] autorelease];
		for (NSArray *triple in [NSArray arrayWithObjects:
									[NSArray arrayWithObjects:SEEStyleSheetFontWeightKey,O_inheritBoldButton,O_boldButton,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontStyleKey,O_inheritItalicButton,O_italicButton,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontUnderlineKey,O_inheritUnderlineButton,O_underlineButton,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontStrikeThroughKey,O_inheritStrikethroughButton,O_strikethroughButton,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontForegroundColorKey,O_inheritColorWell,O_colorWell,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontBackgroundColorKey,O_inheritBackgroundColorWell,O_backgroundColorWell,nil],
									nil]) {
			NSString *key = [triple objectAtIndex:0];
			NSButton *inheritButton = [triple objectAtIndex:1];
//			NSButton *actualButton = [triple objectAtIndex:2];
			if ([directStyleAttributes objectForKey:key] && inheritButton.state == NSOnState) {
				[directStyleAttributes removeObjectForKey:key];
			} else if (![directStyleAttributes objectForKey:key] && inheritButton.state == NSOffState) {
				id value = [computedStyleAttributes objectForKey:key];
				if (value) {
					[directStyleAttributes setObject:value forKey:key];
				}
			}
		}
		NSLog(@"%s %@",__FUNCTION__, directStyleAttributes);
		[self.currentStyleSheet setStyleAttributes:directStyleAttributes forScope:scopeString];
		[O_stylesTableView reloadData];
		[self updateInspector];
	}
	
}

- (IBAction)changeForegroundColor:(id)aSender {
	NSInteger selectedRow = [O_stylesTableView selectedRow];
	if (selectedRow != -1) {
		NSString *scopeString = [self.currentStyleSheet.allScopes objectAtIndex:selectedRow];
		NSMutableDictionary *directStyleAttributes   = [[[self.currentStyleSheet styleAttributesForExactScope:scopeString] mutableCopy] autorelease];
		[directStyleAttributes setObject:[aSender color] forKey:SEEStyleSheetFontForegroundColorKey];
		NSLog(@"%s %@",__FUNCTION__, directStyleAttributes);
		[self.currentStyleSheet setStyleAttributes:directStyleAttributes forScope:scopeString];
		[O_stylesTableView reloadData];
		[self updateInspector];
	}
}

- (IBAction)changeBackgroundColor:(id)aSender {
	NSInteger selectedRow = [O_stylesTableView selectedRow];
	if (selectedRow != -1) {
		NSString *scopeString = [self.currentStyleSheet.allScopes objectAtIndex:selectedRow];
		NSMutableDictionary *directStyleAttributes   = [[[self.currentStyleSheet styleAttributesForExactScope:scopeString] mutableCopy] autorelease];
		[directStyleAttributes setObject:[aSender color] forKey:SEEStyleSheetFontBackgroundColorKey];
		NSLog(@"%s %@",__FUNCTION__, directStyleAttributes);
		[self.currentStyleSheet setStyleAttributes:directStyleAttributes forScope:scopeString];
		[O_stylesTableView reloadData];
		[self updateInspector];
	}
}

- (void)changeTraitByButton:(NSButton *)aButton key:(NSString *)aKey yesValue:(id)aYesValue noValue:(id)aNoValue {
	NSInteger selectedRow = [O_stylesTableView selectedRow];
	if (selectedRow != -1) {
		NSString *scopeString = [self.currentStyleSheet.allScopes objectAtIndex:selectedRow];
		NSMutableDictionary *directStyleAttributes   = [[[self.currentStyleSheet styleAttributesForExactScope:scopeString] mutableCopy] autorelease];
		[directStyleAttributes setObject:[aButton state] == NSOnState ? aYesValue : aNoValue forKey:aKey];
		NSLog(@"%s %@",__FUNCTION__, directStyleAttributes);
		[self.currentStyleSheet setStyleAttributes:directStyleAttributes forScope:scopeString];
		[O_stylesTableView reloadData];
		[self updateInspector];
	}
}

- (IBAction)changeFontTraitItalic:(id)aSender {
	[self changeTraitByButton:aSender key:SEEStyleSheetFontStyleKey yesValue:SEEStyleSheetValueItalic noValue:SEEStyleSheetValueNormal];
}

- (IBAction)changeFontTraitBold:(id)aSender {
	[self changeTraitByButton:aSender key:SEEStyleSheetFontWeightKey yesValue:SEEStyleSheetValueBold noValue:SEEStyleSheetValueNormal];
}

- (IBAction)changeFontTraitUnderline:(id)aSender {
	[self changeTraitByButton:aSender key:SEEStyleSheetFontUnderlineKey yesValue:SEEStyleSheetValueUnderline noValue:SEEStyleSheetValueNone];
}

- (IBAction)changeFontTraitStrikethrough:(id)aSender {
	[self changeTraitByButton:aSender key:SEEStyleSheetFontStrikeThroughKey yesValue:SEEStyleSheetValueStrikeThrough noValue:SEEStyleSheetValueNone];
}




- (NSUndoManager *)undoManager {
    return I_undoManager;
}

//- (void)setStyle:(SyntaxStyle *)aStyle {
//    // style now
//    DocumentMode *mode=[aStyle documentMode];
//    SyntaxStyle *styleToRegister=[[[mode syntaxStyle] copy] autorelease];
//    [I_undoManager registerUndoWithTarget:self selector:@selector(setStyle:) object:styleToRegister];
//    NSIndexSet *newSelection=[SyntaxStyle indexesWhereStyle:aStyle isNotEqualToStyle:styleToRegister];
//    [mode setSyntaxStyle:aStyle];
//    if (![[O_modePopUpButton selectedMode] isEqualTo:mode]) {
//        [O_modePopUpButton setSelectedMode:mode];
//        [self changeMode:O_modePopUpButton];
//    } else {
//        I_currentSyntaxStyle=aStyle;
//        [O_stylesTableView reloadData];
//    }
//    [O_stylesTableView selectRowIndexes:newSelection byExtendingSelection:NO];
//    [O_stylesTableView scrollRowToVisible:[newSelection firstIndex]];
//    [self updateBackgroundColor];
//    [self updateInspector];
//}
//
//
//- (void)storeCurrentStyleForUndo {
//    [I_undoManager registerUndoWithTarget:self selector:@selector(setStyle:) object:[[I_currentSyntaxStyle copy] autorelease]];
//}

#pragma mark -
#pragma mark IBActions

//- (IBAction)changeBackgroundColor:(id)aSender {
//    [self storeCurrentStyleForUndo];
//    NSMutableDictionary *baseStyle=[I_currentSyntaxStyle styleForKey:SyntaxStyleBaseIdentifier];
//    [baseStyle setObject:[aSender color] forKey:@"background-color"];
//    [self updateBackgroundColor];
//}
//
//- (IBAction)changeDarkBackgroundColor:(id)aSender {
//    [self storeCurrentStyleForUndo];
//    NSMutableDictionary *baseStyle=[I_currentSyntaxStyle styleForKey:SyntaxStyleBaseIdentifier];
//    [baseStyle setObject:[aSender color] forKey:@"inverted-background-color"];
//    [self updateBackgroundColor];
//}
//
//- (void)setKey:(NSString *)aKey ofSelectedStylesToObject:(id)anObject {
//    [self storeCurrentStyleForUndo];
//    NSMutableDictionary *style=nil;
//    NSEnumerator *selectedStyles=[self selectedStylesEnumerator];
//    while ((style=[selectedStyles nextObject])) {
//        [style setObject:anObject forKey:aKey];
//    }
//    [O_stylesTableView reloadData];
//    [self updateInspector];
//}
//
//- (IBAction)changeLightForegroundColor:(id)aSender {
//    [self setKey:@"color" ofSelectedStylesToObject:[aSender color]];
//}
//
//- (IBAction)changeDarkForegroundColor:(id)aSender {
//    [self setKey:@"inverted-color" ofSelectedStylesToObject:[aSender color]];
//}
//
//- (void)setTrait:(NSFontTraitMask)aTrait ofSelectedStylesTo:(BOOL)aState {
//    [self storeCurrentStyleForUndo];
//    NSMutableDictionary *style=nil;
//    NSEnumerator *selectedStyles=[self selectedStylesEnumerator];
//    while ((style=[selectedStyles nextObject])) {
//        NSFontTraitMask traits=[[style objectForKey:@"font-trait"] unsignedIntValue];
//        BOOL currentState = traits & aTrait;
//        if (aState && !currentState) {
//            traits = traits | aTrait;
//        } else if (!aState && currentState) {
//            traits = traits & (~aTrait);
//        }
//        [style setObject:[NSNumber numberWithUnsignedInt:traits] forKey:@"font-trait"];
//    }
//    [O_stylesTableView reloadData];
//    [self updateInspector];
//}
//
//- (IBAction)changeFontTraitItalic:(id)aSender {
//    [aSender setAllowsMixedState:NO];
//    [self setTrait:NSItalicFontMask ofSelectedStylesTo:[aSender state]==NSOnState];
//}
//
//- (IBAction)changeFontTraitBold:(id)aSender {
//    [aSender setAllowsMixedState:NO];
//    [self setTrait:NSBoldFontMask ofSelectedStylesTo:[aSender state]==NSOnState];
//}
//
//- (IBAction)import:(id)aSender {
//    NSOpenPanel *openPanel=[NSOpenPanel openPanel];
//    [openPanel setAllowsMultipleSelection:NO];
//    [openPanel setRequiredFileType:@"seestyle"];
//    [openPanel setCanChooseDirectories:NO];
//    [openPanel setCanChooseFiles:YES];
//    [openPanel setExtensionHidden:NO];
//    [openPanel beginSheetForDirectory:nil file:nil 
//               types:[NSArray arrayWithObject:@"seestyle"] 
//               modalForWindow:[O_stylesTableView window] 
//               modalDelegate:self 
//               didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
//               contextInfo:nil];
//}
//
//- (void)importStyleFile:(NSString *)aFilename {
//    NSArray *styleArray=[SyntaxStyle syntaxStylesWithXMLFile:aFilename];
//    if ([styleArray count]>0) {
//        NSMutableString *modeString=[[[[[styleArray objectAtIndex:0] documentMode] displayName] mutableCopy] autorelease];
//        int i;
//        for (i=1;i<[styleArray count];i++) {
//            [modeString appendFormat:@", %@",[[[styleArray objectAtIndex:i] documentMode] displayName]];
//        }
//        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
//        [alert setAlertStyle:NSWarningAlertStyle];
//        [alert setMessageText:NSLocalizedString(@"SeeStyleImportMessage", @"Message Text of Style load alert sheet")];
//        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"SeeStyleImportInformative %@",  @"Informative Text of Style load alert sheet"),modeString]];
//        [alert addButtonWithTitle:NSLocalizedString(@"Import", @"Button choice allowing user to import")];
//        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Button choice allowing user to cancel.")];
//        [alert addButtonWithTitle:NSLocalizedString(@"Open in Editor", @"Button choice allowing user open a file in the editor.")];
//        [alert beginSheetModalForWindow:[O_stylesTableView window]
//                          modalDelegate:self
//                         didEndSelector:@selector(importDidEnd:returnCode:contextInfo:)
//                            contextInfo:[[NSDictionary dictionaryWithObjectsAndKeys:aFilename,@"filename",styleArray,@"style",nil] retain]];
//    } else {
//        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
//        [alert setAlertStyle:NSWarningAlertStyle];
//        [alert setMessageText:NSLocalizedString(@"SeeStyleImportDidFailMessage", @"Message Text of Style load did fail alert sheet")];
//        [alert setInformativeText:NSLocalizedString(@"SeeStyleImportDidFailInformative", @"Informative Text of Style load did fail alert sheet")];
//        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
//        [alert beginSheetModalForWindow:[O_stylesTableView window]
//                          modalDelegate:nil
//                         didEndSelector:nil
//                            contextInfo:NULL];
//    }
//}
//
//- (void)importDidEnd:(NSAlert *)anAlert returnCode:(int)aReturnCode contextInfo:(void *)aDictionary {
//    NSDictionary *dictionary=[(NSDictionary *)aDictionary autorelease];
//    if (aReturnCode == NSAlertFirstButtonReturn) {
//        NSEnumerator *styles=[[dictionary objectForKey:@"style"] objectEnumerator];
//        SyntaxStyle *style=nil;
//        [I_undoManager beginUndoGrouping];
//        while ((style = [styles nextObject])) {
//            [self setStyle:style];
//        }
//        [I_undoManager endUndoGrouping];
//    } else if (aReturnCode == NSAlertThirdButtonReturn) {
//        [[DocumentController sharedInstance] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[dictionary objectForKey:@"filename"]] display:YES error:nil];
//    }
//}
//
//- (void)openPanelDidEnd:(NSOpenPanel *)aPanel returnCode:(int)aReturnCode contextInfo:(void *)contextInfo {
//    NSString *filename=[aPanel filename];
//    if (aReturnCode==NSOKButton) {
//        [aPanel orderOut:self];
//        [self importStyleFile:filename];
//    }
//}
//
//- (IBAction)export:(id)aSender {
//    I_shouldExportAll = ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0;
//    NSSavePanel *savePanel=[NSSavePanel savePanel];
//    [savePanel setPrompt:NSLocalizedString(@"ExportPrompt",@"Text on the active SavePanel Button in the export sheet")];
//    [savePanel setCanCreateDirectories:YES];
//    [savePanel setExtensionHidden:NO];
//    [savePanel setAllowsOtherFileTypes:YES];
//    [savePanel setTreatsFilePackagesAsDirectories:YES];
//    [savePanel setRequiredFileType:@"seestyle"];
//    [savePanel beginSheetForDirectory:nil 
//        file:[I_shouldExportAll?NSLocalizedString(@"StylePrefsIconLabel",@""):[[[[I_currentSyntaxStyle documentMode]  documentModeIdentifier] componentsSeparatedByString:@"."] lastObject] stringByAppendingPathExtension:@"seestyle"] 
//        modalForWindow:[O_stylesTableView window] 
//        modalDelegate:self 
//        didEndSelector:@selector(exportSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
//}
//
//- (void)exportSheetDidEnd:(NSSavePanel *)aPanel returnCode:(int)aReturnCode contextInfo:(void *)aContextInfo {
//    if (aReturnCode==NSOKButton) {
//        [[I_shouldExportAll?[DocumentModeManager xmlFileRepresentationOfAllStyles]:[I_currentSyntaxStyle xmlFileRepresentation] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] writeToFile:[aPanel filename] atomically:YES];
//    }
//}
//
//- (IBAction)revertToMode:(id)aSender {
//    [self storeCurrentStyleForUndo];
//    DocumentMode *mode=[I_currentSyntaxStyle documentMode];
//    [mode setSyntaxStyle:[[[mode defaultSyntaxStyle] copy] autorelease]];
//    [self changeMode:O_modePopUpButton];
//}
//
//- (IBAction)revertSelectionToMode:(id)aSender {
//    [self storeCurrentStyleForUndo];
//    NSMutableDictionary *style=nil;
//    NSEnumerator *selectedStyles=[self selectedStylesEnumerator];
//    SyntaxStyle *defaultStyle=[[O_modePopUpButton selectedMode] defaultSyntaxStyle];
//    while ((style=[selectedStyles nextObject])) {
//        [style addEntriesFromDictionary:[defaultStyle styleForKey:[style objectForKey:kSyntaxHighlightingStyleIDAttributeName]]];
//    }
//    [O_stylesTableView reloadData];
//    [self updateInspector];
//}
//
//- (IBAction)applyToOpenDocuments:(id)aSender {
//    [[NSNotificationCenter defaultCenter] postNotificationName:DocumentModeApplyStylePreferencesNotification object:[O_modeController content]];
//}
//
//
//- (void)didUnselect {
//    // Save preferences
//    [[[NSFontManager sharedFontManager] fontPanel:NO] orderOut:self];
//}
//
- (IBAction)changeFontViaPanel:(id)sender {

    NSFont *newFont = [self baseFont];
    if (!newFont) newFont=[NSFont userFixedPitchFontOfSize:11.0];
    [[NSFontManager sharedFontManager] 
        setSelectedFont:newFont 
             isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (void)updateFontLabel {
	NSFont *font = self.baseFont;
	[O_fontLabel setFont:font];
	[O_fontLabel setStringValue:[NSString stringWithFormat:@"%@, %.1f",[font displayName],[font pointSize]]];
}

- (void)changeFont:(id)fontManager {
	NSFont *newFont = [fontManager convertFont:[NSFont userFixedPitchFontOfSize:0.0]]; // could be any font here
	[self setBaseFont:[[NSFontManager sharedFontManager] convertFont:newFont toSize:11.0]];
	[self updateFontLabel];
	[O_stylesTableView reloadData];
}

- (void)setBaseFont:(NSFont *)aFont {
    [I_baseFont autorelease];
     I_baseFont = [aFont retain];
}

- (NSFont *)baseFont {
    return I_baseFont;
}

- (NSDictionary *)textAttributesForScope:(NSString *)aScopeString {
	NSDictionary *computedStyle = [self.currentStyleSheet styleAttributesForScope:aScopeString];
	NSFont *font = [self baseFont];
	return [SEEStyleSheet textAttributesForStyleAttributes:computedStyle font:font];
}

#pragma mark -
#pragma mark TableView DataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [self.currentStyleSheet.allScopes count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)aRow {
	NSString *scopeString = [self.currentStyleSheet.allScopes objectAtIndex:aRow];
	NSDictionary *textAttributes = [self textAttributesForScope:scopeString];
	return [[[NSAttributedString alloc] initWithString:scopeString attributes:textAttributes] autorelease];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self updateInspector];
}

@end