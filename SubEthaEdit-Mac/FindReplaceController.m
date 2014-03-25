//  FindReplaceController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 23 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

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

NSString * const kSEEGlobalFindAndReplaceStateDefaultsKey = @"GlobalFindAndReplaceState";

static FindReplaceController *sharedInstance=nil;

@interface FindReplaceController ()
@property (nonatomic, strong) NSArray *topLevelNibObjects;

@property (nonatomic, strong) NSMutableArray *findHistory;
@property (nonatomic, strong) NSMutableArray *replaceHistory;

@property (nonatomic, strong) NSString *replaceAllFindString;
@property (nonatomic, strong) NSString *replaceAllReplaceString;
@property (nonatomic) NSRange replaceAllPosRange;
@property (nonatomic) NSRange replaceAllRange;
@property (nonatomic, strong) NSArray *replaceAllMatchArray;
@property (nonatomic, strong) NSDictionary *replaceAllAttributes;
@property (nonatomic, strong) NSMutableString *replaceAllText;
@property (nonatomic, strong) NSTextView *replaceAllTarget;
@property (nonatomic, strong) OGReplaceExpression *replaceAllRepex;
@property (nonatomic, strong) OGRegularExpression *replaceAllRegex;
@property (nonatomic) int replaceAllReplaced;
@property (nonatomic) int replaceAllArrayIndex;
@property (nonatomic) unsigned replaceAllOptions;
@property (nonatomic, strong) SelectionOperation *replaceAllSelectionOperation;

@property (nonatomic, strong) SEEFindAndReplaceState *globalFindAndReplaceState;

@end

@implementation FindReplaceController

+ (FindReplaceController *)sharedInstance {
    return sharedInstance;
}

- (id)init {
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
    }
    return self;
}

- (void) dealloc {
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

- (unsigned)currentOgreOptions {
	unsigned options = [self.globalFindAndReplaceStateController.content regexOptions];
	if (![self.globalFindAndReplaceStateController.content isCaseSensitive]) {
		ONIG_OPTION_ON(options, ONIG_OPTION_IGNORECASE);
	}
    return options;
}

// returns OgreSimpleMatchingSyntax if no regex should be used
- (OgreSyntax)currentOgreSyntax {
	OgreSyntax result = [self.globalFindAndReplaceStateController.content useRegex] ?
		[self.globalFindAndReplaceStateController.content regularExpressionSyntax] :
		OgreSimpleMatchingSyntax;
	return result;
}

- (NSString *)currentOgreEscapeCharacter {
	NSString *result = [self.globalFindAndReplaceStateController.content regularExpressionEscapeCharacter];
	return result;
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

- (void)alertForReadonlyDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
        NSDictionary *alertContext = (__bridge NSDictionary *)contextInfo;
		SEEFindAndReplaceContext *context = [alertContext objectForKey:@"FindAndReplaceContext"];
		PlainTextDocument *document = context.targetPlainTextEditor.document;
        [document setEditAnyway:YES];
        [self performTextFinderAction:context.currentTextFinderActionType context:context];
    }
}

- (void)alertForEncodingDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    NSDictionary *alertContext = (__bridge NSDictionary *)contextInfo;
	SEEFindAndReplaceContext *context = [alertContext objectForKey:@"FindAndReplaceContext"];
    PlainTextDocument *document = context.targetPlainTextEditor.document;
    if (returnCode == NSAlertThirdButtonReturn) {
        [document setFileEncoding:NSUnicodeStringEncoding];
        [[document documentUndoManager] removeAllActions];
        [self performTextFinderAction:context.currentTextFinderActionType context:context];
    } else if (returnCode == NSAlertSecondButtonReturn) {
        [document setFileEncoding:NSUTF8StringEncoding];
        [[document documentUndoManager] removeAllActions];
        [self performTextFinderAction:context.currentTextFinderActionType context:context];
    }
}

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
	if (document && ![document isFileWritable] && ![document editAnyway]) {
		// Call sheet
		NSDictionary *contextInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"EditAnywayAlert", @"Alert",
									 aFindAndReplaceContext, @"FindAndReplaceContext",
									 nil];
		
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert setMessageText:NSLocalizedString(@"Warning", nil)];
		[alert setInformativeText:NSLocalizedString(@"File is read-only", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"Edit anyway", nil)];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
		[[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
		[alert TCM_setContextObject:contextInfo];
		[alert beginSheetModalForWindow:sheetWindow
						  modalDelegate:self
						 didEndSelector:@selector(alertForReadonlyDidEnd:returnCode:contextInfo:)
							contextInfo:(__bridge void *)contextInfo];
		result = NO;
	} else {
		
		NSString *replacementString = [self currentReplaceString];
		if (![replacementString canBeConvertedToEncoding:[document fileEncoding]]) {
			TCMMMSession *session=[document session];
			if ([session isServer] && [session participantCount]<=1) {
				NSDictionary *contextInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											 @"ShouldPromoteAlert", @"Alert",
											 aFindAndReplaceContext, @"FindAndReplaceContext",
											 nil];
				
				NSAlert *alert = [[NSAlert alloc] init];
				[alert setAlertStyle:NSWarningAlertStyle];
				[alert setMessageText:NSLocalizedString(@"You are trying to insert characters that cannot be handled by the file's current encoding. Do you want to cancel the change?", nil)];
				[alert setInformativeText:NSLocalizedString(@"You are no longer restricted by the file's current encoding if you promote to a Unicode encoding.", nil)];
				[alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
				[alert addButtonWithTitle:NSLocalizedString(@"Promote to UTF8", nil)];
				[alert addButtonWithTitle:NSLocalizedString(@"Promote to Unicode", nil)];
				[[[alert buttons] objectAtIndex:0] setKeyEquivalent:@"\r"];
				[alert TCM_setContextObject:contextInfo];
				[alert beginSheetModalForWindow:sheetWindow
								  modalDelegate:self
								 didEndSelector:@selector(alertForEncodingDidEnd:returnCode:contextInfo:)
									contextInfo:(__bridge void *)contextInfo];
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
	
    id target = aTargetTextView;
	
	if (!target) return; // no target nothing to do later on if no target
	
	FoldableTextStorage *foldableTextStorage = nil;
	NSTextStorage *textStorage = [target textStorage];
	NSRange selection = [target selectedRange];
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

	/*
	id firstResponder = [[[NSApplication sharedApplication] mainWindow] firstResponder];
	if ([firstResponder isKindOfClass:[NSTextView class]]) {
		NSTextView *responderView = firstResponder;
		if (responderView.isFieldEditor) {
			if ([responderView.delegate isKindOfClass:[NSTextField class]]) {
				NSTextField *textField = (NSTextField *)responderView.delegate;
				textField.stringValue = responderView.string;
			}
		}
	}
	*/
	
	// the textfinder action now at least contains a search, maybe also a replace
	// TODO: safe this context and mabe reuse it if possible on the next action (therefore we could reuse compiled regexes and more)
	SEEFindAndReplaceContext *context = [SEEFindAndReplaceContext contextWithTextView:aTargetTextView state:self.globalFindAndReplaceState];
	context.currentTextFinderActionType = [aSender tag];
	[self performTextFinderAction:context.currentTextFinderActionType context:context];
}

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

- (void) replaceSelection
{
    BOOL found = YES;

    NSTextView *target = [self targetToFindIn];
    if (target) {
        if (![target isEditable]) {
            NSBeep();
            return;
        }
        NSString *findString = [self currentFindString];
        NSString *replaceString = [self currentReplaceString];

        NSMutableString *text = [[target textStorage] mutableString];
        NSRange selection = [target selectedRange];
        if (selection.length==0) {
            NSBeep();
            return;
        }
        
        PlainTextDocument *aDocument = (PlainTextDocument *)[[[target window] windowController] document];
        NSDictionary *attributes = [aDocument typingAttributes];
        
        [[aDocument session] pauseProcessing];
        [[target textStorage] beginEditing];
        
        if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) {
            [[aDocument documentUndoManager] beginUndoGrouping];
            [self saveFindStringToPasteboard];
            [text replaceCharactersInRange:selection withString:replaceString];
            [[target textStorage] addAttributes:attributes range:NSMakeRange(selection.location, [replaceString length])];
            selection.location = selection.location + [replaceString length];
            selection.length = 0;
        } else {
            // This might not work for lookahead etc.
            OGRegularExpression *regex = nil;
            @try{
            regex = [OGRegularExpression regularExpressionWithString:findString
                                            options:[self currentOgreOptions]
                                            syntax:[self currentOgreSyntax]
                                            escapeCharacter:[self currentOgreEscapeCharacter]];
            } @catch (NSException *exception) {NSBeep();}
            OGRegularExpressionMatch * aMatch = [regex matchInString:text options:[self currentOgreOptions] range:selection];
            if (aMatch != nil) {
                [[aDocument documentUndoManager] beginUndoGrouping];
                OGReplaceExpression *repex = [OGReplaceExpression replaceExpressionWithString:replaceString];
                NSRange matchedRange = [aMatch rangeOfMatchedString];
                NSString *replaceWith = [repex replaceMatchedStringOf:aMatch];
                [text replaceCharactersInRange:matchedRange withString:replaceWith];
                [[target textStorage] addAttributes:attributes range:NSMakeRange(matchedRange.location, [replaceWith length])];
                selection.location = selection.location + [replaceWith length];
                selection.length = 0;
            } else {
                NSBeep();
                found=NO;
            }
        }
        
        [[target textStorage] endEditing];
        if (found) [[aDocument documentUndoManager] endUndoGrouping];
        [[aDocument session] startProcessing];
        
        [target setSelectedRange:selection];
    }
}

- (void)lockDocument:(PlainTextDocument *)aDocument {
    NSEnumerator *plainTextEditors=[[aDocument plainTextEditors] objectEnumerator];
    PlainTextEditor *editor=nil;
    while ((editor=[plainTextEditors nextObject])) {
        [[editor textView] setEditable:NO];
    }
}

- (void)unlockDocument:(PlainTextDocument *)aDocument {
    NSEnumerator *plainTextEditors=[[aDocument plainTextEditors] objectEnumerator];
    PlainTextEditor *editor=nil;
    while ((editor=[plainTextEditors nextObject])) {
        [[editor textView] setEditable:YES];
    }
}

- (void) replaceAFewPlainMatches
{
    const int replacePerCycle = 100;
    int i = replacePerCycle;
    TCMMMTransformator *transformator=[TCMMMTransformator sharedInstance];

    [[_replaceAllTarget textStorage] beginEditing];
    if (_replaceAllReplaced>0) {
        [self setStatusString:[NSString stringWithFormat:NSLocalizedString(@"%d replaced.",@"Number of replaced strings"), _replaceAllReplaced]];
	}
    while (YES) {
        i--;
        if (i<0) break;
        
        
        NSRange foundRange = [_replaceAllText findString:_replaceAllFindString selectedRange:_replaceAllPosRange options:_replaceAllOptions wrap:NO];
        if (foundRange.length) {
            if (foundRange.location < _replaceAllRange.location) {
                _replaceAllPosRange = NSMakeRange(0,0);
                break;
            }
            if (_replaceAllReplaced==0) {
                PlainTextDocument *aDocument = (PlainTextDocument *)[[[_replaceAllTarget window] windowController] document];
                [[aDocument session] pauseProcessing];
                [self lockDocument:aDocument];
                [[aDocument documentUndoManager] beginUndoGrouping];
            }
            [_replaceAllText replaceCharactersInRange:foundRange withString:_replaceAllReplaceString];

            [transformator transformOperation:_replaceAllSelectionOperation serverOperation:[TextOperation textOperationWithAffectedCharRange:foundRange replacementString:_replaceAllReplaceString userID:[TCMMMUserManager myUserID]]];

            [[_replaceAllTarget textStorage] addAttributes:_replaceAllAttributes range:NSMakeRange(foundRange.location, [_replaceAllReplaceString length])];
            _replaceAllReplaced++;
            _replaceAllPosRange.location = foundRange.location;
        }

        if (!foundRange.length) {
            [[_replaceAllTarget textStorage] endEditing];
            _replaceAllFindString = nil;
            _replaceAllReplaceString = nil;
            _replaceAllTarget = nil;
            _replaceAllText = nil;
            _replaceAllAttributes = nil;
            
            PlainTextDocument *aDocument = (PlainTextDocument *)[[[_replaceAllTarget window] windowController] document];
            
            [aDocument selectRange:[_replaceAllSelectionOperation selectedRange]];
            _replaceAllSelectionOperation = nil;
            
            if (_replaceAllReplaced==0) {
				[self signalErrorWithDescription:NSLocalizedString(@"Not found.",@"Find string not found")];
            } else {
                [self setStatusString:[NSString stringWithFormat:NSLocalizedString(@"%d replaced.",@"Number of replaced strings"), _replaceAllReplaced]];
                [[aDocument documentUndoManager] endUndoGrouping];
                [[aDocument session] startProcessing];
                [self unlockDocument:aDocument];
            }
            _replaceAllTarget = nil;
            return;
        }
    }
    
    [[_replaceAllTarget textStorage] endEditing];    
    [self performSelector:@selector(replaceAFewPlainMatches) withObject:nil afterDelay:0.1];
}

- (void) replaceAFewMatches
{
    const int replacePerCycle = 50;
    int i;
    int index = _replaceAllArrayIndex;
    TCMMMTransformator *transformator=[TCMMMTransformator sharedInstance];

    [[_replaceAllTarget textStorage] beginEditing];
        
    for (i = index; i >= MAX(index-replacePerCycle,0); i--) {
        OGRegularExpressionMatch *aMatch = [_replaceAllMatchArray objectAtIndex:i];
        NSRange matchedRange = [aMatch rangeOfMatchedString];
        NSString *replaceWith = [_replaceAllRepex replaceMatchedStringOf:aMatch];

        if (_replaceAllReplaced==0) {
            PlainTextDocument *aDocument = (PlainTextDocument *)[[[_replaceAllTarget window] windowController] document];
            [[aDocument session] pauseProcessing];
            [self lockDocument:aDocument];
            [[aDocument documentUndoManager] beginUndoGrouping];
        }

        [_replaceAllText replaceCharactersInRange:matchedRange withString:replaceWith];

        [transformator transformOperation:_replaceAllSelectionOperation serverOperation:[TextOperation textOperationWithAffectedCharRange:matchedRange replacementString:replaceWith userID:[TCMMMUserManager myUserID]]];

        
        NSRange newRange = NSMakeRange(matchedRange.location, [replaceWith length]);
        [[_replaceAllTarget textStorage] addAttributes:_replaceAllAttributes range:newRange];
        _replaceAllReplaced++;
        [O_progressIndicatorDet setDoubleValue:(double)_replaceAllReplaced];
    }
    
    _replaceAllArrayIndex = i;
    
    if (_replaceAllArrayIndex > 0) { // Not ready yet
        [self performSelector:@selector(replaceAFewMatches) withObject:nil afterDelay:0.02];
    } else { // Ready.
        [[_replaceAllTarget textStorage] endEditing];
        _replaceAllMatchArray = nil;
        _replaceAllText = nil;
        _replaceAllRepex = nil;
        _replaceAllRegex = nil;
        _replaceAllAttributes = nil;
        
        PlainTextDocument *aDocument = (PlainTextDocument *)[[[_replaceAllTarget window] windowController] document];
        
        [aDocument selectRange:[_replaceAllSelectionOperation selectedRange]];
        _replaceAllSelectionOperation = nil;
        
        if (_replaceAllReplaced==0) {
			[self signalErrorWithDescription:NSLocalizedString(@"Not found.",@"Find string not found")];
            NSBeep();
        } else {
            [[aDocument documentUndoManager] endUndoGrouping];
            [self unlockDocument:aDocument];
            [[aDocument session] startProcessing];
            [self setStatusString:[NSString stringWithFormat:NSLocalizedString(@"%d replaced.",@"Number of replaced strings"), _replaceAllReplaced]];
        }
        [O_progressIndicatorDet stopAnimation:nil];
        [O_progressIndicatorDet setHidden:YES];
        [O_progressIndicatorDet display];
        return;
    }
    [[_replaceAllTarget textStorage] endEditing];
}

- (void)replaceAllInTextView:(NSTextView *)aTarget findAndReplaceState:(SEEFindAndReplaceState *)aFindAndReplaceState ranges:(NSArray *)aRangesArray {
    _replaceAllReplaced = 0;
    NSTextView *target = aTarget;
    NSString *findString = aFindAndReplaceState.findString;
    NSString *replaceString = aFindAndReplaceState.replaceString;

	// TODO: remove - is temporary
	NSRange aRange = [aRangesArray.firstObject rangeValue];
	
    if (target) {
		[self setStatusString:@""];
		if ((![target isEditable])||([aRangesArray.firstObject rangeValue].length==0)) {
            [O_progressIndicator stopAnimation:nil];
            NSBeep();
            return;
        }
		NSTextStorage *textStorageToEdit = [aTarget textStorage];
		if ([textStorageToEdit isKindOfClass:[FoldableTextStorage class]]) {
			textStorageToEdit = [(FoldableTextStorage *)textStorageToEdit fullTextStorage];
		}
		
        NSMutableString *text = [textStorageToEdit mutableString];
        PlainTextDocument *aDocument = (PlainTextDocument *)[[(SEETextView *)target editor] document];
        NSDictionary *attributes = [aDocument typingAttributes];
        
        _replaceAllAttributes = attributes;
        
        _replaceAllSelectionOperation = [SelectionOperation new];
        [_replaceAllSelectionOperation setSelectedRange:[target selectedRange]];
        
        if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) {
            [self saveFindStringToPasteboard];
            unsigned options = NSLiteralSearch|NSBackwardsSearch;
            if (!self.globalFindAndReplaceState.caseSensitive) options |= NSCaseInsensitiveSearch;
            
            _replaceAllOptions = options;
            _replaceAllPosRange = NSMakeRange(NSMaxRange(aRange),0);
            _replaceAllFindString = findString;
            _replaceAllReplaceString = replaceString;
            _replaceAllRange = aRange;
            _replaceAllText = text;
            _replaceAllTarget = target;

            [self replaceAFewPlainMatches];

        } else {
        
            [O_progressIndicatorDet setIndeterminate:YES];
            [O_progressIndicatorDet setHidden:NO];
            [O_progressIndicatorDet startAnimation:nil];
    
            
            if (![OGRegularExpression isValidExpressionString:findString]) {
                [O_progressIndicator stopAnimation:nil];
                [self setStatusString:NSLocalizedString(@"Invalid regex",@"InvalidRegex")];
                [O_progressIndicator stopAnimation:nil];
                [O_progressIndicatorDet setHidden:YES];
                NSBeep();
                return;
            }
                
            @try{
            OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:findString
                                     options:[self currentOgreOptions]
                                     syntax:[self currentOgreSyntax]
                                     escapeCharacter:[self currentOgreEscapeCharacter]];
    
            OGReplaceExpression *repex = [OGReplaceExpression replaceExpressionWithString:replaceString];
            
			unsigned ogreoptions = [self currentOgreOptions];
            NSArray *matchArray = [regex allMatchesInString:text options:ogreoptions range:aRange];
            
            _replaceAllRepex = repex;
            _replaceAllRegex = regex;
            _replaceAllMatchArray = matchArray;
            _replaceAllText = text;
            _replaceAllTarget = target;
            
            int count = [matchArray count];
            _replaceAllArrayIndex = count - 1;
            [O_progressIndicatorDet setMaxValue:count];
            [O_progressIndicatorDet setMinValue:0];
            [O_progressIndicatorDet setDoubleValue:0];
            [O_progressIndicatorDet setIndeterminate:NO];
            
                        
            [self replaceAFewMatches];
            } @catch (NSException *exception) {
                NSBeep();
            }

            
        }
    }
}

- (void)findNextAndOrderOut:(id)sender  {
    // NSComboBox's action sending behavior is very albern.
    // Action does get sent on click, but not on pressing enter in history dropdown...
    NSEvent *currentEvent = [NSApp currentEvent];
    if ([currentEvent type]==NSKeyDown) {
        if ([self find:[self currentFindString] forward:YES]) {
			// TODO: order out the view
		}
    }
	[self saveGlobalFindAndReplaceStateToPreferences];
}

// ranges always refer to the fulltextstorage so we need to convert here or use the views editor
- (void)selectAndHighlightRange:(NSRange)aRange inTarget:(id)aTarget {
	PlainTextEditor *editor = [aTarget editor];
	[editor selectRangeInBackground:aRange];
}

- (BOOL)find:(NSString*)findString forward:(BOOL)forward {
    BOOL found = NO;

	@autoreleasepool {
		[O_progressIndicator startAnimation:nil];
		
		BOOL useRegex = ([self currentOgreSyntax] != OgreSimpleMatchingSyntax);
		
		// Check for invalid RegEx
		if (useRegex && (![OGRegularExpression isValidExpressionString:findString])) {
			[O_progressIndicator stopAnimation:nil];
			[self signalErrorWithDescription:NSLocalizedString(@"Invalid regex",@"InvalidRegex")];
			return NO;
		}
		
		
		OGRegularExpression *regex = nil;
		@try{
			regex = [OGRegularExpression regularExpressionWithString:findString
															 options:[self currentOgreOptions]
															  syntax:[self currentOgreSyntax]
													 escapeCharacter:[self currentOgreEscapeCharacter]];
		} @catch (NSException *exception) { NSBeep(); }
		
		NSTextView *target = [self targetToFindIn];
		if (target) {
			NSRange scope = {NSNotFound, 0};
			
			FoldableTextStorage *textStorage = (FoldableTextStorage *)[target textStorage];
			NSString *text = [[textStorage fullTextStorage] string];
			NSRange selection = [textStorage fullRangeForFoldedRange:[target selectedRange]];
			
			
			if (NO) { // TODO: make it work in scopes
				scope = selection;
			}
			else {
				scope = NSMakeRange(0,[text length]);
			}
			
			
			OGRegularExpressionMatch *aMatch = nil;
			NSEnumerator *enumerator;
			
			if (forward) {
				if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) {
					[self saveFindStringToPasteboard];
					unsigned options = NSLiteralSearch;
					if (!self.globalFindAndReplaceState.caseSensitive) options |= NSCaseInsensitiveSearch;
					BOOL wrap = self.globalFindAndReplaceState.shouldWrap;
					
					NSRange foundRange;
					// Check for scoping, as findString:selectedRange:options:wrap:
					// only makes sense for scope:document.
					if (NO) { // TODO: make it work in scopes
						foundRange = [text rangeOfString:findString options:options range:scope];
					} else foundRange = [text findString:findString selectedRange:selection options:options wrap:wrap];
					
					if (foundRange.length) {
						found = YES;
						[self selectAndHighlightRange:foundRange inTarget:target];
					} else {NSBeep();}
					
				} else {
					NSRange findRange;
					unsigned searchTimeOptions = 0;
					if (NO) { // selection scope
							  // TODO: make it work in scopes
						findRange = scope;
					} else {
						findRange = NSMakeRange(NSMaxRange(selection), [text length] - NSMaxRange(selection));
						if (findRange.location > 0) {
							unichar previousCharacter = [text characterAtIndex:findRange.location - 1];
							switch (previousCharacter) { // check if previous character is a newline characte
								case 0x2028:
								case 0x2029:
								case '\n':
								case '\r':
									break;
								default:
									searchTimeOptions |= OgreNotBOLOption;
							}
						}
					}
					@try{
						enumerator=[regex matchEnumeratorInString:text options:searchTimeOptions range:findRange];
					} @catch (NSException *exception) { NSBeep(); }
					
					aMatch = [enumerator nextObject];
					if (aMatch != nil) {
						found = YES;
						NSRange foundRange = [aMatch rangeOfMatchedString];
						[self selectAndHighlightRange:foundRange inTarget:target];
					} else if (self.globalFindAndReplaceState.shouldWrap) {
						@try{
							enumerator = [regex matchEnumeratorInString:text options:[self currentOgreOptions] range:NSMakeRange(0,NSMaxRange(selection))];
						} @catch (NSException *exception) { NSBeep(); }
						
						aMatch = [enumerator nextObject];
						if (aMatch != nil) {
							found = YES;
							NSRange foundRange = [aMatch rangeOfMatchedString];
							[self selectAndHighlightRange:foundRange inTarget:target];
						} else {NSBeep();}
					} else {NSBeep();}
				}
			} else { // backwards
				if ([self currentOgreSyntax]==OgreSimpleMatchingSyntax) {
					// If we are just simple searching, use NSBackwardsSearch because Regex Searching is sloooow backwards.
					[self saveFindStringToPasteboard];
					unsigned options = NSLiteralSearch|NSBackwardsSearch;
					if (!self.globalFindAndReplaceState.caseSensitive) options |= NSCaseInsensitiveSearch;
					BOOL wrap = self.globalFindAndReplaceState.shouldWrap;
					
					NSRange foundRange;
					// Check for scoping, as findString:selectedRange:options:wrap:
					// only makes sense for scope:document.
					if (NO) { // TODO: make it work in scopes
						foundRange = [text rangeOfString:findString options:options range:scope];
					} else foundRange = [text findString:findString selectedRange:selection options:options wrap:wrap];
					if (foundRange.length) {
						found = YES;
						[self selectAndHighlightRange:foundRange inTarget:target];
					} else {NSBeep();}
				} else {
					NSRange findRange;
					if (NO) { // TODO: make it work in scopes
						findRange = scope;
					} else {
						findRange = NSMakeRange(0, selection.location);
					}
					NSArray *matchArray = nil;
                    @try{
                        matchArray = [regex allMatchesInString:text options:[self currentOgreOptions] range:findRange];
                    } @catch (NSException *exception) { NSBeep(); }
					
					if ([matchArray count] > 0) {
						aMatch = [matchArray objectAtIndex:([matchArray count] - 1)];
					}
					if (aMatch != nil) {
						found = YES;
						NSRange foundRange = [aMatch rangeOfMatchedString];
						[self selectAndHighlightRange:foundRange inTarget:target];
					} else if (self.globalFindAndReplaceState.shouldWrap) {
						NSArray *matchArray = [regex allMatchesInString:text options:[self currentOgreOptions] range:NSMakeRange(selection.location, [text length] - selection.location)];
						if ([matchArray count] > 0) aMatch = [matchArray objectAtIndex:([matchArray count] - 1)];
						if (aMatch != nil) {
							found = YES;
							NSRange foundRange = [aMatch rangeOfMatchedString];
							[self selectAndHighlightRange:foundRange inTarget:target];
						}
					}
					
				}
			}
		}
		
		[O_progressIndicator stopAnimation:nil];
		if (!found){
			[self signalErrorWithDescription:NSLocalizedString(@"Not found.",@"Find string not found")];
		}
	}
    return found;
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
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
    if ([[pasteboard types] containsObject:NSStringPboardType]) {
        result = [pasteboard stringForType:NSStringPboardType];
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
		NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
		[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
		[pasteboard setString:currentFindString forType:NSStringPboardType];
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

