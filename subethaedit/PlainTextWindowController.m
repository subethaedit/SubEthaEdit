//
//  PlainTextWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Mar 05 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import "PlainTextWindowController.h"
#import "ParticipantsView.h"
#import "PlainTextDocument.h"
#import "DocumentMode.h"
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
#import "AppController.h"
#import "Toolbar.h"
#import "SEEDocumentDialog.h"
#import "EncodingDoctorDialog.h"
#import "DocumentController.h"
#import "PlainTextWindowControllerTabContext.h"
#import <PSMTabBarControl/PSMTabBarControl.h>
#import <PSMTabBarControl/PSMTabStyle.h>


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
NSString * const ToggleShowInvisibleCharactersToolbarItemIdentifier = 
               @"ToggleShowInvisibleCharactersToolbarItemIdentifier";


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
    if ((self = [super initWithWindowNibName:@"PlainTextWindow"])) {
        I_tabContexts = [[NSMutableArray alloc] init];
        I_isMultiDocument = YES;
        I_contextMenu = [NSMenu new];
        NSMenuItem *item=nil;
        item=(NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"ParticipantContextMenuFollow",@"Follow user entry for Participant context menu") action:@selector(followUser:) keyEquivalent:@""];
        [item setTarget:self];
        [item setTag:ParticipantContextMenuTagFollow];

        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuAIM", @"AIM user entry for Browser context menu") action:@selector(initiateAIMChat:) keyEquivalent:@""];
        [item setTarget:[TCMMMUserManager sharedInstance]];
        [item setTag:ParticipantContextMenuTagAIM];
                
        item = (NSMenuItem *)[I_contextMenu addItemWithTitle:NSLocalizedString(@"BrowserContextMenuEmail", @"Email user entry for Browser context menu") action:@selector(sendEmail:) keyEquivalent:@""];
        [item setTarget:[TCMMMUserManager sharedInstance]];
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
    [O_participantsView setWindowController:nil];
    [O_participantsView release];
    [I_tabContexts release];
    I_plainTextEditors = nil;
    I_editorSplitView = nil;
    I_dialogSplitView = nil;
    I_documentDialog = nil;
    
    [I_tabBar setDelegate:nil];
    [I_tabBar setTabView:nil];
    [I_tabView setDelegate:nil];
    [I_tabBar release];
    [I_tabView release];
        
    [super dealloc];
}

- (void)windowWillLoad {
    if ([self document]) {
        [[self document] windowControllerWillLoadNib:self];
    }
}

- (void)setInitialRadarStatusForPlainTextEditor:(PlainTextEditor *)editor {
    PlainTextDocument *document=(PlainTextDocument *)[self document];
    NSEnumerator *users=[[[[document session] participants] objectForKey:@"ReadWrite"] objectEnumerator];
    TCMMMUser *user=nil;
    while ((user=[users nextObject])) {
        if (user != [TCMMMUserManager me]) {
            [editor setRadarMarkForUser:user];
        }
    }
}

- (void)adjustToolbarToDocumentMode {
    NSToolbar *toolbar = [[[Toolbar alloc] initWithIdentifier:
        [[(PlainTextDocument *)[self document] documentMode] documentModeIdentifier]] autorelease];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDelegate:self];
    [[self window] setToolbar:toolbar];
}

- (void)windowDidLoad {
    // [[[[[self window] standardWindowButton:NSWindowDocumentIconButton] superview] titleCell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
    
    //[self adjustToolbarToDocumentMode];

    //[self validateUpperDrawer];
    
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
    [O_participantsView setWindowController:self];
    [O_actionPullDown setCell:[[ImagePopUpButtonCell new] autorelease]];
    [[O_actionPullDown cell] setPullsDown:YES];
    [[O_actionPullDown cell] setImage:[NSImage imageNamed:@"Action"]];
    [[O_actionPullDown cell] setAlternateImage:[NSImage imageNamed:@"ActionPressed"]];
    [[O_actionPullDown cell] setUsesItemFromMenu:NO];
    [O_actionPullDown addItemWithTitle:@"<do not modify>"];
    NSMenu *menu=[O_actionPullDown menu];
    NSEnumerator *menuItems=[[I_contextMenu itemArray] objectEnumerator];
    id menuItem = nil;
    while ((menuItem = [menuItems nextObject])) {
        [menu addItem:[[menuItem copy] autorelease]];
    }
    [menu setDelegate:self];
    

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(validateUpperDrawer)
                                                 name:TCMMMPresenceManagerAnnouncedSessionsDidChangeNotification 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(adjustToolbarToDocumentMode)
                                                 name:GlobalScriptsDidReloadNotification 
                                               object:nil];
    
    /*
    SInt32 MacVersion;
    if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr){
        if (MacVersion >= 0x1040){
            // this call is Tiger only
            [[[self window] toolbar] setShowsBaselineSeparator:NO];
        }
    }
    */

    [[[self window] contentView] setAutoresizesSubviews:YES];
    NSRect contentFrame = [[[self window] contentView] frame];

    I_tabBar = [[PSMTabBarControl alloc] initWithFrame:NSMakeRect(0.0, NSHeight(contentFrame) - 22.0, NSWidth(contentFrame), 22.0)];
    [I_tabBar setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
    [I_tabBar setStyleNamed:@"Unified"];
    [[[self window] contentView] addSubview:I_tabBar];
    I_tabView = [[NSTabView alloc] initWithFrame:NSMakeRect(0.0, 0.0, NSWidth(contentFrame), NSHeight(contentFrame) - 22.0)];
    [I_tabView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    [I_tabView setTabViewType:NSNoTabsNoBorder];
    [[[self window] contentView] addSubview:I_tabView];
    [I_tabBar setTabView:I_tabView];
    [I_tabView setDelegate:I_tabBar];

    [I_tabBar setDelegate:self];
    
    //[self validateButtons];
}

- (void)takeSettingsFromDocument {
    NSLog(@"%s", __FUNCTION__);
    [self setShowsBottomStatusBar:[(PlainTextDocument *)[self document] showsBottomStatusBar]];
    [[self plainTextEditors] makeObjectsPerformSelector:@selector(takeSettingsFromDocument)];
}

- (void)setIsReceivingContent:(BOOL)aFlag {
    NSLog(@"%s", __FUNCTION__);
    //NSWindow *window=[self window];
    I_flags.isReceivingContent=aFlag;
    if (aFlag) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:TCMMMSessionDidReceiveContentNotification object:[(PlainTextDocument *)[self document] session]];
        //[window setContentView:O_receivingContentView];
                
        NSString *identifier = [[(PlainTextDocument *)[self document] session] sessionID];
        int index = [I_tabView indexOfTabViewItemWithIdentifier:identifier];
        if (index != NSNotFound) {        
            [I_tabView selectTabViewItemAtIndex:index];
            [[I_tabView tabViewItemAtIndex:index] setView:O_receivingContentView];
        }
        
        [O_progressIndicator startAnimation:self];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMMMSessionDidReceiveContentNotification object:[(PlainTextDocument *)[self document] session]];
        [O_progressIndicator stopAnimation:self];
        PlainTextEditor *editor=[I_plainTextEditors objectAtIndex:0];
        //[window setContentView:[editor editorView]];

        NSString *identifier = [[(PlainTextDocument *)[self document] session] sessionID];
        int index = [I_tabView indexOfTabViewItemWithIdentifier:identifier];
        if (index != NSNotFound)     
            [[I_tabView tabViewItemAtIndex:index] setView:[editor editorView]];
        
        [[editor textView] setSelectedRange:NSMakeRange(0,0)];
        [[self window] makeFirstResponder:[editor textView]];
        if ([self window]==[[[NSApp orderedWindows] objectEnumerator] nextObject]) {
            [[self window] makeKeyWindow];
        }
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
    NSLog(@"%s", __FUNCTION__);
    NSSize contentSize=[[I_plainTextEditors objectAtIndex:0] desiredSizeForColumns:aColumns rows:aRows];
    NSWindow *window=[self window];
    NSSize minSize=[window contentMinSize];
    NSRect contentRect=[window contentRectForFrameRect:[window frame]];
    contentSize=NSMakeSize(MAX(contentSize.width,minSize.width),
                             MAX(contentSize.height,minSize.height));
    contentRect.origin.y+=contentRect.size.height-contentSize.height;
    contentRect.size=contentSize;
    NSRect frameRect=[window frameRectForContentRect:contentRect];
    NSScreen *screen=[[self window] screen];
    if (screen) {
        NSRect visibleFrame=[screen visibleFrame];
        if (NSHeight(frameRect)>NSHeight(visibleFrame)) {
            float heightDiff=frameRect.size.height-visibleFrame.size.height;
            frameRect.origin.y+=heightDiff;
            frameRect.size.height-=heightDiff;
        }
        if (NSMinY(frameRect)<NSMinY(visibleFrame)) {
            float positionDiff=NSMinY(visibleFrame)-NSMinY(frameRect);
            frameRect.origin.y+=positionDiff;
        }
    }
    [[self window] setFrame:frameRect display:YES];
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
        return [(PlainTextDocument *)[self document] isAnnounced];
    } else if (selector == @selector(toggleSplitView:)) {
        [menuItem setTitle:[I_plainTextEditors count]==1?
                           NSLocalizedString(@"Split View",@"Split View Menu Entry"):
                           NSLocalizedString(@"Collapse Split View",@"Collapse Split View Menu Entry")];
        return !I_flags.isReceivingContent;
    } else if (selector == @selector(changePendingUsersAccess:)) {
        TCMMMSession *session=[(PlainTextDocument *)[self document] session];
        [menuItem setState:([menuItem tag]==[session accessState])?NSOnState:NSOffState];
        return [session isServer];
    } else if (selector == @selector(readWriteButtonAction:) ||
               selector == @selector(followUser:) ||
               selector == @selector(kickButtonAction:) ||
               selector == @selector(readOnlyButtonAction:)){
        return [menuItem isEnabled];
    }
    return YES;
}

- (NSArray *)plainTextEditors {
    return I_plainTextEditors;
}

- (PlainTextEditor *)activePlainTextEditor {
    NSLog(@"%s", __FUNCTION__);
    if ([I_plainTextEditors count]!=1) {
        id responder=[[self window] firstResponder];
        if ([responder isKindOfClass:[NSTextView class]]) {
            if ([[I_plainTextEditors objectAtIndex:1] textView] == responder) {
                return [I_plainTextEditors objectAtIndex:1];
            }
        }
    } 
    if ([I_plainTextEditors count]>0) {
        return [I_plainTextEditors objectAtIndex:0];
    }
    return nil;
}

#pragma mark -

- (void)gotoLine:(unsigned)aLine {
    NSRange range=[(TextStorage *)[[self document] textStorage] findLine:aLine];
    [self selectRange:range];
}

- (void)selectRange:(NSRange)aRange {
    NSTextView *aTextView=[[self activePlainTextEditor] textView];
    NSRange range=RangeConfinedToRange(aRange,NSMakeRange(0,[[aTextView textStorage] length]));
    [aTextView setSelectedRange:range];
    [aTextView scrollRangeToVisible:range];
    if (!NSEqualRanges(range,aRange)) NSBeep();
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
    } else  if (![session isServer] && [selectedRows count]==1) {
        buttonState |= FollowUserStateMask;
    }
    
    return buttonState;
}

- (void)validateUpperDrawer {
    TCMMMSession *session = [(PlainTextDocument *)[self document] session];
    BOOL isServer=[session isServer];
    [O_URLImageView setHidden:![(PlainTextDocument *)[self document] isAnnounced]];
    [O_pendingUsersAccessPopUpButton setEnabled:isServer];
    TCMMMSessionAccessState state = [session accessState];
    int index = [O_pendingUsersAccessPopUpButton indexOfItemWithTag:state];
    [O_pendingUsersAccessPopUpButton selectItemAtIndex:index];
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
                        if ([aSender isKindOfClass:[TextView class]]) {
                            NSEnumerator    *editors=[[self plainTextEditors] objectEnumerator];
                            PlainTextEditor *editor=nil;
                            while ((editor=[editors nextObject])) {
                                if ([editor textView]==aSender) {
                                    plainTextEditor=editor;
                                    break;
                                }
                            }
                        } 
                        [plainTextEditor setFollowUserID:userID];
                        return;
                    }
                }
            }
        }
    }
    NSBeep();
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
    int newState=-1;
    if ([aSender isKindOfClass:[NSPopUpButton class]]) {
        newState=[[aSender selectedItem] tag];
    } else {
        newState=[aSender tag];;
    }
    if (newState!=-1) {
        TCMMMSession *session=[(PlainTextDocument *)[self document] session];
        [session setAccessState:newState];
    }
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
        [toolbarItem setLabel:NSLocalizedString(@"Participants", @"Participants toolbar label")];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Participants", @"Participants toolbar label")];
        [toolbarItem setToolTip:NSLocalizedString(@"ParticipantsToolTip", @"Participants tool tip")];
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
    } else if ([itemIdent isEqual:ToggleShowInvisibleCharactersToolbarItemIdentifier]) {
        [toolbarItem setToolTip:NSLocalizedString(@"Toggle Invisible Characters", nil)];
        [toolbarItem setLabel:NSLocalizedString(@"Show Invisibles", nil)];
        [toolbarItem setPaletteLabel:NSLocalizedString(@"Toggle Invisibles", nil)];
        [toolbarItem setImage:([NSImage imageNamed: @"InvisibleCharactersShow"])];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(toggleShowInvisibleCharacters:)];    
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
        toolbarItem=[[(PlainTextDocument *)[self document] documentMode] 
                                        toolbar:toolbar 
                          itemForItemIdentifier:itemIdent 
                      willBeInsertedIntoToolbar:willBeInserted];
    }
    if (!toolbarItem) {
        toolbarItem=[[AppController sharedInstance] 
                                        toolbar:toolbar 
                          itemForItemIdentifier:itemIdent 
                      willBeInsertedIntoToolbar:willBeInserted];
    }
    return toolbarItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    NSMutableArray *result=
        [NSMutableArray arrayWithObjects:
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
    [result addObjectsFromArray:
        [[AppController sharedInstance] 
            toolbarDefaultItemIdentifiers:toolbar]];
    [result addObjectsFromArray:
        [[(PlainTextDocument *)[self document] documentMode] 
            toolbarDefaultItemIdentifiers:toolbar]];
    
    return result;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [[[NSArray arrayWithObjects:
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
                ToggleShowInvisibleCharactersToolbarItemIdentifier,
                NSToolbarPrintItemIdentifier,
                NSToolbarCustomizeToolbarItemIdentifier,
                NSToolbarSeparatorItemIdentifier,
                NSToolbarSpaceItemIdentifier,
                NSToolbarFlexibleSpaceItemIdentifier,
                nil] 
                arrayByAddingObjectsFromArray:
                    [[(PlainTextDocument *)[self document] documentMode] 
                        toolbarAllowedItemIdentifiers:toolbar]]
                arrayByAddingObjectsFromArray:[[AppController sharedInstance] 
                                        toolbarAllowedItemIdentifiers:toolbar]];
}

- (void)checkToolbarForUnallowedItems {
    NSToolbar *toolbar=[[self window] toolbar];
    NSArray *itemArray=[toolbar items];
    NSArray *allowedIdentifiers=[self toolbarAllowedItemIdentifiers:toolbar];
    int i = [itemArray count];
    for (--i;i>=0;i--) {
        if (![allowedIdentifiers containsObject:[[itemArray objectAtIndex:i] itemIdentifier]]) {
            [toolbar removeItemAtIndex:i];
        }
    }
}



- (void)toolbarWillAddItem:(NSNotification *)aNotification {
    // to show all items correctly validated
    NSToolbarItem *item=[[aNotification userInfo] objectForKey:@"item"];
    id target=[item target];
    if ([target respondsToSelector:@selector(validateToolbarItem:)]) {
        [item setEnabled:[target validateToolbarItem:item]];
    }
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
    NSString *itemIdentifier = [toolbarItem itemIdentifier];
    if ([itemIdentifier isEqualToString:ParticipantsToolbarItemIdentifier]) {
        return YES;
    } else if ([itemIdentifier isEqualToString:ToggleChangeMarksToolbarItemIdentifier]) {
        PlainTextEditor *editor=[self activePlainTextEditor];
        BOOL showsChangeMarks=[(LayoutManager *)[[editor textView] layoutManager] showsChangeMarks];
        if (!editor) showsChangeMarks=[[self document] showsChangeMarks];
        [toolbarItem setImage:showsChangeMarks
                              ?[NSImage imageNamed: @"HideChangeMarks"]
                              :[NSImage imageNamed: @"ShowChangeMarks"]  ];
        [toolbarItem setLabel:showsChangeMarks
                              ?NSLocalizedString(@"Hide Changes", nil)
                              :NSLocalizedString(@"Show Changes", nil)];
        return YES;
    } else if ([itemIdentifier isEqualToString:ToggleShowInvisibleCharactersToolbarItemIdentifier]) {
        BOOL showsInvisibleCharacters = [[self activePlainTextEditor] showsInvisibleCharacters];
        [toolbarItem setImage:showsInvisibleCharacters
                              ?[NSImage imageNamed: @"InvisibleCharactersHide"]
                              :[NSImage imageNamed: @"InvisibleCharactersShow"]];
        [toolbarItem setLabel:showsInvisibleCharacters
                              ?NSLocalizedString(@"Hide Invisibles", nil)
                              :NSLocalizedString(@"Show Invisibles", nil)];
        return YES;
    }
    
    return YES;
}

- (IBAction)toggleShowInvisibleCharacters:(id)aSender {
    [[self activePlainTextEditor] setShowsInvisibleCharacters:![[self activePlainTextEditor] showsInvisibleCharacters]];
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
    [self synchronizeWindowTitleWithDocumentName];
}


- (void)participantsDataDidChange:(NSNotification *)aNotifcation {
    [O_participantsView setNeedsDisplay:YES];
}

- (void)participantsDidChange:(NSNotification *)aNotifcation {
    [O_participantsView reloadData];
    [self refreshDisplay];
}

- (void)pendingUsersDidChange:(NSNotification *)aNotifcation {
    [O_participantsView reloadData];
    [self synchronizeWindowTitleWithDocumentName];
}

- (void)displayNameDidChange:(NSNotification *)aNotification {
    [self synchronizeWindowTitleWithDocumentName];
}

- (void)refreshDisplay {
    NSEnumerator *plainTextEditors=[[self plainTextEditors] objectEnumerator];
    PlainTextEditor *editor=nil;
    while ((editor=[plainTextEditors nextObject])) {
        [[editor textView] setNeedsDisplay:YES];
    }
    [O_participantsView setNeedsDisplay:YES];
}

#pragma mark -

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    NSLog(@"%s", __FUNCTION__);
    PlainTextDocument *document = (PlainTextDocument *)[self document];
    TCMMMSession *session = [document session];
    
    if ([[document ODBParameters] objectForKey:@"keyFileCustomPath"]) {
        displayName = [[document ODBParameters] objectForKey:@"keyFileCustomPath"];
    } else {
        NSArray *pathComponents = [[document fileName] pathComponents];
        int count = [pathComponents count];
        if (count != 0) {
            NSMutableString *result = [NSMutableString string];
            int i = count;
            int pathComponentsToShow = [[NSUserDefaults standardUserDefaults] integerForKey:AdditionalShownPathComponentsPreferenceKey] + 1;
            for (i = count-1; i >= 1 && i > count-pathComponentsToShow-1; i--) {
                if (i != count-1) {
                    [result insertString:@"/" atIndex:0];
                }
                [result insertString:[pathComponents objectAtIndex:i] atIndex:0];
            }
            if (pathComponentsToShow>1 && i<1 && [[pathComponents objectAtIndex:0] isEqualToString:@"/"]) {
                [result insertString:@"/" atIndex:0];
            }
            displayName = result;
        } else {
            if (session && ![session isServer]) {
                displayName = [session filename];
            }
        }
    }

    if (session && ![session isServer]) {
        displayName = [displayName stringByAppendingFormat:@" - %@", [[[TCMMMUserManager sharedInstance] userForUserID:[session hostID]] name]];
        if ([document fileName]) {
            if (![[[session filename] lastPathComponent] isEqualToString:[[document fileName] lastPathComponent]]) {
                displayName = [displayName stringByAppendingFormat:@" (%@)", [session filename]];
            }
            displayName = [displayName stringByAppendingString:@" *"];
        }
    }
    
    int requests;
    if ((requests=[[[(PlainTextDocument *)[self document] session] pendingUsers] count])>0) {
        displayName=[displayName stringByAppendingFormat:@" (%@)", [NSString stringWithFormat:NSLocalizedString(@"%d pending", @"Pending Users Display in Menu Title Bar"), requests]];
    }

    NSString *jobDescription = [(PlainTextDocument *)[self document] jobDescription];
    if (jobDescription && [jobDescription length] > 0) {
        displayName = [displayName stringByAppendingFormat:@" [%@]", jobDescription];
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

#define SPLITMINHEIGHTTEXT   46.
#define SPLITMINHEIGHTDIALOG 95.

-(void)splitView:(NSSplitView *)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize {
    float splitminheight = (aSplitView==I_dialogSplitView) ? SPLITMINHEIGHTDIALOG : SPLITMINHEIGHTTEXT;
    if (aSplitView != I_dialogSplitView) {
        NSRect frame=[aSplitView bounds];
        NSArray *subviews=[aSplitView subviews];
        NSRect frametop=[[subviews objectAtIndex:0] frame];
        NSRect framebottom=[[subviews objectAtIndex:1] frame];
        float newHeight1=frame.size.height-[aSplitView dividerThickness];
        float topratio=frametop.size.height/(oldSize.height-[aSplitView dividerThickness]);
        frametop.size.height=(float)((int)(newHeight1*topratio));
        if (frametop.size.height<splitminheight) {
            frametop.size.height=splitminheight;
        } else if (newHeight1-frametop.size.height<splitminheight) {
            frametop.size.height=newHeight1-splitminheight;
        }
    
        framebottom.size.height=newHeight1-frametop.size.height;
        framebottom.size.width=frametop.size.width=frame.size.width;
        
        frametop.origin.x=framebottom.origin.x=frame.origin.x;
        frametop.origin.y=frame.origin.y;
        framebottom.origin.y=frame.origin.y+[aSplitView dividerThickness]+frametop.size.height;
        
        [[subviews objectAtIndex:0] setFrame:frametop];
        [[subviews objectAtIndex:1] setFrame:framebottom];
    } else {
        // just keep the height of the first view (dialog)
        NSView *view2 = [[aSplitView subviews] objectAtIndex:1];
        NSSize newSize = [aSplitView bounds].size;
        NSSize frameSize = [view2 frame].size;
        frameSize.height += newSize.height - oldSize.height;
        if (frameSize.height <= splitminheight) {
            frameSize.height = splitminheight;
        }
        [view2 setFrameSize:frameSize];
        [aSplitView adjustSubviews];
    }
}

- (BOOL)splitView:(NSSplitView *)aSplitView canCollapseSubview:(NSView *)aView {
    return NO;
}

- (float)splitView:(NSSplitView *)aSplitView constrainSplitPosition:(float)proposedPosition 
       ofSubviewAt:(int)offset {

    float height=[aSplitView frame].size.height;
    float minHeight=(aSplitView==I_dialogSplitView) ? SPLITMINHEIGHTDIALOG : SPLITMINHEIGHTTEXT;;
    if (proposedPosition<minHeight) {
        return minHeight;
    } else if (proposedPosition+minHeight+[aSplitView dividerThickness]>height) {
        return height-minHeight-[aSplitView dividerThickness];
    } else {
        return proposedPosition;
    }
}

- (id)documentDialog {
    return I_documentDialog;
}

- (void)documentDialogFadeInTimer:(NSTimer *)aTimer {
    NSMutableDictionary *info = [aTimer userInfo];
    NSTimeInterval timeInterval     = [[[aTimer userInfo] objectForKey:@"stop"] 
                                        timeIntervalSinceDate:[[aTimer userInfo] objectForKey:@"start"]];
    NSTimeInterval timeSinceStart   = [[[aTimer userInfo] objectForKey:@"start"] timeIntervalSinceNow] * -1.;
//    NSLog(@"sinceStart: %f, timeInterval: %f, %@ %@",timeSinceStart,timeInterval,[[aTimer userInfo] objectForKey:@"stop"],[[aTimer userInfo] objectForKey:@"start"]);
    float factor = timeSinceStart / timeInterval;
    if (factor > 1.) factor = 1.;
    if (![[info objectForKey:@"type"] isEqualToString:@"BlindDown"]) {
        factor = 1.-factor;
    }
    // make transition sinoidal
    factor = (-cos(factor*M_PI)/2.)+0.5;
    
    
    NSView *dialogView = [[I_dialogSplitView subviews] objectAtIndex:0];
    NSRect targetFrame = [dialogView frame];
    float newHeight = (int)(factor * [[info objectForKey:@"targetHeight"] floatValue]);
    float difference = newHeight - targetFrame.size.height;
    targetFrame.size.height = newHeight;
    [dialogView setFrame:targetFrame];
    NSView *contentView = [[I_dialogSplitView subviews] objectAtIndex:1];
    NSRect contentFrame = [contentView frame];
    contentFrame.size.height -= difference;
    [contentView setFrame:contentFrame];
    [I_dialogSplitView setNeedsDisplay:YES];
    
    if (timeSinceStart >= timeInterval) {
        if (![[info objectForKey:@"type"] isEqualToString:@"BlindDown"]) {
            //[[self window] setContentView:[[I_dialogSplitView subviews] objectAtIndex:1]];
            NSTabViewItem *tab = [I_tabView selectedTabViewItem];
            [tab setView:[[I_dialogSplitView subviews] objectAtIndex:1]];
            [I_dialogSplitView release];
            I_dialogSplitView=nil;
            
            NSLog(@"remove dialogSplitView");
            int index = [[self documents] indexOfObject:[self document]];
            if (index != NSNotFound) [[I_tabContexts objectAtIndex:index] setDialogSplitView:nil];
             
            NSSize minSize = [[self window] contentMinSize];
            minSize.height-=100;
            minSize.width-=63;
            [[self window] setContentMinSize:minSize];
            //[I_documentDialog autorelease];
            if (index != NSNotFound) [[I_tabContexts objectAtIndex:index] setDocumentDialog:nil];
            I_documentDialog = nil;
            [[self window] makeFirstResponder:[[self activePlainTextEditor] textView]];
        }
        [dialogView setAutoresizesSubviews:YES];
        [I_dialogAnimationTimer invalidate];
        [I_dialogAnimationTimer autorelease];
         I_dialogAnimationTimer = nil;
    }
}

- (void)setDocumentDialog:(id)aDocumentDialog {
    [aDocumentDialog setDocument:[self document]];
    if (aDocumentDialog) {
        if (!I_dialogSplitView) {
            NSString *identifier = [[(PlainTextDocument *)[self document] session] sessionID];
            int idx = [I_tabView indexOfTabViewItemWithIdentifier:identifier];
            NSTabViewItem *tab = [I_tabView tabViewItemAtIndex:idx];
            //NSView *contentView = [[[self window] contentView] retain];
            NSView *tabItemView = [[tab view] retain];
            NSView *dialogView = [aDocumentDialog mainView];
            //I_dialogSplitView = [[SplitView alloc] initWithFrame:[contentView frame]];
            I_dialogSplitView = [[[SplitView alloc] initWithFrame:[tabItemView frame]] autorelease];
            
            NSLog(@"add dialogSplitView");
            int index = [[self documents] indexOfObject:[self document]];
            if (index != NSNotFound) [[I_tabContexts objectAtIndex:index] setDialogSplitView:I_dialogSplitView];

            [(SplitView *)I_dialogSplitView setDividerThickness:3.];
            NSRect mainFrame = [dialogView frame];
            //[[self window] setContentView:I_dialogSplitView];
            [tab setView:I_dialogSplitView];
            
            [I_dialogSplitView setIsPaneSplitter:YES];
            [I_dialogSplitView setDelegate:self];
            [I_dialogSplitView addSubview:dialogView];
            mainFrame.size.width = [I_dialogSplitView frame].size.width;
            [dialogView setFrame:mainFrame];
            float targetHeight = mainFrame.size.height;
            [dialogView resizeSubviewsWithOldSize:mainFrame.size];
            mainFrame.size.height = 0;
            [dialogView setAutoresizesSubviews:NO];
            [dialogView setFrame:mainFrame];
            //[I_dialogSplitView addSubview:[contentView autorelease]];
            [I_dialogSplitView addSubview:[tabItemView autorelease]];
            NSSize minSize = [[self window] contentMinSize];
            minSize.height+=100;
            minSize.width+=63;
            [[self window] setContentMinSize:minSize];
            I_dialogAnimationTimer = [[NSTimer scheduledTimerWithTimeInterval:0.01 
                target:self 
                selector:@selector(documentDialogFadeInTimer:) 
                userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                            [NSDate dateWithTimeIntervalSinceNow:0.20], @"stop", 
                            [NSDate date], @"start",
                            [NSNumber numberWithFloat:targetHeight],@"targetHeight",
                            @"BlindDown",@"type",nil] 
                repeats:YES] retain];
        } else {
            NSRect frame = [[[I_dialogSplitView subviews] objectAtIndex:0] frame];
            [[[I_dialogSplitView subviews] objectAtIndex:0] removeFromSuperviewWithoutNeedingDisplay];
            [I_dialogSplitView addSubview:[aDocumentDialog mainView] positioned:NSWindowBelow relativeTo:[[I_dialogSplitView subviews] objectAtIndex:0]];
            [[aDocumentDialog mainView] setFrame:frame];
            [I_dialogSplitView setNeedsDisplay:YES];
        }
        //[I_documentDialog autorelease];
        //I_documentDialog = [aDocumentDialog retain];
        int index = [[self documents] indexOfObject:[self document]];
        if (index != NSNotFound) {
            [[I_tabContexts objectAtIndex:index] setDocumentDialog:aDocumentDialog];
            I_documentDialog = aDocumentDialog;
        }
    } else if (!aDocumentDialog && I_dialogSplitView) {
        [[[I_dialogSplitView subviews] objectAtIndex:0] setAutoresizesSubviews:NO];
        I_dialogAnimationTimer = [[NSTimer scheduledTimerWithTimeInterval:0.01 
            target:self 
            selector:@selector(documentDialogFadeInTimer:) 
            userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                        [NSDate dateWithTimeIntervalSinceNow:0.20], @"stop", 
                        [NSDate date], @"start",
                        [NSNumber numberWithFloat:[[[I_dialogSplitView subviews] objectAtIndex:0] frame].size.height],@"targetHeight",
                        @"BlindUp",@"type",nil] 
            repeats:YES] retain];
    }
}

- (IBAction)toggleDialogView:(id)aSender {
    [self setDocumentDialog:[[[EncodingDoctorDialog alloc] initWithEncoding:NSASCIIStringEncoding] autorelease]];
}

- (IBAction)toggleSplitView:(id)aSender {
    if ([I_plainTextEditors count]==1) {
        PlainTextEditor *plainTextEditor = [[PlainTextEditor alloc] initWithWindowController:self splitButton:NO];
        [I_plainTextEditors addObject:plainTextEditor];
        [plainTextEditor release];
        I_editorSplitView = [[[SplitView alloc] initWithFrame:[[[I_plainTextEditors objectAtIndex:0] editorView] frame]] autorelease];

        NSLog(@"add editorSplitView");
        int index = [[self documents] indexOfObject:[self document]];
        if (index != NSNotFound) [[I_tabContexts objectAtIndex:index] setEditorSplitView:I_editorSplitView];

        if (!I_dialogSplitView) {
            //[[self window] setContentView:I_editorSplitView];
            NSTabViewItem *tab = [I_tabView selectedTabViewItem];
            [tab setView:I_editorSplitView];
        } else {
            [I_dialogSplitView addSubview:I_editorSplitView positioned:NSWindowBelow relativeTo:[[I_dialogSplitView subviews] objectAtIndex:1]];
        }
        NSSize splitSize=[I_editorSplitView frame].size;
        splitSize.height=splitSize.height/2.;
        [[[I_plainTextEditors objectAtIndex:0] editorView] setFrameSize:splitSize];
        [[[I_plainTextEditors objectAtIndex:1] editorView] setFrameSize:splitSize];
        [I_editorSplitView addSubview:[[I_plainTextEditors objectAtIndex:0] editorView]];
        [I_editorSplitView addSubview:[[I_plainTextEditors objectAtIndex:1] editorView]];
        [I_editorSplitView setIsPaneSplitter:YES];
        [I_editorSplitView setDelegate:self];
        [[I_plainTextEditors objectAtIndex:1] setShowsBottomStatusBar:
            [[I_plainTextEditors objectAtIndex:0] showsBottomStatusBar]];
        [[I_plainTextEditors objectAtIndex:0] setShowsBottomStatusBar:NO];
        [[I_plainTextEditors objectAtIndex:1] setShowsGutter:
            [[I_plainTextEditors objectAtIndex:0] showsGutter]];
        [self setInitialRadarStatusForPlainTextEditor:[I_plainTextEditors objectAtIndex:1]];
    } else if ([I_plainTextEditors count]==2) {
        if (!I_dialogSplitView) {
            //[[self window] setContentView:[[I_plainTextEditors objectAtIndex:0] editorView]];
            NSTabViewItem *tab = [I_tabView selectedTabViewItem];
            [tab setView:[[I_plainTextEditors objectAtIndex:0] editorView]];
        } else {
            [I_dialogSplitView addSubview:[[I_plainTextEditors objectAtIndex:0] editorView] positioned:NSWindowBelow relativeTo:I_editorSplitView];
            [I_editorSplitView removeFromSuperview];

            NSLog(@"remove editorSplitView");
            int index = [[self documents] indexOfObject:[self document]];
            if (index != NSNotFound) [[I_tabContexts objectAtIndex:index] setEditorSplitView:nil];

        }
        [[I_plainTextEditors objectAtIndex:0] setShowsBottomStatusBar:
            [[I_plainTextEditors objectAtIndex:1] showsBottomStatusBar]];
        [I_plainTextEditors removeObjectAtIndex:1];
        [I_editorSplitView release];
        I_editorSplitView = nil;
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
                    // (void)NSLocalizedString(@"AwaitingResponse", @"Awaiting Response");
                    // (void)NSLocalizedString(@"DeclinedInvitation", @"Declined Invitation");
                    result=NSLocalizedString(status,@"<do not localize>");
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
        if (anItemIndex<2) {
            NSString *group = anItemIndex==0?@"ReadWrite":@"ReadOnly";
            if ([[participants objectForKey:group] count]>aChildIndex) {
                user=[[participants objectForKey:group] objectAtIndex:aChildIndex];
            } else {
                user=[[[session invitedUsers] objectForKey:group] objectAtIndex:aChildIndex-[[participants objectForKey:group] count]];
            }
        } else if (anItemIndex==2) {
            user=[[session pendingUsers] objectAtIndex:aChildIndex];
        }
        if (user) {
            return [NSString stringWithFormat:@"AIM:%@\nEmail:%@",[[user properties] objectForKey:@"AIM"],[[user properties] objectForKey:@"Email"]];
        }
    }
    return nil;
}

- (BOOL)listView:(TCMListView *)aListView writeRows:(NSIndexSet *)selectedRows toPasteboard:(NSPasteboard *)aPasteBoard {
    TCMMMSession *session=[(PlainTextDocument *)[self document] session];
    [aListView reduceSelectionToChildren];
    selectedRows = [aListView selectedRowIndexes];
    if ([selectedRows count]>0) {
        int state = [self buttonStateForSelectedRows:selectedRows];
        NSDictionary *plist=[NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithBool:(state & KickButtonStateMask)],@"Kick",
            [NSNumber numberWithBool:(state & ReadOnlyButtonStateMask)],@"ReadOnly",
            [NSNumber numberWithBool:(state & ReadWriteButtonStateMask)],@"ReadWrite",nil];
        [aPasteBoard declareTypes:[NSArray arrayWithObjects:@"ParticipantDrag",NSVCardPboardType,nil] owner:nil];
        [aPasteBoard setPropertyList:plist forType:@"ParticipantDrag"];
        NSMutableString *vcfString=[NSMutableString string];
        NSMutableIndexSet *selection=[selectedRows mutableCopy];
        while ([selection count]>0) {
            int row=[selection firstIndex];
            ItemChildPair pair=[O_participantsView itemChildPairAtRow:row];
            TCMMMUser *user=nil;
            if (pair.childIndex!=-1) {
                if (pair.itemIndex==2) {
                    user=[[session pendingUsers] objectAtIndex:pair.childIndex];
                } else {
                    NSString *group=(pair.itemIndex==0)?@"ReadWrite":@"ReadOnly";
                    NSArray *array=[[session participants] objectForKey:group];
                    if ([array count]>pair.childIndex) {
                        user=[array objectAtIndex:pair.childIndex];
                    } else {
                        user=[[[session invitedUsers] objectForKey:group] objectAtIndex:pair.childIndex-[array count]];
                    }
                }
            }
            if (user) {
                NSString *vcf=[user vcfRepresentation];
                if (vcf) {
                    [vcfString appendString:vcf];
                }
            }
            [selection removeIndex:row];
        }
        [selection release];
        [aPasteBoard setData:[vcfString dataUsingEncoding:NSUnicodeStringEncoding] forType:NSVCardPboardType];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark -
#pragma mark ### menu validation ###

-(void)menuNeedsUpdate:(NSMenu *)menu {
    int state = [self buttonStateForSelectedRows:[O_participantsView selectedRowIndexes]];
    NSMutableSet *userset=[NSMutableSet set];
    NSMutableIndexSet *selectedRows=[[[O_participantsView selectedRowIndexes] mutableCopy] autorelease];
    int row;
    TCMMMSession *session=[(PlainTextDocument *)[self document] session];
    for (row=[selectedRows firstIndex];[selectedRows count]>0;[selectedRows removeIndex:row],row=[selectedRows firstIndex]) {
        ItemChildPair pair=[O_participantsView itemChildPairAtRow:row];
        TCMMMUser *user=nil;
        if (pair.childIndex!=-1) {
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
        if (user && ![[user userID] isEqualToString:[TCMMMUserManager myUserID]]) {
            [userset addObject:[user userID]];
        }
    }
    id item;
    item = [menu itemWithTag:ParticipantContextMenuTagAIM];
    [item setRepresentedObject:userset];
    item = [menu itemWithTag:ParticipantContextMenuTagEmail];
    [item setRepresentedObject:userset];
    
    item = [menu itemWithTag:ParticipantContextMenuTagFollow];
    [item setEnabled:[userset count]==1 && (state & FollowUserStateMask)!=0];
    
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

    item = [menu itemWithTag:ParticipantContextMenuTagAIM];
    [item setEnabled:[[item target] validateMenuItem:item]];
    item = [menu itemWithTag:ParticipantContextMenuTagEmail];
    [item setEnabled:[[item target] validateMenuItem:item]];

}

#pragma mark -
#pragma mark ### window delegation  ###

- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame {
    if (!([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)) {
        NSRect windowFrame=[[self window] frame];
        I_flags.zoomFix_defaultFrameHadEqualWidth = (defaultFrame.size.width==windowFrame.size.width);
        defaultFrame.size.width=windowFrame.size.width;
        defaultFrame.origin.x=windowFrame.origin.x;
    }
    return defaultFrame;
}

- (BOOL)windowShouldZoom:(NSWindow *)sender toFrame:(NSRect)newFrame {
  return [sender frame].size.width == newFrame.size.width || ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) || I_flags.zoomFix_defaultFrameHadEqualWidth;
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification {
    // switch mode menu on becoming main
    [(PlainTextDocument *)[self document] adjustModeMenu];
}

#pragma mark -

- (void)setIsMultiDocument:(BOOL)flag {
    I_isMultiDocument = flag;
}

- (BOOL)isMultiDocument {
    return I_isMultiDocument;
}

- (PSMTabBarControl *)tabBar
{
	return I_tabBar;
}

#pragma mark -
#pragma mark  A Method That PlainTextDocument Invokes 


- (void)documentWillClose:(NSDocument *)document 
{
    NSLog(@"%s", __FUNCTION__);
    // Record the document that's closing. We'll just remove it from our list when this object receives a -close message.
    I_documentBeingClosed = document;
}

#pragma mark  Private KVC-Compliance for Public Properties 

- (void)insertObject:(NSDocument *)document inDocumentsAtIndex:(unsigned int)index
{
    // Instantiate the documents array lazily.
    if (!I_documents) {
        I_documents = [[NSMutableArray alloc] init];
    }
    [I_documents insertObject:document atIndex:index];
}


- (void)removeObjectFromDocumentsAtIndex:(unsigned int)index
{
    // Instantiate the documents array lazily, if only to get a useful exception thrown.
    if (!I_documents) {
        I_documents = [[NSMutableArray alloc] init];
    }
    // Forget about the document.
    [I_documents removeObjectAtIndex:index];
}

- (void)insertObject:(PlainTextWindowControllerTabContext *)tabContext inTabContextsAtIndex:(unsigned int)index
{
    NSLog(@"%s", __FUNCTION__);
    [I_tabContexts insertObject:tabContext atIndex:index];
}

- (void)removeObjectFromTabContextsAtIndex:(unsigned int)index
{
    [I_tabContexts removeObjectAtIndex:index];
}

#pragma mark Simple Property Getting 


- (NSArray *)documents 
{
    // Instantiate the documents array lazily.
    if (!I_documents) {
        I_documents = [[NSMutableArray alloc] init];
    }
    return I_documents;
}

- (NSArray *)tabContexts
{
    return I_tabContexts;
}

#pragma mark Overrides of NSWindowController Methods 

- (void)setDocument:(NSDocument *)document 
{
    NSLog(@"%s %@ %@", __FUNCTION__, document, self);
    BOOL isNew = NO;
    [super setDocument:document];
    // A document has been told that this window controller belongs to it.

    // Every document sends it window controllers -setDocument:nil when it's closed. We ignore such messages for some purposes.
    if (document) {
        // Have we already recorded this document in our list?
        NSArray *documents = [self documents];
        if (![documents containsObject:document]) {
            // No. Record it, in a KVO-compliant way.
            [self insertObject:document inDocumentsAtIndex:[documents count]];
            PlainTextWindowControllerTabContext *tabContext = [[[PlainTextWindowControllerTabContext alloc] init] autorelease];
            [I_tabContexts addObject:tabContext];
            
            PlainTextEditor *plainTextEditor = [[PlainTextEditor alloc] initWithWindowController:self splitButton:YES];
            [[self window] setInitialFirstResponder:[plainTextEditor textView]];
                        
            [[tabContext plainTextEditors] addObject:plainTextEditor];
            I_plainTextEditors = [tabContext plainTextEditors];
            NSLog(@"set I_plainTextEditors to: %@", I_plainTextEditors);

            I_editorSplitView = nil;
            I_dialogSplitView = nil;
            [self setInitialRadarStatusForPlainTextEditor:plainTextEditor];
            
            NSTabViewItem *tab = [[NSTabViewItem alloc] initWithIdentifier:[[(PlainTextDocument *)document session] sessionID]];
            [tab setLabel:[document displayName]];
            [tab setView:[plainTextEditor editorView]];
            [plainTextEditor release];
            [I_tabView addTabViewItem:tab];
            NSLog(@"adding tab");
            [I_tabView selectTabViewItem:tab];
            [tab release];
            
            isNew = [I_tabView numberOfTabViewItems] == 1 ? YES : NO;
            
        } else {
            // document is already there
            unsigned index = [[self documents] indexOfObject:document];
            if (index < [I_tabContexts count]) {
                I_plainTextEditors = [(PlainTextWindowControllerTabContext *)[I_tabContexts objectAtIndex:index] plainTextEditors];
                I_editorSplitView = [[I_tabContexts objectAtIndex:index] editorSplitView];
                I_dialogSplitView = [[I_tabContexts objectAtIndex:index] dialogSplitView];
                NSLog(@"set I_plainTextEditors to: %@", I_plainTextEditors);
                if ([I_plainTextEditors count] > 0) {
                    [[self window] setInitialFirstResponder:[[I_plainTextEditors objectAtIndex:0] textView]];
                }
            } else {
                NSLog(@"set I_plainTextEditors to nil");
                I_plainTextEditors = nil;
                I_editorSplitView = nil;
                I_dialogSplitView = nil;
            }
        }
    } else {
        I_plainTextEditors = nil;
        I_editorSplitView = nil;
        I_dialogSplitView = nil;
        NSLog(@"set I_plainTextEditors to nil");
        //[I_tabView selectTabViewItemAtIndex:0];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:PlainTextDocumentSessionWillChangeNotification
                                                  object:[self document]];

    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:PlainTextDocumentSessionDidChangeNotification
                                                  object:[self document]];
                                                  
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:PlainTextDocumentParticipantsDataDidChangeNotification
                                                  object:[self document]];

    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:TCMMMSessionParticipantsDidChangeNotification
                                                  object:[(PlainTextDocument *)[self document] session]];
                                                  
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                   name:TCMMMSessionPendingUsersDidChangeNotification 
                                                 object:[(PlainTextDocument *)[self document] session]];

    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:TCMMMSessionDidChangeNotification 
                                                  object:[(PlainTextDocument *)[self document] session]];
                                               
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:PlainTextDocumentDidChangeDisplayNameNotification 
                                                  object:[self document]];

    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:PlainTextDocumentDidChangeDocumentModeNotification 
                                                  object:[self document]];        
                                                   
    [super setDocument:document];
    
    if (document) {
        [self adjustToolbarToDocumentMode];
        [self refreshDisplay];
        [self validateUpperDrawer];
        [O_participantsView reloadData];
        [self validateButtons];
        
        NSEnumerator *editors = [[self plainTextEditors] objectEnumerator];
        PlainTextEditor *editor = nil;
        while ((editor = [editors nextObject])) {
            [editor updateViews];
        }
    
        if (isNew) {
            DocumentMode *mode = [(PlainTextDocument *)document documentMode];
            [self setSizeByColumns:[[mode defaultForKey:DocumentModeColumnsPreferenceKey] intValue] 
                              rows:[[mode defaultForKey:DocumentModeRowsPreferenceKey] intValue]];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(sessionWillChange:)
                                                     name:PlainTextDocumentSessionWillChangeNotification 
                                                   object:[self document]];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(sessionDidChange:)
                                                     name:PlainTextDocumentSessionDidChangeNotification 
                                                   object:[self document]];

        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(participantsDataDidChange:)
                                                     name:PlainTextDocumentParticipantsDataDidChangeNotification 
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

        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(adjustToolbarToDocumentMode)
                                                     name:PlainTextDocumentDidChangeDocumentModeNotification 
                                                   object:[self document]];        
    }
}


static BOOL PlainTextWindowControllerDocumentClosedByTabControl = NO;

- (void)close
{
    NSLog(@"%s",__FUNCTION__);
    // A document is being closed, and trying to close this window controller. Is it the last document for this window controller?
    NSArray *documents = [self documents];
    unsigned int oldDocumentCount = [documents count];
    if (I_documentBeingClosed && oldDocumentCount > 1) {
        if (!PlainTextWindowControllerDocumentClosedByTabControl) {
            NSString *identifier = [[(PlainTextDocument *)I_documentBeingClosed session] sessionID];
            int index = [I_tabView indexOfTabViewItemWithIdentifier:identifier];
            if (index != NSNotFound) {
                [I_tabView removeTabViewItem:[I_tabView tabViewItemAtIndex:index]];
            }
        }
        PlainTextWindowControllerDocumentClosedByTabControl = NO;
    
        // There are other documents open. Just remove the document being closed from our list.
        unsigned int documentIndex = [documents indexOfObject:I_documentBeingClosed];
        [self removeObjectFromDocumentsAtIndex:documentIndex];
        [I_tabContexts removeObjectAtIndex:documentIndex];
        
        I_documentBeingClosed = nil;

        // If that was the current document (and it probably was) then pick another one. Don't forget that [self documents] has now changed.
        documents = [self documents];
        unsigned int newDocumentCount = [documents count];
        if (documentIndex > (newDocumentCount - 1)) {
            // We closed the last document in the list. Display the new last document.
            documentIndex = newDocumentCount - 1;
        }
        [self setDocument:[documents objectAtIndex:documentIndex]];
    } else {

        // Cocoa Bindings makes many things easier. Unfortunately, one of the things it makes easier is creation of reference counting cycles. In Tiger NSWindowController has a feature that keeps bindings to File's Owner, when File's Owner is a window controller, from retaining the window controller in a way that would prevent its deallocation. We're setting up bindings programmatically in -windowDidLoad though, so that feature doesn't kick in, and we have to explicitly unbind to make sure this window controller and everything in the nib it owns get deallocated.
        //[_graphicView unbind:SKTGraphicViewGridBindingName];
        //[_graphicView unbind:SKTGraphicViewGraphicsBindingName];
        //[_graphicView unbind:SKTGraphicViewSelectionIndexesBindingName];

        // That was the last document. Do the regular NSWindowController thing.
        [self removeObjectFromDocumentsAtIndex:0];
        [I_tabView removeTabViewItem:[I_tabView tabViewItemAtIndex:0]];
        [I_tabContexts removeObjectAtIndex:0];
        [self setDocument:nil];
        
        [[DocumentController sharedDocumentController] removeWindowController:self];
        [super close];
    }
}

#pragma mark PSMTabBarControl Delegate

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSLog(@"%s %@", __FUNCTION__, self);
    NSString *identifier = [tabViewItem identifier];
    NSEnumerator *enumerator = [[self documents] objectEnumerator];
    id document;
    while ((document = [enumerator nextObject])) {
        if ([identifier isEqualToString:[[(PlainTextDocument *)document session] sessionID]]) {
            [self setDocument:document];
            break;
        }
    }
}

- (BOOL)tabView:(NSTabView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSLog(@"%s", __FUNCTION__);
    NSString *identifier = [tabViewItem identifier];
    NSEnumerator *enumerator = [[self documents] objectEnumerator];
    id document;
    while ((document = [enumerator nextObject])) {
        if ([identifier isEqualToString:[[(PlainTextDocument *)document session] sessionID]]) {
            PlainTextWindowControllerDocumentClosedByTabControl = YES;
            [document close];
            break;
        }
    }
    
    return YES;
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDragTabViewItem:(NSTabViewItem *)tabViewItem fromTabBar:(PSMTabBarControl *)tabBarControl
{
	return YES;
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl
{
	return YES;
}

- (NSImage *)tabView:(NSTabView *)aTabView imageForTabViewItem:(NSTabViewItem *)tabViewItem offset:(NSSize *)offset styleMask:(unsigned int *)styleMask
{
    NSLog(@"%s %@", __FUNCTION__, [tabViewItem label]);
    
	// grabs whole window image
	NSImage *viewImage = [[[NSImage alloc] init] autorelease];
	NSRect contentFrame = [[[self window] contentView] frame];
	[[[self window] contentView] lockFocus];
	NSBitmapImageRep *viewRep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:contentFrame] autorelease];
	[viewImage addRepresentation:viewRep];
	[[[self window] contentView] unlockFocus];
	
    // grabs snapshot of dragged tabViewItem's view (represents content being dragged)
	NSView *viewForImage = [tabViewItem view];
	NSRect viewRect = [viewForImage frame];
	NSImage *tabViewImage = [[[NSImage alloc] initWithSize:viewRect.size] autorelease];
	[tabViewImage lockFocus];
	[viewForImage drawRect:[viewForImage bounds]];
	[tabViewImage unlockFocus];
	
	[viewImage lockFocus];
	NSPoint tabOrigin = [I_tabView frame].origin;
	tabOrigin.x += 10;
	tabOrigin.y += 13;
	[tabViewImage compositeToPoint:tabOrigin operation:NSCompositeSourceOver];
	[viewImage unlockFocus];
	
	//draw over where the tab bar would usually be
	NSRect tabFrame = [I_tabBar frame];
	[viewImage lockFocus];
	[[NSColor windowBackgroundColor] set];
	NSRectFill(tabFrame);
	//draw the background flipped, which is actually the right way up
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform scaleXBy:1.0 yBy:-1.0];
	[transform concat];
	tabFrame.origin.y = -tabFrame.origin.y - tabFrame.size.height;
	[(id <PSMTabStyle>)[[aTabView delegate] style] drawBackgroundInRect:tabFrame];
	[transform invert];
	[transform concat];
	
	[viewImage unlockFocus];
	
	if ([[aTabView delegate] orientation] == PSMTabBarHorizontalOrientation) {
		offset->width = [(id <PSMTabStyle>)[[aTabView delegate] style] leftMarginForTabBarControl];
		offset->height = 22;
	} else {
		offset->width = 0;
		offset->height = 22 + [(id <PSMTabStyle>)[[aTabView delegate] style] leftMarginForTabBarControl];
	}
	*styleMask = NSTitledWindowMask;
	
	return viewImage;
}

- (PSMTabBarControl *)tabView:(NSTabView *)aTabView newTabBarForDraggedTabViewItem:(NSTabViewItem *)tabViewItem atPoint:(NSPoint)point
{
	NSLog(@"newTabBarForDraggedTabViewItem: %@ atPoint: %@", [tabViewItem label], NSStringFromPoint(point));
	
	//create a new window controller with no tab items
	PlainTextWindowController *controller = [[[PlainTextWindowController alloc] init] autorelease];
    id <PSMTabStyle> style = (id <PSMTabStyle>)[[aTabView delegate] style];
	
	NSRect windowFrame = [[controller window] frame];
	point.y += windowFrame.size.height - [[[controller window] contentView] frame].size.height;
	point.x -= [style leftMarginForTabBarControl];
	
	[[controller window] setFrameTopLeftPoint:point];
	[[controller tabBar] setStyle:style];
	
    [[DocumentController sharedInstance] addWindowController:controller];

	return [controller tabBar];
}

- (void)tabView:(NSTabView *)aTabView didDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl
{
	NSLog(@"didDropTabViewItem: %@ inTabBar: %@", [tabViewItem label], tabBarControl);
    
    if (![tabBarControl isEqual:I_tabBar]) {
        
        PlainTextWindowController *windowController = (PlainTextWindowController *)[[tabBarControl window] windowController];
        NSString *identifier = [tabViewItem identifier];
        NSEnumerator *enumerator = [[self documents] objectEnumerator];
        id document;
        BOOL found = NO;
        while ((document = [enumerator nextObject])) {
            if ([identifier isEqualToString:[[(PlainTextDocument *)document session] sessionID]]) {
                found = YES;
                break;
            }
        }
        if (found) {
            unsigned int documentIndex = [[self documents] indexOfObject:document];
            PlainTextWindowControllerTabContext *tabContext = [I_tabContexts objectAtIndex:documentIndex];
            [document retain];
            [tabContext retain];
            [document removeWindowController:self];
            [self removeObjectFromDocumentsAtIndex:documentIndex];
            [I_tabContexts removeObjectAtIndex:documentIndex];
            
            [tabContext setWindowController:windowController];
            [windowController insertObject:document inDocumentsAtIndex:[[windowController documents] count]];
            [windowController insertObject:tabContext inTabContextsAtIndex:[[windowController tabContexts] count]];
            [document addWindowController:windowController];

            [document release];
            [tabContext release];
            [windowController setDocument:document];
        }
    }
}


- (void)tabView:(NSTabView *)aTabView closeWindowForLastTabViewItem:(NSTabViewItem *)tabViewItem
{
	NSLog(@"closeWindowForLastTabViewItem: %@", [tabViewItem label]);
	[[self window] close];
}

@end
