//  PlainTextWindowControllerTabContext.m
//  SubEthaEdit
//
//  Created by Martin Ott on 10/17/06.

#import "PlainTextWindowControllerTabContext.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"

#import "PlainTextEditor.h"
#import "SEEWebPreviewViewController.h"

#import "SEEParticipantsOverlayViewController.h"
#import "PlainTextLoadProgress.h"

#import "SEEEncodingDoctorDialogViewController.h"
#import "SEESplitView.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

CGFloat const SEEMinWebPreviewWidth = 320.0;
CGFloat const SEEMinEditorWidth = 385.0;


NSString * const SEEPlainTextWindowControllerTabContextActiveEditorDidChangeNotification = @"SEEPlainTextWindowControllerTabContextActiveEditorDidChangeNotification";

void * const SEEPlainTextWindowControllerTabContextHasEditorSplitObservanceContext = (void *)&SEEPlainTextWindowControllerTabContextHasEditorSplitObservanceContext;
void * const SEEPlainTextWindowControllerTabContextHasWebPreviewSplitObservanceContext = (void *)&SEEPlainTextWindowControllerTabContextHasWebPreviewSplitObservanceContext;
void * const SEEPlainTextWindowControllerTabContextPresentedViewObservanceContext = (void *)&SEEPlainTextWindowControllerTabContextPresentedViewObservanceContext;

@interface PlainTextWindowControllerTabContext ()
- (void)registerKVO;
- (void)unregisterKVO;

- (void)updateEditorSplitView;
- (void)updateWebPreviewSplitView;
@end

@implementation PlainTextWindowControllerTabContext

@synthesize activePlainTextEditor = _activePlainTextEditor;

- (id)init {
    self = [super init];
    if (self) {
		self.uuid = [NSString UUIDString];

        _plainTextEditors = [[NSMutableArray alloc] init];

		[self registerKVO];
    }
    return self;
}

- (void)dealloc {
	[self unregisterKVO];
    [_plainTextEditors makeObjectsPerformSelector:@selector(setWindowControllerTabContext:) withObject:nil];
}

- (PlainTextWindowController *)windowController {
	PlainTextWindowController *result = [self.contentView.window windowController];
	return result;
}

#pragma mark - KVO

- (void)registerKVO {
	[self addObserver:self forKeyPath:@"hasEditorSplit" options:0 context:SEEPlainTextWindowControllerTabContextHasEditorSplitObservanceContext];
	[self addObserver:self forKeyPath:@"hasWebPreviewSplit" options:0 context:SEEPlainTextWindowControllerTabContextHasWebPreviewSplitObservanceContext];
  [self addObserver:self forKeyPath:@"presentedView"
            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:SEEPlainTextWindowControllerTabContextPresentedViewObservanceContext];
}

- (void)unregisterKVO {
	[self removeObserver:self forKeyPath:@"hasEditorSplit" context:SEEPlainTextWindowControllerTabContextHasEditorSplitObservanceContext];
	[self removeObserver:self forKeyPath:@"hasWebPreviewSplit" context:SEEPlainTextWindowControllerTabContextHasWebPreviewSplitObservanceContext];
  [self removeObserver:self forKeyPath:@"presentedView" context:SEEPlainTextWindowControllerTabContextPresentedViewObservanceContext];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SEEPlainTextWindowControllerTabContextHasEditorSplitObservanceContext) {
		[self updateEditorSplitView];
    } else if (context == SEEPlainTextWindowControllerTabContextHasWebPreviewSplitObservanceContext) {
		[self updateWebPreviewSplitView];
    } else if (context == SEEPlainTextWindowControllerTabContextPresentedViewObservanceContext) {
      [self updatePresentedViewForChange:change];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - Debugging description

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, document: %@", [super description], self.document];
}


#pragma mark - Alerts

- (void)setIsAlertScheduled:(BOOL)flag {
    if (flag) {
        [self setIcon:[NSImage imageNamed:@"SymbolWarn"]];
        [self setIconName:@"Alert"];
    } else {
        [self setIcon:nil];
        [self setIconName:@""];
    }
    _isAlertScheduled = flag;
}

#pragma mark - View Management

- (void)updatePresentedViewForChange:(NSDictionary *)change {
  NSView *oldView = [change objectForKey:NSKeyValueChangeOldKey];
  NSView *newView = [change objectForKey:NSKeyValueChangeNewKey];
  
  if (![oldView isEqual:[NSNull null]] && [[oldView superview] isEqual:self.contentView]) {
    [oldView removeFromSuperview];
  }
  
  newView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  newView.frame = self.contentView.frame;
  [self.contentView addSubview:newView];
}

#pragma mark - Active Editor

- (void)setActivePlainTextEditor:(PlainTextEditor *)activePlainTextEditor {
	if ([self.plainTextEditors containsObject:activePlainTextEditor]) {
		_activePlainTextEditor = activePlainTextEditor;
		[[NSNotificationCenter defaultCenter] postNotificationName:SEEPlainTextWindowControllerTabContextActiveEditorDidChangeNotification object:self];
	}
}

- (PlainTextEditor *)activePlainTextEditor {
	PlainTextEditor *result = _activePlainTextEditor;
	if (!result) {
		result = self.plainTextEditors.firstObject;
	}
	return result;
}


#pragma mark - Editor Split

- (void)toggleEditorSplit {
	
	id firstResponder = [self.plainTextEditors[0] textView].window.firstResponder;
	BOOL wasFirstResponder = [[self.plainTextEditors valueForKeyPath:@"textView"] containsObject:firstResponder];
	
	self.hasEditorSplit = ! self.hasEditorSplit;

	if (wasFirstResponder) {
		NSTextView *textView = [self.plainTextEditors[0] textView];
		[textView.window makeFirstResponder:textView];
	}
}

- (void)updateEditorSplitView {
	NSMutableArray *plainTextEditors = self.plainTextEditors;
	PlainTextWindowController *windowController = self.windowController;
	NSSplitView *dialogSplitView = self.dialogSplitView;
	NSSplitView *webPreviewSplitView = self.webPreviewSplitView;
	BOOL hasEditorSplit = self.hasEditorSplit;

	if ([plainTextEditors count] > 0) {
		if (hasEditorSplit && [plainTextEditors count] == 1) {
			PlainTextEditor *plainTextEditor = [[PlainTextEditor alloc] initWithWindowControllerTabContext:self splitButton:NO];
			plainTextEditor.editorView.identifier = @"SecondEditor";
			[plainTextEditors addObject:plainTextEditor];

			NSSplitView *editorSplitView = [[SEESplitView alloc] initWithFrame:[[plainTextEditors[0] editorView] frame]];
			editorSplitView.identifier = @"EditorSplit";
			editorSplitView.dividerStyle = NSSplitViewDividerStyleThin;
			editorSplitView.layer.backgroundColor = [[NSColor darkOverlaySeparatorColorBackgroundIsDark:YES appearanceIsDark:YES] CGColor];
			SEEEditorSplitViewDelegate *splitDelegate = [[SEEEditorSplitViewDelegate alloc] initWithTabContext:self];
			editorSplitView.delegate = splitDelegate;

			if (dialogSplitView) {
				[dialogSplitView addSubview:editorSplitView positioned:NSWindowBelow relativeTo:[[dialogSplitView subviews] objectAtIndex:1]];
			} else if (webPreviewSplitView) {
				[webPreviewSplitView replaceSubview:webPreviewSplitView.subviews[1] with:editorSplitView];
			} else {
				self.presentedView = editorSplitView;
			}
			NSSize splitSize = [editorSplitView frame].size;
			splitSize.height = floor(splitSize.height / 2.);

			[[plainTextEditors[0] editorView] setFrameSize:splitSize];
			[[plainTextEditors[1] editorView] setFrameSize:splitSize];

			[[plainTextEditors[0] editorView] setTranslatesAutoresizingMaskIntoConstraints:YES];
			
			[editorSplitView addSubview:[plainTextEditors[0] editorView]];
			[editorSplitView addSubview:[plainTextEditors[1] editorView]];

			self.editorSplitView = editorSplitView;
			self.editorSplitViewDelegate = splitDelegate;

			[plainTextEditors[1] setShowsBottomStatusBar: [plainTextEditors[0] showsBottomStatusBar]];
			[plainTextEditors[0] setShowsBottomStatusBar:NO];
			[plainTextEditors[1] setShowsGutter:[plainTextEditors[0] showsGutter]];

			[windowController setInitialRadarStatusForPlainTextEditor:plainTextEditors[1]];

			// show participant overlay if split gets toggled
			if ([plainTextEditors[0] hasBottomOverlayView]) {
				[plainTextEditors[0] displayViewControllerInBottomArea:nil];
				SEEParticipantsOverlayViewController *participantsOverlay = [[SEEParticipantsOverlayViewController alloc] initWithTabContext:self];
				[plainTextEditors[1] displayViewControllerInBottomArea:participantsOverlay];
			}

			[windowController updateWindowMinSize];
			[editorSplitView adjustSubviews];

		} else if (!hasEditorSplit && [plainTextEditors count] == 2) {
			NSSplitView *editorSplitView = self.editorSplitView;

			//Preserve scroll position of second editor, if it is currently the selected one.
			id fr = [[self.contentView window] firstResponder];
			NSRect visibleRect = NSZeroRect;
			if (fr == [plainTextEditors[1] textView]) {
				visibleRect = [[plainTextEditors[1] textView] visibleRect];
				[[plainTextEditors[0] textView] setSelectedRange:[[plainTextEditors[1] textView] selectedRange]];
			}

			if (dialogSplitView) {
				NSView *editorView = [plainTextEditors[0] editorView];
				[editorView setFrame:[editorSplitView frame]];
				[dialogSplitView addSubview:editorView positioned:NSWindowBelow relativeTo:editorSplitView];
				[editorSplitView removeFromSuperview];
			} else if (webPreviewSplitView) {
				NSView *editorView = [plainTextEditors[0] editorView];
				[editorView setFrame:[editorSplitView frame]];
				[webPreviewSplitView addSubview:editorView positioned:NSWindowBelow relativeTo:editorSplitView];
				[editorSplitView removeFromSuperview];
			} else {
				self.presentedView = [plainTextEditors[0] editorView];
			}

			self.editorSplitView = nil;
			PlainTextEditor *editorToClose = plainTextEditors[1];
			[plainTextEditors removeObjectAtIndex:1];

			// show participant overlay if split gets toggled
			if ([editorToClose hasBottomOverlayView]) {
				[editorToClose displayViewControllerInBottomArea:nil];
				SEEParticipantsOverlayViewController *participantsOverlay = [[SEEParticipantsOverlayViewController alloc] initWithTabContext:self];
				[plainTextEditors[0] displayViewControllerInBottomArea:participantsOverlay];
			}

			[plainTextEditors[0] setShowsBottomStatusBar:[editorToClose showsBottomStatusBar]];
			[editorToClose prepareForDealloc];
			self.editorSplitView = nil;

			// restore scroll position of second editor if it was the selected one
			if (!NSEqualRects(NSZeroRect,visibleRect)) {
				[[plainTextEditors[0] textView] scrollRectToVisible:visibleRect];
			}
		}

		self.windowController.window.initialFirstResponder = [plainTextEditors[0] textView];
		[plainTextEditors[0] updateSplitButtonForIsSplit:[plainTextEditors count] != 1];

		NSTextView *textView = [plainTextEditors[0] textView];
		NSRange selectedRange = [textView selectedRange];
		[textView scrollRangeToVisible:selectedRange];

		if ([plainTextEditors count] == 2) {
			[[plainTextEditors[1] textView] scrollRangeToVisible:selectedRange];
		}

		[windowController updateWindowMinSize];
	}
}


#pragma mark - Preview Split

- (void)updateWebPreviewSplitView {
	NSView *viewRepresentedByTab = self.presentedView;

	if (!self.hasWebPreviewSplit && viewRepresentedByTab == self.webPreviewSplitView) {
		NSView *editorView = viewRepresentedByTab.subviews.lastObject;
		[editorView removeFromSuperview];
		editorView.frame = viewRepresentedByTab.frame;
		[viewRepresentedByTab removeFromSuperview];

		self.webPreviewSplitView.delegate = nil;
		self.webPreviewSplitViewDelegate = nil;
		self.webPreviewSplitView = nil;

		self.webPreviewViewController = nil;

		editorView.translatesAutoresizingMaskIntoConstraints = YES;
		editorView.autoresizesSubviews = YES;
		editorView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		self.presentedView = editorView;

		[self.windowController updateWindowMinSize];

	} else if (self.hasWebPreviewSplit && self.webPreviewSplitView == nil) {
		[viewRepresentedByTab removeFromSuperview];

		NSSplitView *webPreviewSplitView = [[SEESplitView alloc] initWithFrame:viewRepresentedByTab.frame];
		SEEWebPreviewSplitViewDelegate* webPreviewSplitDelegate = [[SEEWebPreviewSplitViewDelegate alloc] initWithTabContext:self];
		webPreviewSplitView.identifier = @"WebPreviewSplit";
		webPreviewSplitView.dividerStyle = NSSplitViewDividerStyleThin;
		webPreviewSplitView.delegate = webPreviewSplitDelegate;
		webPreviewSplitView.vertical = YES;
		webPreviewSplitView.autoresizesSubviews = YES;
		webPreviewSplitView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		self.presentedView = webPreviewSplitView;

		SEEWebPreviewViewController *webPreviewViewController = [[SEEWebPreviewViewController alloc] initWithPlainTextDocument:self.document];

		self.webPreviewViewController = webPreviewViewController;
		self.webPreviewSplitViewDelegate = webPreviewSplitDelegate;
		self.webPreviewSplitView = webPreviewSplitView;
		
		[webPreviewSplitView addSubview:webPreviewViewController.view];
		[webPreviewSplitView addSubview:viewRepresentedByTab];

		[self.windowController updateWindowMinSize];

		{ // initally try to split the window half/half
			CGFloat dividerThickness = webPreviewSplitView.dividerThickness;
			NSSize newSplitViewSize = webPreviewSplitView.bounds.size;

			NSView *firstSubview = webPreviewSplitView.subviews[0];
			NSView *secondSubview = webPreviewSplitView.subviews[1];

			NSRect firstSubviewFrame = firstSubview.frame;
			NSRect secondSubviewFrame = secondSubview.frame;

			firstSubviewFrame.size.width = MAX(SEEMinWebPreviewWidth, MIN(round(newSplitViewSize.width / 2.0), newSplitViewSize.width - SEEMinEditorWidth));
			secondSubviewFrame.size.width = newSplitViewSize.width - firstSubviewFrame.size.width - dividerThickness;
			secondSubviewFrame.origin.x = firstSubviewFrame.size.width + dividerThickness;

			firstSubview.frame = firstSubviewFrame;
			secondSubview.frame = secondSubviewFrame;
		}

		[webPreviewSplitView adjustSubviews];

		[webPreviewViewController refreshAndEmptyCache:self];
	}
}

#pragma mark - Document Dialog

- (void)updateDocumentDialogSplit {
	NSSplitView *dialogSplitView = self.dialogSplitView;
	NSViewController<SEEDocumentDialogViewController> *documentDialog = self.documentDialog;
	if (documentDialog && !dialogSplitView) {
		PlainTextWindowControllerTabContext *tabContext = self;
		
		NSView *viewToReplace = self.presentedView;
		if (self.webPreviewSplitView) {
			viewToReplace = self.webPreviewSplitView.subviews.lastObject;
		} else if (self.editorSplitView) {
			viewToReplace = self.editorSplitView;
		}
		
		NSView *dialogView = [documentDialog view];
		
		NSSplitView *dialogSplitView = [[NSSplitView alloc] initWithFrame:[viewToReplace frame]];
		dialogSplitView.identifier = @"DialogSplit";
		tabContext.dialogSplitViewDelegate = [[SEEDialogSplitViewDelegate alloc] initWithTabContext:self];
		dialogSplitView.delegate = tabContext.dialogSplitViewDelegate;
		dialogSplitView.dividerStyle = NSSplitViewDividerStyleThin;
		self.dialogSplitView = dialogSplitView;
		
		if ([self.presentedView isEqual:viewToReplace]) {
			self.presentedView = dialogSplitView;
		} else {
			[viewToReplace.superview replaceSubview:viewToReplace with:dialogSplitView];
		}
		
		[dialogSplitView addSubview:dialogView];
		[dialogSplitView addSubview:viewToReplace];

		[self.windowController updateWindowMinSize];
		[dialogSplitView adjustSubviews];

	} else if (!documentDialog && dialogSplitView) {

		// remove document dialog splitview
		NSView *viewToMoveUp = self.dialogSplitView.subviews.lastObject;
		
		if (self.webPreviewSplitView) {
			[viewToMoveUp setTranslatesAutoresizingMaskIntoConstraints:YES];
			[self.webPreviewSplitView replaceSubview:self.dialogSplitView with:viewToMoveUp];
		} else {
			self.presentedView = viewToMoveUp;
		}
		
		self.dialogSplitView.delegate = nil;
		self.dialogSplitViewDelegate = nil;
		self.dialogSplitView = nil;

		[self.windowController updateWindowMinSize];
	}
}

- (void)setDocumentDialog:(NSViewController<SEEDocumentDialogViewController> *)aDocumentDialog {
	[aDocumentDialog setTabContext:self];
	_documentDialog = aDocumentDialog;
	[self updateDocumentDialogSplit];
}

#pragma mark - Participants Overlay

- (IBAction)openParticipantsOverlay:(id)aSender {

	PlainTextEditor *editor = [[self plainTextEditors] lastObject];
	if (editor) {
		SEEParticipantsOverlayViewController *participantsOverlay = [[SEEParticipantsOverlayViewController alloc] initWithTabContext:self];
		[editor displayViewControllerInBottomArea:participantsOverlay];
	}
}

- (IBAction)closeParticipantsOverlay:(id)aSender {
	PlainTextEditor *editor = [[self plainTextEditors] lastObject];
	if (editor) {
		[editor displayViewControllerInBottomArea:nil];
	}
}

- (IBAction)toggleParticipantsOverlay:(id)aSender {
	PlainTextEditor *editor = [[self plainTextEditors] lastObject];
	if (editor) {
		if (editor.hasBottomOverlayView) {
			[editor displayViewControllerInBottomArea:nil];
		} else {
			SEEParticipantsOverlayViewController *participantsOverlay = [[SEEParticipantsOverlayViewController alloc] initWithTabContext:self];
			[editor displayViewControllerInBottomArea:participantsOverlay];
		}
	}
}

- (BOOL)showsParticipantsOverlay {
	BOOL result = [self.plainTextEditors.lastObject hasBottomOverlayView];
	return result;
}

#pragma mark - Restorable State

+ (NSArray *)restorableStateKeyPaths {
	NSArray *restorableStateKeyPaths = [super restorableStateKeyPaths];
	return [restorableStateKeyPaths arrayByAddingObjectsFromArray:@[@"hasEditorSplit", @"hasWebPreviewSplit"]];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
//	NSLog(@"%s - %d : %@", __FUNCTION__, __LINE__, self.document.displayName);
	[coder encodeObject:self.uuid forKey:@"SEETabContextUUID"];

	[super encodeRestorableStateWithCoder:coder];

	// The bookmarks are used by SEEDocumentController to restore the tab documents.
	NSURL *documentURL = self.document.fileURL;
	NSNumber *isFileWritable = nil;
	NSURLBookmarkCreationOptions fileBookmarkOptions = NSURLBookmarkCreationWithSecurityScope;
	[documentURL getResourceValue:&isFileWritable forKey:NSURLIsWritableKey error:nil];
	if (! isFileWritable.boolValue) {
		fileBookmarkOptions = NSURLBookmarkCreationWithSecurityScope | NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess;
	}
	NSData *documentURLBookmark = [documentURL bookmarkDataWithOptions:fileBookmarkOptions
										includingResourceValuesForKeys:nil
														 relativeToURL:nil
																 error:nil];


	NSURL *documentAutosaveURL = self.document.autosavedContentsFileURL;
	NSNumber *isAutosaveFileWritable = nil;
	NSURLBookmarkCreationOptions autosaveFileBookmarkOptions = NSURLBookmarkCreationWithSecurityScope;
	[documentAutosaveURL getResourceValue:&isAutosaveFileWritable forKey:NSURLIsWritableKey error:nil];
	if (! isAutosaveFileWritable.boolValue) {
		autosaveFileBookmarkOptions = NSURLBookmarkCreationWithSecurityScope | NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess;
	}

	NSData *documentAutosaveURLBookmark = [documentAutosaveURL bookmarkDataWithOptions:autosaveFileBookmarkOptions
														includingResourceValuesForKeys:nil
																		 relativeToURL:nil
																				 error:nil];

	[coder encodeObject:documentURLBookmark forKey:@"SEETabContextDocumentURLBookmark"];
	[coder encodeObject:documentAutosaveURLBookmark forKey:@"SEETabContextDocumentAutosaveURLBookmark"];
	[coder encodeBool:self.hasEditorSplit forKey:@"SEETabContextHasEditorSplit"];
	[coder encodeBool:self.hasWebPreviewSplit forKey:@"SEETabContextHasWebPreviewSplit"];
}

- (void)restoreStateWithCoder:(NSCoder *)coder {
//	NSLog(@"%s - %d : %@", __FUNCTION__, __LINE__, self.document.displayName);
	NSString *uuidString = [coder decodeObjectForKey:@"SEETabContextUUID"];
	if (uuidString) {
		self.uuid = uuidString;
	}

	[super restoreStateWithCoder:coder];

	BOOL hasEditorSplit = [coder decodeBoolForKey:@"SEETabContextHasEditorSplit"];
	self.hasEditorSplit = hasEditorSplit;

	BOOL hasWebPreviewSplit = [coder decodeBoolForKey:@"SEETabContextHasWebPreviewSplit"];
	self.hasWebPreviewSplit = hasWebPreviewSplit;
}

@end
