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
#import "TextStorage.h"
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "SelectionOperation.h"
#import "ImagePopUpButtonCell.h"
#import "LayoutManager.h"
#import "TextView.h"
#import "SplitView.h"
#import "RendezvousBrowserController.h"
#import "TCMMMSession.h"

NSString * const PlainTextWindowToolbarIdentifier = 
               @"PlainTextWindowToolbarIdentifier";
NSString * const ParticipantsToolbarItemIdentifier = 
               @"ParticipantsToolbarItemIdentifier";
NSString * const ShiftLeftToolbarItemIdentifier = 
               @"ShiftLeftToolbarItemIdentifier";
NSString * const ShiftRightToolbarItemIdentifier = 
               @"ShiftRightToolbarItemIdentifier";
NSString * const NextSymbolToolbarItemIdentifier = 
               @"NextSymbolToolbarItemIdentifier";
NSString * const PreviousSymbolToolbarItemIdentifier = 
               @"PreviousSymbolToolbarItemIdentifier";
NSString * const NextChangeToolbarItemIdentifier = 
               @"NextChangeToolbarItemIdentifier";
NSString * const PreviousChangeToolbarItemIdentifier = 
               @"PreviousChangeToolbarItemIdentifier";
NSString * const RendezvousToolbarItemIdentifier = 
               @"RendezvousToolbarItemIdentifier";
NSString * const ToggleChangeMarksToolbarItemIdentifier = 
               @"ToggleChangeMarksToolbarItemIdentifier";
NSString * const ToggleAnnouncementToolbarItemIdentifier = 
               @"ToggleAnnouncementToolbarItemIdentifier";


@implementation PlainTextWindowController

- (id)init {
    if ((self=[super initWithWindowNibName:@"PlainTextWindow"])) {
        I_plainTextEditors = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:PlainTextWindowToolbarIdentifier] autorelease];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
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
    [O_participantsView setDoubleAction:@selector(participantDoubleAction:)];
    [O_participantsView setTarget:self];
    
    [O_actionPullDown setCell:[[ImagePopUpButtonCell new] autorelease]];
    [[O_actionPullDown cell] setPullsDown:YES];
    [[O_actionPullDown cell] setImage:[NSImage imageNamed:@"Action"]];
    [[O_actionPullDown cell] setAlternateImage:[NSImage imageNamed:@"ActionPressed"]];
    [[O_actionPullDown cell] setUsesItemFromMenu:NO];
    [O_actionPullDown addItemsWithTitles:[NSArray arrayWithObjects:@"<do not modify>", @"Ich", @"bin", @"das", @"Action", @"MenŸ", nil]];
    
    //[O_newUserView setFrameSize:NSMakeSize([O_newUserView frame].size.width, 0)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(sessionWillChange:)
                                                 name:PlainTextDocumentSessionWillChangeNotification 
                                               object:[self document]];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(sessionDidChange:)
                                                 name:PlainTextDocumentSessionDidChangeNotification 
                                               object:[self document]];

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(participantsDidChange:)
                                                 name:PlainTextDocumentParticipantsDidChangeNotification 
                                               object:[self document]];

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(participantsDidChange:)
                                                 name:TCMMMSessionParticipantsDidChangeNotification 
                                               object:[(PlainTextDocument *)[self document] session]];

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(pendingUsersDidChange:)
                                                 name:TCMMMSessionPendingUsersDidChangeNotification 
                                               object:[(PlainTextDocument *)[self document] session]];

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(displayNameDidChange:)
                                                 name:PlainTextDocumentDidChangeDisplayNameNotification 
                                               object:[self document]];
    
    PlainTextEditor *plainTextEditor = [[PlainTextEditor alloc] initWithWindowController:self splitButton:YES];
    [[self window] setInitialFirstResponder:[plainTextEditor textView]];
    [[self window] setContentView:[plainTextEditor editorView]];
    [I_plainTextEditors addObject:plainTextEditor];
    [plainTextEditor release];
    if ([self document]) {
        [[self document] windowControllerDidLoadNib:self];
    }
    
    [self validateButtons];
}

- (void)setIsReceivingContent:(BOOL)aFlag {
    NSWindow *window=[self window];
    I_flags.isReceivingContent=aFlag;
    if (aFlag) {
        [window setContentView:O_receivingContentView];
        [O_progressIndicator startAnimation:self];
    } else {
        [O_progressIndicator stopAnimation:self];
        [window setContentView:[[I_plainTextEditors objectAtIndex:0] editorView]];
    }
}


- (void)setSizeByColumns:(int)aColumns rows:(int)aRows {
    NSSize contentSize=[[I_plainTextEditors objectAtIndex:0] desiredSizeForColumns:aColumns rows:aRows];
    NSWindow *window=[self window];
    NSSize minSize=[window contentMinSize];
    
    [[self window] setContentSize:NSMakeSize(MAX(contentSize.width,minSize.width),
                                             MAX(contentSize.height,minSize.height))];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL selector = [menuItem action];
    
    if (selector == @selector(toggleParticipantsDrawer:)) {
        [menuItem setTitle:
            [(NSDrawer *)[[[self window] drawers] objectAtIndex:0] state] == NSDrawerOpenState ?
            NSLocalizedString(@"Hide Participants", nil) :
            NSLocalizedString(@"Show Participants", nil)];
        return YES;
    } else if (selector == @selector(toggleBottomStatusBar:)) {
        [menuItem setState:[[I_plainTextEditors lastObject] showsBottomStatusBar]?NSOnState:NSOffState];
        return YES;
    } else if (selector == @selector(toggleLineNumbers:)) {
        [menuItem setState:[self showsGutter]?NSOnState:NSOffState];
        return YES;
    } else if (selector == @selector(copyDocumentURL:)) {
        return [[(PlainTextDocument *)[self document] session] isServer];
    } else if (selector == @selector(toggleSplitView:)) {
        [menuItem setTitle:[I_plainTextEditors count]==1?
                           NSLocalizedString(@"Split View",@"Split View Menu Entry"):
                           NSLocalizedString(@"Collapse Split View",@"Collapse Split View Menu Entry")];
        return !I_flags.isReceivingContent;
    }
    return YES;
}

- (NSArray *)plainTextEditors {
    return I_plainTextEditors;
}

- (PlainTextEditor *)activePlainTextEditor {
    if ([I_plainTextEditors count]!=1) {
        id responder=[[self window]firstResponder];
        if ([responder isKindOfClass:[NSTextView class]]) {
            if ([[I_plainTextEditors objectAtIndex:1] textView] == responder) {
                return [I_plainTextEditors objectAtIndex:1];
            }
        }
    }
    return [I_plainTextEditors objectAtIndex:0];
}

#pragma mark -

- (void)gotoLine:(unsigned)aLine {
    NSRange range=[(TextStorage *)[[self document] textStorage] findLine:aLine];
    [self selectRange:range];
}

- (void)selectRange:(NSRange)aRange {
    NSTextView *aTextView=[[self activePlainTextEditor] textView];
    NSRange range=NSIntersectionRange(aRange,NSMakeRange(0,[[aTextView textStorage] length]));
    if (range.length>0) {
        [aTextView setSelectedRange:range];
    }
    [aTextView scrollRangeToVisible:range];
}

#pragma mark -

- (BOOL)showsBottomStatusBar {
    return [[I_plainTextEditors lastObject] showsBottomStatusBar];
}

- (void)setShowsBottomStatusBar:(BOOL)aFlag {
    BOOL showsBottomStatusBar=[self showsBottomStatusBar];
    if (showsBottomStatusBar!=aFlag) {
        [[I_plainTextEditors lastObject] setShowsBottomStatusBar:aFlag];
        [[self document] setShowsBottomStatusBar:aFlag];
    }
}

- (IBAction)openParticipantsDrawer:(id)aSender {
    [O_participantsDrawer open:aSender];
}

- (IBAction)closeParticipantsDrawer:(id)aSender {
    [O_participantsDrawer close:aSender];
}

- (IBAction)toggleParticipantsDrawer:(id)sender {
    [O_participantsDrawer toggle:sender];
}

- (void)validateButtons {
    [O_kickButton setEnabled:NO];
    [O_readOnlyButton setEnabled:NO];
    [O_readWriteButton setEnabled:NO];
    if ([[(PlainTextDocument *)[self document] session] isServer]) {
        if ([O_participantsView numberOfSelectedRows] == 1) {
            int selectedRow=[O_participantsView selectedRow];
            ItemChildPair pair=[O_participantsView itemChildPairAtRow:selectedRow];
            if (pair.childIndex!=-1) {
                if (pair.itemIndex==0) {
                    [O_readOnlyButton setEnabled:YES];
                } else if (pair.itemIndex==1) {
                    [O_readWriteButton setEnabled:YES];
                } else if (pair.itemIndex==2) {
                    [O_readOnlyButton setEnabled:YES];
                    [O_readWriteButton setEnabled:YES];
                }
                [O_kickButton setEnabled:YES];
            }
        }
    }
}

- (IBAction)kickButtonAction:(id)aSender {
    if ([O_participantsView numberOfSelectedRows] == 1) {
        int selectedRow=[O_participantsView selectedRow];
        ItemChildPair pair=[O_participantsView itemChildPairAtRow:selectedRow];
        if (pair.childIndex!=-1) {
            TCMMMSession *session=[(PlainTextDocument *)[self document] session];
            if (pair.itemIndex==2) {
                [session setGroup:@"PoofGroup" forPendingUsersWithIndexes:[NSIndexSet indexSetWithIndex:pair.childIndex]];
            } else {
                NSString *userID=[[[[session participants] objectForKey:(pair.itemIndex==0?@"ReadWrite":@"ReadOnly")] objectAtIndex:pair.childIndex] userID];
                if (![userID isEqualToString:[TCMMMUserManager myUserID]]) {
                    [session setGroup:@"PoofGroup" forParticipantsWithUserIDs:[NSArray arrayWithObject:userID]];
                }
            }
        }
    }
    [O_participantsView reloadData];
    [self validateButtons];
}

- (IBAction)readOnlyButtonAction:(id)aSender {
    if ([O_participantsView numberOfSelectedRows] == 1) {
        int selectedRow=[O_participantsView selectedRow];
        ItemChildPair pair=[O_participantsView itemChildPairAtRow:selectedRow];
        if (pair.childIndex!=-1) {
            if (pair.itemIndex==2) {
                [[(PlainTextDocument *)[self document] session] setGroup:@"ReadOnly" forPendingUsersWithIndexes:[NSIndexSet indexSetWithIndex:pair.childIndex]];
            }
        }
    }
    [O_participantsView reloadData];
    [self validateButtons];
}
- (IBAction)readWriteButtonAction:(id)aSender {
    if ([O_participantsView numberOfSelectedRows] == 1) {
        int selectedRow=[O_participantsView selectedRow];
        ItemChildPair pair=[O_participantsView itemChildPairAtRow:selectedRow];
        if (pair.childIndex!=-1) {
            TCMMMSession *session=[(PlainTextDocument *)[self document] session];
            if (pair.itemIndex==2) {
                [session setGroup:@"ReadWrite" forPendingUsersWithIndexes:[NSIndexSet indexSetWithIndex:pair.childIndex]];
            } else if (pair.itemIndex==1) {
                NSString *userID=[[[[session participants] objectForKey:(pair.itemIndex==0?@"ReadWrite":@"ReadOnly")] objectAtIndex:pair.childIndex] userID];
                if (![userID isEqualToString:[TCMMMUserManager myUserID]]) {
                    [session setGroup:@"ReadWrite" forParticipantsWithUserIDs:
                        [NSArray arrayWithObject:userID]];
                }
            }
        }
    }
    [O_participantsView reloadData];
    [self validateButtons];
}

- (IBAction)participantDoubleAction:(id)aSender {
    [self readWriteButtonAction:(id)aSender];
}

- (IBAction)changePendingUsersAccess:(id)aSender {
    TCMMMSession *session=[(PlainTextDocument *)[self document] session];
    [session setAccessState:[[aSender selectedItem] tag]];
}

- (IBAction)toggleBottomStatusBar:(id)aSender {
    [self setShowsBottomStatusBar:![self showsBottomStatusBar]];
    [(PlainTextDocument *)[self document] setShowsBottomStatusBar:[self showsBottomStatusBar]];
}

- (BOOL)showsGutter {
    return [[I_plainTextEditors objectAtIndex:0] showsGutter];
}

- (void)setShowsGutter:(BOOL)aFlag {
    int i;
    for (i=0;i<[I_plainTextEditors count];i++) {
        [[I_plainTextEditors objectAtIndex:i] setShowsGutter:aFlag];
    }
    [[self document] setShowsGutter:aFlag];
}

- (IBAction)toggleLineNumbers:(id)aSender {
    [self setShowsGutter:![self showsGutter]];
}


- (IBAction)jumpToNextSymbol:(id)aSender {
    TextView *textView = (TextView *)[[self activePlainTextEditor] textView];
    NSRange change = [[self document] rangeOfPrevious:NO 
                                       symbolForRange:NSMakeRange(NSMaxRange([textView selectedRange]),0)];
    if (change.location == NSNotFound) {
        NSBeep();
    } else {
        [textView setSelectedRange:change];
        [textView scrollRangeToVisible:change];
    }
}

- (IBAction)jumpToPreviousSymbol:(id)aSender {
    TextView *textView = (TextView *)[[self activePlainTextEditor] textView];
    NSRange change = [[self document] rangeOfPrevious:YES 
                                       symbolForRange:NSMakeRange([textView selectedRange].location,0)];
    if (change.location == NSNotFound) {
        NSBeep();
    } else {
        [textView setSelectedRange:change];
        [textView scrollRangeToVisible:change];
    }
}


- (IBAction)jumpToNextChange:(id)aSender {
    [[self activePlainTextEditor] jumpToNextChange:aSender];
}

- (IBAction)jumpToPreviousChange:(id)aSender {
    [[self activePlainTextEditor] jumpToPreviousChange:aSender];
}


- (IBAction)copyDocumentURL:(id)aSender {

    NSURL *documentURL = [[self document] documentURL];    
    
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    NSArray *pbTypes = [NSArray arrayWithObjects:NSStringPboardType, NSURLPboardType, @"CorePasteboardFlavorType 0x75726C20", @"CorePasteboardFlavorType 0x75726C6E", nil];
    [pboard declareTypes:pbTypes owner:self];
    const char *dataUTF8 = [[documentURL absoluteString] UTF8String];
    [pboard setData:[NSData dataWithBytes:dataUTF8 length:strlen(dataUTF8)] forType:@"CorePasteboardFlavorType 0x75726C20"];
    dataUTF8 = [[[self document] displayName] UTF8String];
    [pboard setData:[NSData dataWithBytes:dataUTF8 length:strlen(dataUTF8)] forType:@"CorePasteboardFlavorType 0x75726C6E"];
    [pboard setString:[documentURL absoluteString] forType:NSStringPboardType];
    [documentURL writeToPasteboard:pboard];
}

#pragma mark -
#pragma mark ### Toolbar ###

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
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(toggleShowsChangeMarks:)];    
    } else if ([itemIdent isEqual:PreviousSymbolToolbarItemIdentifier]) {
        [toolbarItem setToolTip:NSLocalizedString(@"Goto Previous Symbol", nil)];
        [toolbarItem setLabel:NSLocalizedString(@"Previous Symbol", nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Previous Symbol", nil)];
        [toolbarItem setImage:[NSImage imageNamed: @"PreviousSymbol"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(jumpToPreviousSymbol:)];    
    } else if ([itemIdent isEqual:NextSymbolToolbarItemIdentifier]) {
        [toolbarItem setToolTip:NSLocalizedString(@"Goto Next Symbol", nil)];
        [toolbarItem setLabel:NSLocalizedString(@"Next Symbol", nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Next Symbol", nil)];
        [toolbarItem setImage:[NSImage imageNamed:@"NextSymbol"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(jumpToNextSymbol:)];    
    } else if ([itemIdent isEqual:PreviousChangeToolbarItemIdentifier]) {
        [toolbarItem setToolTip:NSLocalizedString(@"Goto Previous Change", nil)];
        [toolbarItem setLabel:NSLocalizedString(@"Previous Change", nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Previous Change", nil)];
        [toolbarItem setImage:[NSImage imageNamed: @"PreviousChange"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(jumpToPreviousChange:)];    
    } else if ([itemIdent isEqual:NextChangeToolbarItemIdentifier]) {
        [toolbarItem setToolTip:NSLocalizedString(@"Goto Next Change", nil)];
        [toolbarItem setLabel:NSLocalizedString(@"Next Change", nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Next Change", nil)];
        [toolbarItem setImage:[NSImage imageNamed:@"NextChange"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(jumpToNextChange:)];    
    } else if ([itemIdent isEqual:ToggleAnnouncementToolbarItemIdentifier]) {
        [toolbarItem setToolTip:NSLocalizedString(@"Announce/Conceal Document", nil)];
        [toolbarItem setLabel:NSLocalizedString(@"Announce/Conceal", nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Announce/Conceal", nil)];
        [toolbarItem setImage:([NSImage imageNamed: @"Announce"])];
        [toolbarItem setTarget:[self document]];
        [toolbarItem setAction:@selector(toggleIsAnnounced:)];    
    } else {
        toolbarItem = nil;
    }
    
    return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
                RendezvousToolbarItemIdentifier,
                ToggleAnnouncementToolbarItemIdentifier,
                NSToolbarSeparatorItemIdentifier,
                ShiftLeftToolbarItemIdentifier,
                ShiftRightToolbarItemIdentifier,
                PreviousSymbolToolbarItemIdentifier,
                NextSymbolToolbarItemIdentifier,
                PreviousChangeToolbarItemIdentifier,
                NextChangeToolbarItemIdentifier,
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
                PreviousSymbolToolbarItemIdentifier,
                NextSymbolToolbarItemIdentifier,
                ParticipantsToolbarItemIdentifier,
                PreviousChangeToolbarItemIdentifier,
                NextChangeToolbarItemIdentifier,
                ToggleChangeMarksToolbarItemIdentifier,
                ToggleAnnouncementToolbarItemIdentifier,
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
    } else if ([itemIdentifier isEqualToString:ToggleChangeMarksToolbarItemIdentifier]) {
        return [[self activePlainTextEditor] validateToolbarItem:toolbarItem];
    }
    
    return YES;
}

- (IBAction)toggleShowsChangeMarks:(id)aSender {
    [[self activePlainTextEditor] toggleShowsChangeMarks:aSender];
}

#pragma mark -

- (void)sessionWillChange:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMMMSessionParticipantsDidChangeNotification object:[(PlainTextDocument *)[self document] session]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMMMSessionPendingUsersDidChangeNotification object:[(PlainTextDocument *)[self document] session]];
}

- (void)sessionDidChange:(NSNotification *)aNotification {
    [O_participantsView reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(participantsDidChange:)
                                                 name:TCMMMSessionParticipantsDidChangeNotification 
                                               object:[(PlainTextDocument *)[self document] session]];

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(pendingUsersDidChange:)
                                                 name:TCMMMSessionPendingUsersDidChangeNotification 
                                               object:[(PlainTextDocument *)[self document] session]];
    BOOL isEditable=[(PlainTextDocument *)[self document] isEditable];
    NSEnumerator *plainTextEditors=[[self plainTextEditors] objectEnumerator];
    PlainTextEditor *editor=nil;
    while ((editor=[plainTextEditors nextObject])) {
        [[editor textView] setEditable:isEditable];
    }
}

- (void)participantsDidChange:(NSNotification *)aNotifcation {
    [O_participantsView reloadData];
}

- (void)pendingUsersDidChange:(NSNotification *)aNotifcation {
    [O_participantsView reloadData];
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

-(void)splitView:(NSSplitView *)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize {
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
}

- (BOOL)splitView:(NSSplitView *)aSplitView canCollapseSubview:(NSView *)aView {
    return NO;
}

- (float)splitView:(NSSplitView *)aSplitView constrainSplitPosition:(float)proposedPosition 
       ofSubviewAt:(int)offset {

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

- (IBAction)toggleSplitView:(id)aSender {
    if ([I_plainTextEditors count]==1) {
        PlainTextEditor *plainTextEditor = [[PlainTextEditor alloc] initWithWindowController:self splitButton:NO];
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
        [[I_plainTextEditors objectAtIndex:1] setShowsBottomStatusBar:
            [[I_plainTextEditors objectAtIndex:0] showsBottomStatusBar]];
        [[I_plainTextEditors objectAtIndex:0] setShowsBottomStatusBar:NO];
        [[I_plainTextEditors objectAtIndex:1] setShowsGutter:
            [[I_plainTextEditors objectAtIndex:0] showsGutter]];
        
        [splitView release];
    } else if ([I_plainTextEditors count]==2) {
        [[self window] setContentView:[[I_plainTextEditors objectAtIndex:0] editorView]];
        [[I_plainTextEditors objectAtIndex:0] setShowsBottomStatusBar:
            [[I_plainTextEditors objectAtIndex:1] showsBottomStatusBar]];
        [I_plainTextEditors removeObjectAtIndex:1];
    }
    [[I_plainTextEditors objectAtIndex:0] setIsSplit:[I_plainTextEditors count]!=1];
    NSTextView *textView=[[I_plainTextEditors objectAtIndex:0] textView];
    NSRange selectedRange=[textView selectedRange];
    [textView scrollRangeToVisible:selectedRange];
    if ([I_plainTextEditors count]==2) {
        [[[I_plainTextEditors objectAtIndex:1] textView] scrollRangeToVisible:selectedRange];
    }
    [[self window] makeFirstResponder:textView];
}

#pragma mark -
#pragma mark ### ParticipantsView data source methods ###

- (int)numberOfItemsInParticipantsView:(ParticipantsView *)aListView {
    if ([[[(PlainTextDocument *)[self document] session] pendingUsers] count] >0) {
        return 3;
    } else {
        return 2;
    }
}

- (int)participantsView:(ParticipantsView *)aListView numberOfChildrenOfItemAtIndex:(int)anItemIndex {
    TCMMMSession *session=[(PlainTextDocument *)[self document] session];
    NSDictionary *participants=[session participants];
    if (anItemIndex==0) {
        return [[participants objectForKey:@"ReadWrite"] count];
    } else if (anItemIndex==1) {
        return [[participants objectForKey:@"ReadOnly"] count];
    } else if (anItemIndex==2) {
        return [[session pendingUsers] count];
    }
    return 0;
}

- (id)participantsView:(ParticipantsView *)aListView objectValueForTag:(int)aTag ofItemAtIndex:(int)anItemIndex {

    static NSImage *statusReadWrite=nil;
    static NSImage *statusReadOnly=nil;
    static NSImage *statusPending=nil;

    if (!statusReadWrite) statusReadWrite=[[NSImage imageNamed:@"StatusReadWrite"] retain];
    if (!statusReadOnly)  statusReadOnly=[[NSImage imageNamed:@"StatusReadOnly"] retain];
    if (!statusPending)   statusPending=[[NSImage imageNamed:@"StatusPending"] retain];
    if (anItemIndex==0) {
        if (aTag==ParticipantsItemStatusImageTag) {
            return statusReadWrite;
        } else if (aTag==ParticipantsItemNameTag) {
            return NSLocalizedString(@"read/write",@"Description in Participants view for Read Write access");
        } 
    } else if (anItemIndex==1) {
        if (aTag==ParticipantsItemStatusImageTag) {
            return statusReadOnly;
        } else if (aTag==ParticipantsItemNameTag) {
            return NSLocalizedString(@"read only",@"Description in Participants view for Read Only access");
        } 
    } else if (anItemIndex==2) {
        if (aTag==ParticipantsItemStatusImageTag) {
            return statusPending;
        } else if (aTag==ParticipantsItemNameTag) {
            return NSLocalizedString(@"pending users",@"Description in Participants view for pending users");
        } 
    }
    return nil;
}

- (id)participantsView:(ParticipantsView *)aListView objectValueForTag:(int)aTag atIndex:(int)anIndex ofItemAtIndex:(int)anItemIndex {
    PlainTextDocument *document=(PlainTextDocument *)[self document];
    TCMMMSession *session=[document session];
    NSDictionary *participants=[session participants];
    TCMMMUser *user=nil;
    if (anItemIndex==0) {
        user=[[participants objectForKey:@"ReadWrite"] objectAtIndex:anIndex];
    } else if (anItemIndex==1) {
        user=[[participants objectForKey:@"ReadOnly"] objectAtIndex:anIndex];
    } else if (anItemIndex==2) {
        user=[[session pendingUsers] objectAtIndex:anIndex];
    }
    if (anItemIndex>=0 && anItemIndex<3) {
        if (aTag==ParticipantsChildNameTag) {
            return [user name];
        } else if (aTag==ParticipantsChildStatusTag) {
            NSMutableDictionary *properties=[user propertiesForSessionID:[session sessionID]];
            SelectionOperation *selectionOperation=[properties objectForKey:@"SelectionOperation"];
            if ([[user userID] isEqualToString:[TCMMMUserManager myUserID]]) {
                return [(TextStorage *)[document textStorage] 
                        positionStringForRange:[[[self activePlainTextEditor] textView] selectedRange]];
            } else if (selectionOperation) {
                return [(TextStorage *)[document textStorage] positionStringForRange:[selectionOperation selectedRange]];
            } else {
                return @"";
            }
        } else if (aTag==ParticipantsChildImageTag) {
            return [[user properties] objectForKey:@"Image32"];
        } else if (aTag==ParticipantsChildImageNextToNameTag) {
            return [[user properties] objectForKey:@"ColorImage"];
        }
    }
    return nil;
}

- (void)participantsViewDidChangeSelection:(ParticipantsView *)aListView {
    [self validateButtons];
}

@end
