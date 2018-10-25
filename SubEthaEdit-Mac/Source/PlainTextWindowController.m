//  PlainTextWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Mar 05 2004.

#import "PlainTextWindowController.h"
#import "PlainTextDocument.h"
#import "DocumentMode.h"
#import "PlainTextEditor.h"
#import "PlainTextWindow.h"
#import "FoldableTextStorage.h"
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "TCMMMUserSEEAdditions.h"
#import "SelectionOperation.h"
#import "ImagePopUpButtonCell.h"
#import "LayoutManager.h"
#import "SEETextView.h"
#import "GeneralPreferences.h"
#import "TCMMMSession.h"
#import "AppController.h"
#import "SEEEncodingDoctorDialogViewController.h"
#import "SEEDocumentController.h"
#import "PlainTextWindowControllerTabContext.h"
#import "NSMenuTCMAdditions.h"
#import "PlainTextLoadProgress.h"
#import <PSMTabBarControl/PSMTabBarControl.h>
#import <PSMTabBarControl/PSMTabStyle.h>
#import "URLBubbleWindow.h"
#import "SEEParticipantsOverlayViewController.h"
#import "SEETabStyle.h"
#import "SEEWebPreviewViewController.h"
#import "FindAllController.h"
#import <objc/objc-runtime.h>			// for objc_msgSend


static NSPoint S_cascadePoint = {0.0,0.0};

@interface PlainTextWindowController ()

@property (assign) NSRect frameForNonFullScreenMode;

- (void)insertObject:(NSDocument *)document inDocumentsAtIndex:(NSUInteger)index;
- (void)removeObjectFromDocumentsAtIndex:(NSUInteger)index;
@end

#pragma mark -

@implementation PlainTextWindowController

+ (void)initialize {
	if (self == [PlainTextWindowController class]) {
		[PSMTabBarControl registerTabStyleClass:[SEETabStyle class]];
	}
}

- (instancetype)init {
	self = [super initWithWindowNibName:@"PlainTextWindow"];
    if (self) {
		[self setShouldCascadeWindows:NO];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForPortMapStatus) name:TCMPortMapperDidFinishWorkNotification object:[TCMPortMapper sharedInstance]];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    I_dialogSplitView = nil;
    I_documentDialog = nil;
    
    [I_documents release];
    I_documents = nil;

	[I_tabBar setDelegate:nil];
	[I_tabBar setTabView:nil];
	[I_tabView setDelegate:nil];
	[I_tabBar release];
	[I_tabView release];
	 
    [[SEEDocumentController sharedInstance] updateTabMenu];
            
    [super dealloc];
}

- (void)windowWillLoad {
    if ([self document]) {
        [[self document] windowControllerWillLoadNib:self];
    }
}

- (void)windowDidLoad {
	NSWindow *window = self.window;
    [[window contentView] setAutoresizesSubviews:YES];

	NSRect contentFrame = [[window contentView] frame];
	 
	I_tabBar = [[PSMTabBarControl alloc] initWithFrame:NSMakeRect(0.0, NSHeight(contentFrame) - [SEETabStyle desiredTabBarControlHeight], NSWidth(contentFrame), [SEETabStyle desiredTabBarControlHeight])];
    [I_tabBar setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
//	[I_tabBar setTearOffStyle:PSMTabBarTearOffMiniwindow];
    [I_tabBar setStyleNamed:@"SubEthaEdit"];
	[I_tabBar setAlwaysShowActiveTab:YES];

	// hook up add tab button
	[I_tabBar setShowAddTabButton:YES];
	[[I_tabBar addTabButton] setTarget:nil];
	[[I_tabBar addTabButton] setAction:@selector(newDocumentInTab:)];

    [[window contentView] addSubview:I_tabBar];

    I_tabView = [[NSTabView alloc] initWithFrame:NSMakeRect(0.0, 0.0, NSWidth(contentFrame), NSHeight(contentFrame) - [SEETabStyle desiredTabBarControlHeight])];
    [I_tabView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
    [I_tabView setTabViewType:NSNoTabsNoBorder];

    [[window contentView] addSubview:I_tabView];
    [I_tabBar setTabView:I_tabView];
    [I_tabView setDelegate:I_tabBar];
    [I_tabBar setDelegate:self];
    [I_tabBar setPartnerView:I_tabView];

    BOOL shouldHideTabBar = [[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyAlwaysShowTabBar];
    [I_tabBar setHideForSingleTab:!shouldHideTabBar];
    [I_tabBar hideTabBar:!shouldHideTabBar animate:NO];
    [I_tabBar setCellOptimumWidth:300];
    [I_tabBar setCellMinWidth:140];

    [self updateForPortMapStatus];
	[self updateWindowMinSize];
}


#pragma mark -

- (void)setInitialRadarStatusForPlainTextEditor:(PlainTextEditor *)editor {
    PlainTextDocument *document=(PlainTextDocument *)[self document];
    NSEnumerator *users=[[[[document session] participants] objectForKey:TCMMMSessionReadWriteGroupName] objectEnumerator];
    TCMMMUser *user=nil;
    while ((user=[users nextObject])) {
        if (user != [TCMMMUserManager me]) {
            [editor setRadarMarkForUser:user];
        }
    }
}

- (void)updateForPortMapStatus {
//    BOOL isAnnounced = [(PlainTextDocument *)[self document] isAnnounced];
//    BOOL isServer = [[(PlainTextDocument *)[self document] session] isServer];
//    if (isAnnounced) {
//        BOOL portMapped = ([[[[TCMPortMapper sharedInstance] portMappings] anyObject] mappingStatus] == TCMPortMappingStatusMapped);
//        NSString *URLString = [[[[[self document] documentURL] absoluteString] componentsSeparatedByString:@"?"] objectAtIndex:0];
//        [O_URLTextField setObjectValue:URLString];
//    } else if (isServer) {
//        [O_URLTextField setObjectValue:NSLocalizedString(@"Document not advertised.\nNo Document URL.",@"Text for document URL field when not advertised")];
//    } else {
//        [O_URLTextField setObjectValue:NSLocalizedString(@"Not your Document.\nNo Document URL.",@"Text for document URL field when not your document")];
//    }
}

- (BOOL)isShowingFindAndReplaceInterface {
	BOOL result = [self.plainTextEditors.firstObject isShowingFindAndReplaceInterface];
	return result;
}

- (IBAction)showFindAndReplaceInterface:(id)aSender {
	[self.plainTextEditors.firstObject showFindAndReplace:aSender];
}

- (void)takeSettingsFromDocument {
    [self setShowsBottomStatusBar:[(PlainTextDocument *)[self document] showsBottomStatusBar]];
    [[self plainTextEditors] makeObjectsPerformSelector:@selector(takeSettingsFromDocument)];
}

- (NSTabViewItem *)tabViewItemForDocument:(PlainTextDocument *)document {
    unsigned count = [I_tabView numberOfTabViewItems];
    unsigned i;
    for (i = 0; i < count; i++) {
        NSTabViewItem *tabItem = [I_tabView tabViewItemAtIndex:i];
        id identifier = [tabItem identifier];
        if ([[identifier document] isEqual:document]) {
            return tabItem;
        }
    }
    return nil;
}

- (PlainTextWindowControllerTabContext *)windowControllerTabContextForDocument:(PlainTextDocument *)aDocument {
	NSTabViewItem *item = [self tabViewItemForDocument:aDocument];
	PlainTextWindowControllerTabContext *result = [item identifier];
	return result;
}

- (PlainTextWindowControllerTabContext *)selectedTabContext {
	PlainTextWindowControllerTabContext *result = self.selectedTabViewItem.identifier;
	return result;
}

- (NSTabViewItem *)selectedTabViewItem {
	NSTabViewItem *result = self.tabView.selectedTabViewItem;
	return result;
}

- (void)document:(PlainTextDocument *)document isReceivingContent:(BOOL)flag;
{
    if (![[self documents] containsObject:document])
        return;
        
    NSTabViewItem *tabViewItem = [self tabViewItemForDocument:document];
    if (tabViewItem) {
        PlainTextWindowControllerTabContext *tabContext = [tabViewItem identifier];
        [tabContext setValue:[NSNumber numberWithBool:flag] forKeyPath:@"isReceivingContent"];
        [tabContext setValue:[NSNumber numberWithBool:flag] forKeyPath:@"isProcessing"];

        if (flag) {
            PlainTextLoadProgress *loadProgress = [tabContext loadProgress];
            if (!loadProgress) {
                loadProgress = [[PlainTextLoadProgress alloc] init];
                [tabContext setLoadProgress:loadProgress];
                [loadProgress release];
            }
            [tabViewItem setView:[loadProgress loadProgressView]];
            [loadProgress registerForSession:[document session]];
            [loadProgress startAnimation];

            
        } else {
            PlainTextLoadProgress *loadProgress = [tabContext loadProgress];

            [loadProgress stopAnimation];

            PlainTextEditor *editor = [[tabContext plainTextEditors] objectAtIndex:0];

            [tabViewItem setView:[editor editorView]];
            [tabViewItem setInitialFirstResponder:[editor textView]];
            [[editor textView] setSelectedRange:NSMakeRange(0, 0)];

            if ([I_tabView selectedTabViewItem] == tabViewItem) [[self window] makeFirstResponder:[editor textView]];
            if ([self window] == [[[NSApp orderedWindows] objectEnumerator] nextObject]) {
                [[self window] makeKeyWindow];
            }
        }
    }
}

- (void)documentDidLoseConnection:(PlainTextDocument *)document {
    NSTabViewItem *tabViewItem = [self tabViewItemForDocument:document];
    if (tabViewItem) {
        PlainTextWindowControllerTabContext *tabContext = [tabViewItem identifier];
        [tabContext setValue:[NSNumber numberWithBool:NO] forKeyPath:@"isReceivingContent"];
        [tabContext setValue:[NSNumber numberWithBool:NO] forKeyPath:@"isProcessing"];
        PlainTextLoadProgress *loadProgress = [tabContext loadProgress];
        [loadProgress stopAnimation];
        [loadProgress setStatusText:NSLocalizedString(@"Did lose Connection!", @"Text in Proxy window")];
    }
}

- (void)setWindowFrame:(NSRect)aFrame constrainedToScreen:(NSScreen *)aScreen display:(BOOL)aFlag {
	if (!aScreen) {
		// search for a screen that fits most of the frame
		NSEnumerator *screens = [[NSScreen screens] objectEnumerator];
		NSScreen *screen = nil;
		double overlapArea = -1.0;
		while ((screen = [screens nextObject])) {
			NSRect intersectionRect = NSIntersectionRect(aFrame, [screen frame]);
			double thisOverlapArea = intersectionRect.size.width * intersectionRect.size.height;
			if (thisOverlapArea > overlapArea) {
				aScreen = screen;
				overlapArea = thisOverlapArea;
			}
		}
		// only do that when we don't have an associated screen
		NSRect targetScreenVisibleFrame = [aScreen visibleFrame];
		if (NSWidth(targetScreenVisibleFrame) < NSWidth(aFrame)) {
			aFrame.size.width = targetScreenVisibleFrame.size.width;
		}
		if (NSMinX(targetScreenVisibleFrame) > NSMinX(aFrame)) {
			aFrame.origin.x += NSMinX(targetScreenVisibleFrame) - NSMinX(aFrame);
		}
		if (NSMaxX(targetScreenVisibleFrame) < NSMaxX(aFrame)) {
			aFrame.origin.x -= NSMaxX(aFrame) - NSMaxX(targetScreenVisibleFrame);
		}
		I_doNotCascade = YES;
	}

    if (aScreen) {
        NSRect visibleFrame=[aScreen visibleFrame];
        if (NSHeight(aFrame)>NSHeight(visibleFrame)) {
            CGFloat heightDiff=aFrame.size.height-visibleFrame.size.height;
            aFrame.origin.y+=heightDiff;
            aFrame.size.height-=heightDiff;
        }
        if (NSMinY(aFrame)<NSMinY(visibleFrame)) {
            CGFloat positionDiff=NSMinY(visibleFrame)-NSMinY(aFrame);
            aFrame.origin.y+=positionDiff;
        }
    }
    [[self window] setFrame:aFrame display:YES];
}

- (void)setSizeByColumns:(NSInteger)aColumns rows:(NSInteger)aRows {
	PlainTextWindowControllerTabContext *tabContext = self.selectedTabContext;
	PlainTextEditor *editor = tabContext.plainTextEditors.firstObject;
	[editor storePosition];
    NSSize contentSize=[editor desiredSizeForColumns:aColumns rows:aRows];
    contentSize.width  = ceil(contentSize.width);
    contentSize.height = ceil(contentSize.height + NSHeight(self.tabBar.frame));
    NSWindow *window=[self window];
    NSSize minSize=[window contentMinSize];
    NSRect contentRect=[window contentRectForFrameRect:[window frame]];
    contentSize=NSMakeSize(MAX(contentSize.width,minSize.width),
                             MAX(contentSize.height,minSize.height));
    contentRect.origin.y+=contentRect.size.height-contentSize.height;
    contentRect.size=contentSize;
    NSRect frameRect=[window frameRectForContentRect:contentRect];
    NSScreen *screen=[[self window] screen];
    [self setWindowFrame:frameRect constrainedToScreen:screen display:YES];
	[editor restorePositionAfterOperation:nil];
    
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL selector = [menuItem action];
    
	if (selector == @selector(toggleWrap:) ||
		selector == @selector(toggleTopStatusBar:) ||
		selector == @selector(toggleShowsChangeMarks:) ||
		selector == @selector(toggleShowInvisibles:)) {
		return [self.activePlainTextEditor validateMenuItem:menuItem];
    } else if (selector ==@selector(toggleWebPreview:)) {
		[menuItem setState:self.selectedTabContext.hasWebPreviewSplit ? NSOnState : NSOffState];
		return YES;
	} else if (selector == @selector(toggleParticipantsOverlay:)) {
        [menuItem setState:
            [self.plainTextEditors.lastObject hasBottomOverlayView] ?
            NSOnState :
            NSOffState];
        return YES;
	} else if (selector == @selector(toggleBottomStatusBar:)) {
		PlainTextWindowControllerTabContext *tabContext = self.selectedTabContext;
        [menuItem setState:[[tabContext.plainTextEditors lastObject] showsBottomStatusBar]?NSOnState:NSOffState];
        return YES;
    } else if (selector == @selector(toggleLineNumbers:)) {
        [menuItem setState:[self showsGutter]?NSOnState:NSOffState];
        return YES;
    } else if (selector == @selector(copyDocumentURL:)) {
        return [(PlainTextDocument *)[self document] isAnnounced];
    } else if (selector == @selector(toggleSplitView:)) {
		PlainTextWindowControllerTabContext *tabContext = self.selectedTabContext;
        [menuItem setTitle:[tabContext.plainTextEditors count]==1?
                           NSLocalizedString(@"Split View",@"Split View Menu Entry"):
                           NSLocalizedString(@"Collapse Split View",@"Collapse Split View Menu Entry")];
        
        BOOL isReceivingContent = NO;
        NSTabViewItem *tabViewItem = [self tabViewItemForDocument:[self document]];
        if (tabViewItem) isReceivingContent = [[tabViewItem identifier] isReceivingContent];
        return !isReceivingContent;
    } else if (selector == @selector(changePendingUsersAccess:)) {
        TCMMMSession *session=[(PlainTextDocument *)[self document] session];
        [menuItem setState:([menuItem tag]==[session accessState])?NSOnState:NSOffState];
        return [session isServer];
    } else if (selector == @selector(readWriteButtonAction:) ||
               selector == @selector(followUser:) ||
               selector == @selector(kickButtonAction:) ||
               selector == @selector(readOnlyButtonAction:)) {
        return [menuItem isEnabled];
    } else if (selector == @selector(openInSeparateWindow:)) {
        return ([[self documents] count] > 1);
    } else if (selector == @selector(closeTab:)) {
        if ([self.window isKeyWindow])
            return YES;
		else
			return NO;
    } else if (selector == @selector(selectNextTab:)) {
        if ([self hasManyDocuments])
            return YES;
        else
            return NO;
    } else if (selector == @selector(selectPreviousTab:)) {
        if ([self hasManyDocuments])
            return YES;
        else
            return NO;
    } else if (selector == @selector(showDocumentAtIndex:)) {
        int documentNumberToShow = [[menuItem representedObject] intValue];
        id document = nil;
        NSArray *documents = [self orderedDocuments];
        if ([documents count] > documentNumberToShow) {
            document = [documents objectAtIndex:documentNumberToShow];
			[menuItem setMark:[document isDocumentEdited]];
			
            if (([self document] == document) &&
                ([[self window] isKeyWindow] || 
                 [[self window] isMainWindow])) {
                [menuItem setState:NSOnState];
            }
        }
        return ![[self window] attachedSheet] || ([[self window] attachedSheet] && [self document] == document);
    }
    
    return YES;
}


#pragma mark -

- (void)gotoLine:(unsigned)aLine {
	PlainTextEditor *activeEditor = [self activePlainTextEditor];
	[activeEditor gotoLine:aLine];
}

// selects a range of the fulltextstorage
- (void)selectRange:(NSRange)aRange {
	PlainTextEditor *activeEditor = [self activePlainTextEditor];
	[activeEditor selectRange:aRange];
}

- (void)selectRangeInBackground:(NSRange)aRange {
	PlainTextEditor *activeEditor = [self activePlainTextEditor];
	[activeEditor selectRangeInBackground:aRange];
}

#pragma mark -

- (IBAction)openInSeparateWindow:(id)sender {
    PlainTextDocument *document = [self document];
    NSUInteger documentIndex = [[self documents] indexOfObject:document];
    NSTabViewItem *tabViewItem = [self tabViewItemForDocument:document];
    
    [tabViewItem retain];
    [document retain];
    [document setKeepUndoManagerOnZeroWindowControllers:YES];
    [document removeWindowController:self];
    [self removeObjectFromDocumentsAtIndex:documentIndex];
    [I_tabView removeTabViewItem:tabViewItem];
    
    PlainTextWindowController *windowController = [[[PlainTextWindowController alloc] init] autorelease];
    
    NSRect contentRect = [[self window] contentRectForFrameRect:[[self window] frame]];
    NSRect frame = [[windowController window] frameRectForContentRect:contentRect];
    NSPoint cascadedTopLeft = [[self window] cascadeTopLeftFromPoint:NSZeroPoint];
    frame.origin.x = cascadedTopLeft.x;
    frame.origin.y = cascadedTopLeft.y - NSHeight(frame);
    NSScreen *screen = [[self window] screen];
    if (screen) {
        NSRect visibleFrame = [screen visibleFrame];
        if (NSHeight(frame) > NSHeight(visibleFrame)) {
            CGFloat heightDiff = frame.size.height - visibleFrame.size.height;
            frame.origin.y += heightDiff;
            frame.size.height -= heightDiff;
        }
        if (NSMinY(frame) < NSMinY(visibleFrame)) {
            CGFloat positionDiff = NSMinY(visibleFrame) - NSMinY(frame);
            frame.origin.y += positionDiff;
        }
    }
    [[windowController window] setFrame:frame display:YES];

    [[SEEDocumentController sharedInstance] addWindowController:windowController];
    [windowController insertObject:document inDocumentsAtIndex:[[windowController documents] count]];
    [document addWindowController:windowController];
    [document setKeepUndoManagerOnZeroWindowControllers:NO];
    [[windowController tabView] addTabViewItem:tabViewItem];
    [[windowController tabView] selectTabViewItem:tabViewItem];

    [tabViewItem release];
    [document release];
    [windowController setDocument:document];
    [windowController showWindow:self];

	PlainTextEditor *editor = [[self plainTextEditors] lastObject];
    if (editor.hasBottomOverlayView) {
        [windowController openParticipantsOverlay:self];
    }
}

- (BOOL)showsBottomStatusBar {
	PlainTextWindowControllerTabContext *tabContext = self.selectedTabContext;
    return [[tabContext.plainTextEditors lastObject] showsBottomStatusBar];
}

- (void)setShowsBottomStatusBar:(BOOL)aFlag {
    BOOL showsBottomStatusBar=[self showsBottomStatusBar];
    if (showsBottomStatusBar!=aFlag) {
		PlainTextWindowControllerTabContext *tabContext = self.selectedTabContext;
		[[tabContext.plainTextEditors lastObject] setShowsBottomStatusBar:aFlag];
        [[self document] setShowsBottomStatusBar:aFlag];
    }
}

- (BOOL)showsGutter {
	PlainTextWindowControllerTabContext *tabContext = self.selectedTabContext;
    return [[tabContext.plainTextEditors objectAtIndex:0] showsGutter];
}

- (void)setShowsGutter:(BOOL)aFlag {
	PlainTextWindowControllerTabContext *tabContext = self.selectedTabContext;
    for (id loopItem in tabContext.plainTextEditors) {
        [loopItem setShowsGutter:aFlag];
    }
    [[self document] setShowsGutter:aFlag];
	[self invalidateRestorableState];
}

- (IBAction)toggleLineNumbers:(id)aSender {
    [self setShowsGutter:![self showsGutter]];
	[self invalidateRestorableState];
}

- (IBAction)jumpToNextSymbol:(id)aSender {
    [[self activePlainTextEditor] jumpToNextSymbol:aSender];
}

- (IBAction)jumpToPreviousSymbol:(id)aSender {
    [[self activePlainTextEditor] jumpToPreviousSymbol:aSender];
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

- (IBAction)toggleShowInvisibles:(id)aSender {
    [[self activePlainTextEditor] toggleShowInvisibles:aSender];
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
    [self synchronizeWindowTitleWithDocumentName];
}

- (void)participantsDataDidChange:(NSNotification *)aNotifcation {
}

- (void)participantsDidChange:(NSNotification *)aNotifcation {
    [self synchronizeWindowTitleWithDocumentName]; // update the lock
    [self refreshDisplay];
}

- (void)pendingUsersDidChange:(NSNotification *)aNotifcation {
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
}


#pragma mark -

- (void)updateLock {
    BOOL showLock=NO;
    PlainTextDocument *document = (PlainTextDocument *)[self document];
    TCMMMSession *session = [document session];
    showLock = [session isSecure] && ([document isAnnounced] || [session participantCount] + [session openInvitationCount]>1);
    [I_lockImageView setHidden:!showLock];
}

- (void)synchronizeWindowTitleWithDocumentName {
    [super synchronizeWindowTitleWithDocumentName];
    [self updateForPortMapStatus];
    [self updateLock];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName document:(PlainTextDocument *)document {
    TCMMMSession *session = [document session];
    
	NSTabViewItem *tabViewItem = [self tabViewItemForDocument:document];
    if (tabViewItem) [tabViewItem setLabel:displayName];

    if ([[document ODBParameters] objectForKey:@"keyFileCustomPath"]) {
        displayName = [[document ODBParameters] objectForKey:@"keyFileCustomPath"];
    } else {
        NSArray *pathComponents = [[document fileURL] pathComponents];
		NSString *changedName = [PlainTextDocument displayStringWithAdditionalPathComponentsForPathComponents:pathComponents];
		
        if (!changedName) {
            if (session && ![session isServer]) {
                changedName = [session filename];
            }
        }
		if (changedName) {
			displayName = changedName;
		}
    }

    if (session && ![session isServer]) {
        displayName = [displayName stringByAppendingFormat:@" - %@", [[[TCMMMUserManager sharedInstance] userForUserID:[session hostID]] name]];
        if ([document fileURL]) {
            if (![[[session filename] lastPathComponent] isEqualToString:[[document fileURL] lastPathComponent]]) {
                displayName = [displayName stringByAppendingFormat:@" (%@)", [session filename]];
            }
            displayName = [displayName stringByAppendingString:@" *"];
        }
    }
    
    NSUInteger requests;
    if ((requests=[[[(PlainTextDocument *)[self document] session] pendingUsers] count])>0) {
        displayName=[displayName stringByAppendingFormat:@" (%@)", [NSString stringWithFormat:NSLocalizedString(@"%d pending", @"Pending Users Display in Menu Title Bar"), requests]];
    }

    NSString *jobDescription = [(PlainTextDocument *)[self document] jobDescription];
    if (jobDescription && [jobDescription length] > 0) {
        displayName = [displayName stringByAppendingFormat:@" [%@]", jobDescription];
    }
    
    NSArray *windowControllers=[document windowControllers];
    if ([windowControllers count]>1) {
        displayName = [displayName stringByAppendingFormat:@" - %lu/%lu",
                        [windowControllers indexOfObject:self]+1,
                        (unsigned long)[windowControllers count]];
    }
    
    return displayName;
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    return [self windowTitleForDocumentDisplayName:displayName document:(PlainTextDocument *)[self document]];
}


#pragma mark -

- (void)updateWindowMinSize {
	CGFloat minHeight = 0.0;
	CGFloat minWidth = 0.0;

	PlainTextWindowControllerTabContext *tabContext = self.selectedTabContext;
	NSSplitView *editorSplitView = tabContext.editorSplitView;
	NSSplitView *dialogSplitView = tabContext.dialogSplitView;
	NSSplitView *webPreviewSplitView = tabContext.webPreviewSplitView;

	if (webPreviewSplitView) {
		minWidth += webPreviewSplitView.dividerThickness;
		minWidth += SEEMinEditorWidth; // editor width
		minWidth += SEEMinWebPreviewWidth; // preview
	}

	if (dialogSplitView) {
		minHeight += SPLITMINHEIGHTDIALOG;
		minHeight += [dialogSplitView dividerThickness];
	}
	
	for (PlainTextEditor *editor in tabContext.plainTextEditors) {
		minHeight += editor.desiredMinHeight;
	}
	if (tabContext.plainTextEditors.count > 1) {
		minHeight += [editorSplitView dividerThickness];
	}
	
	NSSize minSize = NSMakeSize(MAX(SEEMinEditorWidth, minWidth), MAX(minHeight, 230.));
	[self.window setContentMinSize:minSize];
	
	BOOL needsResizing = NO;
	NSRect contentRect = [self.window contentRectForFrameRect:self.window.frame];
	if (NSHeight(contentRect) < minSize.height) {
		contentRect.size.height = minSize.height;
		needsResizing = YES;
	}
	if (NSWidth(contentRect) < minSize.width) {
		contentRect.size.width = minSize.width;
		needsResizing = YES;
	}
	
	if (needsResizing) {
		NSRect newFrame = [self.window frameRectForContentRect:contentRect];
		
		newFrame.origin.y = NSMaxY(self.window.frame) - NSHeight(newFrame);
		
		newFrame = [self.window constrainFrameRect:newFrame toScreen:self.window.screen];
		[self.window setFrame:newFrame display:YES];
		if (editorSplitView) {
			[editorSplitView setPosition:NSHeight([editorSplitView.subviews.firstObject frame]) ofDividerAtIndex:0];
		}
		if (dialogSplitView) {
			[dialogSplitView setPosition:NSHeight([dialogSplitView.subviews.firstObject frame]) ofDividerAtIndex:0];
		}
	}
}


#pragma mark - Dialog Split

- (void)setDocumentDialog:(id)aDocumentDialog {
	PlainTextWindowControllerTabContext *tabContext = self.selectedTabContext;
	tabContext.documentDialog = aDocumentDialog;
}

- (id)documentDialog {
	id result = self.selectedTabContext.documentDialog;
	return result;
}

#pragma mark - Editor Split

- (IBAction)toggleSplitView:(id)aSender {
	PlainTextWindowControllerTabContext *tabContext = [self selectedTabContext];
	[tabContext toggleEditorSplit];
}

#pragma mark Editors

- (NSArray *)plainTextEditors {
	PlainTextWindowControllerTabContext *tabContext = self.selectedTabContext;
    return tabContext.plainTextEditors;
}

- (PlainTextEditor *)activePlainTextEditor {
	PlainTextEditor *result = self.selectedTabContext.activePlainTextEditor;
	return result;
}

- (void)setActivePlainTextEditor:(PlainTextEditor *)activePlainTextEditor {
	[self.selectedTabContext setActivePlainTextEditor:activePlainTextEditor];
	[self invalidateRestorableState];
}

- (PlainTextEditor *)activePlainTextEditorForDocument:(PlainTextDocument *)aDocument {
	PlainTextEditor *result = nil;
	NSTabViewItem *tabViewItem = [self tabViewItemForDocument:aDocument];
    if (tabViewItem) {
        PlainTextWindowControllerTabContext *tabContext = [tabViewItem identifier];
		result = tabContext.activePlainTextEditor;
    }
	return result;
}


#pragma mark - Participants Overlay

- (IBAction)openParticipantsOverlay:(id)aSender {
	PlainTextWindowControllerTabContext *context = self.selectedTabContext;
	[context openParticipantsOverlay:aSender];
}

- (IBAction)closeParticipantsOverlay:(id)aSender {
	PlainTextWindowControllerTabContext *context = self.selectedTabContext;
	[context closeParticipantsOverlay:aSender];
}

- (IBAction)toggleParticipantsOverlay:(id)aSender {
	PlainTextWindowControllerTabContext *context = self.selectedTabContext;
	[context toggleParticipantsOverlay:aSender];
}

- (void)openParticipantsOverlayForDocument:(PlainTextDocument *)aDocument {
	PlainTextWindowControllerTabContext *context = [self tabViewItemForDocument:aDocument].identifier;
	[context openParticipantsOverlay:aDocument];
}

- (void)closeParticipantsOverlayForDocument:(PlainTextDocument *)aDocument {
	PlainTextWindowControllerTabContext *context = [self tabViewItemForDocument:aDocument].identifier;
	[context closeParticipantsOverlay:aDocument];
}

- (IBAction)changePendingUsersAccess:(id)aSender {
    [(PlainTextDocument *)[self document] changePendingUsersAccess:aSender];
}


#pragma mark - PlainTextEditor Bars

- (IBAction)toggleWrap:(id)aSender {
    [self.activePlainTextEditor toggleWrap:aSender];
}

- (IBAction)toggleTopStatusBar:(id)aSender {
    [self.activePlainTextEditor toggleTopStatusBar:aSender];
}

- (IBAction)toggleBottomStatusBar:(id)aSender {
    [self setShowsBottomStatusBar:![self showsBottomStatusBar]];
    [(PlainTextDocument *)[self document] setShowsBottomStatusBar:[self showsBottomStatusBar]];
}


#pragma mark - WebPreview Split

- (IBAction)toggleWebPreview:(id)sender {
	NSResponder *oldFirstResponder = self.window.firstResponder;
	PlainTextWindowControllerTabContext *tabContext = [self selectedTabContext];

	// when split is closing and the webView is first responder make te editor the first responder
	if (tabContext.hasWebPreviewSplit) {
		NSView *webView = tabContext.webPreviewSplitView.subviews.firstObject;
		if (webView && [oldFirstResponder isKindOfClass:[NSView class]] && [((NSView *)oldFirstResponder) isDescendantOf:webView]) {
			oldFirstResponder = tabContext.activePlainTextEditor.textView;
		}
	}

	tabContext.hasWebPreviewSplit = ! tabContext.hasWebPreviewSplit;

	[self updateWindowMinSize];
    [[self window] makeFirstResponder:oldFirstResponder];
}

- (IBAction)refreshWebPreview:(id)aSender {
	PlainTextWindowControllerTabContext *tabContext = [self selectedTabContext];
    if (!tabContext.webPreviewViewController) {
        [self toggleWebPreview:self];
    } else {
        [tabContext.webPreviewViewController refresh:self];
    }
}


#pragma mark - Window restoration
#pragma mark Full Screen Support: Persisting and Restoring Window's Non-FullScreen Frame

+ (NSArray *)restorableStateKeyPaths
{
    return [[super restorableStateKeyPaths] arrayByAddingObjectsFromArray:@[@"frameForNonFullScreenMode"]];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
//	NSLog(@"%s - %d : %@", __FUNCTION__, __LINE__, [self.document displayName]);
	[super encodeRestorableStateWithCoder:coder];

	PlainTextDocument *selectedDocument = self.document;

	NSMutableArray *tabLookupKeys = [NSMutableArray array];
	for (PlainTextDocument *tabDocument in self.orderedDocuments) {
		NSTabViewItem *tabItem = [self tabViewItemForDocument:tabDocument];
		PlainTextWindowControllerTabContext *tabContext = tabItem.identifier;

		NSString *tabLookupKey = tabContext.uuid;
		[tabLookupKeys addObject:tabLookupKey];

		NSMutableData *tabData = [NSMutableData data];
		NSKeyedArchiver *tabCoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:tabData];
		[tabCoder setOutputFormat:NSPropertyListBinaryFormat_v1_0];
		[tabContext encodeRestorableStateWithCoder:tabCoder];
		if (tabDocument != selectedDocument) {
			[tabItem.view encodeRestorableStateWithCoder:tabCoder];
			[tabDocument encodeRestorableStateWithCoder:tabCoder];
		} else {
			[coder encodeObject:tabLookupKey forKey:@"PlainTextWindowSelectedTabLookupKey"];
		}
		[tabCoder finishEncoding];
		[coder encodeObject:tabData forKey:tabLookupKey];
		[tabCoder release];
	}

	[coder encodeObject:tabLookupKeys forKey:@"PlainTextWindowOpenTabLookupKeys"];
}

- (void)restoreStateWithCoder:(NSCoder *)coder {
//	NSLog(@"%s - %d : %@", __FUNCTION__, __LINE__, [self.document displayName]);
	[super restoreStateWithCoder:coder];

	PlainTextDocument *selectedDocument = self.document;

	for (PlainTextDocument *tabDocument in self.orderedDocuments) {
		NSTabViewItem *tabItem = [self tabViewItemForDocument:tabDocument];
		PlainTextWindowControllerTabContext *tabContext = tabItem.identifier;

		NSString *tabLookupKey = tabContext.uuid;

		NSData *tabData = [coder decodeObjectForKey:tabLookupKey];
		NSKeyedUnarchiver *tabCoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:tabData];
		if (tabCoder) {
			[tabContext restoreStateWithCoder:tabCoder];

			// -restoreStateWithCoder on the selected document and view will be called by the window default implementation afterwards
			if (tabDocument != selectedDocument) {
				[tabItem.view restoreStateWithCoder:tabCoder];
				[tabDocument restoreStateWithCoder:tabCoder];
			}
		}
		[tabCoder finishDecoding];
		[tabCoder release];
	}
}


#pragma mark - NSWindowDelegate

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
    [self updateLock];
    // switch mode menu on becoming main
    [(PlainTextDocument *)[self document] adjustModeMenu];
    // also make sure the tab menu is updated correctly
    [[SEEDocumentController sharedInstance] updateTabMenu];
    
    NSTabViewItem *tabViewItem = [I_tabView selectedTabViewItem];
    if (tabViewItem) {
        PlainTextWindowControllerTabContext *tabContext = [tabViewItem identifier];
        if ([tabContext isAlertScheduled]) {
            [[tabContext document] presentScheduledAlertForWindow:[self window]];
            [tabContext setIsAlertScheduled:NO];
        }
    }
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
    NSMenu *fileMenu = [[[NSApp mainMenu] itemWithTag:FileMenuTag] submenu];
    NSInteger index = [fileMenu indexOfItemWithTarget:nil andAction:@selector(closeTab:)];
    if (index) {
        NSMenuItem *item = [fileMenu itemAtIndex:index];
        [item setKeyEquivalent:@"w"];
        [item setKeyEquivalentModifierMask:NSCommandKeyMask];
    }
    index = [fileMenu indexOfItemWithTarget:nil andAction:@selector(performClose:)];
    if (index) {
        NSMenuItem *item = [fileMenu itemAtIndex:index];
        [item setKeyEquivalent:@"W"];
    }
    index = [fileMenu indexOfItemWithTarget:nil andAction:@selector(closeAllDocuments:)];
    if (index) {
        NSMenuItem *item = [fileMenu itemAtIndex:index];
        [item setKeyEquivalent:@"W"];
        [item setKeyEquivalentModifierMask:NSShiftKeyMask | NSAlternateKeyMask | NSCommandKeyMask];
    }
	
	[self showFirstUseHelpIfNeeded];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
    NSMenu *fileMenu = [[[NSApp mainMenu] itemWithTag:FileMenuTag] submenu];
    NSInteger index = [fileMenu indexOfItemWithTarget:nil andAction:@selector(closeTab:)];
    if (index) {
        NSMenuItem *item = [fileMenu itemAtIndex:index];
        [item setKeyEquivalent:@""];
    }
    index = [fileMenu indexOfItemWithTarget:nil andAction:@selector(performClose:)];
    if (index) {
        NSMenuItem *item = [fileMenu itemAtIndex:index];
        [item setKeyEquivalent:@"w"];
    }
    index = [fileMenu indexOfItemWithTarget:nil andAction:@selector(closeAllDocuments:)];
    if (index) {
        NSMenuItem *item = [fileMenu itemAtIndex:index];
        [item setKeyEquivalent:@"w"];
        [item setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];
    }
}


- (void)showFirstUseHelpIfNeeded {
	if (![[AppController sharedInstance] didShowFirstUseWindowHelp]) {
		PlainTextEditor *editorToShow = self.selectedTabContext.plainTextEditors.lastObject;
		[NSOperationQueue TCM_performBlockOnMainQueue:^{
			if (![[AppController sharedInstance] didShowFirstUseWindowHelp] &&
				[editorToShow.plainTextWindowController selectedTabContext] == editorToShow.windowControllerTabContext &&
				[editorToShow.plainTextWindowController.window isKeyWindow] &&
				[(PlainTextDocument *)[editorToShow.plainTextWindowController document] session].isServer) {
				[editorToShow showFirstUseHelp];
				[NSOperationQueue TCM_performBlockOnMainQueue:^{
					[[AppController sharedInstance] setDidShowFirstUseWindowHelp:YES];
				} afterDelay:2.0];
			}
		} afterDelay:1.5];
	}
}

#pragma mark - NSWindowDelegate - Fullscreen

- (NSArray *)allMyFindAllWindowControllers {
	NSMutableArray *result = [NSMutableArray array];
	for (PlainTextDocument *document in self.documents) {
		for (FindAllController *findAllController in document.findAllControllers) {
			if ([self isEqual:findAllController.findAndReplaceContext.targetTextView.window.windowController]) {
				[result addObject:findAllController];
			}
		}
	}
	return result;
}

// Called to allow the delegate to modify the full-screen content size.
// The window size to use when displaying content size.
- (NSSize)window:(NSWindow *)aWindow willUseFullScreenContentSize:(NSSize)aProposedSize {
	return aProposedSize;
}

// Returns the presentation options the window uses when transitioning to full-screen mode.
// - (NSApplicationPresentationOptions)window:(NSWindow *)aWindow willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)aProposedOptions {
//	 return aProposedOptions;
// }
// The proposed options. See NSApplicationPresentationOptions for the possible values.
// The options the window should use when transitioning to full-screen mode. These may be the same as the proposedOptions or may be modified.


#pragma mark -
#pragma mark Enter Full Screen

- (void)windowWillEnterFullScreen:(NSNotification *)aNotification {
	for (FindAllController *findAllController in [self allMyFindAllWindowControllers]) {
		[(NSPanel *)findAllController.window setFloatingPanel:YES];
	}
}

- (void)windowDidEnterFullScreen:(NSNotification *)aNotification {
	for (FindAllController *findAllController in [self allMyFindAllWindowControllers]) {
		[(NSPanel *)findAllController.window setFloatingPanel:NO];
		[findAllController.window setLevel:NSFloatingWindowLevel];
	}
}

#pragma mark -
#pragma mark Exit Full Screen

- (void)windowDidExitFullScreen:(NSNotification *)aNotification {
	for (FindAllController *findAllController in [self allMyFindAllWindowControllers]) {
		[findAllController.window setLevel:NSNormalWindowLevel];
	}
}

#pragma mark -

- (void)cascadeWindow {
    NSWindow *window = [self window];
    S_cascadePoint = [window cascadeTopLeftFromPoint:S_cascadePoint];
    [window setFrameTopLeftPoint:S_cascadePoint];
}

- (IBAction)showWindow:(id)aSender {
    if (![[self window] isVisible] && !I_doNotCascade) {
    	[self cascadeWindow];
    }
    [super showWindow:aSender];
}

- (NSRect)dissolveToFrame {
	if ([self hasManyDocuments] ||
	 ([PlainTextDocument transientDocument] && [[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyOpenNewDocumentInTab])) {
		NSWindow *window = [self window];
		NSRect bounds = [[I_tabBar performSelector:@selector(lastVisibleTab)] frame];
		bounds = [[window contentView] convertRect:bounds fromView:I_tabBar];
		bounds.size.height += 25.;
		bounds.origin.y -= 32.;
		bounds = NSInsetRect(bounds,-8.,-9.);
		bounds.origin.x +=1;
		NSPoint point1 = bounds.origin;
		NSPoint point2 = NSMakePoint(NSMaxX(bounds),NSMaxY(bounds));

		NSRect rect1 = {point1, 1.0, 1.0};
		rect1 = [window convertRectToScreen:rect1];
		point1 = rect1.origin;

		NSRect rect2 = {point2, 1.0, 1.0};
		rect2 = [window convertRectToScreen:rect2];
		point2 = rect2.origin;

		bounds = NSMakeRect(MIN(point1.x,point2.x),MIN(point1.y,point2.y),ABS(point1.x-point2.x),ABS(point1.y-point2.y));
		return bounds;
	} else {
		return NSOffsetRect(NSInsetRect([[self window] frame],-9.,-9.),0.,-4.);
	}
}

- (void)documentUpdatedChangeCount:(PlainTextDocument *)document
{
    NSTabViewItem *tabViewItem = [self tabViewItemForDocument:document];
    if (tabViewItem) {
        PlainTextWindowControllerTabContext *tabContext = [tabViewItem identifier];
        if ([tabContext isEdited] != [document isDocumentEdited])
            [tabContext setIsEdited:[document isDocumentEdited]];
    }
}

- (void)moveAllTabsToWindowController:(PlainTextWindowController *)windowController {

    for (PlainTextDocument *document in I_documents) {
        NSUInteger documentIndex = [[self documents] indexOfObject:document];
        NSTabViewItem *tabViewItem = [self tabViewItemForDocument:document];
        
        [tabViewItem retain];
        [document retain];
	    [document setKeepUndoManagerOnZeroWindowControllers:YES];
        [document removeWindowController:self];
        [self removeObjectFromDocumentsAtIndex:documentIndex];
        [I_tabView removeTabViewItem:tabViewItem];

        if (![[windowController documents] containsObject:document]) {
            [windowController insertObject:document inDocumentsAtIndex:[[windowController documents] count]];
            [document addWindowController:windowController];
            [[windowController tabView] addTabViewItem:tabViewItem];
        }

        [tabViewItem release];
	    [document setKeepUndoManagerOnZeroWindowControllers:NO];

		PlainTextEditor *editor = [[self plainTextEditors] lastObject];
		if (editor.hasBottomOverlayView) {
			[windowController openParticipantsOverlayForDocument:document];
		}

        [document release];
        [[windowController tabBar] hideTabBar:NO animate:YES];
    }
}

- (BOOL)hasManyDocuments
{
    return [[self documents] count] > 1;
}

- (PSMTabBarControl *)tabBar {
	return I_tabBar;
}

- (NSTabView *)tabView {
    return I_tabView;
}

- (IBAction)selectNextTab:(id)sender
{
    NSTabViewItem *item = [I_tabView selectedTabViewItem];
    [I_tabView selectNextTabViewItem:self];
    if ([item isEqual:[I_tabView selectedTabViewItem]]) {
        [I_tabView selectFirstTabViewItem:self];
    }
}

- (IBAction)selectPreviousTab:(id)sender
{
    NSTabViewItem *item = [I_tabView selectedTabViewItem];
    [I_tabView selectPreviousTabViewItem:self];
    if ([item isEqual:[I_tabView selectedTabViewItem]]) {
        [I_tabView selectLastTabViewItem:self];
    }
}

- (IBAction)showDocumentAtIndex:(id)aMenuEntry {
    int documentNumberToShow = [[aMenuEntry representedObject] intValue];
    NSArray *documents = [self orderedDocuments];
    if ([documents count] > documentNumberToShow) {
        id document = [documents objectAtIndex:documentNumberToShow];
        [self selectTabForDocument:document];
        [self showWindow:nil];
        [document showWindows];
    }
}

- (NSArray *)plainTextEditorsForDocument:(id)aDocument {
    NSMutableArray *editors = [NSMutableArray array];
    for (PlainTextDocument *document in self.documents) {
        if ([document isEqual:aDocument]) {
            NSTabViewItem *tabViewItem = [self tabViewItemForDocument:document];
            if (tabViewItem) {
                PlainTextWindowControllerTabContext *tabContext = [tabViewItem identifier];
                [editors addObjectsFromArray:[tabContext plainTextEditors]];
            }
        }
    }
    
    return editors;
}

- (BOOL)selectTabForDocument:(id)aDocument {
    NSTabViewItem *tabViewItem = [self tabViewItemForDocument:aDocument];
    if (tabViewItem) {
        [I_tabView selectTabViewItem:tabViewItem];
        return YES;
    } else {
        return NO;
    }
}

- (IBAction)closeTab:(id)sender {
    [[self document] canCloseDocumentWithDelegate:self shouldCloseSelector:@selector(document:shouldClose:contextInfo:) contextInfo:nil];
}

- (void)closeAllTabsAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [[alert window] orderOut:self];

    if (returnCode == NSAlertFirstButtonReturn) {
        [self reviewChangesAndQuitEnumeration:YES];
    } else if (returnCode == NSAlertThirdButtonReturn) {
        NSArray *documents = [self documents];
        unsigned count = [documents count];
        while (count--) {
            PlainTextDocument *document = [documents objectAtIndex:count];
            [self documentWillClose:document];
            [document close];
        }
    }
}

- (void)closeAllTabs {
    NSArray *documents = [self documents];
    unsigned count = [documents count];
    unsigned needsSaving = 0;
    unsigned hasMultipleViews = 0;
 
    // Determine if there are any unsaved documents...

    while (count--) {
        PlainTextDocument *document = [documents objectAtIndex:count];
        if (document && [document isDocumentEdited]) {
            needsSaving++;

            if ([[document windowControllers] count] > 1)
                hasMultipleViews++;
        }
    }
    if (needsSaving > 0) {
        needsSaving -= hasMultipleViews;
        if (needsSaving > 1) {	// If we only have 1 unsaved document, we skip the "review changes?" panel
        
            NSString *title = [NSString stringWithFormat:NSLocalizedString(@"You have %d documents in this window with unsaved changes. Do you want to review these changes?", nil), needsSaving];
            
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert setMessageText:title];
            [alert setInformativeText:NSLocalizedString(@"If you don\\U2019t review your documents, all your changes will be lost.", @"Warning in the alert panel which comes up when user chooses Quit and there are unsaved documents.")];
            [alert addButtonWithTitle:NSLocalizedString(@"Review Changes\\U2026", @"Choice (on a button) given to user which allows him/her to review all unsaved documents if he/she quits the application without saving them all first.")];
            [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Button choice allowing user to cancel.")];
            [alert addButtonWithTitle:NSLocalizedString(@"Discard Changes", @"Choice (on a button) given to user which allows him/her to quit the application even though there are unsaved documents.")];
            [alert beginSheetModalForWindow:[self window]
                              modalDelegate:self
                             didEndSelector:@selector(closeAllTabsAlertDidEnd:returnCode:contextInfo:)
                                contextInfo:nil];
        } else {
            [self reviewChangesAndQuitEnumeration:YES];
        }
    } else {
        documents = [self documents];
        count = [documents count];
        while (count--) {
            PlainTextDocument *document = [documents objectAtIndex:count];
            [self documentWillClose:document];
            [document close];
        }
    }
}

- (void)reviewedDocument:(NSDocument *)doc shouldClose:(BOOL)shouldClose contextInfo:(void *)contextInfo
{      
    NSWindow *sheet = [[self window] attachedSheet];
    if (sheet) [sheet orderOut:self];
    
    if (shouldClose) {
        NSArray *windowControllers = [doc windowControllers];
        NSUInteger windowControllerCount = [windowControllers count];
        if (windowControllerCount > 1) {
            [self documentWillClose:doc];
            [self close];
        } else {
            [doc close];
        }
        
        if (contextInfo) ((void (*)(id, SEL, BOOL))objc_msgSend)(self, (SEL)contextInfo, YES);
    } else {
        if (contextInfo) ((void (*)(id, SEL, BOOL))objc_msgSend)(self, (SEL)contextInfo, NO);
    }
    
}

- (void)reviewChangesAndQuitEnumeration:(BOOL)cont{
    if (cont) {
        NSArray *documents = [self documents];
        unsigned count = [documents count];
        while (count--) {
            PlainTextDocument *document = [documents objectAtIndex:count];
            if ([document isDocumentEdited] && [self selectTabForDocument:document]) {
                [document canCloseDocumentWithDelegate:self
                                   shouldCloseSelector:@selector(reviewedDocument:shouldClose:contextInfo:)
                                           contextInfo:@selector(reviewChangesAndQuitEnumeration:)];
				return;
            }
        }
        
        documents = [self documents];
        count = [documents count];
        while (count--) {
            PlainTextDocument *document = [documents objectAtIndex:count];
            [self documentWillClose:document];
            [document close];
        }
    }
    
    // if we get to here, either cont was YES and we reviewed all documents, or cont was NO and we don't want to quit
}


#pragma mark - A Method That PlainTextDocument Invokes

- (void)documentWillClose:(NSDocument *)document {
    // Record the document that's closing. We'll just remove it from our list when this object receives a -close message.
    I_documentBeingClosed = document;
}


#pragma mark - Private KVC-Compliance for Public Properties

- (void)insertObject:(NSDocument *)document inDocumentsAtIndex:(NSUInteger)index {
    // Instantiate the documents array lazily.
    if (!I_documents) {
        I_documents = [[NSMutableArray alloc] init];
    }
    [I_documents insertObject:document atIndex:index];
}

- (void)removeObjectFromDocumentsAtIndex:(NSUInteger)index {
    // Instantiate the documents array lazily, if only to get a useful exception thrown.
    if (!I_documents) {
        I_documents = [[NSMutableArray alloc] init];
    }
    // Forget about the document.
    [I_documents removeObjectAtIndex:index];
}


#pragma mark Simple Property Getting 

- (NSArray *)orderedDocuments {
    NSMutableArray *result = [NSMutableArray array];
    NSEnumerator *tabViewItems = [[[self tabBar] representedTabViewItems] objectEnumerator];
    id identifier;
    while ((identifier = [[tabViewItems nextObject] identifier])) {
        id document = [identifier document];
        if ([[self documents] containsObject:document]) {
            [result addObject:document];
        }
    }
    return result;
}

- (NSArray *)documents 
{
    // Instantiate the documents array lazily.
    if (!I_documents) {
        I_documents = [[NSMutableArray alloc] init];
    }
    return I_documents;
}


#pragma mark Overrides of NSWindowController Methods 

- (NSTabViewItem *)addDocument:(NSDocument *)document {
    NSArray *documents = [self documents];
    if (![documents containsObject:document]) {
        // No. Record it, in a KVO-compliant way.
        [self insertObject:document inDocumentsAtIndex:[documents count]];
        PlainTextWindowControllerTabContext *tabContext = [[[PlainTextWindowControllerTabContext alloc] init] autorelease];
        [tabContext setDocument:(PlainTextDocument *)document];
        [tabContext setIsEdited:[(PlainTextDocument *)document isDocumentEdited]];
        
        PlainTextLoadProgress *loadProgress = [[PlainTextLoadProgress alloc] init];
        [tabContext setLoadProgress:loadProgress];
        [loadProgress release];

        PlainTextEditor *plainTextEditor = [[PlainTextEditor alloc] initWithWindowControllerTabContext:tabContext splitButton:YES];
        [[self window] setInitialFirstResponder:[plainTextEditor textView]];
		plainTextEditor.editorView.identifier = @"FirstEditor";
                    
        [[tabContext plainTextEditors] addObject:plainTextEditor];

        I_dialogSplitView = nil;

        NSTabViewItem *tab = [[NSTabViewItem alloc] initWithIdentifier:tabContext];
		tabContext.tab = tab;
        [tab setLabel:[document displayName]];
        [tab setView:[plainTextEditor editorView]];
        [tab setInitialFirstResponder:[plainTextEditor textView]];
        [plainTextEditor release];
        [I_tabView addTabViewItem:tab];
        [tab release];
        if ([documents count] > 1) {
			PlainTextDocument *transientDocument = [PlainTextDocument transientDocument];
			if (!([documents count] == 2 &&
				  transientDocument &&
				  [documents containsObject:transientDocument]))
			{
				[I_tabBar hideTabBar:NO animate:YES];
			}
        }
        return tab;
    }
    return nil;
}

- (void)setDocument:(NSDocument *)document {
    PlainTextDocument *previouslySelectedDocument = self.document;
    
    if (document == previouslySelectedDocument) {
        [super setDocument:document];
        NSTabViewItem *tabViewItem = [self tabViewItemForDocument:(PlainTextDocument *)document];
        if (tabViewItem) {
            PlainTextWindowControllerTabContext *tabContext = [tabViewItem identifier];
            I_dialogSplitView = [tabContext dialogSplitView];
        }
    } else {
        [[URLBubbleWindow sharedURLBubbleWindow] hideIfNecessary];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        if (previouslySelectedDocument) {
            [center removeObserver:self
                              name:PlainTextDocumentSessionWillChangeNotification
                            object:previouslySelectedDocument];
            
            [center removeObserver:self
                              name:PlainTextDocumentSessionDidChangeNotification
                            object:previouslySelectedDocument];
            
            [center removeObserver:self
                              name:PlainTextDocumentParticipantsDataDidChangeNotification
                            object:previouslySelectedDocument];
            
            [center removeObserver:self
                              name:TCMMMSessionParticipantsDidChangeNotification
                            object:[previouslySelectedDocument session]];
            
            [center removeObserver:self
                              name:TCMMMSessionPendingUsersDidChangeNotification
                            object:[previouslySelectedDocument session]];
            
            [center removeObserver:self
                              name:TCMMMSessionDidChangeNotification
                            object:[previouslySelectedDocument session]];
            
            [center removeObserver:self
                              name:PlainTextDocumentDidChangeDisplayNameNotification
                            object:previouslySelectedDocument];
            
            [center removeObserver:self
                              name:PlainTextDocumentDidChangeDocumentModeNotification
                            object:previouslySelectedDocument];
        }
        
        BOOL isNew = NO;
        [super setDocument:document];
        // A document has been told that this window controller belongs to it.
        
        // Every document sends it window controllers -setDocument:nil when it's closed. We ignore such messages for some purposes.
        if (document) {
            // Have we already recorded this document in our list?
            NSArray *documents = [self documents];
            if (![documents containsObject:document]) {
                // No. Record it, in a KVO-compliant way.
                NSTabViewItem *tab = [self addDocument:document];
                [I_tabView selectTabViewItem:tab];
                
                isNew = [I_tabView numberOfTabViewItems] == 1 ? YES : NO;
            } else {
                // document is already there
                NSTabViewItem *tabViewItem = [self tabViewItemForDocument:(PlainTextDocument *)document];
                if (tabViewItem) {
                    PlainTextWindowControllerTabContext *tabContext = [tabViewItem identifier];
                    I_dialogSplitView = [tabContext dialogSplitView];
                    if ([tabContext.plainTextEditors count] > 0) {
                        [[self window] setInitialFirstResponder:[[tabContext.plainTextEditors objectAtIndex:0] textView]];
                    }
                    [I_tabView selectTabViewItem:tabViewItem];
                } else {
                    I_dialogSplitView = nil;
                }
            }
            
            if ([[self window] isKeyWindow]) {
                [(PlainTextDocument *)document adjustModeMenu];
                [[SEEDocumentController sharedInstance] updateTabMenu];
            }
            [self refreshDisplay];
            
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
            
            [center addObserver:self
                       selector:@selector(sessionWillChange:)
                           name:PlainTextDocumentSessionWillChangeNotification
                         object:document];
            [center addObserver:self
                       selector:@selector(sessionDidChange:)
                           name:PlainTextDocumentSessionDidChangeNotification
                         object:document];
            
            [center addObserver:self
                       selector:@selector(participantsDataDidChange:)
                           name:PlainTextDocumentParticipantsDataDidChangeNotification
                         object:document];
            
            [center addObserver:self
                       selector:@selector(participantsDidChange:)
                           name:TCMMMSessionParticipantsDidChangeNotification
                         object:[(PlainTextDocument *)document session]];
            
            [center addObserver:self
                       selector:@selector(pendingUsersDidChange:)
                           name:TCMMMSessionPendingUsersDidChangeNotification
                         object:[(PlainTextDocument *)document session]];
            
            [center addObserver:self
                       selector:@selector(MMSessionDidChange:)
                           name:TCMMMSessionDidChangeNotification
                         object:[(PlainTextDocument *)document session]];
            
            [center addObserver:self
                       selector:@selector(displayNameDidChange:)
                           name:PlainTextDocumentDidChangeDisplayNameNotification
                         object:document];
            
            [center postNotificationName:@"PlainTextWindowControllerDocumentDidChangeNotification" object:self];
        } else {
            I_dialogSplitView = nil;
        }
        [self updateWindowMinSize];
    }
}


- (void)close {
    //NSLog(@"%s",__FUNCTION__);
    // A document is being closed, and trying to close this window controller. Is it the last document for this window controller?
    NSArray *documents = [self documents];
    NSUInteger oldDocumentCount = [documents count];

	PlainTextWindowControllerTabContext *contextToClose = nil;

    if (I_documentBeingClosed && oldDocumentCount > 1) {
        NSTabViewItem *tabViewItem = [self tabViewItemForDocument:(PlainTextDocument *)I_documentBeingClosed];
        if (tabViewItem) {
			contextToClose = [(PlainTextWindowControllerTabContext *)tabViewItem.identifier retain];
			[I_tabView removeTabViewItem:tabViewItem]; // TODO Remove for terminate???
		}

        id document = nil;
        BOOL keepCurrentDocument = ![[self document] isEqual:I_documentBeingClosed];
        if (keepCurrentDocument) document = [self document];

        [I_documentBeingClosed removeWindowController:self]; // ??? removes restore state?

        // There are other documents open. Just remove the document being closed from our list.
        NSUInteger documentIndex = [documents indexOfObject:I_documentBeingClosed];
        [self removeObjectFromDocumentsAtIndex:documentIndex];

        I_documentBeingClosed = nil;

        // If that was the current document (and it probably was) then pick another one. Don't forget that [self documents] has now changed.
        if (!keepCurrentDocument) {
            documents = [self documents];
            NSUInteger newDocumentCount = [documents count];
            if (documentIndex > (newDocumentCount - 1)) {
                // We closed the last document in the list. Display the new last document.
                documentIndex = newDocumentCount - 1;
            }
            document = [documents objectAtIndex:documentIndex];
        }
        [self setDocument:document];
    } else {
        // That was the last document. Do the regular NSWindowController thing.
        if ([I_documents count] > 0) {
            [[I_documents objectAtIndex:0] removeWindowController:self];
            [self removeObjectFromDocumentsAtIndex:0];
        }
        if ([I_tabView numberOfTabViewItems] > 0) {
			NSTabViewItem *tabViewItem = [I_tabView tabViewItemAtIndex:0];
			contextToClose = [(PlainTextWindowControllerTabContext *)tabViewItem.identifier retain];
			[I_tabView removeTabViewItem:tabViewItem];
		}
        [self setDocument:nil];
		
        [[SEEDocumentController sharedDocumentController] removeWindowController:self];
        [super close];
    }
	[contextToClose.plainTextEditors makeObjectsPerformSelector:@selector(prepareForDealloc)];
	[contextToClose release];
}


#pragma mark - PSMTabBarControlDelegate

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    PlainTextWindowControllerTabContext *tabContext = [tabViewItem identifier];
    id document = [tabContext document];
    if ([[self documents] containsObject:document]) {
        [self setDocument:document];
        if ([tabContext isAlertScheduled]) {
            [document presentScheduledAlertForWindow:[self window]];
            [tabContext setIsAlertScheduled:NO];
        }

		[self invalidateRestorableState];
    }
}

- (void)document:(NSDocument *)doc shouldClose:(BOOL)shouldClose contextInfo:(void *)contextInfo {
    if (shouldClose) {
        NSArray *windowControllers = [doc windowControllers];
        NSUInteger windowControllerCount = [windowControllers count];

		if (self.tabView.tabViewItems.count == 1) {
			// [self close] doesn't trigger window delegate calls. so we need to make sure we update the menu
			// through the window resign call when closing the last tab.
			[self windowDidResignKey:nil];
		}

        if (windowControllerCount > 1) {
            [self documentWillClose:doc];
            [self close];
        } else {
            [doc close];
        }

        // updateTabMenu
        [[SEEDocumentController sharedInstance] updateTabMenu];
    }
}

- (BOOL)tabView:(NSTabView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem {
    id document = [[tabViewItem identifier] document];
    [document canCloseDocumentWithDelegate:self shouldCloseSelector:@selector(document:shouldClose:contextInfo:) contextInfo:nil];

    return NO;
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDragTabViewItem:(NSTabViewItem *)tabViewItem fromTabBar:(PSMTabBarControl *)tabBarControl {
	return YES;
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl {
    if ([[tabBarControl window] attachedSheet]) {
        return NO;
    }

    if (![aTabView isEqual:I_tabView]) {
        PlainTextWindowController *windowController = (PlainTextWindowController *)[[tabBarControl window] windowController];
        id document = [[tabViewItem identifier] document];
        if ([[windowController documents] containsObject:document]) {
            return NO;
        }
    }
	return YES;
}

- (NSImage *)tabView:(NSTabView *)aTabView imageForTabViewItem:(NSTabViewItem *)tabViewItem offset:(NSSize *)offset styleMask:(NSUInteger *)styleMask {
	[[self window] disableFlushWindow];
    NSTabViewItem *oldItem = [aTabView selectedTabViewItem];
    [aTabView selectTabViewItem:tabViewItem];
    [aTabView display];

	// get the view chache
	NSView *contentView = [[self window] contentView];
	NSBitmapImageRep *viewCache = [contentView bitmapImageRepForCachingDisplayInRect:contentView.frame];
	[contentView cacheDisplayInRect:contentView.frame toBitmapImageRep:viewCache];

    [aTabView selectTabViewItem:oldItem];
    [aTabView display];
	[[self window] enableFlushWindow];

	NSImage *viewImage = [NSImage imageWithSize:viewCache.size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
		[viewCache drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0 respectFlipped:NO hints:nil];

		//draw over where the tab bar would usually be
		NSRect tabFrame = [I_tabBar frame];
		[[NSColor clearColor] set];
		NSRectFill(tabFrame);

		//draw the background flipped, which is actually the right way up
		NSAffineTransform *transform = [NSAffineTransform transform];
		[transform scaleXBy:1.0 yBy:-1.0];
		[transform concat];
		tabFrame.origin.y = -tabFrame.origin.y - tabFrame.size.height;
		[[((PSMTabBarControl *)[aTabView delegate]) style] drawBezelOfTabBarControl:I_tabBar inRect:tabFrame];
		[transform invert];
		[transform concat];

		return YES;
	}];

	if (offset != NULL) {
		PSMTabBarControl *tabItem = (PSMTabBarControl *)[aTabView delegate];
		if ([tabItem orientation] == PSMTabBarHorizontalOrientation) {
			offset->width = [(id <PSMTabStyle>)[tabItem style] leftMarginForTabBarControl:tabItem];
			offset->height = 24;
		} else {
			offset->width = 0;
			offset->height = 24 + [(id <PSMTabStyle>)[tabItem style] leftMarginForTabBarControl:tabItem];
		}
	}

	if (styleMask != NULL) {
		*styleMask = NSBorderlessWindowMask; //NSTitledWindowMask;
	}

	return viewImage;
}

- (PSMTabBarControl *)tabView:(NSTabView *)aTabView newTabBarForDraggedTabViewItem:(NSTabViewItem *)tabViewItem atPoint:(NSPoint)point {
	BOOL shouldCreateFullscreenWindow = NO;

	if ([aTabView isEqual:I_tabView] && (aTabView.window.styleMask & NSFullScreenWindowMask) == NSFullScreenWindowMask) {
		NSWindow *window = aTabView.window;
        
        NSRect screenMouseRect = NSZeroRect;
        screenMouseRect.origin = point;
        NSRect windowMouseRect = [window convertRectFromScreen:screenMouseRect];
        
		NSPoint windowMousePoint = windowMouseRect.origin;
		NSView *hitView = [window.contentView hitTest:windowMousePoint];
		if (hitView != nil) {
			if (aTabView.tabViewItems.count > 1) {
				shouldCreateFullscreenWindow = YES;
			} else {
				[window setAlphaValue:1.0];
				return nil;
			}
		}
	}

	//create a new window controller with no tab items
	PlainTextWindowController *controller = [[[PlainTextWindowController alloc] init] autorelease];
	PSMTabBarControl *tabBarControl = (PSMTabBarControl *)[aTabView delegate];
    id <PSMTabStyle> style = [tabBarControl style];

	NSWindow *newWindow = [controller window];
	if (shouldCreateFullscreenWindow) {
		[newWindow toggleFullScreen:self];
	} else {
		NSRect windowFrame = [newWindow frame];
		point.y += windowFrame.size.height - [[newWindow contentView] frame].size.height;
		point.x -= [style leftMarginForTabBarControl:tabBarControl];

		NSRect contentRect = [[self window] contentRectForFrameRect:[[self window] frame]];
		NSRect frame = [newWindow frameRectForContentRect:contentRect];
		[newWindow setFrame:frame display:NO];
		[newWindow setFrameTopLeftPoint:point];
	}
	[[controller tabBar] setStyle:style];

	BOOL hideForSingleTab = [(PSMTabBarControl *)[aTabView delegate] hideForSingleTab];
	[[controller tabBar] setHideForSingleTab:hideForSingleTab];
	
    [[SEEDocumentController sharedInstance] addWindowController:controller];

	return [controller tabBar];
}

- (void)tabView:(NSTabView *)aTabView didDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl {
    if ([[self window] isMainWindow]) {
        // update window menu
        [[SEEDocumentController sharedInstance] updateTabMenu];
    }
    if (![tabBarControl isEqual:I_tabBar]) {
        
        PlainTextWindowController *windowController = (PlainTextWindowController *)[[tabBarControl window] windowController];
		windowController.frameForNonFullScreenMode = self.frameForNonFullScreenMode;
		[windowController invalidateRestorableState];

        id document = [[tabViewItem identifier] document];
        NSUInteger documentIndex = [[self documents] indexOfObject:document];
        [document retain];
	    [document setKeepUndoManagerOnZeroWindowControllers:YES];
        [document removeWindowController:self];
        [self removeObjectFromDocumentsAtIndex:documentIndex];
        
        if ([[self documents] count] == 0) {
            [[self retain] autorelease];
            [[SEEDocumentController sharedInstance] removeWindowController:[[self retain] autorelease]];
        } else {
            [self setDocument:[[[[self tabView] selectedTabViewItem] identifier] document]];
        } 
        
        [windowController insertObject:document inDocumentsAtIndex:[[windowController documents] count]];
        [document addWindowController:windowController];
	    [document setKeepUndoManagerOnZeroWindowControllers:NO];

        [windowController setDocument:document];
        
		PlainTextEditor *editor = [[self plainTextEditors] lastObject];
		if (editor.hasBottomOverlayView) {
			[windowController openParticipantsOverlayForDocument:document];
		}
        [document release];

        if (![windowController hasManyDocuments]) {
            [tabBarControl setHideForSingleTab:![[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyAlwaysShowTabBar]];
            [tabBarControl hideTabBar:![[NSUserDefaults standardUserDefaults] boolForKey:kSEEDefaultsKeyAlwaysShowTabBar] animate:NO];
        }
    }
}

- (void)tabView:(NSTabView *)aTabView closeWindowForLastTabViewItem:(NSTabViewItem *)tabViewItem {
	[[self window] close];
}

- (BOOL)tabView:(NSTabView *)aTabView validateOverflowMenuItem:(NSMenuItem *)menuItem forTabViewItem:(NSTabViewItem *)tabViewItem {
    return YES;
}

- (NSString *)tabView:(NSTabView *)aTabView toolTipForTabViewItem:(NSTabViewItem *)tabViewItem {
    PlainTextWindowControllerTabContext *tabContext = [tabViewItem identifier];
    PlainTextDocument *document = [tabContext document];
    return [self windowTitleForDocumentDisplayName:[document displayName] document:document];
}

@end
