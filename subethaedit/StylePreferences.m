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
    [[[O_baseStyleTableView tableColumns] objectAtIndex:0] setDataCell:[[TextFieldCell new] autorelease]];
    [[[O_baseStyleTableView tableColumns] objectAtIndex:1] setDataCell:[[TextFieldCell new] autorelease]];
    [[[O_remainingStylesTableView tableColumns] objectAtIndex:0] setDataCell:[[TextFieldCell new] autorelease]];
    [[[O_remainingStylesTableView tableColumns] objectAtIndex:1] setDataCell:[[TextFieldCell new] autorelease]];

}

- (IBAction)validateDefaultsState:(id)aSender {
    //DocumentMode *baseMode=[[DocumentModeManager sharedInstance] baseMode];
    //DocumentMode *selectedMode=[O_modeController content];
}

- (IBAction)changeMode:(id)aSender {

    DocumentMode *newMode=[aSender selectedMode];
    [O_modeController setContent:newMode];
    NSDictionary *fontAttributes = [newMode defaultForKey:DocumentModeFontAttributesPreferenceKey];
    NSFont *font=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:12.];
    if (!font) font=[NSFont userFixedPitchFontOfSize:12.];
    [self setBaseFont:font];
    [self validateDefaultsState:aSender];
    I_currentSyntaxStyle=[newMode syntaxStyle];
    NSDictionary *baseStyle=[I_currentSyntaxStyle styleForKey:SyntaxStyleBaseIdentifier];
    [O_baseStyleTableView setLightBackgroundColor:[baseStyle objectForKey:@"background-color"]];
    [O_baseStyleTableView setDarkBackgroundColor: [baseStyle objectForKey:@"inverted-background-color"]];
    [O_baseStyleTableView reloadData];
    [O_remainingStylesTableView setLightBackgroundColor:[baseStyle objectForKey:@"background-color"]];
    [O_remainingStylesTableView setDarkBackgroundColor: [baseStyle objectForKey:@"inverted-background-color"]];
    [O_remainingStylesTableView reloadData];
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
    if (aTableView == O_baseStyleTableView) {
        return 1;
    } else {
        return [[I_currentSyntaxStyle allKeys] count]-1;
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)aRow {
    if (aTableView == O_remainingStylesTableView) {
        aRow+=1;
    }
    NSString *key=[[I_currentSyntaxStyle allKeys] objectAtIndex:aRow];
    NSDictionary *style=[I_currentSyntaxStyle styleForKey:key];
    NSString *localizedString=[I_currentSyntaxStyle localizedStringForKey:key];
    NSDictionary *attributes=[NSDictionary dictionaryWithObjectsAndKeys:[[NSFontManager sharedFontManager] convertFont:[self baseFont] toHaveTrait:[[style objectForKey:@"font-trait"] unsignedIntValue]],NSFontAttributeName,
        [[aTableColumn identifier]isEqualToString:@"light"]?[style objectForKey:@"color"]:[style objectForKey:@"inverted-color"],NSForegroundColorAttributeName,
        nil];
    return [[[NSAttributedString alloc] initWithString:localizedString attributes:attributes] autorelease];
}


@end