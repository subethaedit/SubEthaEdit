//
//  PlainTextWindowControllerTabContext.m
//  SubEthaEdit
//
//  Created by Martin Ott on 10/17/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "PlainTextWindowControllerTabContext.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"

#import "PlainTextEditor.h"
#import "WebPreviewViewController.h"

#import "SEEParticipantsOverlayViewController.h"
#import "PlainTextLoadProgress.h"
#import "SplitView.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

NSString * const SEEPlainTextWindowControllerTabContextActiveEditorDidChangeNotification = @"SEEPlainTextWindowControllerTabContextActiveEditorDidChangeNotification";

void * const SEEPlainTextWindowControllerTabContextHasEditorSplitObservanceContext = (void *)&SEEPlainTextWindowControllerTabContextHasEditorSplitObservanceContext;
void * const SEEPlainTextWindowControllerTabContextHasWebPreviewSplitObservanceContext = (void *)&SEEPlainTextWindowControllerTabContextHasWebPreviewSplitObservanceContext;

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
        _plainTextEditors = [[NSMutableArray alloc] init];

		[self registerKVO];
    }
    return self;
}

- (void)dealloc {
	[self unregisterKVO];
    [_plainTextEditors makeObjectsPerformSelector:@selector(setWindowControllerTabContext:) withObject:nil];
}


#pragma mark - KVO

- (void)registerKVO {
	[self addObserver:self forKeyPath:@"hasEditorSplit" options:0 context:SEEPlainTextWindowControllerTabContextHasEditorSplitObservanceContext];
	[self addObserver:self forKeyPath:@"hasWebPreviewSplit" options:0 context:SEEPlainTextWindowControllerTabContextHasWebPreviewSplitObservanceContext];
}

- (void)unregisterKVO {
	[self removeObserver:self forKeyPath:@"hasEditorSplit" context:SEEPlainTextWindowControllerTabContextHasEditorSplitObservanceContext];
	[self removeObserver:self forKeyPath:@"hasWebPreviewSplit" context:SEEPlainTextWindowControllerTabContextHasWebPreviewSplitObservanceContext];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SEEPlainTextWindowControllerTabContextHasEditorSplitObservanceContext) {
		[self updateEditorSplitView];
    } else if (context == SEEPlainTextWindowControllerTabContextHasWebPreviewSplitObservanceContext) {
		[self updateWebPreviewSplitView];
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

-(void)updateEditorSplitView {
	NSMutableArray *plainTextEditors = self.plainTextEditors;
	PlainTextWindowController *windowController = (PlainTextWindowController *)[self.tab.tabView.window windowController];
	NSSplitView *dialogSplitView = self.dialogSplitView;
	NSSplitView *webPreviewSplitView = self.webPreviewSplitView;
	BOOL hasEditorSplit = self.hasEditorSplit;

	if ([plainTextEditors count] > 0) {
		if (hasEditorSplit && [plainTextEditors count] == 1) {
			PlainTextEditor *plainTextEditor = [[PlainTextEditor alloc] initWithWindowControllerTabContext:self splitButton:NO];
			plainTextEditor.editorView.identifier = @"SecondEditor";
			[plainTextEditors addObject:plainTextEditor];

			SplitView *editorSplitView = [[SplitView alloc] initWithFrame:[[plainTextEditors[0] editorView] frame]];
			editorSplitView.identifier = @"EditorSplit";
			SEEEditorSplitViewDelegate *splitDelegate = [[SEEEditorSplitViewDelegate alloc] initWithTabContext:self];
			editorSplitView.delegate = splitDelegate;

			if (dialogSplitView) {
				[dialogSplitView addSubview:editorSplitView positioned:NSWindowBelow relativeTo:[[dialogSplitView subviews] objectAtIndex:1]];
			} else if (webPreviewSplitView) {
				[webPreviewSplitView replaceSubview:webPreviewSplitView.subviews[1] with:editorSplitView];
			} else {
				[self.tab setView:editorSplitView];
			}
			NSSize splitSize = [editorSplitView frame].size;
			splitSize.height = splitSize.height / 2.;

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
			
		} else if (!hasEditorSplit && [plainTextEditors count] == 2) {
			NSSplitView *editorSplitView = self.editorSplitView;

			//Preserve scroll position of second editor, if it is currently the selected one.
			id fr = [[self.tab.tabView window] firstResponder];
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
				[self.tab setView:[plainTextEditors[0] editorView]];
				[self.tab setInitialFirstResponder:[plainTextEditors[0] editorView]];
			}

			self.editorSplitView = nil;
			PlainTextEditor *editorToClose = plainTextEditors[1];

			// show participant overlay if split gets toggled
			if ([editorToClose hasBottomOverlayView]) {
				[editorToClose displayViewControllerInBottomArea:nil];
				SEEParticipantsOverlayViewController *participantsOverlay = [[SEEParticipantsOverlayViewController alloc] initWithTabContext:self];
				[plainTextEditors[0] displayViewControllerInBottomArea:participantsOverlay];
			}

			[plainTextEditors[0] setShowsBottomStatusBar:[editorToClose showsBottomStatusBar]];
			[editorToClose prepareForDealloc];
			[plainTextEditors removeObjectAtIndex:1];
			self.editorSplitView = nil;

			// restore scroll position of second editor if it was the selected one
			if (!NSEqualRects(NSZeroRect,visibleRect)) {
				[[plainTextEditors[0] textView] scrollRectToVisible:visibleRect];
			}
		}

		[plainTextEditors[0] updateSplitButtonForIsSplit:[plainTextEditors count] != 1];

		NSTextView *textView = [plainTextEditors[0] textView];
		NSRange selectedRange = [textView selectedRange];
		[textView scrollRangeToVisible:selectedRange];

		if ([plainTextEditors count] == 2) {
			[[plainTextEditors[1] textView] scrollRangeToVisible:selectedRange];
		}

		[windowController updateWindowMinSize];
		[[windowController window] makeFirstResponder:textView];
	}
}


#pragma mark - Preview Split

- (void)updateWebPreviewSplitView {
	NSView *viewRepresentedByTab = self.tab.view;
	NSResponder *oldFirstResponder = self.tab.tabView.window.firstResponder;

	if (!self.hasWebPreviewSplit && viewRepresentedByTab == self.webPreviewSplitView) {
		NSView *webView = viewRepresentedByTab.subviews.firstObject;
		if ([oldFirstResponder isKindOfClass:[NSView class]] && [((NSView *)oldFirstResponder) isDescendantOf:webView]) {
			oldFirstResponder = self.activePlainTextEditor.textView;
		}

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
		[self.tab setView:editorView];
	} else if (self.hasWebPreviewSplit && self.webPreviewSplitView == nil) {
		[viewRepresentedByTab removeFromSuperview];

		NSSplitView *webPreviewSplitView = [[NSSplitView alloc] initWithFrame:viewRepresentedByTab.frame];
		SEEWebPreviewSplitViewDelegate* webPreviewSplitDelegate = [[SEEWebPreviewSplitViewDelegate alloc] initWithTabContext:self];
		webPreviewSplitView.identifier = @"WebPreviewSplit";
		webPreviewSplitView.delegate = webPreviewSplitDelegate;
		webPreviewSplitView.vertical = YES;
		webPreviewSplitView.dividerStyle = NSSplitViewDividerStyleThin;
		webPreviewSplitView.autoresizesSubviews = YES;
		webPreviewSplitView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		[self.tab setView:webPreviewSplitView];

		WebPreviewViewController *webPreviewViewController = [[WebPreviewViewController alloc] initWithPlainTextDocument:self.document];

		[webPreviewSplitView addSubview:webPreviewViewController.view];
		[webPreviewSplitView addSubview:viewRepresentedByTab];
		[webPreviewSplitView adjustSubviews];

		[webPreviewViewController refreshAndEmptyCache:self];

		self.webPreviewViewController = webPreviewViewController;
		self.webPreviewSplitViewDelegate = webPreviewSplitDelegate;
		self.webPreviewSplitView = webPreviewSplitView;
	}

	PlainTextWindowController *windowController = (PlainTextWindowController *)[self.tab.tabView.window windowController];
	[windowController updateWindowMinSize];
    [windowController.window makeFirstResponder:oldFirstResponder];
}



#pragma mark - Restorable State

+ (NSArray *)restorableStateKeyPaths {
	NSArray *restorableStateKeyPaths = [super restorableStateKeyPaths];
	return [restorableStateKeyPaths arrayByAddingObjectsFromArray:@[@"hasEditorSplit", @"hasWebPreviewSplit"]];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
//	NSLog(@"%s - %d : %@", __FUNCTION__, __LINE__, self.document.displayName);
	[super encodeRestorableStateWithCoder:coder];

	// The bookmarks are used by SEEDocumentController to restore the tab documents.
	NSURL *documentURL = self.document.fileURL;
	NSURL *documentAutosaveURL = self.document.autosavedContentsFileURL;

	NSData *documentURLBookmark = [documentURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
										includingResourceValuesForKeys:nil
														 relativeToURL:nil
																 error:nil];
	
	NSData *documentAutosaveURLBookmark = [documentAutosaveURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
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
	[super restoreStateWithCoder:coder];

	BOOL hasEditorSplit = [coder decodeBoolForKey:@"SEETabContextHasEditorSplit"];
	self.hasEditorSplit = hasEditorSplit;

	BOOL hasWebPreviewSplit = [coder decodeBoolForKey:@"SEETabContextHasWebPreviewSplit"];
	self.hasWebPreviewSplit = hasWebPreviewSplit;
}

@end
