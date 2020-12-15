//  FindReplaceController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 23 2004.

#import "OgreKit/OgreKit.h"
#import "FindReplaceController.h"
#import "PlainTextWindowController.h"
#import "PlainTextDocument.h"
#import "PlainTextEditor.h"
#import "SEETextView.h"
#import "TCMMMSession.h"
#import "FoldableTextStorage.h"
#import "FindAllController.h"
#import "UndoManager.h"
#import "time.h"
#import "TextOperation.h"
#import <objc/objc-runtime.h>
#import "SEEFindAndReplaceContext.h"

NSString * const kSEEGlobalFindAndReplaceStateDefaultsKey = @"FindAndReplace_GlobalState";
NSString * const kSEEFindAndReplaceHistoryDefaultsKey     = @"FindAndReplace_History";

static FindReplaceController *sharedInstance=nil;

@interface FindReplaceController ()
@property (nonatomic, strong) NSArray *topLevelNibObjects;

@property (nonatomic, strong) NSMutableArray *findHistory;
@property (nonatomic, strong) NSMutableArray *replaceHistory;

@property (nonatomic, strong) SEEFindAndReplaceState *globalFindAndReplaceState;
@property (nonatomic, strong) NSMutableArray *internalfindReplaceHistory;
@end

@implementation FindReplaceController

+ (FindReplaceController *)sharedInstance {
    return sharedInstance;
}

- (instancetype)init {
    if (sharedInstance) {
 		self = nil;
        return sharedInstance;
    }
    
    self = [super init];
    if (self) {
        sharedInstance = self;
        _findHistory = [NSMutableArray new];
        _replaceHistory = [NSMutableArray new];
		self.globalFindAndReplaceState = [SEEFindAndReplaceState new];
		[self readGlobalFindAndReplaceStateFromPreferences];
		self.globalFindAndReplaceStateController = [[NSObjectController alloc] initWithContent:self.globalFindAndReplaceState];
		self.internalfindReplaceHistory = [NSMutableArray new];
		[self readFindAndReplaceHistoryFromPreferences];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidBecomeActiveNotification object:[NSApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillResignActiveNotification object:[NSApplication sharedApplication]];
	self.topLevelNibObjects = nil;
}

- (void)ensureUI {
    if (!O_gotoPanel) {
		NSArray *topLevelNibObjects = nil;
        if (![[NSBundle mainBundle] loadNibNamed:@"FindReplace" owner:self topLevelObjects:&topLevelNibObjects]) {
            NSBeep();
        } else {
			self.topLevelNibObjects = topLevelNibObjects;
		}
    }
}

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidActivate:) name:NSApplicationDidBecomeActiveNotification object:[NSApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResign:) name:NSApplicationWillResignActiveNotification object:[NSApplication sharedApplication]];
}

- (NSPanel *)gotoPanel {
    [self ensureUI];
    return O_gotoPanel;
}

- (NSPanel *)tabWidthPanel {
    [self ensureUI];
    return O_tabWidthPanel;
}

- (IBAction)orderFrontTabWidthPanel:(id)aSender {
	PlainTextDocument *document=(PlainTextDocument *)[[[[self targetToFindIn] window] windowController] document];
    if (document) {
        NSPanel *panel = [self tabWidthPanel];
        [O_tabWidthTextField setIntValue:[document tabWidth]];
        [O_tabWidthTextField selectText:nil];
        [panel makeKeyAndOrderFront:nil];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
	BOOL result = ([self targetDocument] != nil);
	if (result) {
		if (anItem.tag == NSTextFinderActionReplace ||
			anItem.tag == NSTextFinderActionReplaceAndFind ||
			anItem.tag == NSTextFinderActionReplaceAll) {
			if (![self targetToFindIn].isEditable) {
				result = NO;
			}
		}
	}
    return result;
}

- (IBAction)chooseTabWidth:(id)aSender {
    PlainTextDocument *document = [self targetDocument];
    int tabWidth=[O_tabWidthTextField intValue];
    if (tabWidth>0) {
        [document setTabWidth:tabWidth];
        [[self tabWidthPanel] orderOut:self];   
    }
}

- (IBAction)orderFrontGotoPanel:(id)aSender {
    NSPanel *panel = [self gotoPanel];
    [[O_gotoLineTextField cell] setSendsActionOnEndEditing:NO];
    [O_gotoLineTextField selectText:nil];
    [panel makeKeyAndOrderFront:nil];    
    [[O_gotoLineTextField cell] setSendsActionOnEndEditing:YES];
}

#pragma mark -

- (IBAction)gotoLine:(id)aSender {
    NSTextView *textView = [self targetToFindIn];
    [(PlainTextWindowController *)[[textView window] windowController] gotoLine:[O_gotoLineTextField intValue]];

}

- (IBAction)gotoLineAndClosePanel:(id)aSender {
    [self gotoLine:aSender];
    [[self gotoPanel] orderOut:self];   
}

- (SEETextView *)targetToFindIn {
	NSWindowController *windowController = [[NSApp mainWindow] windowController];
	SEETextView *result = nil;
	if (windowController && [windowController respondsToSelector:@selector(activePlainTextEditor)]) {
		result = (SEETextView *)[[(PlainTextWindowController *)windowController activePlainTextEditor] textView];
	}
    return result;
}

- (PlainTextDocument *)targetDocument {
	NSWindowController *windowController = [[NSApp mainWindow] windowController];
	PlainTextDocument *result = [windowController document];
	if (result && ![result isKindOfClass:[PlainTextDocument class]]) {
		result = nil;
	}
	return result;
}

#pragma mark - User Defaults Management

- (void)saveGlobalFindAndReplaceStateToPreferences {
    [[NSUserDefaults standardUserDefaults] setObject:self.globalFindAndReplaceState.dictionaryRepresentation forKey:kSEEGlobalFindAndReplaceStateDefaultsKey];
}

- (void)readGlobalFindAndReplaceStateFromPreferences {
	NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSEEGlobalFindAndReplaceStateDefaultsKey];
	SEEFindAndReplaceState *globalState = self.globalFindAndReplaceState;
	if (prefs) {
		[globalState takeValuesFromDictionaryRepresentation:prefs];
	}
}

- (void)readFindAndReplaceHistoryFromPreferences {
	NSArray *history= [[NSUserDefaults standardUserDefaults] arrayForKey:kSEEFindAndReplaceHistoryDefaultsKey];
	for (NSDictionary *dictionary in history) {
		SEEFindAndReplaceState *state = [SEEFindAndReplaceState new];
		[state takeValuesFromDictionaryRepresentation:dictionary];
		[self.internalfindReplaceHistory addObject:state];
	}
}

- (void)saveFindAndReplaceHistoryToPreferences {
	NSArray *arrayToStore = [self.internalfindReplaceHistory valueForKeyPath:@"dictionaryRepresentation"];
	[[NSUserDefaults standardUserDefaults] setObject:arrayToStore forKey:kSEEFindAndReplaceHistoryDefaultsKey];
}

#pragma mark - History Management

- (NSArray *)findReplaceHistory {
	NSArray *result = [self.internalfindReplaceHistory copy];
	return result;
}

- (void)storeFindeReplaceStateInHistory:(SEEFindAndReplaceState *)aFindReplaceState {
	NSDictionary *thisDictionary = [aFindReplaceState dictionaryRepresentation];
	NSArray *representationArray = [self.internalfindReplaceHistory valueForKeyPath:@"dictionaryRepresentation"];
	NSUInteger index = [representationArray indexOfObject:thisDictionary];
	BOOL needsStoring = NO;
	if (index == NSNotFound) {
		[self.internalfindReplaceHistory insertObject:[aFindReplaceState copy] atIndex:0];
		needsStoring = YES;
	} else if (index != 0) {
		SEEFindAndReplaceState *state = self.internalfindReplaceHistory[index];
		[self.internalfindReplaceHistory removeObjectAtIndex:index];
		[self.internalfindReplaceHistory insertObject:state atIndex:0];
		needsStoring = YES;
	}
	if (self.internalfindReplaceHistory.count > 30) {
		[self.internalfindReplaceHistory removeLastObject];
	}
	if (needsStoring) {
		[self saveFindAndReplaceHistoryToPreferences];
	}
}

- (void)takeGlobalFindAndReplaceStateValuesFromState:(SEEFindAndReplaceState *)aFindAndReplaceState {
	self.globalFindAndReplaceState = [aFindAndReplaceState copy];
	[self.globalFindAndReplaceStateController setContent:self.globalFindAndReplaceState];
}

#pragma mark -

- (NSString *)currentReplaceString {
	NSString *result;// = [O_replaceComboBox stringValue];
	result = self.globalFindAndReplaceState.replaceString;
	return result;
}

- (void)setCurrentReplaceString:(NSString *)aString {
	[self.globalFindAndReplaceStateController setValue:aString forKeyPath:@"content.replaceString"];
}

- (NSString *)currentFindString {
	NSString *result;// = [O_findComboBox stringValue];
	result = self.globalFindAndReplaceState.findString;
	return result;
}

- (void)setCurrentFindString:(NSString *)aString {
	[self.globalFindAndReplaceStateController setValue:aString forKeyPath:@"content.findString"];
	[self saveFindStringToPasteboard];
}

- (void)performFindPanelAction:(id)sender {
	id targetTextView = [self targetToFindIn];
    [self performFindPanelAction:sender inTargetTextView:targetTextView];
}

/*! @return an array of full ranges of the search area*/
- (NSArray *)rangesForScopeInTextView:(NSTextView *)aTextView {
	NSArray *result = nil;
	if ([aTextView isKindOfClass:[SEETextView class]]) {
		result = [(SEETextView *)aTextView searchScopeRanges];
	} else {
		result = @[[NSValue valueWithRange:NSMakeRange(0, aTextView.textStorage.length)]];
	}
	return result;
}

/*! @return YES if the replacement can be done - e.g. the document is writable and the encoding allowes for all the replacement characters, NO otherwise */
- (BOOL)testValidityOfReplacementAndReportToUserForContext:(SEEFindAndReplaceContext *)aFindAndReplaceContext {
	BOOL result = YES;
	PlainTextDocument *document = aFindAndReplaceContext.targetPlainTextEditor.document;
	NSWindow *sheetWindow = aFindAndReplaceContext.targetTextView.window;
	if (document &&
		![document isFileWritable] &&
		![document editAnyway]) {
		// Call sheet
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSAlertStyleWarning];
		[alert setMessageText:NSLocalizedString(@"Warning", nil)];
		[alert setInformativeText:NSLocalizedString(@"File is read-only", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"Edit anyway", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];

		[alert beginSheetModalForWindow:sheetWindow completionHandler:^(NSModalResponse returnCode) {
			if (returnCode != NSAlertFirstButtonReturn) {
				return;
			}
			
			PlainTextDocument *document = aFindAndReplaceContext.targetPlainTextEditor.document;
			[document setEditAnyway:YES];

			[self performTextFinderAction:aFindAndReplaceContext.currentTextFinderActionType context:aFindAndReplaceContext];
		}];

		result = NO;
	} else {

		NSString *replacementString = [self currentReplaceString];
		if (replacementString && ![replacementString canBeConvertedToEncoding:[document fileEncoding]]) {
			TCMMMSession *session=[document session];
			if ([session isServer] && [session participantCount]<=1) {
				NSAlert *alert = [[NSAlert alloc] init];
				[alert setAlertStyle:NSAlertStyleWarning];
				[alert setMessageText:NSLocalizedString(@"You are trying to insert characters that cannot be handled by the file's current encoding. Do you want to cancel the change?", nil)];
				[alert setInformativeText:NSLocalizedString(@"You are no longer restricted by the file's current encoding if you promote to a Unicode encoding.", nil)];
				[alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
				[alert addButtonWithTitle:NSLocalizedString(@"Promote to UTF8", nil)];
				[alert addButtonWithTitle:NSLocalizedString(@"Promote to Unicode", nil)];

				[alert beginSheetModalForWindow:sheetWindow completionHandler:^(NSModalResponse returnCode) {
					PlainTextDocument *document = aFindAndReplaceContext.targetPlainTextEditor.document;

					if (returnCode == NSAlertThirdButtonReturn) {
						[document setFileEncoding:NSUnicodeStringEncoding];
						[[document documentUndoManager] removeAllActions];
						[self performTextFinderAction:aFindAndReplaceContext.currentTextFinderActionType context:aFindAndReplaceContext];
					} else if (returnCode == NSAlertSecondButtonReturn) {
						[document setFileEncoding:NSUTF8StringEncoding];
						[[document documentUndoManager] removeAllActions];
						[self performTextFinderAction:aFindAndReplaceContext.currentTextFinderActionType context:aFindAndReplaceContext];
					}
				}];

				result = NO;
			} else {
				// this is not our document and therefore we can't improve the encoding
				[self signalErrorWithDescription:nil];
			}
		}
	}
	return result;
}

- (NSString *)statusString {
	return [self.globalFindAndReplaceStateController valueForKeyPath:@"content.statusString"];
}

- (void)setStatusString:(NSString *)aString {
	[self.globalFindAndReplaceStateController setValue:[aString copy] forKeyPath:@"content.statusString"];
}

- (void)signalErrorWithDescription:(NSString *)aDescription {
	NSBeep();
	if (aDescription) {
		[self setStatusString:aDescription];
	}
}

- (void)performFindPanelAction:(id)aSender inTargetTextView:(NSTextView *)aTargetTextView {
	// clear UI
	[self setStatusString:@""];

	// first the actions that don't need anything
	if ([aSender tag]==NSTextFinderActionShowFindInterface) {
		return;
    }
	
	if (!aTargetTextView) return; // no target nothing to do later on if no target
	
	FoldableTextStorage *foldableTextStorage = nil;
	NSTextStorage *textStorage = [aTargetTextView textStorage];
	NSRange selection = [aTargetTextView selectedRange];
	if ([textStorage isKindOfClass:[FoldableTextStorage class]]) {
		foldableTextStorage = (FoldableTextStorage *)textStorage;
		textStorage = [foldableTextStorage fullTextStorage];
		selection = [foldableTextStorage fullRangeForFoldedRange:selection];
	}
	NSString *text = [textStorage string];
	
	if ([aSender tag]==NSTextFinderActionSetSearchString) {
		[self setCurrentFindString:[text substringWithRange:selection]];
 		return;
    } else if ([aSender tag]==TCMTextFinderActionSetReplaceString) {
		[self setCurrentReplaceString:[text substringWithRange:selection]];
		return;
    }

	// the textfinder action now at least contains a search, maybe also a replace
	// TODO: safe this context and mabe reuse it if possible on the next action (therefore we could reuse compiled regexes and more)
	SEEFindAndReplaceContext *context = [SEEFindAndReplaceContext contextWithTextView:aTargetTextView state:self.globalFindAndReplaceState];
	[self performTextFinderAction:[aSender tag] context:context];
}

- (void)performTextFinderAction:(NSInteger)aTextFinderActionType textView:(SEETextView *)aTextView {
	SEEFindAndReplaceContext *context = [SEEFindAndReplaceContext contextWithTextView:aTextView state:self.globalFindAndReplaceState];
	[self performTextFinderAction:aTextFinderActionType context:context];
}


/*! funnel point for all search and replace actions */
- (void)performTextFinderAction:(NSInteger)aTextFinderActionType context:(SEEFindAndReplaceContext *)aContext {
	
	aContext.currentTextFinderActionType = aTextFinderActionType; // seems redundant in the current flow, but needs to be set here so this method might be called from other places as well. all a little crufty refactoring in progress
	// Check for replace operation in case it's a read-only file or the insertion text needs the encoding to be promoted first.
	if (aContext.textFinderActionWantsToReplaceText) {
		if (![self testValidityOfReplacementAndReportToUserForContext:aContext]) {
			return;
		}
	}
    
	// now let us deal with the different search and replace actions possible
	BOOL result = [aContext performCurrentTextFinderAction];
    if (result) {
		[self saveGlobalFindAndReplaceStateToPreferences];
	}
}

// ranges always refer to the fulltextstorage so we need to convert here or use the views editor
- (void)selectAndHighlightRange:(NSRange)aRange inTarget:(id)aTarget {
	PlainTextEditor *editor = [aTarget editor];
	[editor selectRangeInBackground:aRange];
}

#pragma mark -
#pragma mark ### Notification handling ###

- (void)applicationDidActivate:(NSNotification *)notification {
    //if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax)
	[self loadFindStringFromPasteboard];
}

- (void)applicationWillResign:(NSNotification *)notification {
    //if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax)
	[self saveFindStringToPasteboard];
}

- (NSString *)pasteboardFindString {
	NSString *result = nil;
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSPasteboardNameFind];
    if ([[pasteboard types] containsObject:NSPasteboardTypeString]) {
        result = [pasteboard stringForType:NSPasteboardTypeString];
	}
	return result;
}

- (void)loadFindStringFromPasteboard {
	NSString *findString = [self pasteboardFindString];
	if (findString && findString.length > 0) {
		[self setCurrentFindString:findString];
	}
}

- (void)saveFindStringToPasteboard {
	NSString *currentFindString = [self currentFindString];
	NSString *pasteboardFindString = [self pasteboardFindString];
	if (currentFindString && ![currentFindString isEqualToString:pasteboardFindString]) {
		NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSPasteboardNameFind];
		[pasteboard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
		[pasteboard setString:currentFindString forType:NSPasteboardTypeString];
	}
}

@end 

@implementation NSString (NSStringTextFinding)

- (NSRange)findString:(NSString *)string selectedRange:(NSRange)selectedRange options:(unsigned)options wrap:(BOOL)wrap {
    BOOL forwards = (options & NSBackwardsSearch) == 0;
    unsigned length = [self length];
    NSRange searchRange, range;

    if (forwards) {
	searchRange.location = NSMaxRange(selectedRange);
	searchRange.length = length - searchRange.location;
	range = [self rangeOfString:string options:options range:searchRange];
        if ((range.length == 0) && wrap) {	/* If not found look at the first part of the string */
            searchRange.location = 0;
            searchRange.length = NSMaxRange(selectedRange);
            range = [self rangeOfString:string options:options range:searchRange];
        }
    } else {
	searchRange.location = 0;
	searchRange.length = selectedRange.location;
        range = [self rangeOfString:string options:options range:searchRange];
        if ((range.length == 0) && wrap) {
            searchRange.location = selectedRange.location;
            searchRange.length = length - searchRange.location;
            range = [self rangeOfString:string options:options range:searchRange];
        }
    }
    return range;
}    

@end

