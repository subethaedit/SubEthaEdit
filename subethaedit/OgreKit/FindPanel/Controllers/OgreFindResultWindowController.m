/*
 * Name: OgreFindResultWindow.m
 * Project: OgreKit
 *
 * Creation Date: Jun 10 2004
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreFindResultWindowController.h>

@implementation OgreFindResultWindowController

- (id)initWithTextFindResult:(OgreTextFindResult*)textFindResult liveUpdate:(BOOL)liveUpdate
{
    self = [super init];
    if (self != nil) {
        _textFindResult = [textFindResult retain];
        [_textFindResult setDelegate:self]; // 検索結果の更新通知を受け取るようにする。
        _liveUpdate = liveUpdate;
        [NSBundle loadNibNamed:@"OgreFindResultWindow" owner:self];
    }
    return self;
}

- (void)awakeFromNib
{
    [window setTitle:OgreTextFinderLocalizedString(@"Find Result")];
    
    NSString    *message;
    if ([_textFindResult numberOfMatches] > 1) {
        message = OgreTextFinderLocalizedString(@"%d strings found.");
    } else {
        message = OgreTextFinderLocalizedString(@"%d string found.");
    }
    [messageField setStringValue:[NSString stringWithFormat:message, [_textFindResult numberOfMatches]]];
    
    [liveUpdateCheckBox setTitle:OgreTextFinderLocalizedString(@"Live Update")];
    
    [liveUpdateCheckBox setState:(int)_liveUpdate];
    
    message = OgreTextFinderLocalizedString(@"Find String: %@");
    [findStringField setStringValue:[NSString stringWithFormat:message, [_textFindResult findString]]];
    
    [self setupOutlineView];
}

- (void)setupOutlineView
{
    NSTextFieldCell *headerCell;
    headerCell = [[grepOutlineView tableColumnWithIdentifier:@"name"] headerCell];
    [headerCell setTitle:OgreTextFinderLocalizedString(@"Line")];
    headerCell = [[grepOutlineView tableColumnWithIdentifier:@"outline"] headerCell];
    [headerCell setTitle:OgreTextFinderLocalizedString(@"Found String")];
    
    [[grepOutlineView outlineTableColumn] setDataCell:[_textFindResult nameCell]];
    [grepOutlineView setRowHeight:[_textFindResult rowHeight]];
    
    [grepOutlineView reloadData];
    [grepOutlineView expandItem:[self outlineView:nil child:0 ofItem:nil] expandChildren:YES];
 	// grepTableViewのdouble clickを検知
	[grepOutlineView setTarget:self];
	[grepOutlineView setDoubleAction:@selector(grepOutlineViewDoubleClicked)];
}

- (void)setFrameTopLeftPoint:(NSPoint)aPoint
{
    [window setFrameTopLeftPoint:aPoint];
}

- (void)show
{
    [window makeKeyAndOrderFront:self];
}

- (void)close
{
    [window close];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    [_textFindResult setDelegate:nil];
    [_textFindResult release];
    _textFindResult = nil;
    [grepOutlineView reloadData];
    [self release];
}

- (void)dealloc
{
    [_textFindResult setDelegate:nil];
    [_textFindResult release];
    [super dealloc];
}

- (void)setTextFindResult:(OgreTextFindResult*)textFindResult
{
    [_textFindResult setDelegate:nil];
    [_textFindResult autorelease];
    _textFindResult = [textFindResult retain];
    [_textFindResult setDelegate:self];
    [self setupOutlineView];
}

- (NSWindow*)window
{
    return window;
}

- (void)tellMeTargetToFindIn:(id)textFinder
{
	[textFinder setTargetToFindIn:nil]; // (まだ)検索させない
}

/* delegate method of OgreTextFindResult */
- (void)didUpdateTextFindResult:(id)textFindResult
{
	if (_liveUpdate) [grepOutlineView reloadData];   // very slow
}

/* NSOutlineViewDataSource methods */
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (_textFindResult == nil) return NO;

    NSObject <OgreTextFindComponent>    *aItem;
    
    aItem = item;
    if (aItem == nil) {
        // root
        aItem = [_textFindResult result];
    }
    
    return [aItem isBranch];
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (_textFindResult == nil) return 0;
    
    NSObject <OgreTextFindComponent>    *aItem;
    
    aItem = item;
    if (aItem == nil) {
        // root
        aItem = [_textFindResult result];
    }
    
    return [aItem numberOfChildrenInSelection:NO];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	if (_textFindResult == nil) return nil;
    
    NSObject <OgreTextFindComponent>    *aItem;
    
    aItem = item;
    if (aItem == nil) {
        // root
        aItem = [_textFindResult result];
    }
    
    return [aItem childAtIndex:index inSelection:NO];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (_textFindResult == nil) return [_textFindResult missingString];
	
    return [(NSObject <OgreTextFindComponent>*)item valueForKey:[tableColumn identifier]];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([[tableColumn identifier] isEqualToString:@"name"]) 
        [_textFindResult outlineView:outlineView willDisplayCell:cell forTableColumn:tableColumn item:item];
}

- (void)grepOutlineViewDoubleClicked
{
	int	clickedRowIndex = [grepOutlineView clickedRow];
	if (clickedRowIndex < 0) return;
    
    OgreFindResultLeaf  *item = [grepOutlineView itemAtRow:clickedRowIndex];
	BOOL	found = [item showMatchedString];
    
	if (!found) NSBeep();
}

- (void)outlineViewSelectionDidChange:(NSNotification*)aNotification
{
	int	clickedRowIndex = [grepOutlineView selectedRow];
	if (clickedRowIndex < 0) return;
    
    OgreFindResultLeaf  *item = [grepOutlineView itemAtRow:clickedRowIndex];
	BOOL	found = [item selectMatchedString];
    
	if (!found) NSBeep();
}

/* live update check box clicked*/
- (IBAction)updateLiveUpdate:(id)sender
{
	if (_textFindResult != nil) [grepOutlineView reloadData];
	_liveUpdate = ([liveUpdateCheckBox state] == NSOnState);
}


@end
