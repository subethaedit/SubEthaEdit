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
#import "PlainTextEditor.h"
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "SelectionOperation.h"
#import "ImagePopUpButtonCell.h"
#import "LayoutManager.h"
#import "TextView.h"
#import "SplitView.h"
#import "RendezvousBrowserController.h"

NSString * const PlainTextWindowToolbarIdentifier = @"PlainTextWindowToolbarIdentifier";
NSString * const ParticipantsToolbarItemIdentifier = 
               @"ParticipantsToolbarItemIdentifier";
NSString * const ShiftLeftToolbarItemIdentifier = 
               @"ShiftLeftToolbarItemIdentifier";
NSString * const ShiftRightToolbarItemIdentifier = 
               @"ShiftRightToolbarItemIdentifier";
NSString * const RendezvousToolbarItemIdentifier = 
               @"RendezvousToolbarItemIdentifier";
NSString * const ToggleChangeMarksToolbarItemIdentifier = 
               @"ToggleChangeMarksToolbarItemIdentifier";


@implementation PlainTextWindowController

- (id)init {
    if ((self=[super initWithWindowNibName:@"PlainTextWindow"])) {
        I_plainTextEditors = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    [[[self window] toolbar] setDelegate:nil];
    [O_participantsView release];
    [I_plainTextEditors release];
    [super dealloc];
}

- (void)windowWillLoad {
    if ([self document]) {
        [[self document] windowControllerWillLoadNib:self];
    }
}

- (void)windowDidLoad {

    [O_pendingUsersTableView setTarget:self];
    [O_pendingUsersTableView setDoubleAction:@selector(pendingUsersTableViewDoubleAction:)];

    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:PlainTextWindowToolbarIdentifier] autorelease];
    [toolbar setAllowsUserCustomization:YES];
    //[toolbar setAutosavesConfiguration:YES];
    [toolbar setDelegate:self];
    [[self window] setToolbar:toolbar];
    
    NSSize drawerSize = [O_participantsDrawer contentSize];
    drawerSize.width = 170;
    [O_participantsDrawer setContentSize:drawerSize];
    
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

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(displayNameDidChange:)
                                                 name:PlainTextDocumentDidChangeDisplayNameNotification 
                                               object:[self document]];
    
    PlainTextEditor *plainTextEditor = [[PlainTextEditor alloc] initWithWindowController:self];
    [[self window] setContentView:[plainTextEditor editorView]];
    [I_plainTextEditors addObject:plainTextEditor];
    [plainTextEditor release];
    if ([self document]) {
        [[self document] windowControllerDidLoadNib:self];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL selector = [menuItem action];
    
    if (selector == @selector(toggleParticipantsDrawer:)) {
        [menuItem setTitle:
            [(NSDrawer *)[[[self window] drawers] objectAtIndex:0] state] == NSDrawerOpenState ?
            NSLocalizedString(@"Hide Participants", nil) :
            NSLocalizedString(@"Show Participants", nil)];
        return YES;
    } 
    return YES;
}

- (NSArray *)plainTextEditors {
    return I_plainTextEditors;
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
    } else if ([itemIdent isEqual:RendezvousToolbarItemIdentifier]) { 
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Rendezvous", nil)];
        [toolbarItem setLabel:NSLocalizedString(@"Rendezvous", nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Open Rendezvous Browser", nil)];
        [toolbarItem setImage:[NSImage imageNamed: @"Rendezvous"]];
        [toolbarItem setTarget:[RendezvousBrowserController sharedInstance]];
        [toolbarItem setAction:@selector(showWindow:)];
    } else if ([itemIdent isEqual:ShiftRightToolbarItemIdentifier]) {
        [toolbarItem setToolTip:NSLocalizedString(@"Shift Selection Right", nil)];
        [toolbarItem setLabel:NSLocalizedString(@"Shift Right", nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Shift Right", nil)];
        [toolbarItem setImage:([NSImage imageNamed: @"ShiftRight"])];
        [toolbarItem setTarget:nil];
        [toolbarItem setAction:@selector(shiftRight:)];    
    } else if ([itemIdent isEqual:ShiftLeftToolbarItemIdentifier]) {
        [toolbarItem setToolTip:NSLocalizedString(@"Shift Selection Left", nil)];
        [toolbarItem setLabel:NSLocalizedString(@"Shift Left", nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Shift Left", nil)];
        [toolbarItem setImage:([NSImage imageNamed: @"ShiftLeft"])];
        [toolbarItem setTarget:nil];
        [toolbarItem setAction:@selector(shiftLeft:)];    
    } else if ([itemIdent isEqual:ToggleChangeMarksToolbarItemIdentifier]) {
        [toolbarItem setToolTip:NSLocalizedString(@"Toggle Change Marks", nil)];
        [toolbarItem setLabel:NSLocalizedString(@"Toggle Changes", nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Toggle Changes", nil)];
        [toolbarItem setImage:([NSImage imageNamed: @"ShowChangeMarks"])];
        [toolbarItem setTarget:nil];
        [toolbarItem setAction:@selector(toggleShowsChangeMarks:)];    
    } else {
        toolbarItem = nil;
    }
    
    return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
                RendezvousToolbarItemIdentifier,
                NSToolbarSeparatorItemIdentifier,
                ShiftLeftToolbarItemIdentifier,
                ShiftRightToolbarItemIdentifier,
                ToggleChangeMarksToolbarItemIdentifier,
                NSToolbarFlexibleSpaceItemIdentifier,
                ParticipantsToolbarItemIdentifier,
                nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
                RendezvousToolbarItemIdentifier,
                ShiftLeftToolbarItemIdentifier,
                ShiftRightToolbarItemIdentifier,
                ParticipantsToolbarItemIdentifier,
                ToggleChangeMarksToolbarItemIdentifier,
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

- (void)displayNameDidChange:(NSNotification *)aNotification {
    [self synchronizeWindowTitleWithDocumentName];
}

#pragma mark -

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
//    if ([[self document] isRemote]) {
//        displayName=[displayName stringByAppendingFormat:@" (%@)",
//                        [[[UserManager sharedInstance] userForUserId:[[self document] userIdOfHost]] 
//                            objectForKey:kUserNameProperty]];
//    }
    int requests;
    if ((requests=[[[(PlainTextDocument *)[self document] session] pendingUsers] count])>0) {
        displayName=[displayName stringByAppendingFormat:@" (%@)", [NSString stringWithFormat:NSLocalizedString(@"%d pending", @"Pending Users Display in Menu Title Bar"), requests]];
    }


    NSArray *windowControllers=[[self document] windowControllers];
    if ([windowControllers count]>1) {
        displayName = [displayName stringByAppendingFormat:@" - %d/%d",
                        [windowControllers indexOfObject:self]+1,
                        [windowControllers count]];
    }
    
    return displayName;
}

#pragma mark -

#define SPLITMINHEIGHT 46.
//- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
//}

-(void)splitView:(NSSplitView *)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize {
    if (aSplitView != O_participantsSplitView) {
        NSRect frame=[aSplitView bounds];
        NSArray *subviews=[aSplitView subviews];
        NSRect frametop=[[subviews objectAtIndex:0] frame];
        NSRect framebottom=[[subviews objectAtIndex:1] frame];
        float newHeight1=frame.size.height-[aSplitView dividerThickness];
        float topratio=frametop.size.height/(oldSize.height-[aSplitView dividerThickness]);
        frametop.size.height=(float)((int)(newHeight1*topratio));
        if (frametop.size.height<SPLITMINHEIGHT) {
            frametop.size.height=SPLITMINHEIGHT;
        } else if (newHeight1-frametop.size.height<SPLITMINHEIGHT) {
            frametop.size.height=newHeight1-SPLITMINHEIGHT;
        }

        framebottom.size.height=newHeight1-frametop.size.height;
        framebottom.size.width=frametop.size.width=frame.size.width;
        
        frametop.origin.x=framebottom.origin.x=frame.origin.x;
        frametop.origin.y=frame.origin.y;
        framebottom.origin.y=frame.origin.y+[aSplitView dividerThickness]+frametop.size.height;
        
        [[subviews objectAtIndex:0] setFrame:frametop];
        [[subviews objectAtIndex:1] setFrame:framebottom];
    } else {
        [aSplitView adjustSubviews];
    }
}

- (BOOL)splitView:(NSSplitView *)aSplitView canCollapseSubview:(NSView *)aView {
    if (aSplitView != O_participantsSplitView) {
        return NO;
    }
    
    return YES;
}

- (float)splitView:(NSSplitView *)aSplitView constrainSplitPosition:(float)proposedPosition 
       ofSubviewAt:(int)offset {
    if (aSplitView != O_participantsSplitView) {
        float height=[aSplitView frame].size.height;
        float minHeight=SPLITMINHEIGHT;
        if (proposedPosition<minHeight) {
            return minHeight;
        } else if (proposedPosition+minHeight+[aSplitView dividerThickness]>height) {
            return height-minHeight-[aSplitView dividerThickness];
        } else {
            return proposedPosition;
        }
    }
    return proposedPosition;
}

- (void)toggleSplitView:(id)aSender {
    if ([I_plainTextEditors count]==1) {
        PlainTextEditor *plainTextEditor = [[PlainTextEditor alloc] initWithWindowController:self];
        [I_plainTextEditors addObject:plainTextEditor];
        [plainTextEditor release];
        NSSplitView *splitView = [[SplitView alloc] initWithFrame:[[[self window] contentView] frame]];
        [[self window] setContentView:splitView];
        NSSize splitSize=[splitView frame].size;
        splitSize.height=splitSize.height/2.;
        [[[I_plainTextEditors objectAtIndex:0] editorView] setFrameSize:splitSize];
        [[[I_plainTextEditors objectAtIndex:1] editorView] setFrameSize:splitSize];
        [splitView addSubview:[[I_plainTextEditors objectAtIndex:0] editorView]];
        [splitView addSubview:[[I_plainTextEditors objectAtIndex:1] editorView]];
        [splitView setIsPaneSplitter:YES];
        [splitView setDelegate:self];
        [splitView release];
    } else if ([I_plainTextEditors count]==2) {
        [[self window] setContentView:[[I_plainTextEditors objectAtIndex:0] editorView]];
        [I_plainTextEditors removeObjectAtIndex:1];
    }
}

#pragma mark -
#pragma mark ### ParticipantsView data source methods ###

- (int)numberOfItemsInParticipantsView:(ParticipantsView *)aListView {
    return 2;
}

- (int)participantsView:(ParticipantsView *)aListView numberOfChildrenOfItemAtIndex:(int)anItemIndex {
    NSDictionary *participants=[[(PlainTextDocument *)[self document] session] participants];
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

@end
