//
//  StylePreferences.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Oct 07 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "StylePreferences.h"
#import "SyntaxStyle.h"
#import "DocumentModeManager.h"
#import "DocumentController.h"
#import "TableView.h"
#import "TextFieldCell.h"
#import "GeneralPreferences.h"
#import "OverlayView.h"
#import "SyntaxHighlighter.h"

@implementation StylePreferences

- (id) init {
    self = [super init];
    if (self) {
        I_baseStyleDictionary=[NSMutableDictionary new];
        I_undoManager=[NSUndoManager new];
    }
    return self;
}

- (void)dealloc {
    [I_baseStyleDictionary release];
    [I_undoManager release];
    [super dealloc];
}

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

- (void)adjustTableViewColumns:(NSNotification *)aNotification {
    float width=[[[O_stylesTableView enclosingScrollView] contentView] frame].size.width;
    width-=[O_stylesTableView intercellSpacing].width*3;
    float width2=width/2.;
    NSArray *columns=[O_stylesTableView tableColumns];
    [[columns objectAtIndex:0] setWidth:width2];
    [[columns objectAtIndex:1] setWidth:width2];
}

- (void)mainViewDidLoad {
    // Initialize user interface elements to reflect current preference settings
    [self changeMode:O_modePopUpButton];
    
    // Set tableview to non highlighting cells
    [[[O_stylesTableView tableColumns] objectAtIndex:0] setDataCell:[[TextFieldCell new] autorelease]];
    [[[O_stylesTableView tableColumns] objectAtIndex:1] setDataCell:[[TextFieldCell new] autorelease]];
    
    [[O_stylesTableView enclosingScrollView] setPostsFrameChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustTableViewColumns:) name:NSViewFrameDidChangeNotification object:[O_stylesTableView enclosingScrollView]];
    NSMutableAttributedString *string=[[O_italicButton attributedTitle] mutableCopy];
    [string addAttribute:NSObliquenessAttributeName value:[NSNumber numberWithFloat:.2] range:NSMakeRange(0,[[string string] length])];
    [O_italicButton setAttributedTitle:[string autorelease]];
    [self adjustTableViewColumns:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentModeListChanged:) name:@"DocumentModeListChanged" object:nil];
    
}

- (void)documentModeListChanged:(NSNotification *)aNotification {
    [self performSelector:@selector(changeMode:) withObject:O_modePopUpButton afterDelay:.2];
}

- (void)didSelect {
    if (!I_overlayWindow) {
        NSPoint baseOrigin, screenOrigin;
        NSView *styleBox=[O_defaultStyleButton superview];
        baseOrigin = [styleBox convertPoint:NSMakePoint([styleBox frame].origin.x,
                                 [styleBox frame].origin.y) toView:nil];
        screenOrigin = [[styleBox window] convertBaseToScreen:baseOrigin];

        NSRect windowRect=NSMakeRect(screenOrigin.x,screenOrigin.y,
                                     [styleBox frame].size.width,[styleBox frame].size.height);
        windowRect=NSInsetRect(windowRect,-2,-2);
    
        OverlayView *view=[[[OverlayView alloc] initWithFrame:[styleBox frame]] autorelease];
        [view setDelegate:self];
        [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [styleBox addSubview:view positioned:NSWindowBelow relativeTo:nil];
    }
}

- (void)updateBackgroundColor {
    NSDictionary *baseStyle=[[[O_styleController content] syntaxStyle] styleForKey:SyntaxStyleBaseIdentifier];
    [O_backgroundColorWell         setColor:[baseStyle objectForKey:@"background-color"]         ];
    [O_invertedBackgroundColorWell setColor:[baseStyle objectForKey:@"inverted-background-color"]]; 
    [O_stylesTableView setLightBackgroundColor:[baseStyle objectForKey:@"background-color"]];
    [O_stylesTableView setDarkBackgroundColor: [baseStyle objectForKey:@"inverted-background-color"]];
    [O_stylesTableView reloadData];
}

- (void)takeFontFromMode:(DocumentMode *)aMode {
    NSDictionary *fontAttributes = [aMode defaultForKey:DocumentModeFontAttributesPreferenceKey];
    NSFont *font=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:11.];
    if (!font) font=[NSFont userFixedPitchFontOfSize:11.];
    [self setBaseFont:font];
}

- (IBAction)validateDefaultsState:(id)aSender {
    BOOL useDefault=[[[O_modePopUpButton selectedMode] defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue];
    DocumentMode *baseMode=[[DocumentModeManager sharedInstance] baseMode];
    DocumentMode *selectedMode=[O_modePopUpButton selectedMode];
    [O_fontController setContent:([O_fontDefaultButton state]==NSOnState)?baseMode:selectedMode];
    [O_styleController setContent:useDefault?baseMode:selectedMode];
    [O_defaultStyleButton setHidden:[[I_currentSyntaxStyle documentMode] isBaseMode]];
    if (O_defaultStyleButton !=aSender) {
        [O_defaultStyleButton setState:useDefault?NSOnState:NSOffState];
    }

    [O_stylesTableView setDisableFirstRow:useDefault];
    
    if (useDefault) {
        [O_stylesTableView deselectRow:0];
    }
    NSDictionary *baseStyle=[[[O_styleController content] syntaxStyle] styleForKey:SyntaxStyleBaseIdentifier];
    [O_backgroundColorWell         setColor:[baseStyle objectForKey:@"background-color"]         ];
    [O_invertedBackgroundColorWell setColor:[baseStyle objectForKey:@"inverted-background-color"]]; 
    [self takeFontFromMode:selectedMode];
    [self updateBackgroundColor];
    [O_lightBackgroundButton       setEnabled:!useDefault];
    [O_darkBackgroundButton        setEnabled:!useDefault];
    [O_backgroundColorWell         setEnabled:!useDefault];
    [O_invertedBackgroundColorWell setEnabled:!useDefault];
}

- (IBAction)changeDefaultState:(id)aSender {
    BOOL useDefault = ([aSender state]==NSOnState);
    [[[O_modePopUpButton selectedMode] defaults] setObject:[NSNumber numberWithBool:useDefault] forKey:DocumentModeUseDefaultStylePreferenceKey];
    [self validateDefaultsState:aSender];
}

#define BUFFERSIZE 40

- (NSEnumerator *)selectedStylesEnumerator {
    NSMutableArray *styleArray=[NSMutableArray array];
    unsigned int indexBuffer[BUFFERSIZE];
    NSArray *allKeys=[I_currentSyntaxStyle allKeys];
    NSIndexSet *selectedRows=[O_stylesTableView selectedRowIndexes];
    NSRange range=NSMakeRange(0,NSNotFound);
    int count;
    while ((count=[selectedRows getIndexes:indexBuffer maxCount:BUFFERSIZE inIndexRange:&range])) {
        int i=0;
        for (i=0;i<count;i++) {
            [styleArray addObject:[I_currentSyntaxStyle styleForKey:[allKeys objectAtIndex:indexBuffer[i]]]];
        }
    }
    
    return [styleArray objectEnumerator];
}

#define UNITITIALIZED -5
#define MANY  -4

- (void)updateInspector {
    int bold=UNITITIALIZED, italic=UNITITIALIZED, manyColors=NO,manyInvertedColors=NO,revertable=NO;
    unsigned int indexBuffer[BUFFERSIZE];
    NSColor *color=nil,*invertedColor=nil;
    NSArray *allKeys=[I_currentSyntaxStyle allKeys];
    NSIndexSet *selectedRows=[O_stylesTableView selectedRowIndexes];
    NSRange range=NSMakeRange(0,NSNotFound);
    SyntaxStyle *defaultStyle=[[I_currentSyntaxStyle documentMode] defaultSyntaxStyle];
    int count;
    while ((count=[selectedRows getIndexes:indexBuffer maxCount:BUFFERSIZE inIndexRange:&range])) {
        int i=0;
        for (i=0;i<count;i++) {
            unsigned int index=indexBuffer[i];
            NSString *key=[allKeys objectAtIndex:index];
            NSDictionary *style=[I_currentSyntaxStyle styleForKey:key];
            if (bold!=MANY) {
                BOOL innerBold=([[style objectForKey:@"font-trait"] unsignedIntValue] & NSBoldFontMask);
                if (bold==UNITITIALIZED) {
                    bold=innerBold;
                } else {
                    if (bold!=innerBold) {
                        bold=MANY;
                    }
                }
            }
            if (italic!=MANY) {
                BOOL innerItalic=([[style objectForKey:@"font-trait"] unsignedIntValue] & NSItalicFontMask);
                if (italic==UNITITIALIZED) {
                    italic=innerItalic;
                } else {
                    if (italic!=innerItalic) {
                        italic=MANY;
                    }
                }
            }
            if (!manyColors) {
                NSColor *innerColor=[style objectForKey:@"color"];
                if (!color) {
                    color=innerColor;
                } else {
                    if (![[color HTMLString] isEqualToString:[innerColor HTMLString]]) {
                        manyColors=YES;
                    }
                }
            }
            if (!manyInvertedColors) {
                NSColor *innerColor=[style objectForKey:@"inverted-color"];
                if (!invertedColor) {
                    invertedColor=innerColor;
                } else {
                    if (![[invertedColor HTMLString] isEqualToString:[innerColor HTMLString]]) {
                        manyInvertedColors=YES;
                    }
                }
            }
            if (![SyntaxStyle style:style isEqualToStyle:[defaultStyle styleForKey:key]]) {
                revertable=YES;
            }
        }
    }
    
    [O_italicButton      setEnabled:(bold!=UNITITIALIZED)];
    [O_boldButton        setEnabled:(bold!=UNITITIALIZED)];
    [O_colorWell         setEnabled:(bold!=UNITITIALIZED)];
    [O_invertedColorWell setEnabled:(bold!=UNITITIALIZED)];
    if (bold!=UNITITIALIZED) {
        [O_italicButton setAllowsMixedState:italic==MANY];
        [O_italicButton setState:italic==MANY?NSMixedState:(italic?NSOnState:NSOffState)];
        [O_boldButton   setAllowsMixedState:bold==MANY];
        [O_boldButton   setState:bold  ==MANY?NSMixedState:(bold  ?NSOnState:NSOffState)];
        [O_colorWell setColor:color];
        [O_invertedColorWell setColor:invertedColor];
    }
    [O_revertSelectionToModeButton setEnabled:revertable];
    // sad but needed...
    [[O_boldButton superview] setNeedsDisplay:YES];
}

- (NSUndoManager *)undoManager {
    return I_undoManager;
}

- (void)setStyle:(SyntaxStyle *)aStyle {
    // style now
    DocumentMode *mode=[aStyle documentMode];
    SyntaxStyle *styleToRegister=[[[mode syntaxStyle] copy] autorelease];
    [I_undoManager registerUndoWithTarget:self selector:@selector(setStyle:) object:styleToRegister];
    NSIndexSet *newSelection=[SyntaxStyle indexesWhereStyle:aStyle isNotEqualToStyle:styleToRegister];
    [mode setSyntaxStyle:aStyle];
    if (![[O_modePopUpButton selectedMode] isEqualTo:mode]) {
        [O_modePopUpButton setSelectedMode:mode];
        [self changeMode:O_modePopUpButton];
    } else {
        I_currentSyntaxStyle=aStyle;
        [O_stylesTableView reloadData];
    }
    [O_stylesTableView selectRowIndexes:newSelection byExtendingSelection:NO];
    [O_stylesTableView scrollRowToVisible:[newSelection firstIndex]];
    [self updateBackgroundColor];
    [self updateInspector];
}


- (void)storeCurrentStyleForUndo {
    [I_undoManager registerUndoWithTarget:self selector:@selector(setStyle:) object:[[I_currentSyntaxStyle copy] autorelease]];
}

#pragma mark -
#pragma mark IBActions

- (IBAction)changeMode:(id)aSender {
    DocumentMode *newMode=[aSender selectedMode];
    [O_modeController setContent:newMode];
    I_currentSyntaxStyle=[newMode syntaxStyle];
    [O_stylesTableView reloadData];
    [O_stylesTableView selectRow:0 byExtendingSelection:NO];
    [self validateDefaultsState:aSender];
    [self updateInspector];
}

- (IBAction)changeLightBackgroundColor:(id)aSender {
    [self storeCurrentStyleForUndo];
    NSMutableDictionary *baseStyle=[I_currentSyntaxStyle styleForKey:SyntaxStyleBaseIdentifier];
    [baseStyle setObject:[aSender color] forKey:@"background-color"];
    [self updateBackgroundColor];
}

- (IBAction)changeDarkBackgroundColor:(id)aSender {
    [self storeCurrentStyleForUndo];
    NSMutableDictionary *baseStyle=[I_currentSyntaxStyle styleForKey:SyntaxStyleBaseIdentifier];
    [baseStyle setObject:[aSender color] forKey:@"inverted-background-color"];
    [self updateBackgroundColor];
}

- (void)setKey:(NSString *)aKey ofSelectedStylesToObject:(id)anObject {
    [self storeCurrentStyleForUndo];
    NSMutableDictionary *style=nil;
    NSEnumerator *selectedStyles=[self selectedStylesEnumerator];
    while ((style=[selectedStyles nextObject])) {
        [style setObject:anObject forKey:aKey];
    }
    [O_stylesTableView reloadData];
    [self updateInspector];
}

- (IBAction)changeLightForegroundColor:(id)aSender {
    [self setKey:@"color" ofSelectedStylesToObject:[aSender color]];
}

- (IBAction)changeDarkForegroundColor:(id)aSender {
    [self setKey:@"inverted-color" ofSelectedStylesToObject:[aSender color]];
}

- (void)setTrait:(NSFontTraitMask)aTrait ofSelectedStylesTo:(BOOL)aState {
    [self storeCurrentStyleForUndo];
    NSMutableDictionary *style=nil;
    NSEnumerator *selectedStyles=[self selectedStylesEnumerator];
    while ((style=[selectedStyles nextObject])) {
        NSFontTraitMask traits=[[style objectForKey:@"font-trait"] unsignedIntValue];
        BOOL currentState = traits & aTrait;
        if (aState && !currentState) {
            traits = traits | aTrait;
        } else if (!aState && currentState) {
            traits = traits & (~aTrait);
        }
        [style setObject:[NSNumber numberWithUnsignedInt:traits] forKey:@"font-trait"];
    }
    [O_stylesTableView reloadData];
    [self updateInspector];
}

- (IBAction)changeFontTraitItalic:(id)aSender {
    [aSender setAllowsMixedState:NO];
    [self setTrait:NSItalicFontMask ofSelectedStylesTo:[aSender state]==NSOnState];
}

- (IBAction)changeFontTraitBold:(id)aSender {
    [aSender setAllowsMixedState:NO];
    [self setTrait:NSBoldFontMask ofSelectedStylesTo:[aSender state]==NSOnState];
}

- (IBAction)import:(id)aSender {
    NSOpenPanel *openPanel=[NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setRequiredFileType:@"seestyle"];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setExtensionHidden:NO];
    [openPanel beginSheetForDirectory:nil file:nil 
               types:[NSArray arrayWithObject:@"seestyle"] 
               modalForWindow:[O_stylesTableView window] 
               modalDelegate:self 
               didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
               contextInfo:nil];
}

- (void)importStyleFile:(NSString *)aFilename {
    NSArray *styleArray=[SyntaxStyle syntaxStylesWithXMLFile:aFilename];
    if ([styleArray count]>0) {
        NSMutableString *modeString=[[[[[styleArray objectAtIndex:0] documentMode] displayName] mutableCopy] autorelease];
        int i;
        for (i=1;i<[styleArray count];i++) {
            [modeString appendFormat:@", %@",[[[styleArray objectAtIndex:i] documentMode] displayName]];
        }
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:NSLocalizedString(@"SeeStyleImportMessage", @"Message Text of Style load alert sheet")];
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"SeeStyleImportInformative %@",  @"Informative Text of Style load alert sheet"),modeString]];
        [alert addButtonWithTitle:NSLocalizedString(@"Import", @"Button choice allowing user to import")];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Button choice allowing user to cancel.")];
        [alert addButtonWithTitle:NSLocalizedString(@"Open in Editor", @"Button choice allowing user open a file in the editor.")];
        [alert beginSheetModalForWindow:[O_stylesTableView window]
                          modalDelegate:self
                         didEndSelector:@selector(importDidEnd:returnCode:contextInfo:)
                            contextInfo:[[NSDictionary dictionaryWithObjectsAndKeys:aFilename,@"filename",styleArray,@"style",nil] retain]];
    } else {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:NSLocalizedString(@"SeeStyleImportDidFailMessage", @"Message Text of Style load did fail alert sheet")];
        [alert setInformativeText:NSLocalizedString(@"SeeStyleImportDidFailInformative", @"Informative Text of Style load did fail alert sheet")];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [alert beginSheetModalForWindow:[O_stylesTableView window]
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:NULL];
    }
}

- (void)importDidEnd:(NSAlert *)anAlert returnCode:(int)aReturnCode contextInfo:(void *)aDictionary {
    NSDictionary *dictionary=[(NSDictionary *)aDictionary autorelease];
    if (aReturnCode == NSAlertFirstButtonReturn) {
        NSEnumerator *styles=[[dictionary objectForKey:@"style"] objectEnumerator];
        SyntaxStyle *style=nil;
        [I_undoManager beginUndoGrouping];
        while ((style = [styles nextObject])) {
            [self setStyle:style];
        }
        [I_undoManager endUndoGrouping];
    } else if (aReturnCode == NSAlertThirdButtonReturn) {
        [[DocumentController sharedInstance] openDocumentWithContentsOfFile:[dictionary objectForKey:@"filename"] display:YES];
    }
}

- (void)openPanelDidEnd:(NSOpenPanel *)aPanel returnCode:(int)aReturnCode contextInfo:(void *)contextInfo {
    NSString *filename=[aPanel filename];
    if (aReturnCode==NSOKButton) {
        [aPanel orderOut:self];
        [self importStyleFile:filename];
    }
}

- (IBAction)export:(id)aSender {
    I_shouldExportAll = ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0;
    NSSavePanel *savePanel=[NSSavePanel savePanel];
    [savePanel setPrompt:NSLocalizedString(@"ExportPrompt",@"Text on the active SavePanel Button in the export sheet")];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setExtensionHidden:NO];
    [savePanel setAllowsOtherFileTypes:YES];
    [savePanel setTreatsFilePackagesAsDirectories:YES];
    [savePanel setRequiredFileType:@"seestyle"];
    [savePanel beginSheetForDirectory:nil 
        file:[I_shouldExportAll?NSLocalizedString(@"StylePrefsIconLabel",@""):[[[[I_currentSyntaxStyle documentMode]  documentModeIdentifier] componentsSeparatedByString:@"."] lastObject] stringByAppendingPathExtension:@"seestyle"] 
        modalForWindow:[O_stylesTableView window] 
        modalDelegate:self 
        didEndSelector:@selector(exportSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)exportSheetDidEnd:(NSSavePanel *)aPanel returnCode:(int)aReturnCode contextInfo:(void *)aContextInfo {
    if (aReturnCode==NSOKButton) {
        [[I_shouldExportAll?[DocumentModeManager xmlFileRepresentationOfAllStyles]:[I_currentSyntaxStyle xmlFileRepresentation] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO] writeToFile:[aPanel filename] atomically:YES];
    }
}

- (IBAction)revertToMode:(id)aSender {
    [self storeCurrentStyleForUndo];
    DocumentMode *mode=[I_currentSyntaxStyle documentMode];
    [mode setSyntaxStyle:[[[mode defaultSyntaxStyle] copy] autorelease]];
    [self changeMode:O_modePopUpButton];
}

- (IBAction)revertSelectionToMode:(id)aSender {
    [self storeCurrentStyleForUndo];
    NSMutableDictionary *style=nil;
    NSEnumerator *selectedStyles=[self selectedStylesEnumerator];
    SyntaxStyle *defaultStyle=[[O_modePopUpButton selectedMode] defaultSyntaxStyle];
    while ((style=[selectedStyles nextObject])) {
        [style addEntriesFromDictionary:[defaultStyle styleForKey:[style objectForKey:kSyntaxHighlightingStyleIDAttributeName]]];
    }
    [O_stylesTableView reloadData];
    [self updateInspector];
}

- (IBAction)applyToOpenDocuments:(id)aSender {
    [[NSNotificationCenter defaultCenter] postNotificationName:DocumentModeApplyStylePreferencesNotification object:[O_modeController content]];
}


- (void)didUnselect {
    // Save preferences
    [[[NSFontManager sharedFontManager] fontPanel:NO] orderOut:self];
}

- (IBAction)changeFontViaPanel:(id)sender {
    NSDictionary *fontAttributes=[[O_modePopUpButton selectedMode] defaultForKey:DocumentModeFontAttributesPreferenceKey];
    NSFont *newFont=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
    if (!newFont) newFont=[NSFont userFixedPitchFontOfSize:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
    [[NSFontManager sharedFontManager] 
        setSelectedFont:newFont 
             isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (void)changeFont:(id)fontManager {
    if ([O_fontDefaultButton state]!=NSOnState) {
        NSFont *newFont = [fontManager convertFont:[NSFont userFixedPitchFontOfSize:0.0]]; // could be any font here
        NSMutableDictionary *dict=[NSMutableDictionary dictionary];
        [dict setObject:[newFont fontName] 
                 forKey:NSFontNameAttribute];
        [dict setObject:[NSNumber numberWithFloat:[newFont pointSize]] 
                 forKey:NSFontSizeAttribute];
        [[O_modePopUpButton selectedMode] setValue:dict forKeyPath:@"defaults.FontAttributes"];
        [self changeMode:O_modePopUpButton];
    }
}

- (void)setBaseFont:(NSFont *)aFont {
    [I_baseFont autorelease];
     I_baseFont = [aFont retain];
}

- (NSFont *)baseFont {
    return I_baseFont;
}

#pragma mark -
#pragma mark TableView DataSource
- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[I_currentSyntaxStyle allKeys] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)aRow {
    BOOL darkBackground = ![[aTableColumn identifier]isEqualToString:@"light"];
    BOOL useDefault=[[[O_modePopUpButton selectedMode] defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue];
    NSString *key=[[I_currentSyntaxStyle allKeys] objectAtIndex:aRow];
    NSDictionary *style=[(useDefault && aRow==0)?([[DocumentModeManager baseMode] syntaxStyle]):I_currentSyntaxStyle styleForKey:key];
    NSString *localizedString=[I_currentSyntaxStyle localizedStringForKey:key];
    NSFont *font=[self baseFont];
    NSFontManager *fontManager=[NSFontManager sharedFontManager];
    NSFontTraitMask traits=[[style objectForKey:@"font-trait"] unsignedIntValue];
    if (traits & NSBoldFontMask) {
        font=[fontManager convertFont:font toHaveTrait:NSBoldFontMask];
    }
    if (traits & NSItalicFontMask) {
        font=[fontManager convertFont:font toHaveTrait:NSItalicFontMask];
    }
    static NSMutableParagraphStyle *s_paragraphStyle=nil;
    if (!s_paragraphStyle) {
        s_paragraphStyle=[[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [s_paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    BOOL synthesise=[[NSUserDefaults standardUserDefaults] boolForKey:SynthesiseFontsPreferenceKey];
    float obliquenessFactor=.0;
    if (synthesise && (traits & NSItalicFontMask) && !([fontManager traitsOfFont:font] & NSItalicFontMask)) {
        obliquenessFactor=.2;
    }
    float strokeWidth=.0;
    if (synthesise && (traits & NSBoldFontMask) && !([fontManager traitsOfFont:font] & NSBoldFontMask)) {
        strokeWidth=darkBackground?-9.:-3.;
    }
    
    NSDictionary *attributes=[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,
        darkBackground?[style objectForKey:@"inverted-color"]:[style objectForKey:@"color"],NSForegroundColorAttributeName,
        s_paragraphStyle,NSParagraphStyleAttributeName,
        [NSNumber numberWithFloat:obliquenessFactor],NSObliquenessAttributeName,
        [NSNumber numberWithFloat:strokeWidth],NSStrokeWidthAttributeName,
        nil];
    return [[[NSAttributedString alloc] initWithString:localizedString attributes:attributes] autorelease];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self updateInspector];
}

#pragma mark TableView Delegate

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
    BOOL useDefault=[[[O_modePopUpButton selectedMode] defaultForKey:DocumentModeUseDefaultStylePreferenceKey] boolValue];
    if (rowIndex==0 && useDefault) {
        return NO;
    }
    return YES;
}

@end