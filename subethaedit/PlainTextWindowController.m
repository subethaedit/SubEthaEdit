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
#import "TCMMMUserSEEAdditions.h"
#import "SelectionOperation.h"
#import "ImagePopUpButtonCell.h"
#import "LayoutManager.h"
#import "TextView.h"
#import "SplitView.h"
#import "RendezvousBrowserController.h"
#import "InternetBrowserController.h"
#import "GeneralPreferences.h"
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
NSString * const InternetToolbarItemIdentifier = 
               @"InternetToolbarItemIdentifier";
NSString * const ToggleChangeMarksToolbarItemIdentifier = 
               @"ToggleChangeMarksToolbarItemIdentifier";
NSString * const ToggleAnnouncementToolbarItemIdentifier = 
               @"ToggleAnnouncementToolbarItemIdentifier";

static int KickButtonStateMask=1;
static int ReadOnlyButtonStateMask=2;
static int ReadWriteButtonStateMask=4;
static int DenyStateMask=8;
static int KickStateMask=16;
static int ReadWriteButtonForcedOffMask=32;
static int ReadOnlyButtonForcedOffMask=64;
static int FollowUserStateMask=128;

enum {
    ParticipantContextMenuTagFollow = 1,
    ParticipantContextMenuTagAIM,
    ParticipantContextMenuTagEmail,
    ParticipantContextMenuTagAddToAddressBook,
    ParticipantContextMenuTagReadWrite,
    ParticipantContextMenuTagReadOnly,
    ParticipantContextMenuTagKickDeny
};


@interface PlainTextWindowController (PlainTextWindowControllerPrivateAdditions)

- (void)validateUpperDrawer;

@end

#pragma mark -

@implementation PlainTextWindowController

- (id)init {
    if ((self=[super initWithWindowNibName:@"PlainTextWindow"])) {
        I_plainTextEditors = [NSMutableArray new];
        I_contextMenu = [NSMenu new];
        NSMenuItem *item=nil;
        item=(NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"ParticipantContextMenuFollow",@"Follow user entry for Participant context menu") action:@selector(followUser:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:ParticipantContextMenuTagFollow];

        item=(NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"ParticipantContextMenuAIM %@ ...",@"AIM user entry for Participant context menu") action:@selector(openAIMTextChat:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:ParticipantContextMenuTagAIM];

        item=(NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"ParticipantContextMenuEmail %@ ...",@"Email user entry for Participant context menu") action:@selector(sendEmail:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:ParticipantContextMenuTagEmail];

        [I_contextMenu addItem:[NSMenuItem separatorItem]];

        item=(NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"ParticipantContextMenuReadWrite",@"ReadWrite user entry for Participant context menu") action:@selector(readWriteButtonAction:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:ParticipantContextMenuTagReadWrite];

        item=(NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"ParticipantContextMenuReadOnly",@"ReadWrite user entry for Participant context menu") action:@selector(readOnlyButtonAction:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:ParticipantContextMenuTagReadOnly];

        item=(NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"ParticipantContextMenuKickDeny",@"KickDeny user entry for Participant context menu") action:@selector(kickButtonAction:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:ParticipantContextMenuTagKickDeny];
        [I_contextMenu setDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[self window] toolbar] setDelegate:nil];
    [O_participantsView setDocument:nil];
    [O_participantsView release];
    [I_plainTextEditors makeObjectsPerformSelector:@selector(setWindowController:) withObject:nil];
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
    [self validateUpperDrawer];
    
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
    [O_participantsView setDocument:(PlainTextDocument *)[self document]];
    [O_actionPullDown setCell:[[ImagePopUpButtonCell new] autorelease]];
    [[O_actionPullDown cell] setPullsDown:YES];
    [[O_actionPullDown cell] setImage:[NSImage imageNamed:@"Action"]];
    [[O_actionPullDown cell] setAlternateImage:[NSImage imageNamed:@"ActionPressed"]];
    [[O_actionPullDown cell] setUsesItemFromMenu:NO];
    [O_actionPullDown addItemWithTitle:@"<do not modify>"];
    NSMenu *menu=[O_actionPullDown menu];
    [menu setDelegate:self];
    NSEnumerator *menuItems=[[I_contextMenu itemArray] objectEnumerator];
    id menuItem = nil;
    while ((menuItem = [menuItems nextObject])) {
        [menu addItem:[[menuItem copy] autorelease]];
    }
//    [O_actionPullDown addItemsWithTitles:[NSArray arrayWithObjects:@"<do not modify>", @"Ich", @"bin", @"das", @"Action", @"MenŸ", nil]];
    
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
                                             selector:@selector(MMSessionDidChange:)
                                                 name:TCMMMSessionDidChangeNotification 
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:TCMMMSessionDidReceiveContentNotification object:[(PlainTextDocument *)[self document] session]];
        [window setContentView:O_receivingContentView];
        [O_progressIndicator startAnimation:self];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMMMSessionDidReceiveContentNotification object:[(PlainTextDocument *)[self document] session]];
        [O_progressIndicator stopAnimation:self];
        [window setContentView:[[I_plainTextEditors objectAtIndex:0] editorView]];
    }
}

- (void)didLoseConnection {
    [O_progressIndicator stopAnimation:self];
    [O_receivingStatusTextField setStringValue:NSLocalizedString(@"Did lose Connection!",@"Text in Proxy window")];
}

- (void)updateProgress:(NSNotification *)aNotification {
    [O_progressIndicator setDoubleValue:[[aNotification object] percentOfSessionReceived]];
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
    [self validateUpperDrawer];
    [O_participantsDrawer open:aSender];
}

- (IBAction)closeParticipantsDrawer:(id)aSender {
    [O_participantsDrawer close:aSender];
}

- (IBAction)toggleParticipantsDrawer:(id)sender {
    [self validateUpperDrawer];
    [O_participantsDrawer toggle:sender];
}

- (int)buttonStateForSelectedRows:(NSIndexSet *)selectedRows {
    int buttonState=0;
    TCMMMSession *session=[(PlainTextDocument *)[self document] session];
    if ([session isServer] && [selectedRows count]>0) {
        buttonState = KickButtonStateMask;
        if ([selectedRows count]==1) {
            buttonState |= FollowUserStateMask;
        }
        NSMutableIndexSet *rows=[[selectedRows mutableCopy] autorelease];
        unsigned int row=NSNotFound;
        NSDictionary *participants=[session participants];
        for (row=[rows firstIndex];row!=NSNotFound;row=[rows firstIndex]) {
            ItemChildPair pair=[O_participantsView itemChildPairAtRow:row];
            if (pair.childIndex!=-1) {
                if (pair.itemIndex==0) {
                    if (pair.childIndex<[[participants objectForKey:@"ReadWrite"] count]) {
                        if ([[[[participants objectForKey:@"ReadWrite"] objectAtIndex:pair.childIndex] userID] isEqualToString:[TCMMMUserManager myUserID]]) {
                            return 0;
                        } else {
                            buttonState = buttonState | ReadOnlyButtonStateMask;
                        }
                    } else {
                        buttonState &= ~FollowUserStateMask;
                        buttonState = ( buttonState & (~ReadOnlyButtonStateMask) ) | ReadOnlyButtonForcedOffMask;
                    }
                    buttonState |= KickStateMask;
                } else if (pair.itemIndex==1) {
                    if (pair.childIndex<[[participants objectForKey:@"ReadOnly"] count]) {
                        buttonState = buttonState | ReadWriteButtonStateMask;
                    } else {
                        buttonState &= ~FollowUserStateMask;
                        buttonState = (buttonState & (~ReadWriteButtonStateMask)) | ReadWriteButtonForcedOffMask;
                    }
                    buttonState |= KickStateMask;
                } else if (pair.itemIndex==2) {
                    if (!(buttonState & ReadWriteButtonForcedOffMask)) {
                        buttonState |= ReadWriteButtonStateMask;
                    }
                    if (!(buttonState & ReadOnlyButtonForcedOffMask)) {
                        buttonState |= ReadOnlyButtonStateMask;
                    }
                    buttonState |= DenyStateMask;
                    buttonState &= ~FollowUserStateMask;
                }
            }
            [rows removeIndex:row];
        }
    }
    
    return buttonState;
}

- (void)validateUpperDrawer {
    TCMMMSession *session = [(PlainTextDocument *)[self document] session];
    if ([session isServer]) {
        [O_URLImageView setHidden:NO];
        [O_pendingUsersAccessPopUpButton setEnabled:YES];
    } else {
        [O_URLImageView setHidden:YES];
        [O_pendingUsersAccessPopUpButton setEnabled:NO];
        TCMMMSessionAccessState state = [session accessState];
        int index = [O_pendingUsersAccessPopUpButton indexOfItemWithTag:state];
        [O_pendingUsersAccessPopUpButton selectItemAtIndex:index];
    }
}

- (void)validateButtons {
    int state=[self buttonStateForSelectedRows:[O_participantsView selectedRowIndexes]];
    [O_kickButton setEnabled:(state & KickButtonStateMask)];
    [O_readOnlyButton setEnabled:(state & ReadOnlyButtonStateMask)];
    [O_readWriteButton setEnabled:(state & ReadWriteButtonStateMask)];
}

- (IBAction)kickButtonAction:(id)aSender {
    TCMMMSession *session=[(PlainTextDocument *)[self document] session];
    if ([session isServer]) {
        NSMutableIndexSet *pendingUsersIndexSet=[NSMutableIndexSet indexSet];
        NSMutableArray *userIDsToKick=[NSMutableArray array];
        NSMutableArray *userIDsToCancelInvitation=[NSMutableArray array];
        NSMutableIndexSet *rows=[[[O_participantsView selectedRowIndexes] mutableCopy] autorelease];
        unsigned int row=NSNotFound;
        NSDictionary *participants=[session participants];
        NSDictionary *invitedUsers=[session invitedUsers];
        for (row=[rows firstIndex];row!=NSNotFound;row=[rows firstIndex]) {
            ItemChildPair pair=[O_participantsView itemChildPairAtRow:row];
            if (pair.childIndex!=-1) {
                if (pair.itemIndex!=2) {
                    NSString *group=(pair.itemIndex==0)?@"ReadWrite":@"ReadOnly";
                    if ([[participants objectForKey:group] count]>pair.childIndex) {
                        NSString *userID=[[[participants objectForKey:group] objectAtIndex:pair.childIndex] userID];
                        if (![userID isEqualToString:[TCMMMUserManager myUserID]]) {
                            [userIDsToKick addObject:userID];
                        }
                    } else {
                        [userIDsToCancelInvitation addObject:[[[invitedUsers objectForKey:group] objectAtIndex:pair.childIndex-[[participants objectForKey:group] count]] userID]];
                    }
                } else {
                    [pendingUsersIndexSet addIndex:pair.childIndex];
                }
            }
            [rows removeIndex:row];
        }
        if ([pendingUsersIndexSet count]>0) {
            [session setGroup:@"PoofGroup" forPendingUsersWithIndexes:pendingUsersIndexSet];
        }
        if ([userIDsToKick count]>0) {
            [session setGroup:@"PoofGroup" forParticipantsWithUserIDs:userIDsToKick];
        }
        if ([userIDsToCancelInvitation count]>0) {
            NSEnumerator *userIDs=[userIDsToCancelInvitation objectEnumerator];
            NSString *userID=nil;
            while ((userID=[userIDs nextObject])) {
                [session cancelInvitationForUserWithID:userID];
            }
        }
    
        [O_participantsView reloadData];
        [self validateButtons];
    }
}

- (IBAction)readOnlyButtonAction:(id)aSender {
    TCMMMSession *session=[(PlainTextDocument *)[self document] session];
    if ([session isServer]) {
        NSMutableIndexSet *pendingUsersIndexSet=[NSMutableIndexSet indexSet];
        NSMutableArray *userIDsToChangeGroup=[NSMutableArray array];
        NSMutableIndexSet *rows=[[[O_participantsView selectedRowIndexes] mutableCopy] autorelease];
        unsigned int row=NSNotFound;
        NSDictionary *participants=[session participants];
        NSArray *readWriteArray=[participants objectForKey:@"ReadWrite"];
        for (row=[rows firstIndex];row!=NSNotFound;row=[rows firstIndex]) {
            ItemChildPair pair=[O_participantsView itemChildPairAtRow:row];
            if (pair.childIndex!=-1) {
                if (pair.itemIndex==0) {
                    if ([readWriteArray count]>pair.childIndex) {
                        NSString *userID=[[readWriteArray objectAtIndex:pair.childIndex] userID];
                        if (![userID isEqualToString:[TCMMMUserManager myUserID]]) {
                            [userIDsToChangeGroup addObject:userID];
                        }
                    } 
                } else if (pair.itemIndex==2) {
                    [pendingUsersIndexSet addIndex:pair.childIndex];
                }
            }
            [rows removeIndex:row];
        }
        if ([pendingUsersIndexSet count]>0) {
            [session setGroup:@"ReadOnly" forPendingUsersWithIndexes:pendingUsersIndexSet];
        }
        if ([userIDsToChangeGroup count]>0) {
            [session setGroup:@"ReadOnly" forParticipantsWithUserIDs:userIDsToChangeGroup];
        }
    
        [O_participantsView reloadData];
        [self validateButtons];
    }
}

- (IBAction)readWriteButtonAction:(id)aSender {
    TCMMMSession *session=[(PlainTextDocument *)[self document] session];
    if ([session isServer]) {
        NSMutableIndexSet *pendingUsersIndexSet=[NSMutableIndexSet indexSet];
        NSMutableArray *userIDsToChangeGroup=[NSMutableArray array];
        NSMutableIndexSet *rows=[[[O_participantsView selectedRowIndexes] mutableCopy] autorelease];
        unsigned int row=NSNotFound;
        NSDictionary *participants=[session participants];
        NSArray *readOnlyArray=[participants objectForKey:@"ReadOnly"];
        for (row=[rows firstIndex];row!=NSNotFound;row=[rows firstIndex]) {
            ItemChildPair pair=[O_participantsView itemChildPairAtRow:row];
            if (pair.childIndex!=-1) {
                if (pair.itemIndex==1) {
                    if ([readOnlyArray count]>pair.childIndex) {
                        [userIDsToChangeGroup addObject:[[readOnlyArray objectAtIndex:pair.childIndex] userID]];
                    } 
                } else if (pair.itemIndex==2) {
                    [pendingUsersIndexSet addIndex:pair.childIndex];
                }
            }
            [rows removeIndex:row];
        }
        if ([pendingUsersIndexSet count]>0) {
            [session setGroup:@"ReadWrite" forPendingUsersWithIndexes:pendingUsersIndexSet];
        }
        if ([userIDsToChangeGroup count]>0) {
            [session setGroup:@"ReadWrite" forParticipantsWithUserIDs:userIDsToChangeGroup];
        }
    
        [O_participantsView reloadData];
        [self validateButtons];
    }
}

- (IBAction)followUser:(id)aSender {
    if ([O_participantsView numberOfSelectedRows] == 1) {
        int selectedRow=[O_participantsView selectedRow];
        ItemChildPair pair=[O_participantsView itemChildPairAtRow:selectedRow];
        if (pair.childIndex!=-1) {
            if (pair.itemIndex!=2) {
                NSArray *participantArray=[[[(PlainTextDocument *)[self document] session] participants] objectForKey:(pair.itemIndex==0?@"ReadWrite":@"ReadOnly")];
                if ([participantArray count]>pair.childIndex) {
                    NSString *userID=[[participantArray objectAtIndex:pair.childIndex] userID];
                    if (![userID isEqualToString:[TCMMMUserManager myUserID]]) {
                        PlainTextEditor *plainTextEditor=[self activePlainTextEditor];
                        [plainTextEditor setFollowUserID:userID];
                    }
                }
            }
        }
    }
}

- (IBAction)participantDoubleAction:(id)aSender {
    if ([O_participantsView numberOfSelectedRows] == 1) {
        int selectedRow=[O_participantsView selectedRow];
        ItemChildPair pair=[O_participantsView itemChildPairAtRow:selectedRow];
        if (pair.childIndex!=-1) {
            TCMMMSession *session=[(PlainTextDocument *)[self document] session];
            if (pair.itemIndex==2) {
                [session setGroup:@"ReadWrite" forPendingUsersWithIndexes:[NSIndexSet indexSetWithIndex:pair.childIndex]];
            } else {
                [self followUser:aSender];
            }
        }
    }
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
    } else if ([itemIdent isEqual:InternetToolbarItemIdentifier]) { 
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Internet", nil)];
        [toolbarItem setLabel:NSLocalizedString(@"Internet", nil)];
        [toolbarItem setToolTip:NSLocalizedString(@"Open Internet Browser", nil)];
        [toolbarItem setImage:[NSImage imageNamed: @"Internet"]];
        [toolbarItem setTarget:[InternetBrowserController sharedInstance]];
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
                ParticipantsToolbarItemIdentifier,
                ToggleAnnouncementToolbarItemIdentifier,
                NSToolbarSeparatorItemIdentifier,
                PreviousSymbolToolbarItemIdentifier,
                NextSymbolToolbarItemIdentifier,
                PreviousChangeToolbarItemIdentifier,
                NextChangeToolbarItemIdentifier,
                ToggleChangeMarksToolbarItemIdentifier,
                NSToolbarFlexibleSpaceItemIdentifier,
                RendezvousToolbarItemIdentifier,
                InternetToolbarItemIdentifier,
                nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:
                InternetToolbarItemIdentifier,
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMMMSessionDidChangeNotification object:[(PlainTextDocument *)[self document] session]];
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
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(MMSessionDidChange:)
                                                 name:TCMMMSessionDidChangeNotification 
                                               object:[(PlainTextDocument *)[self document] session]];
                                                       
    BOOL isEditable=[(PlainTextDocument *)[self document] isEditable];
    NSEnumerator *plainTextEditors=[[self plainTextEditors] objectEnumerator];
    PlainTextEditor *editor=nil;
    while ((editor=[plainTextEditors nextObject])) {
        [[editor textView] setEditable:isEditable];
    }
}

- (void)MMSessionDidChange:(NSNotification *)aNotifcation {
    [self validateUpperDrawer];
}

- (void)participantsDidChange:(NSNotification *)aNotifcation {
    [O_participantsView reloadData];
}

- (void)pendingUsersDidChange:(NSNotification *)aNotifcation {
    [O_participantsView reloadData];
    [self synchronizeWindowTitleWithDocumentName];
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

- (int)listView:(TCMListView *)aListView numberOfEntriesOfItemAtIndex:(int)anItemIndex {
    if (anItemIndex==-1) {
        if ([[[(PlainTextDocument *)[self document] session] pendingUsers] count] >0) {
            return 3;
        } else {
            return 2;
        }
    } else {
        TCMMMSession *session=[(PlainTextDocument *)[self document] session];
        NSDictionary *participants=[session participants];
        NSDictionary *invitedUsers=[session invitedUsers];
        if (anItemIndex==0) {
            return [[participants objectForKey:@"ReadWrite"] count] + 
                   [[invitedUsers objectForKey:@"ReadWrite"] count];
        } else if (anItemIndex==1) {
            return [[participants objectForKey:@"ReadOnly"] count] + 
                   [[invitedUsers objectForKey:@"ReadOnly"] count];
        } else if (anItemIndex==2) {
            return [[session pendingUsers] count];
        }
        return 0;
    }
}

- (id)listView:(TCMListView *)aListView objectValueForTag:(int)aTag atChildIndex:(int)aChildIndex ofItemAtIndex:(int)anItemIndex {
    if (aChildIndex == -1) {
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
    } else {
        PlainTextDocument *document=(PlainTextDocument *)[self document];
        TCMMMSession *session=[document session];
        NSDictionary *participants=[session participants];
        NSDictionary *invitedUsers=[session invitedUsers];
        NSString *status=nil;
        TCMMMUser *user=nil;
        int participantCount=0;
        if (anItemIndex==0 || anItemIndex==1) {
            NSString *group=(anItemIndex==0)?@"ReadWrite":@"ReadOnly";
            participantCount=[[participants objectForKey:group] count];
            if (aChildIndex < participantCount) {
                user=[[participants objectForKey:group] objectAtIndex:aChildIndex];
            } else {
                user=[[invitedUsers objectForKey:group] objectAtIndex:aChildIndex-participantCount];
                status=[session stateOfInvitedUserById:[user userID]];
            }
        } else if (anItemIndex==2) {
            user=[[session pendingUsers] objectAtIndex:aChildIndex];
        }
        if (anItemIndex>=0 && anItemIndex<3) {
            if (aTag==ParticipantsChildNameTag) {
                return [user name];
            } else if (aTag==ParticipantsChildStatusTag) {
                NSMutableDictionary *properties=[user propertiesForSessionID:[session sessionID]];
                SelectionOperation *selectionOperation=[properties objectForKey:@"SelectionOperation"];
                NSColor *userColor=[[document documentBackgroundColor] blendedColorWithFraction:
                                        [[NSUserDefaults standardUserDefaults] floatForKey:ChangesSaturationPreferenceKey]/100.
                                     ofColor:[user changeColor]];
                NSDictionary *attributes=[NSDictionary dictionaryWithObjectsAndKeys:
                   [NSFont systemFontOfSize:[NSFont smallSystemFontSize]],NSFontAttributeName, 
                   [document documentForegroundColor],NSForegroundColorAttributeName,
                   userColor,NSBackgroundColorAttributeName, nil];
                NSString *result=@" ";
                if (status) {
                    result=status;
                } else if ([[user userID] isEqualToString:[TCMMMUserManager myUserID]]) {
                    result =[(TextStorage *)[document textStorage] 
                            positionStringForRange:[[[self activePlainTextEditor] textView] selectedRange]];
                } else if (selectionOperation) {
                    result =[(TextStorage *)[document textStorage] positionStringForRange:[selectionOperation selectedRange]];
                }
                return [[[NSAttributedString alloc] initWithString:result attributes:attributes] autorelease];
            } else if (aTag==ParticipantsChildImageTag) {
                return [[user properties] objectForKey:(status || anItemIndex==2)?@"Image32Dimmed":@"Image32"];
            } else if (aTag==ParticipantsChildImageNextToNameTag) {
                return [[user properties] objectForKey:@"ColorImage"];
            }
        }
        return nil;
    }
}

-(void)listViewDidChangeSelection:(TCMListView *)aListView {
    [self validateButtons];
}

-(NSMenu *)contextMenuForListView:(TCMListView *)aListView clickedAtRow:(int)aRow {
    ItemChildPair pair=[O_participantsView itemChildPairAtRow:aRow];
    if (pair.childIndex!=-1) {
        return I_contextMenu;
    }
    return nil;
}

- (NSString *)listView:(TCMListView *)aListView toolTipStringAtChildIndex:(int)aChildIndex ofItemAtIndex:(int)anItemIndex {
    if (aChildIndex!=-1) {
        PlainTextDocument *document=(PlainTextDocument *)[self document];
        TCMMMSession *session=[document session];
        NSDictionary *participants=[session participants];
        TCMMMUser *user=nil;
        if (anItemIndex==0) {
            user=[[participants objectForKey:@"ReadWrite"] objectAtIndex:aChildIndex];
        } else if (anItemIndex==1) {
            user=[[participants objectForKey:@"ReadOnly"] objectAtIndex:aChildIndex];
        } else if (anItemIndex==2) {
            user=[[session pendingUsers] objectAtIndex:aChildIndex];
        }
        if (user) {
            return [NSString stringWithFormat:@"AIM:%@\nEmail:%@",[[user properties] objectForKey:@"AIM"],[[user properties] objectForKey:@"Email"]];
        }
    }
    return nil;
}

-(void)menuNeedsUpdate:(NSMenu *)menu {
    int state = [self buttonStateForSelectedRows:[O_participantsView selectedRowIndexes]];
    if ([O_participantsView numberOfSelectedRows] == 1) {
        TCMMMUser *user=nil;
        int selectedRow=[O_participantsView selectedRow];
        ItemChildPair pair=[O_participantsView itemChildPairAtRow:selectedRow];
        if (pair.childIndex!=-1) {
            TCMMMSession *session=[(PlainTextDocument *)[self document] session];
            if (pair.itemIndex==2) {
                user=[[session pendingUsers] objectAtIndex:pair.childIndex];
            } else {
                NSArray *participantArray=[[session participants] objectForKey:(pair.itemIndex==0?@"ReadWrite":@"ReadOnly")];
                if ([participantArray count]>pair.childIndex) {
                    user=[participantArray objectAtIndex:pair.childIndex];
                } else {
                    user=[[[session invitedUsers] objectForKey:(pair.itemIndex==0?@"ReadWrite":@"ReadOnly")] objectAtIndex:pair.childIndex-[participantArray count]];
                }
            }
        }
        id item;
        item = [menu itemWithTag:ParticipantContextMenuTagFollow];
        [item setEnabled:(state & FollowUserStateMask)];
        item = [menu itemWithTag:ParticipantContextMenuTagAIM];
        [item setTitle:[NSString stringWithFormat:NSLocalizedString(@"ParticipantContextMenuAIM %@ ...",@"AIM user entry for Participant context menu"),[[user properties] objectForKey:@"AIM"]]];
        item = [menu itemWithTag:ParticipantContextMenuTagEmail];
        [item setTitle:[NSString stringWithFormat:NSLocalizedString(@"ParticipantContextMenuEmail %@ ...",@"AIM user entry for Participant context menu"),[[user properties] objectForKey:@"Email"]]];
    } else {
        id item = [menu itemWithTag:ParticipantContextMenuTagFollow];
        [item setEnabled:NO];
    }
    id item;
    item = [menu itemWithTag:ParticipantContextMenuTagReadWrite];
    [item setEnabled:(state & ReadWriteButtonStateMask)];
    item = [menu itemWithTag:ParticipantContextMenuTagReadOnly];
    [item setEnabled:(state & ReadOnlyButtonStateMask)];
    item = [menu itemWithTag:ParticipantContextMenuTagKickDeny];
    [item setEnabled:(state & KickButtonStateMask)];
    NSString *string=NSLocalizedString(@"ParticipantContextMenuKick",@"KickDeny user entry for Participant context menu");
    if ((state & KickStateMask) && (state & DenyStateMask)) {
        string=NSLocalizedString(@"ParticipantContextMenuKickDeny",@"KickDeny user entry for Participant context menu");
    } else if (state & DenyStateMask) {
        string=NSLocalizedString(@"ParticipantContextMenuDeny",@"KickDeny user entry for Participant context menu");
    }
    [item setTitle:string];
}


@end
