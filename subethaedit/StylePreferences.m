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
#import "TableView.h"
#import "TextFieldCell.h"


@implementation StylePreferences

- (id) init {
    self = [super init];
    if (self) {
        I_baseStyleDictionary=[NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [I_baseStyleDictionary release];
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

- (void)mainViewDidLoad {
    // Initialize user interface elements to reflect current preference settings
    [self changeMode:O_modePopUpButton];
    
    // Set tableview to non highlighting cells
    [[[O_stylesTableView tableColumns] objectAtIndex:0] setDataCell:[[TextFieldCell new] autorelease]];
    [[[O_stylesTableView tableColumns] objectAtIndex:1] setDataCell:[[TextFieldCell new] autorelease]];

}

- (IBAction)validateDefaultsState:(id)aSender {
    //DocumentMode *baseMode=[[DocumentModeManager sharedInstance] baseMode];
    //DocumentMode *selectedMode=[O_modeController content];
}

- (void)updateBackgroundColor {
    NSDictionary *baseStyle=[I_currentSyntaxStyle styleForKey:SyntaxStyleBaseIdentifier];
    [O_stylesTableView setLightBackgroundColor:[baseStyle objectForKey:@"background-color"]];
    [O_stylesTableView setDarkBackgroundColor: [baseStyle objectForKey:@"inverted-background-color"]];
    [O_stylesTableView reloadData];
}

#define BUFFERSIZE 40
#define UNITITIALIZED -5
#define MANY  -4 

- (void)updateInspector {
    int bold=UNITITIALIZED, italic=UNITITIALIZED, manyColors=NO,manyInvertedColors=NO;
    unsigned int indexBuffer[BUFFERSIZE];
    NSColor *color=nil,*invertedColor=nil;
    NSArray *allKeys=[I_currentSyntaxStyle allKeys];
    NSIndexSet *selectedRows=[O_stylesTableView selectedRowIndexes];
    NSRange range=NSMakeRange(0,NSNotFound);
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
        }
    }
    
    [O_italicButton setAllowsMixedState:italic==MANY];
    [O_italicButton setState:italic==MANY?NSMixedState:(italic?NSOnState:NSOffState)];
    [O_boldButton   setAllowsMixedState:bold==MANY];
    [O_boldButton   setState:bold  ==MANY?NSMixedState:(bold  ?NSOnState:NSOffState)];
    [O_colorWell setColor:color];
    [O_invertedColorWell setColor:invertedColor];
}

- (IBAction)changeMode:(id)aSender {

    DocumentMode *newMode=[aSender selectedMode];
    [O_modeController setContent:newMode];
    NSDictionary *fontAttributes = [newMode defaultForKey:DocumentModeFontAttributesPreferenceKey];
    NSFont *font=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:11.];
    if (!font) font=[NSFont userFixedPitchFontOfSize:11.];
    [self setBaseFont:font];
    [self validateDefaultsState:aSender];
    I_currentSyntaxStyle=[newMode syntaxStyle];
    [self updateBackgroundColor];
}

- (void)didUnselect {
    // Save preferences
}

- (void)setBaseFont:(NSFont *)aFont {
    [I_baseFont autorelease];
     I_baseFont = [aFont retain];
}

- (NSFont *)baseFont {
    return I_baseFont;
}


#pragma mark TableView DataSource
- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[I_currentSyntaxStyle allKeys] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)aRow {
    NSString *key=[[I_currentSyntaxStyle allKeys] objectAtIndex:aRow];
    NSDictionary *style=[I_currentSyntaxStyle styleForKey:key];
    NSString *localizedString=[I_currentSyntaxStyle localizedStringForKey:key];
    NSDictionary *attributes=[NSDictionary dictionaryWithObjectsAndKeys:[[NSFontManager sharedFontManager] convertFont:[self baseFont] toHaveTrait:[[style objectForKey:@"font-trait"] unsignedIntValue]],NSFontAttributeName,
        [[aTableColumn identifier]isEqualToString:@"light"]?[style objectForKey:@"color"]:[style objectForKey:@"inverted-color"],NSForegroundColorAttributeName,
        nil];
    return [[[NSAttributedString alloc] initWithString:localizedString attributes:attributes] autorelease];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self updateInspector];
}


@end