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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultParagraphStyleDidChange:) name:PlainTextDocumentDefaultParagraphStyleDidChangeNotification object:[self document]];

    [O_pendingUsersTableView setTarget:self];
    [O_pendingUsersTableView setDoubleAction:@selector(pendingUsersTableViewDoubleAction:)];
    [[O_textView layoutManager] replaceTextStorage:[[self document] textStorage]];
    [O_textView setDelegate:self];

    [O_textView setDefaultParagraphStyle:[[self document] defaultParagraphStyle]];

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
    
    //[O_newUserView setFrameSize:NSMakeSize([O_newUserView frame].size.width, 0)];
    
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
        [[(PlainTextDocument *)[self document] session] setGroup:@"ReadWrite" forPendingUsersWithIndexes:set];
    }
    [O_participantsView reloadData];
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

- (void)defaultParagraphStyleDidChange:(NSNotification *)aNotification {
    [O_textView setDefaultParagraphStyle:[[self document] defaultParagraphStyle]];
}
#pragma mark -
#pragma mark ### ParticipantsView data source methods ###

- (int)numberOfItemsInParticipantsView:(ParticipantsView *)aListView {
    return 2;
}

- (int)participantsView:(ParticipantsView *)aListView numberOfChildrenOfItemAtIndex:(int)anItemIndex {
    NSDictionary *participants=[[(PlainTextDocument *)[self document] session] participants];
    NSLog(@"Participants: %@",[participants description]);
    if (anItemIndex==0) {
        return [[participants objectForKey:@"ReadWrite"] count];
    } else if (anItemIndex==1) {
        return [[participants objectForKey:@"ReadOnly"] count];
    }
    return 0;
}

- (id)participantsView:(ParticipantsView *)aListView objectValueForTag:(int)aTag ofItemAtIndex:(int)anItemIndex {

//    static NSImage *statusLock=nil;
    static NSImage *statusReadOnly=nil;

//    if (!statusLock) statusLock=[[NSImage imageNamed:@"StatusLock"] retain];
    if (!statusReadOnly) statusReadOnly=[[NSImage imageNamed:@"StatusReadOnly"] retain];
    if (anItemIndex==0) {
        if (aTag==ParticipantsItemStatusImageTag) {
            return nil;
        } else if (aTag==ParticipantsItemNameTag) {
            return @"read/write";
        } 
    } else if (anItemIndex==1) {
        if (aTag==ParticipantsItemStatusImageTag) {
            return statusReadOnly;
        } else if (aTag==ParticipantsItemNameTag) {
            return @"read only";
        } 
    }
    return nil;
}

- (id)participantsView:(ParticipantsView *)aListView objectValueForTag:(int)aTag atIndex:(int)anIndex ofItemAtIndex:(int)anItemIndex {
    NSDictionary *participants=[[(PlainTextDocument *)[self document] session] participants];
    TCMMMUser *user=nil;
    if (anItemIndex==0) {
        user=[[participants objectForKey:@"ReadWrite"] objectAtIndex:anIndex];
    } else if (anItemIndex==1) {
        user=[[participants objectForKey:@"ReadOnly"] objectAtIndex:anIndex];
    }
    if (anItemIndex>=0 && anItemIndex<2) {
        if (aTag==ParticipantsChildNameTag) {
            return [user name];
        } else if (aTag==ParticipantsChildStatusTag) {
            return @"status";
        } else if (aTag==ParticipantsChildImageTag) {
            return [[user properties] objectForKey:@"Image32"];
        } else if (aTag==ParticipantsChildImageNextToNameTag) {
            return [[user properties] objectForKey:@"ColorImage"];
        }
    }
    return nil;
}


#pragma mark -
#pragma mark ### NSTextView delegate methods ###

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
    return [[self document] textView:aTextView doCommandBySelector:aSelector];
}

-(BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
    [aTextView setTypingAttributes:[(PlainTextDocument *)[self document] plainTextAttributes]];
    return YES;
}

@end
