//
//  PlainTextWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Mar 05 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "PlainTextWindowController.h"
#import "ParticipantsView.h"
#import "PlainTextDocument.h"
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "SelectionOperation.h"
#import "ImagePopUpButtonCell.h"


NSString * const PlainTextWindowToolbarIdentifier = @"PlainTextWindowToolbarIdentifier";
NSString * const ParticipantsToolbarItemIdentifier = @"ParticipantsToolbarItemIdentifier";


@implementation PlainTextWindowController

- (id)init {
    if ((self=[super initWithWindowNibName:@"PlainTextWindow"])) {
    
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:[self document] name:NSTextViewDidChangeSelectionNotification object:O_textView];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [O_textView setDelegate:nil];
    [[[self window] toolbar] setDelegate:nil];
    [O_participantsView release];
    [super dealloc];
}

- (void)windowWillLoad {
    if ([self document]) {
        [[self document] windowControllerWillLoadNib:self];
    }
}

- (void)windowDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:[self document] selector:@selector(textViewDidChangeSelection:) name:NSTextViewDidChangeSelectionNotification object:O_textView];

    [O_pendingUsersTableView setTarget:self];
    [O_pendingUsersTableView setDoubleAction:@selector(pendingUsersTableViewDoubleAction:)];
    [[O_textView layoutManager] replaceTextStorage:[[self document] textStorage]];
    [O_textView setDelegate:self];
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:PlainTextWindowToolbarIdentifier] autorelease];
    [toolbar setAllowsUserCustomization:YES];
    //[toolbar setAutosavesConfiguration:YES];
    [toolbar setDelegate:self];
    [[self window] setToolbar:toolbar];
    
    NSSize drawerSize = [O_participantsDrawer contentSize];
    drawerSize.width = 170;
    [O_participantsDrawer setContentSize:drawerSize];
    
    if ([self document]) {
        [[self document] windowControllerDidLoadNib:self];
    }
    
    NSRect frame = [[O_participantsScrollView contentView] frame];
    O_participantsView = [[ParticipantsView alloc] initWithFrame:frame];
    [O_participantsScrollView setBorderType:NSBezelBorder];
    [O_participantsView setDelegate:self];
    [O_participantsView setDataSource:self];
    [O_participantsScrollView setHasVerticalScroller:YES];
    [[O_participantsScrollView verticalScroller] setControlSize:NSSmallControlSize];
    [O_participantsScrollView setDocumentView:O_participantsView];
    [O_participantsView noteEnclosingScrollView];
    
    [O_actionPullDown setCell:[[ImagePopUpButtonCell new] autorelease]];
    [[O_actionPullDown cell] setPullsDown:YES];
    [[O_actionPullDown cell] setImage:[NSImage imageNamed:@"Action"]];
    [[O_actionPullDown cell] setAlternateImage:[NSImage imageNamed:@"ActionPressed"]];
    [[O_actionPullDown cell] setUsesItemFromMenu:NO];
    [O_actionPullDown addItemsWithTitles:[NSArray arrayWithObjects:@"<do not modify>", @"Ich", @"bin", @"das", @"Action", @"MenŸ", nil]];
    
    [O_newUserView setFrameSize:NSMakeSize([O_newUserView frame].size.width, 0)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(pendingUsersDidChange:)
                                                 name:TCMMMSessionPendingUsersDidChangeNotification 
                                               object:[(PlainTextDocument *)[self document] session]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    
    if (action == @selector(toggleParticipantsDrawer:)) {
        [menuItem setTitle:
            [(NSDrawer *)[[[self window] drawers] objectAtIndex:0] state] == NSDrawerOpenState ?
            NSLocalizedString(@"Hide Participants", nil) :
            NSLocalizedString(@"Show Participants", nil)];
        return YES;
    }
    
    return YES;
}


- (NSTextView *)textView {
    return O_textView;
}

#pragma mark -

- (IBAction)toggleParticipantsDrawer:(id)sender {
    [O_participantsDrawer toggle:sender];
}

- (IBAction)changePendingUsersAccess:(id)aSender {

}

- (IBAction)pendingUsersTableViewDoubleAction:(id)aSender {
    NSLog(@"pendingUsersTableViewDoubleAction");
    NSIndexSet *set = [aSender selectedRowIndexes];
    if ([set count] > 0) {
        [[(PlainTextDocument *)[self document] session] setGroup:@"NixPoofState" forPendingUsersWithIndexes:set];
    }
}

#pragma mark -

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {

    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
    
    if ([itemIdent isEqualToString:ParticipantsToolbarItemIdentifier]) {
        [toolbarItem setLabel:@"Participants"];
        [toolbarItem setPaletteLabel:@"Participants"];
        [toolbarItem setToolTip:@"Participants"];
        [toolbarItem setImage:[NSImage imageNamed:@"Participants"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(toggleParticipantsDrawer:)];
    } else {
        toolbarItem = nil;
    }
    
    return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
                NSToolbarFlexibleSpaceItemIdentifier,
                ParticipantsToolbarItemIdentifier,
                nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
                ParticipantsToolbarItemIdentifier,
                NSToolbarPrintItemIdentifier,
                NSToolbarCustomizeToolbarItemIdentifier,
                NSToolbarSeparatorItemIdentifier,
                NSToolbarSpaceItemIdentifier,
                NSToolbarFlexibleSpaceItemIdentifier,
                nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
    NSString *itemIdentifier = [toolbarItem itemIdentifier];
    
    if ([itemIdentifier isEqualToString:ParticipantsToolbarItemIdentifier]) {
        return YES;
    }
    
    return YES;
}

#pragma mark -

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[[(PlainTextDocument *)[self document] session] pendingUsers] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    TCMMMUser *user = [[[(PlainTextDocument *)[self document] session] pendingUsers] objectAtIndex:row];
    if ([[tableColumn identifier] isEqualToString:@"image"]) {
        return [[user properties] objectForKey:@"Image16"];
    } else if ([[tableColumn identifier] isEqualToString:@"name"]) {
        return [user name];
    }
    
    return nil;
}

- (void)pendingUsersDidChange:(NSNotification *)aNotifcation {
    [O_pendingUsersTableView reloadData];
}

#pragma mark -

//- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
//}

#pragma mark -
#pragma mark ### NSTextView delegate methods ###


@end
