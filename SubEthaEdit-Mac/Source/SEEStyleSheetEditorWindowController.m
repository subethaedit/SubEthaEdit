//  StylePreferences.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Oct 07 2004.

#import "SEEStyleSheetEditorWindowController.h"
#import "SyntaxStyle.h"
#import "DocumentModeManager.h"
#import "SEEDocumentController.h"
#import "TableView.h"
#import "TextFieldCell.h"
#import "GeneralPreferences.h"
#import "SyntaxHighlighter.h"
#import "PlainTextDocument.h"

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


// TODO: clean out the rest of the pref pane related things, make sure everything that needs to be called is still called. 

@interface SEEStyleSheetEditorWindowController ()
@property (nonatomic, strong) SEEStyleSheet *currentStyleSheet;

@property (nonatomic, strong) IBOutlet TableView *O_stylesTableView;
@property (nonatomic, strong) IBOutlet DocumentModePopUpButton *O_modePopUpButton;
@property (nonatomic, strong) IBOutlet NSObjectController *O_modeController;

@property (nonatomic, strong) IBOutlet NSButton *O_boldButton;
@property (nonatomic, strong) IBOutlet NSButton *O_italicButton;
@property (nonatomic, strong) IBOutlet NSButton *O_underlineButton;
@property (nonatomic, strong) IBOutlet NSButton *O_strikethroughButton;

@property (nonatomic, strong) IBOutlet NSColorWell *O_colorWell;
@property (nonatomic, strong) IBOutlet NSColorWell *O_backgroundColorWell;

@property (nonatomic, strong) IBOutlet NSButton *O_inheritBoldButton;
@property (nonatomic, strong) IBOutlet NSButton *O_inheritItalicButton;
@property (nonatomic, strong) IBOutlet NSButton *O_inheritUnderlineButton;
@property (nonatomic, strong) IBOutlet NSButton *O_inheritStrikethroughButton;
@property (nonatomic, strong) IBOutlet NSButton *O_inheritColorWell;
@property (nonatomic, strong) IBOutlet NSButton *O_inheritBackgroundColorWell;

@property (nonatomic, strong) IBOutlet NSPopUpButton *O_styleSheetPopUpButton;

@property (nonatomic, strong) IBOutlet NSTextView *O_sheetSnippetTextView;

@property (nonatomic, strong) IBOutlet NSButton *O_saveStyleSheetButton;
@property (nonatomic, strong) IBOutlet NSButton *O_revertStyleSheetButton;
@property (nonatomic, strong) IBOutlet NSButton *O_revealInFinderButton;

@property (nonatomic, strong) IBOutlet NSButton *O_duplicateStyleSheetButton;

@property (nonatomic, strong) IBOutlet NSButton *O_addScopeButton;
@property (nonatomic, strong) IBOutlet NSButton *O_removeScopeButton;

@property (nonatomic, strong) IBOutlet NSButton *O_showOnlyMatchingScopesButton;

@property (nonatomic, strong) IBOutlet NSComboBox *O_scopeComboBox;

@property (nonatomic, strong) IBOutlet NSTextField *O_fontLabel;

@property (nonatomic, strong) NSUndoManager *undoManager;

@end

@implementation SEEStyleSheetEditorWindowController

- (id)init {
    self = [super initWithWindowNibName:@"SEEStyleSheetEditorWindowController"];
    if (self) {
        self.undoManager = [NSUndoManager new];
        SEEStyleSheet *styleSheet = [SEEStyleSheet new];
//		[styleSheet importStyleSheetAtPath:[[NSBundle mainBundle] URLForResource:@"Default" withExtension:@"sss" subdirectory:@"Modes/Styles"]];
        self.currentStyleSheet = styleSheet;
//		NSLog(@"%s %@",__FUNCTION__,styleSheet.allScopes);
    }
    return self;
}

- (void)windowDidLoad {
	[self.window setTitle:NSLocalizedString(@"StyleSheetPrefsIconLabel", @"Label displayed below tyle pref icon and used as window title.")];
	[self takeFontFromMode:[DocumentModeManager baseMode]];
	
	[self.O_styleSheetPopUpButton removeAllItems];
	[self.O_styleSheetPopUpButton addItemsWithTitles:[[DocumentModeManager sharedInstance] allStyleSheetNames]];
	[self switchToStyleSheetName:[self.O_styleSheetPopUpButton itemTitleAtIndex:0]];
    
    // Set tableview to non highlighting cells
    for (NSTableColumn *column in [self.O_stylesTableView tableColumns]) {
		[column setDataCell:[TextFieldCell new]];
	}
    
    [[self.O_stylesTableView enclosingScrollView] setPostsFrameChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustTableViewColumns:) name:NSViewFrameDidChangeNotification object:[self.O_stylesTableView enclosingScrollView]];
    NSMutableAttributedString *string=[[self.O_italicButton attributedTitle] mutableCopy];
    [string addAttribute:NSObliquenessAttributeName value:[NSNumber numberWithFloat:.2] range:NSMakeRange(0,[[string string] length])];
    [self.O_italicButton setAttributedTitle:string];
    
    string=[[self.O_underlineButton attributedTitle] mutableCopy];
    [string addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(0,[[string string] length])];
    [self.O_underlineButton setAttributedTitle:string];
    
    string=[[self.O_strikethroughButton attributedTitle] mutableCopy];
    [string addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(0,[[string string] length])];
    [self.O_strikethroughButton setAttributedTitle:string];
    
    [self adjustTableViewColumns:nil];
    [self updateForChangedStyles];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentModeListChanged:) name:@"DocumentModeListChanged" object:nil];
}

- (void)dealloc {
    self.currentStyleSheet = nil;
}

- (void)adjustTableViewColumns:(NSNotification *)aNotification {
    CGFloat width=[[[self.O_stylesTableView enclosingScrollView] contentView] frame].size.width;
    width-=[self.O_stylesTableView intercellSpacing].width * 2;
    CGFloat width2 = MIN(300,width/2);
    NSArray *columns=[self.O_stylesTableView tableColumns];
    [[columns objectAtIndex:0] setWidth:width2];
    [[columns objectAtIndex:1] setWidth:width-width2];
}

- (void)switchToStyleSheetName:(NSString *)aStyleSheetName {
	self.currentStyleSheet = [[DocumentModeManager sharedInstance] styleSheetForName:aStyleSheetName];
	[self.currentStyleSheet setScopeExamples:[[self.O_modeController content] scopeExamples]];
	[self updateForChangedStyles];
}

- (void)changeStyleSheet:(id)aSender {
	NSString *styleSheetName = [[self.O_styleSheetPopUpButton selectedItem] title];
	[self switchToStyleSheetName:styleSheetName];
}

- (void)didSelect {
	PlainTextDocument *frontmostDocument = [[SEEDocumentController sharedInstance] frontmostPlainTextDocument];
	if (frontmostDocument) {
		[self selectMode:[frontmostDocument documentMode]];
		// TODO: select a stylesheet from the mode's stylesheet settings (if not already the case)
	}
}

- (void)updateBackgroundColor {
	NSColor *backgroundColor = [[self.currentStyleSheet styleAttributesForScope:SEEStyleSheetMetaDefaultScopeName] objectForKey:SEEStyleSheetFontBackgroundColorKey];
	if (!backgroundColor) backgroundColor = [NSColor whiteColor];
    [self.O_stylesTableView setLightBackgroundColor:backgroundColor];
    [self.O_stylesTableView setDarkBackgroundColor: backgroundColor];
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

- (void)updateScopeButtons {
	BOOL scopeExists = ([self.currentStyleSheet styleAttributesForExactScope:[self.O_scopeComboBox stringValue]] != nil);
	
	[self.O_addScopeButton    setEnabled:!scopeExists];
	[self.O_removeScopeButton setEnabled:scopeExists];
}

- (void)updateInspector {
	NSInteger selectedRow = [self.O_stylesTableView selectedRow];
	if (selectedRow != -1) {
		NSString *scopeString = [[self scopesArray] objectAtIndex:selectedRow];
		
		[self.O_scopeComboBox setStringValue:scopeString];
		
		NSDictionary *computedStyleAttributes = [self.currentStyleSheet      styleAttributesForScope:scopeString];
		NSDictionary *directStyleAttributes   = [self.currentStyleSheet styleAttributesForExactScope:scopeString];
		
		for (NSArray *triple in [NSArray arrayWithObjects:
									[NSArray arrayWithObjects:SEEStyleSheetFontWeightKey,self.O_inheritBoldButton,self.O_boldButton,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontStyleKey,self.O_inheritItalicButton,self.O_italicButton,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontUnderlineKey,self.O_inheritUnderlineButton,self.O_underlineButton,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontStrikeThroughKey,self.O_inheritStrikethroughButton,self.O_strikethroughButton,nil],
									nil]) {
			NSString *key = [triple objectAtIndex:0];
			NSButton *inheritButton = [triple objectAtIndex:1];
			NSButton *actualButton = [triple objectAtIndex:2];
			BOOL inherit = [directStyleAttributes objectForKey:key] == 0;
			[inheritButton setState:inherit ? NSOnState : NSOffState];
			NSString *value = [computedStyleAttributes objectForKey:key];
			BOOL isSet = value && ![value isEqualToString:SEEStyleSheetValueNone] && ![value isEqualToString:SEEStyleSheetValueNormal];
//			NSLog(@"%s %@ -> %d",__FUNCTION__, value, isSet);
			[actualButton setState:isSet ? NSOnState : NSOffState];
			[actualButton setEnabled:!inherit];
		}

		for (NSArray *triple in [NSArray arrayWithObjects:
									[NSArray arrayWithObjects:SEEStyleSheetFontForegroundColorKey,self.O_inheritColorWell,self.O_colorWell,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontBackgroundColorKey,self.O_inheritBackgroundColorWell,self.O_backgroundColorWell,nil],
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
		NSTextStorage *ts = [self.O_sheetSnippetTextView textStorage];
        [ts setAttributedString:[[NSAttributedString alloc] initWithString:snippet attributes:@{ NSFontAttributeName : [NSFont userFixedPitchFontOfSize:11.],
                                                                                                 NSForegroundColorAttributeName : [NSColor labelColor] }]];
		
	}
	BOOL hasChanges = [self.currentStyleSheet hasChanges];
	[self.O_saveStyleSheetButton   setEnabled:hasChanges];
	[self.O_revertStyleSheetButton setEnabled:hasChanges];
	[self updateScopeButtons];
}

- (IBAction)toggleMatchingScopes:(id)aSender {
	[self.O_stylesTableView reloadData];
}


- (IBAction)takeInheritanceState:(id)aSender {
	NSInteger selectedRow = [self.O_stylesTableView selectedRow];
	if (selectedRow != -1) {
		NSLog(@"%s %ld",__FUNCTION__, (long)[aSender state]);
		NSString *scopeString = [[self scopesArray] objectAtIndex:selectedRow];
		NSDictionary *computedStyleAttributes = [self.currentStyleSheet      styleAttributesForScope:scopeString];
		NSMutableDictionary *directStyleAttributes   = [[self.currentStyleSheet styleAttributesForExactScope:scopeString] mutableCopy];
		for (NSArray *triple in [NSArray arrayWithObjects:
									[NSArray arrayWithObjects:SEEStyleSheetFontWeightKey,self.O_inheritBoldButton,self.O_boldButton,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontStyleKey,self.O_inheritItalicButton,self.O_italicButton,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontUnderlineKey,self.O_inheritUnderlineButton,self.O_underlineButton,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontStrikeThroughKey,self.O_inheritStrikethroughButton,self.O_strikethroughButton,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontForegroundColorKey,self.O_inheritColorWell,self.O_colorWell,nil],
									[NSArray arrayWithObjects:SEEStyleSheetFontBackgroundColorKey,self.O_inheritBackgroundColorWell,self.O_backgroundColorWell,nil],
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
		[self updateForChangedStyles];
	}
	
}

- (void)updateForChangedStyles {
	[self.O_stylesTableView reloadData];
	[self updateBackgroundColor];
	[self updateInspector];
}


- (void)selectMode:(DocumentMode *)aDocumentMode {
	[self.O_modeController setContent:aDocumentMode];
	[self.O_modePopUpButton setSelectedMode:aDocumentMode];
	[self.currentStyleSheet setScopeExamples:[aDocumentMode scopeExamples]];

	NSDictionary *fontAttributes=[aDocumentMode defaultForKey:DocumentModeFontAttributesPreferenceKey];
	NSFont *newFont=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:12.0];
	if (!newFont) newFont=[NSFont userFixedPitchFontOfSize:12.0];
	[self setBaseFont:newFont];


	[self.O_stylesTableView reloadData];
	[self.O_scopeComboBox reloadData];
	NSLog(@"%s scopes:%@ \n contexts:%@",__FUNCTION__, [aDocumentMode.syntaxDefinition allScopes], [aDocumentMode.syntaxDefinition allLanguageContexts]);
}

- (IBAction)changeMode:(id)aSender {
    DocumentMode *newMode=[aSender selectedMode];
    if (newMode) {
	    [self selectMode:newMode];
    }
}

- (IBAction)applyToOpenDocuments:(id)aSender {
	for (DocumentMode *mode in [[DocumentModeManager sharedInstance] allLoadedDocumentModes]) {
	    [[NSNotificationCenter defaultCenter] postNotificationName:DocumentModeApplyStylePreferencesNotification object:mode];
	}
}


- (IBAction)changeForegroundColor:(id)aSender {
	NSInteger selectedRow = [self.O_stylesTableView selectedRow];
	if (selectedRow != -1) {
		NSString *scopeString = [[self scopesArray] objectAtIndex:selectedRow];
		NSMutableDictionary *directStyleAttributes = [[self.currentStyleSheet styleAttributesForExactScope:scopeString] mutableCopy];
		[directStyleAttributes setObject:[aSender color] forKey:SEEStyleSheetFontForegroundColorKey];
		NSLog(@"%s %@",__FUNCTION__, directStyleAttributes);
		[self.currentStyleSheet setStyleAttributes:directStyleAttributes forScope:scopeString];
		[self updateForChangedStyles];
	}
}

- (IBAction)changeBackgroundColor:(id)aSender {
	NSInteger selectedRow = [self.O_stylesTableView selectedRow];
	if (selectedRow != -1) {
		NSString *scopeString = [[self scopesArray] objectAtIndex:selectedRow];
		NSMutableDictionary *directStyleAttributes   = [[self.currentStyleSheet styleAttributesForExactScope:scopeString] mutableCopy];
		[directStyleAttributes setObject:[aSender color] forKey:SEEStyleSheetFontBackgroundColorKey];
		NSLog(@"%s %@",__FUNCTION__, directStyleAttributes);
		[self.currentStyleSheet setStyleAttributes:directStyleAttributes forScope:scopeString];
		[self updateForChangedStyles];
	}
}

- (void)changeTraitByButton:(NSButton *)aButton key:(NSString *)aKey yesValue:(id)aYesValue noValue:(id)aNoValue {
	NSInteger selectedRow = [self.O_stylesTableView selectedRow];
	if (selectedRow != -1) {
		NSString *scopeString = [[self scopesArray] objectAtIndex:selectedRow];
		NSMutableDictionary *directStyleAttributes   = [[self.currentStyleSheet styleAttributesForExactScope:scopeString] mutableCopy];
		[directStyleAttributes setObject:[aButton state] == NSOnState ? aYesValue : aNoValue forKey:aKey];
		NSLog(@"%s %@",__FUNCTION__, directStyleAttributes);
		[self.currentStyleSheet setStyleAttributes:directStyleAttributes forScope:scopeString];
		[self updateForChangedStyles];
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


- (IBAction)saveStyleSheet:(id)aSender {
	[[DocumentModeManager sharedInstance] saveStyleSheet:self.currentStyleSheet];
	[self updateInspector];
}

- (IBAction)duplicateStyleSheet:(id)aSender {
	SEEStyleSheet *sheet = [[DocumentModeManager sharedInstance] duplicateStyleSheet:self.currentStyleSheet];
	[self.O_styleSheetPopUpButton removeAllItems];
	[self.O_styleSheetPopUpButton addItemsWithTitles:[[DocumentModeManager sharedInstance] allStyleSheetNames]];
	[self.O_styleSheetPopUpButton selectItemWithTitle:[sheet styleSheetName]];
	[self changeStyleSheet:self];
}

- (IBAction)revertStyleSheet:(id)aSender {
	[self.currentStyleSheet revertToPersistentState];
	[self updateInspector];
	[self.O_stylesTableView reloadData];
}


- (IBAction)revealStyleSheetInFinder:(id)aSender {
	[[DocumentModeManager sharedInstance] revealStyleSheetInFinder:self.currentStyleSheet];
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
//        [[SEEDocumentController sharedInstance] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[dictionary objectForKey:@"filename"]] display:YES error:nil];
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

- (void)documentModeListChanged:(NSNotification *)aNotification {
    [self performSelector:@selector(changeMode:) withObject:self.O_modePopUpButton afterDelay:.2];
}

- (IBAction)removeScope:(id)aSender {
	NSString *scopeString = [self.O_scopeComboBox stringValue];
	BOOL scopeExists = ([self.currentStyleSheet styleAttributesForExactScope:scopeString] != nil);

	if (scopeExists) {
		[self.currentStyleSheet removeStyleAttributesForScope:scopeString];
		[self updateForChangedStyles];
	}
}
- (IBAction)addScope:(id)aSender {
	NSString *scopeString = [self.O_scopeComboBox stringValue];
	BOOL scopeExists = ([self.currentStyleSheet styleAttributesForExactScope:scopeString] != nil);
	NSString *selectedScopeString = [[self scopesArray] objectAtIndex:[self.O_stylesTableView selectedRow]];

	if (!scopeExists) {
		[self.currentStyleSheet setStyleAttributes:[self.currentStyleSheet styleAttributesForExactScope:selectedScopeString] forScope:scopeString];
		[self updateForChangedStyles];
	}
}


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
	[self.O_fontLabel setFont:font];
	[self.O_fontLabel setStringValue:[NSString stringWithFormat:@"%@, %.1f",[font displayName],[font pointSize]]];
}

- (void)changeFont:(id)fontManager {
	NSFont *newFont = [fontManager convertFont:[NSFont userFixedPitchFontOfSize:0.0]]; // could be any font here
	[self setBaseFont:[[NSFontManager sharedFontManager] convertFont:newFont toSize:11.0]];
	[self updateFontLabel];
	[self updateForChangedStyles];
}

- (NSDictionary *)textAttributesForScope:(NSString *)aScopeString {
	NSDictionary *computedStyle = [self.currentStyleSheet styleAttributesForScope:aScopeString];
	NSFont *font = [self baseFont];
	NSMutableDictionary *result = [[SEEStyleSheet textAttributesForStyleAttributes:computedStyle font:font] mutableCopy];
    static NSMutableParagraphStyle *s_paragraphStyle=nil;
    if (!s_paragraphStyle) {
        s_paragraphStyle=[[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [s_paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    }
	[result setObject:s_paragraphStyle forKey:NSParagraphStyleAttributeName];
	return result;
}

- (IBAction)copy:aSender {
	NSInteger selectedRow = [self.O_stylesTableView selectedRow];
	if (selectedRow != -1) {
		NSString *scopeString = [[self scopesArray] objectAtIndex:selectedRow];
		self.copiedStyle = [self.currentStyleSheet styleAttributesForExactScope:scopeString];
	}
}

- (IBAction)paste:aSender {
	if (self.copiedStyle) {
		NSInteger selectedRow = [self.O_stylesTableView selectedRow];
		if (selectedRow != -1) {
			NSString *scopeString = [[self scopesArray] objectAtIndex:selectedRow];
			[self.currentStyleSheet setStyleAttributes:self.copiedStyle forScope:scopeString];
			[self updateInspector];
			[self.O_stylesTableView reloadData];
		}
	}
}


#pragma mark -

- (void)controlTextDidChange:(NSNotification *)aNotification {
	[self updateScopeButtons];
}

- (void)comboBoxSelectionIsChanging:(NSNotification *)aNotification {
	[self updateScopeButtons];
}

- (void)comboBoxSelectionDidChange:(NSNotification *)aNotification {
	[self updateScopeButtons];
}

- (void)comboBoxWillDismiss:(NSNotification *)aNotification {
	[self updateScopeButtons];
}


- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
//	NSLog(@"%s %@",__FUNCTION__,[[O_modeController content] availableScopes]);
	return [[[self.O_modeController content] availableScopes] count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
//	NSLog(@"%s",__FUNCTION__);
	return [[[self.O_modeController content] availableScopes] objectAtIndex:index];
}

#pragma mark -
#pragma mark TableView DataSource

- (NSArray *)scopesArray {
	return (self.O_showOnlyMatchingScopesButton.state == NSOnState) ? self.currentStyleSheet.allScopesWithExamples : self.currentStyleSheet.allScopes;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[self scopesArray] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)aRow {
	
	
	NSString *scopeString = [[self scopesArray] objectAtIndex:aRow];
	NSDictionary *textAttributes = [self textAttributesForScope:scopeString];
	if ([[aTableColumn identifier] isEqualToString:@"scope"]) {
		return [[NSAttributedString alloc] initWithString:scopeString attributes:textAttributes];
	} else {
		NSString *exampleString = [self.currentStyleSheet exampleForScope:scopeString];
		return [[NSAttributedString alloc] initWithString:exampleString attributes:textAttributes];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self updateInspector];
}

@end
