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
#import "URLBubbleWindow.h"
#import "SEEParticipantsOverlayViewController.h"
#import "SEEWebPreviewViewController.h"
#import "FindAllController.h"
#import <objc/objc-runtime.h>			// for objc_msgSend

// This just constrains the window to the screen initially,
// in effect the first window position is defined in PlainTextWindow.xib this way
static NSPoint S_cascadePoint = {0.0,0.0};

@interface PlainTextWindowController () {
    // Pointers to the current instances
    __weak id I_documentDialog;
    __weak NSSplitView *I_dialogSplitView;

    PlainTextWindowControllerTabContext *I_tabContext;
    
    NSTimer *I_dialogAnimationTimer;
    
    BOOL I_doNotCascade;
    BOOL I_zoomFix_defaultFrameHadEqualWidth;
    
@private
    NSImageView *I_lockImageView;
}

@property (nonatomic) NSRect frameForNonFullScreenMode;
@end

#pragma mark -

@implementation PlainTextWindowController

- (instancetype)init {
	self = [super initWithWindowNibName:@"PlainTextWindow"];
    if (self) {
		[self setShouldCascadeWindows:NO];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)windowWillLoad {
    [self.document windowControllerWillLoadNib:self];
}

- (void)windowDidLoad {
    NSWindow *window = self.window;
    [[window contentView] setAutoresizesSubviews:YES];

    NSTextField *titleBarTextField = [self SEE_titlebarTextField];
    
    // Configure the truncation here
    if (titleBarTextField) {
        titleBarTextField.allowsDefaultTighteningForTruncation = YES;
        titleBarTextField.lineBreakMode = NSLineBreakByTruncatingHead;
        titleBarTextField.maximumNumberOfLines = 1;
    }

    [self updateWindowMinSize];
}


#pragma mark -

// Typed convenience acccessor
- (PlainTextDocument *)plainTextDocument {
    return (PlainTextDocument *)self.document;
}

- (void)setInitialRadarStatusForPlainTextEditor:(PlainTextEditor *)editor {
    PlainTextDocument *document=self.plainTextDocument;
    NSEnumerator *users=[[[[document session] participants] objectForKey:TCMMMSessionReadWriteGroupName] objectEnumerator];
    TCMMMUser *user=nil;
    while ((user=[users nextObject])) {
        if (user != [TCMMMUserManager me]) {
            [editor setRadarMarkForUser:user];
        }
    }
}

- (BOOL)isShowingFindAndReplaceInterface {
	BOOL result = [self.plainTextEditors.firstObject isShowingFindAndReplaceInterface];
	return result;
}

- (IBAction)showFindAndReplaceInterface:(id)aSender {
	[self.plainTextEditors.firstObject showFindAndReplace:aSender];
}

- (void)takeSettingsFromDocument {
    [self setShowsBottomStatusBar:[self.plainTextDocument showsBottomStatusBar]];
    [[self plainTextEditors] makeObjectsPerformSelector:@selector(takeSettingsFromDocument)];
}

- (PlainTextWindowControllerTabContext *)windowControllerTabContextForDocument:(PlainTextDocument *)aDocument {
  if (aDocument == self.document) {
    return I_tabContext;
  }
  
  return nil;
}

- (void)document:(PlainTextDocument *)document isReceivingContent:(BOOL)flag; {
    if (document != self.document) {
        return;
    }
    
    [I_tabContext setValue:[NSNumber numberWithBool:flag] forKeyPath:@"isReceivingContent"];
    [I_tabContext setValue:[NSNumber numberWithBool:flag] forKeyPath:@"isProcessing"];
    
    if (flag) {
        PlainTextLoadProgress *loadProgress = [I_tabContext loadProgress];
        if (!loadProgress) {
            loadProgress = [[PlainTextLoadProgress alloc] init];
            [I_tabContext setLoadProgress:loadProgress];
        }
        [I_tabContext setPresentedView:[loadProgress loadProgressView]];
        [loadProgress registerForSession:[document session]];
        [loadProgress startAnimation];
        
        
    } else {
        PlainTextLoadProgress *loadProgress = [I_tabContext loadProgress];
        
        [loadProgress stopAnimation];
        
        PlainTextEditor *editor = [[I_tabContext plainTextEditors] objectAtIndex:0];
        
        [I_tabContext setPresentedView:[editor editorView]];
        [I_tabContext.windowController.window setInitialFirstResponder:[editor textView]];
        [[editor textView] setSelectedRange:NSMakeRange(0, 0)];
        
        if ([self window] == [[[NSApp orderedWindows] objectEnumerator] nextObject]) {
            [[self window] makeKeyWindow];
        }
    }
}

- (void)documentDidLoseConnection:(PlainTextDocument *)document {
    PlainTextWindowControllerTabContext *tabContext = [self windowControllerTabContextForDocument:document];
    if (tabContext) {
        [tabContext setValue:@NO forKeyPath:@"isReceivingContent"];
        [tabContext setValue:@NO forKeyPath:@"isProcessing"];
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
	PlainTextWindowControllerTabContext *tabContext = self.SEE_tabContext;
	PlainTextEditor *editor = tabContext.plainTextEditors.firstObject;
	[editor storePosition];
    NSSize contentSize=[editor desiredSizeForColumns:aColumns rows:aRows];
    contentSize.width  = ceil(contentSize.width);
    contentSize.height = ceil(contentSize.height);
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
		selector == @selector(toggleShowInvisibles:) ||
        selector == @selector(toggleShowInconsistentIndentation:)){
		return [self.activePlainTextEditor validateMenuItem:menuItem];
    } else if (selector ==@selector(toggleWebPreview:)) {
		[menuItem setState:self.SEE_tabContext.hasWebPreviewSplit ? NSOnState : NSOffState];
		return YES;
	} else if (selector == @selector(toggleParticipantsOverlay:)) {
        [menuItem setState:
            [self.plainTextEditors.lastObject hasBottomOverlayView] ?
            NSOnState :
            NSOffState];
        return YES;
	} else if (selector == @selector(toggleBottomStatusBar:)) {
		PlainTextWindowControllerTabContext *tabContext = self.SEE_tabContext;
        [menuItem setState:[[tabContext.plainTextEditors lastObject] showsBottomStatusBar]?NSOnState:NSOffState];
        return YES;
    } else if (selector == @selector(toggleLineNumbers:)) {
        [menuItem setState:[self showsGutter]?NSOnState:NSOffState];
        return YES;
    } else if (selector == @selector(copyDocumentURL:)) {
        return [self.plainTextDocument isAnnounced];
    } else if (selector == @selector(toggleSplitView:)) {
		PlainTextWindowControllerTabContext *tabContext = self.SEE_tabContext;
        [menuItem setTitle:[tabContext.plainTextEditors count]==1?
                           NSLocalizedString(@"Split View",@"Split View Menu Entry"):
                           NSLocalizedString(@"Collapse Split View",@"Collapse Split View Menu Entry")];
        
        BOOL isReceivingContent = NO;
        if (tabContext) isReceivingContent = [tabContext isReceivingContent];
        return !isReceivingContent;
    } else if (selector == @selector(changePendingUsersAccess:)) {
        TCMMMSession *session=[self.plainTextDocument session];
        [menuItem setState:([menuItem tag]==[session accessState])?NSOnState:NSOffState];
        return [session isServer];
    } else if (selector == @selector(readWriteButtonAction:) ||
               selector == @selector(followUser:) ||
               selector == @selector(kickButtonAction:) ||
               selector == @selector(readOnlyButtonAction:)) {
        return [menuItem isEnabled];
    } else if (selector == @selector(closeTab:)) {
        if (self.window.isKeyWindow) {
            return YES;
        } else {
			return NO;
        }
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

- (BOOL)showsBottomStatusBar {
	PlainTextWindowControllerTabContext *tabContext = self.SEE_tabContext;
    return [[tabContext.plainTextEditors lastObject] showsBottomStatusBar];
}

- (void)setShowsBottomStatusBar:(BOOL)aFlag {
    BOOL showsBottomStatusBar=[self showsBottomStatusBar];
    if (showsBottomStatusBar!=aFlag) {
		PlainTextWindowControllerTabContext *tabContext = self.SEE_tabContext;
		[[tabContext.plainTextEditors lastObject] setShowsBottomStatusBar:aFlag];
        [[self document] setShowsBottomStatusBar:aFlag];
    }
}

- (BOOL)showsGutter {
	PlainTextWindowControllerTabContext *tabContext = self.SEE_tabContext;
    return [[tabContext.plainTextEditors objectAtIndex:0] showsGutter];
}

- (void)setShowsGutter:(BOOL)aFlag {
	PlainTextWindowControllerTabContext *tabContext = self.SEE_tabContext;
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

- (IBAction)toggleShowInconsistentIndentation:(id)aSender {
    [[self activePlainTextEditor] toggleShowInconsistentIndentation:aSender];
}

- (IBAction)toggleShowsChangeMarks:(id)aSender {
    [[self activePlainTextEditor] toggleShowsChangeMarks:aSender];
}


#pragma mark -

- (void)sessionWillChange:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMMMSessionParticipantsDidChangeNotification object:[self.plainTextDocument session]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMMMSessionPendingUsersDidChangeNotification object:[self.plainTextDocument session]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMMMSessionDidChangeNotification object:[self.plainTextDocument session]];
}

- (void)sessionDidChange:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(participantsDidChange:)
                                                 name:TCMMMSessionParticipantsDidChangeNotification 
                                               object:[self.plainTextDocument session]];

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(pendingUsersDidChange:)
                                                 name:TCMMMSessionPendingUsersDidChangeNotification 
                                               object:[self.plainTextDocument session]];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(MMSessionDidChange:)
                                                 name:TCMMMSessionDidChangeNotification 
                                               object:[self.plainTextDocument session]];
                                                       
    BOOL isEditable=[self.plainTextDocument isEditable];
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
    PlainTextDocument *document = self.plainTextDocument;
    TCMMMSession *session = [document session];
    showLock = [session isSecure] && ([document isAnnounced] || [session participantCount] + [session openInvitationCount]>1);
    [I_lockImageView setHidden:!showLock];
}

- (void)synchronizeWindowTitleWithDocumentName {
    [super synchronizeWindowTitleWithDocumentName];
    if (self.windowLoaded) { // Don't trigger load of window prematurely
        [self SEE_postprocessUpdateOfWindowTitle];
    }
    
    [self updateLock];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName document:(PlainTextDocument *)document {
    TCMMMSession *session = [document session];

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
    if ((requests=[[[self.plainTextDocument session] pendingUsers] count])>0) {
        displayName=[displayName stringByAppendingFormat:@" (%@)", [NSString stringWithFormat:NSLocalizedString(@"%lu pending", @"Pending Users Display in Menu Title Bar"), (unsigned long)requests]];
    }

    NSString *jobDescription = [self.plainTextDocument jobDescription];
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
    return [self windowTitleForDocumentDisplayName:displayName document:self.plainTextDocument];
}


#pragma mark -

- (void)updateWindowMinSize {
	CGFloat minHeight = 0.0;
	CGFloat minWidth = 0.0;

	PlainTextWindowControllerTabContext *tabContext = self.SEE_tabContext;
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

- (NSTextField *)SEE_titlebarTextField {
    NSButton *closeButton = [self.window standardWindowButton:NSWindowCloseButton];
    if ([closeButton.superview isKindOfClass:NSClassFromString(@"NSTitlebarView")]) {
        // return first NSTextField of that
        for (id view in closeButton.superview.subviews) {
            if ([view isKindOfClass:[NSTextField class]]) {
                return view;
            }
        }
    }
    return nil;
}

- (void)SEE_postprocessUpdateOfWindowTitle {
    NSWindowTab *tab = self.window.tab;
    tab.title = self.plainTextDocument.displayName;
    
    // clean out the attributed title and use the configuraiton of the textfield -
    // if that is too radical we could just adjust the linebreakmode
    // of the read attributed string and set it again on the text field
    NSTextField *titlebarTextField = [self SEE_titlebarTextField];
    titlebarTextField.stringValue = titlebarTextField.attributedStringValue.string;
}

#pragma mark - Dialog Split

- (void)setDocumentDialog:(id)aDocumentDialog {
	PlainTextWindowControllerTabContext *tabContext = self.SEE_tabContext;
	tabContext.documentDialog = aDocumentDialog;
}

- (id)documentDialog {
	id result = self.SEE_tabContext.documentDialog;
	return result;
}

#pragma mark - Editor Split

- (IBAction)toggleSplitView:(id)aSender {
	PlainTextWindowControllerTabContext *tabContext = [self SEE_tabContext];
	[tabContext toggleEditorSplit];
}

#pragma mark Editors

- (NSArray<PlainTextEditor *> *)plainTextEditors {
    return I_tabContext.plainTextEditors;
}

- (PlainTextEditor *)activePlainTextEditor {
	PlainTextEditor *result = self.SEE_tabContext.activePlainTextEditor;
	return result;
}

- (void)setActivePlainTextEditor:(PlainTextEditor *)activePlainTextEditor {
	[self.SEE_tabContext setActivePlainTextEditor:activePlainTextEditor];
	[self invalidateRestorableState];
}

- (PlainTextEditor *)activePlainTextEditorForDocument:(PlainTextDocument *)aDocument {
	PlainTextEditor *result = nil;
  PlainTextWindowControllerTabContext *tabContext = [self windowControllerTabContextForDocument:aDocument];
	result = tabContext.activePlainTextEditor;
	return result;
}


#pragma mark - Participants Overlay

- (IBAction)openParticipantsOverlay:(id)aSender {
	PlainTextWindowControllerTabContext *context = self.SEE_tabContext;
	[context openParticipantsOverlay:aSender];
}

- (IBAction)closeParticipantsOverlay:(id)aSender {
	PlainTextWindowControllerTabContext *context = self.SEE_tabContext;
	[context closeParticipantsOverlay:aSender];
}

- (IBAction)toggleParticipantsOverlay:(id)aSender {
	PlainTextWindowControllerTabContext *context = self.SEE_tabContext;
	[context toggleParticipantsOverlay:aSender];
}

- (void)openParticipantsOverlayForDocument:(PlainTextDocument *)aDocument {
	PlainTextWindowControllerTabContext *context = [self windowControllerTabContextForDocument:aDocument];
	[context openParticipantsOverlay:aDocument];
}

- (void)closeParticipantsOverlayForDocument:(PlainTextDocument *)aDocument {
	PlainTextWindowControllerTabContext *context = [self windowControllerTabContextForDocument:aDocument];
	[context closeParticipantsOverlay:aDocument];
}

- (IBAction)changePendingUsersAccess:(id)aSender {
    [self.plainTextDocument changePendingUsersAccess:aSender];
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
    [self.plainTextDocument setShowsBottomStatusBar:[self showsBottomStatusBar]];
}


#pragma mark - WebPreview Split

- (IBAction)toggleWebPreview:(id)sender {
	NSResponder *oldFirstResponder = self.window.firstResponder;
	PlainTextWindowControllerTabContext *tabContext = [self SEE_tabContext];

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
	PlainTextWindowControllerTabContext *tabContext = [self SEE_tabContext];
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
}

- (void)restoreStateWithCoder:(NSCoder *)coder {
//	NSLog(@"%s - %d : %@", __FUNCTION__, __LINE__, [self.document displayName]);
	[super restoreStateWithCoder:coder];
}


#pragma mark - NSWindowDelegate

- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame {
    if (!([[NSApp currentEvent] modifierFlags] & NSEventModifierFlagShift)) {
        NSRect windowFrame=[[self window] frame];
        I_zoomFix_defaultFrameHadEqualWidth = (defaultFrame.size.width==windowFrame.size.width);
        defaultFrame.size.width=windowFrame.size.width;
        defaultFrame.origin.x=windowFrame.origin.x;
    }
    return defaultFrame;
}

- (BOOL)windowShouldZoom:(NSWindow *)sender toFrame:(NSRect)newFrame {
    return (([sender frame].size.width == newFrame.size.width)
            || ([[NSApp currentEvent] modifierFlags] & NSEventModifierFlagShift)
            || I_zoomFix_defaultFrameHadEqualWidth);
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification {
    [self updateLock];
    [self.plainTextDocument adjustModeMenu];
    PlainTextWindow *window = (PlainTextWindow *)self.window;

    [window ensureTabBarVisiblity:SEEDocumentController.shouldAlwaysShowTabBar];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification {
	[self showFirstUseHelpIfNeeded];
}

- (void)showFirstUseHelpIfNeeded {
	if (![[AppController sharedInstance] didShowFirstUseWindowHelp]) {
		PlainTextEditor *editorToShow = self.SEE_tabContext.plainTextEditors.lastObject;
		[NSOperationQueue TCM_performBlockOnMainQueue:^{
			if (![[AppController sharedInstance] didShowFirstUseWindowHelp] &&
				[editorToShow.plainTextWindowController SEE_tabContext] == editorToShow.windowControllerTabContext &&
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
    PlainTextDocument *document = self.plainTextDocument;
    for (FindAllController *findAllController in document.findAllControllers) {
        if ([self isEqual:findAllController.findAndReplaceContext.targetTextView.window.windowController]) {
            [result addObject:findAllController];
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
}

- (IBAction)showWindow:(id)aSender {
    if (![[self window] isVisible] &&
        !I_doNotCascade &&
        !self.isInTabGroup) {
    	[self cascadeWindow];
    }
    [super showWindow:aSender];
}

- (NSRect)dissolveToFrame {
    return NSOffsetRect(NSInsetRect(self.window.frame, -9., -9.), 0., -4.);
}

- (void)documentDidUpdateChangeCount {
    PlainTextDocument *document = self.plainTextDocument;
    if ([I_tabContext isEdited] != [document isDocumentEdited]) {
        [I_tabContext setIsEdited:[document isDocumentEdited]];
    }
}

- (BOOL)isInTabGroup {
    BOOL result = self.window.tabbedWindows.count > 1;
    return result;
}

- (void)document:(PlainTextDocument *)doc shouldClose:(BOOL)shouldClose contextInfo:(void *)contextInfo {
    if (shouldClose) {
        if (doc.windowControllers.count > 1) {
            [self close];
        } else {
            [doc close];
        }
    }
}

- (PlainTextWindowControllerTabContext *)SEE_tabContext {
    return I_tabContext;
}

#pragma mark Overrides of NSWindowController Methods 

- (void)setDocument:(NSDocument *)document {
    PlainTextDocument *previouslySelectedDocument = self.document;
    
    if (document == previouslySelectedDocument) {
        [super setDocument:document];
        PlainTextWindowControllerTabContext *tabContext = [self windowControllerTabContextForDocument:(PlainTextDocument *)document];
        if (tabContext) {
            I_dialogSplitView = [tabContext dialogSplitView];
        }
    } else {
        
        [previouslySelectedDocument removeObserver:self forKeyPath:@"hasAlerts"];
        
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
        
        // A document has been told that this window controller belongs to it.
        [super setDocument:document];
        [document addObserver:self forKeyPath:@"hasAlerts" options:NSKeyValueObservingOptionInitial context:nil];

        // Every document sends it window controllers -setDocument:nil when it's closed. We ignore such messages for some purposes.
        if (document == nil) {
            I_dialogSplitView = nil;
        } else {
            
            PlainTextWindow *window = (PlainTextWindow *)self.window;
            
            I_tabContext = ({
                PlainTextWindowControllerTabContext *tabContext = [[PlainTextWindowControllerTabContext alloc] init];
                [tabContext setDocument:(PlainTextDocument *)document];
                [tabContext setIsEdited:[(PlainTextDocument *)document isDocumentEdited]];
                
                PlainTextLoadProgress *loadProgress = [[PlainTextLoadProgress alloc] init];
                [tabContext setLoadProgress:loadProgress];
                
                PlainTextEditor *plainTextEditor = [[PlainTextEditor alloc] initWithWindowControllerTabContext:tabContext splitButton:YES];
                window.initialFirstResponder = plainTextEditor.textView;
                NSView *editorView = [plainTextEditor editorView];
                editorView.identifier = @"FirstEditor";
                editorView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
                
                [[tabContext plainTextEditors] addObject:plainTextEditor];
                
                tabContext.contentView = window.contentView;
                tabContext.presentedView = editorView;
                
                tabContext;
            });
            
            I_dialogSplitView = nil;
            
            if ([[self window] isKeyWindow]) {
                [(PlainTextDocument *)document adjustModeMenu];
            }
            
            DocumentMode *mode = [(PlainTextDocument *)document documentMode];
            [self setSizeByColumns:[[mode defaultForKey:DocumentModeColumnsPreferenceKey] intValue]
                              rows:[[mode defaultForKey:DocumentModeRowsPreferenceKey] intValue]];
            
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
            
        }
        [self updateWindowMinSize];
    }
}


- (void)close {
    PlainTextDocument *document = self.plainTextDocument;
    [self setDocument:nil];
    [document removeWindowController:self];
    [[SEEDocumentController sharedDocumentController] removeWindowController:self];
    [super close];
    
    [I_tabContext.plainTextEditors makeObjectsPerformSelector:@selector(prepareForDealloc)];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"hasAlerts"]) {
        [(PlainTextWindow *)self.window setShowsCautionSymbolInTab:self.plainTextDocument.hasAlerts];
    }
}

@end
