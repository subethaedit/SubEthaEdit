//  SEEFindAndReplaceContext.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 24.03.14.

#import "SEEFindAndReplaceContext.h"
#import "FullTextStorage.h"
#import "FoldableTextStorage.h"
#import "PlainTextDocument.h"
#import "FindAllController.h"

typedef NS_ENUM(uint8_t, SEESearchRangeDirection) {
	kSEESearchRangeDirectionForward,
	kSEESearchRangeDirectionBackward,
};

@interface SEEFindAndReplaceSubRange : NSObject
@property (nonatomic, strong) FullTextStorage *textStorage;
@property (nonatomic) NSRange range;
+ (instancetype)subRangeWithTextStorage:(FullTextStorage *)aFullTextStorage range:(NSRange)aRange;
+ (instancetype)subRangeWithCurrentSelectionOfTextView:(SEETextView *)aTextView;
@property (nonatomic, readonly) BOOL isRangeLocationAtBeginningOfLine;
@property (nonatomic, readonly) BOOL isRangeMaxAtEndOfLine;
@property (nonatomic, readonly) unsigned ogreSearchTimeOptions;

@end


@interface SEEFindAndReplaceContext ()
+ (dispatch_queue_t)findAndReplaceBackroundQueue;
- (void)signalErrorWithDescription:(NSString *)aDescription;
/* replace all state */
@property (nonatomic) NSInteger replaceCountForReplaceAll;

@end

@implementation SEEFindAndReplaceContext

+ (dispatch_queue_t)findAndReplaceBackroundQueue {
	static dispatch_queue_t background_queue;
	if (!background_queue) {
		background_queue = dispatch_queue_create("find and replace background queue", DISPATCH_QUEUE_SERIAL);
	}
	return background_queue;
}

+ (instancetype)contextWithTextView:(NSTextView *)aTextView state:(SEEFindAndReplaceState *)aState {
	SEEFindAndReplaceContext *result = [SEEFindAndReplaceContext new];
	result.targetTextView = (SEETextView *)aTextView;
	result.findAndReplaceState = aState;
	return result;
}

- (PlainTextEditor *)targetPlainTextEditor {
	PlainTextEditor *result = self.targetTextView.editor;
	return result;
}

- (FullTextStorage *)targetFullTextStorage {
	FullTextStorage *result = [(FoldableTextStorage *)self.targetTextView.textStorage fullTextStorage];
	return result;
}

- (BOOL)textFinderActionWantsToReplaceText {
	NSInteger textFinderActionType = self.currentTextFinderActionType;
	BOOL result = ((textFinderActionType==NSFindPanelActionReplace) ||
				   (textFinderActionType==NSFindPanelActionReplaceAndFind) ||
				   (textFinderActionType==NSFindPanelActionReplaceAll));
	return result;
}

#pragma mark - helpers

- (void)signalErrorWithDescription:(NSString *)aDescription {
	self.localizedErrorDescriptionString = aDescription;
	[[FindReplaceController sharedInstance] signalErrorWithDescription:aDescription];
}

- (NSString *)pasteboardFindString {
	NSString *result = nil;
    NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSPasteboardNameFind];
    if ([[pasteboard types] containsObject:NSStringPboardType]) {
        result = [pasteboard stringForType:NSStringPboardType];
	}
	return result;
}

- (void)saveFindStringToFindPasteboard {
	NSString *currentFindString = self.findAndReplaceState.findString;
	NSString *pasteboardFindString = [self pasteboardFindString];
	if (currentFindString && ![currentFindString isEqualToString:pasteboardFindString]) {
		NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSPasteboardNameFind];
		[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
		[pasteboard setString:currentFindString forType:NSStringPboardType];
	}
}


/*! @return YES if valid, NO if invalid. currentTextFinderActionType must be set. also has side effects: prepares regexes if necessary */

- (BOOL)validityCheckAndPrepare {
	if (self.findAndReplaceState.findString.length == 0) {
		[self signalErrorWithDescription:NSLocalizedString(@"FIND_REPLACE_ERROR_INVALID_FIND_STRING", @"invalid find string, (e.g. zero length find strings)")];
		return NO;
	}
	
	// compile search regex
	SEEFindAndReplaceState *state = self.findAndReplaceState;
	
	BOOL shouldBuildRegex = NO;
	BOOL shouldBuildReplaceExpression = NO;
	switch (self.currentTextFinderActionType) {
		case NSTextFinderActionReplaceAll:
			shouldBuildReplaceExpression = YES;
		case NSTextFinderActionNextMatch:
		case NSTextFinderActionPreviousMatch:
		case TCMTextFinderActionFindAll:
			shouldBuildRegex = YES;
			break;
		case NSTextFinderActionReplace:
			shouldBuildRegex = YES;
			if (state.useRegex) {
				shouldBuildReplaceExpression = YES;
			}
			break;
		default:
			break;
	}
	
	
	
	OgreSyntax regexSyntax = state.useRegex ? state.regularExpressionSyntax : OgreSimpleMatchingSyntax;
	if (shouldBuildRegex) {
		if (![OGRegularExpression isValidExpressionString:state.findString
												  options:state.regexOptionsForExpressionBuilding
												   syntax:regexSyntax
										  escapeCharacter:state.regularExpressionEscapeCharacter]) {
			NSString *errorString = state.useRegex ? NSLocalizedString(@"Invalid regex",@"InvalidRegex") : NSLocalizedString(@"FIND_REPLACE_ERROR_INVALID_FIND_STRING", @"invalid find string, (e.g. zero length find strings)");
			[self signalErrorWithDescription:errorString];
			return NO;
		}
		
		OGRegularExpression *regex = nil;
		@try{
			regex = [OGRegularExpression regularExpressionWithString:state.findString
															 options:state.regexOptionsForExpressionBuilding
															  syntax:regexSyntax
													 escapeCharacter:state.regularExpressionEscapeCharacter];
		} @catch (NSException *exception) {
			NSString *errorString = state.useRegex ? NSLocalizedString(@"Invalid regex",@"InvalidRegex") : NSLocalizedString(@"FIND_REPLACE_ERROR_INVALID_FIND_STRING", @"invalid find string, (e.g. zero length find strings)");
			[self signalErrorWithDescription:errorString];
			NSLog(@"%s exception during regex build:%@",__FUNCTION__,exception);
			return NO;
		}
		self.findExpression = regex;
	}
	
	if (shouldBuildReplaceExpression) {
		OGReplaceExpression *replaceExpression = [OGReplaceExpression replaceExpressionWithString:state.replaceString syntax:regexSyntax escapeCharacter:state.regularExpressionEscapeCharacter];
		self.replaceExpression = replaceExpression;
	}
	
	// current meaningful funnel point for adding to history
	[[FindReplaceController sharedInstance] storeFindeReplaceStateInHistory:self.findAndReplaceState];
	
	return YES;
}

- (SEEFindAndReplaceSubRange *)nextSubrange:(SEEFindAndReplaceSubRange *)aPreviousSubrange direction:(SEESearchRangeDirection)aDirection {
	
	SEEFindAndReplaceSubRange *result = nil;
	
	// get all the search ranges for the current document
	FullTextStorage *fullTextStorage = aPreviousSubrange.textStorage;
	NSArray *rangesArray = [self.targetTextView searchScopeRanges];
	NSRange nextRange = NSMakeRange(NSNotFound, 0);
	if (aDirection == kSEESearchRangeDirectionForward) {
		NSUInteger location = NSMaxRange(aPreviousSubrange.range);
		for (NSValue *rangeValue in rangesArray) {
			NSRange searchScopeRange = rangeValue.rangeValue;
			if (NSLocationInRange(location, searchScopeRange)) {
				nextRange.location = location;
				nextRange.length = NSMaxRange(searchScopeRange) - location;
				break;
			} else if (searchScopeRange.location >= location) {
				nextRange = searchScopeRange;
				break;
			}
		}
		if (nextRange.location != NSNotFound) {
			result = [SEEFindAndReplaceSubRange subRangeWithTextStorage:fullTextStorage range:nextRange];
		}
	} else if (aDirection == kSEESearchRangeDirectionBackward) {
		NSUInteger location = aPreviousSubrange.range.location;
		for (NSValue *rangeValue in rangesArray.reverseObjectEnumerator) {
			NSRange searchScopeRange = rangeValue.rangeValue;
			if (NSLocationInRange(location, searchScopeRange) &&
				searchScopeRange.location < location) {
				nextRange.location = searchScopeRange.location;
				nextRange.length = location - searchScopeRange.location;
				break;
			} else if (searchScopeRange.location < location) {
				nextRange = searchScopeRange;
				break;
			}
		}
		if (nextRange.location != NSNotFound) {
			result = [SEEFindAndReplaceSubRange subRangeWithTextStorage:fullTextStorage range:nextRange];
		}
		
	}
	return result;
}

#pragma mark -
- (BOOL)performCurrentTextFinderAction {
	BOOL result = NO;
	
	if (self.targetFullTextStorage.length != 0) {
		
		NSInteger textFinderActionType = self.currentTextFinderActionType;
		if (textFinderActionType == NSTextFinderActionNextMatch) {
			result = [self findNextForward:YES];
		} else if (textFinderActionType == NSTextFinderActionPreviousMatch) {
			result = [self findNextForward:NO];
		}
		else if (textFinderActionType == NSTextFinderActionReplace) {
			result = [self replaceSelection];
		} else if (textFinderActionType == NSTextFinderActionReplaceAndFind) {
			result = [self replaceSelection];
			if (result) {
				result = [self findNextForward:YES];
			}
		}
		else if (textFinderActionType == NSTextFinderActionReplaceAll) {
			result = [self replaceAll];
		}
		else if (textFinderActionType == TCMTextFinderActionFindAll) {
			[self showFindAllResults];
		}
	}
	
	return result;
}

- (BOOL)findNextForward:(BOOL)isForward {
	self.currentTextFinderActionType = (isForward ? NSTextFinderActionNextMatch : NSTextFinderActionPreviousMatch);
	BOOL result = [self validityCheckAndPrepare];
	if (result) {
		if (self.findAndReplaceState.useRegex == NO) {
			[self saveFindStringToFindPasteboard];
		}
		
		SEEFindAndReplaceSubRange *subrange = [SEEFindAndReplaceSubRange subRangeWithCurrentSelectionOfTextView:self.targetTextView];
		SEEFindAndReplaceSubRange *startSubRange = subrange;
		
		SEESearchRangeDirection direction = isForward ? kSEESearchRangeDirectionForward : kSEESearchRangeDirectionBackward;
		NSRange fullFoundRange = {NSNotFound,0};
		
		BOOL isWrapRun = NO;
		BOOL shouldStop = YES;
		if (self.findAndReplaceState.shouldWrap) {
			shouldStop = NO;
		}
		while (YES) {
			while ((subrange = [self nextSubrange:subrange direction:direction])) {

				// get all the matches we can find in that range
				NSEnumerator *enumerator = nil;
				@try{
					enumerator=[self.findExpression matchEnumeratorInString:subrange.textStorage.string options:subrange.ogreSearchTimeOptions range:subrange.range];
				} @catch (NSException *exception) {
					[self signalErrorWithDescription:nil];
					NSLog(@"%s exception while finding:%@",__FUNCTION__,exception);
					return NO;
				}
				
				OGRegularExpressionMatch *match = nil;
				match = [enumerator nextObject];
				if (!isForward) {
					OGRegularExpressionMatch *nextMatch = nil;
					while ((nextMatch = [enumerator nextObject])) {
						match = nextMatch;
					}
				}
				
				if (match) {
					// we found something
					fullFoundRange = [match rangeOfMatchedString];
					[self.targetPlainTextEditor selectRangeInBackground:fullFoundRange];
					return YES;
				}
				
				// break wrapping run if we run over the original start position
				if (isWrapRun) {
					if (isForward) {
						if (NSMaxRange(subrange.range) > NSMaxRange(startSubRange.range)) {
							break; // do not run over again
						}
					} else {
						if (subrange.range.location < startSubRange.range.location) {
							break;
						}
					}
				}
				
			}
			
			// exit or wrap
			if (shouldStop) {
				break;
			} else { // wrap
				FullTextStorage *fullTextStorage = self.targetFullTextStorage;
				NSRange range = isForward ? NSMakeRange(0, 0) : NSMakeRange(fullTextStorage.length, 0);
				subrange = [SEEFindAndReplaceSubRange subRangeWithTextStorage:fullTextStorage range:range];
				isWrapRun = YES;
				shouldStop = YES;
			}
		}
		
		// if we arrive here we failed
		result = NO;
		[self signalErrorWithDescription:NSLocalizedString(@"Not found",@"Find string not found")];
	}
	
	return result;
}

- (BOOL)replaceSelection {
	self.currentTextFinderActionType = NSTextFinderActionReplace;
	BOOL result = [self validityCheckAndPrepare];
	if (result) {
		OGRegularExpressionMatch *match = nil;
		NSString *replaceString = self.findAndReplaceState.replaceString;
		if (self.findAndReplaceState.useRegex) {
			// to make look aheads and look behinds work in most cases we search again in the line range
			SEEFindAndReplaceSubRange *subrange = [SEEFindAndReplaceSubRange subRangeWithCurrentSelectionOfTextView:self.targetTextView];
			NSString *contentString = [subrange.textStorage string];
			SEEFindAndReplaceSubRange *lineSubrange = [SEEFindAndReplaceSubRange subRangeWithTextStorage:subrange.textStorage range:[contentString lineRangeForRange:subrange.range]];

			// get all the matches we can find in that range
			NSEnumerator *enumerator = nil;
			@try{
				enumerator=[self.findExpression matchEnumeratorInString:contentString options:lineSubrange.ogreSearchTimeOptions range:lineSubrange.range];
			} @catch (NSException *exception) {
				[self signalErrorWithDescription:nil];
				NSLog(@"%s exception while finding:%@",__FUNCTION__,exception);
				return NO;
			}
			
			while ((match = [enumerator nextObject])) {
				if (NSEqualRanges(subrange.range, match.rangeOfMatchedString)) {
					break;
				}
			}
			if (match) {
				replaceString = [self.replaceExpression replaceMatchedStringOf:match];
			}
		} else {
			SEEFindAndReplaceSubRange *subrange = [SEEFindAndReplaceSubRange subRangeWithCurrentSelectionOfTextView:self.targetTextView];
			NSEnumerator *enumerator = nil;
			@try{
				enumerator=[self.findExpression matchEnumeratorInString:subrange.textStorage.string options:subrange.ogreSearchTimeOptions range:subrange.range];
			} @catch (NSException *exception) {
				[self signalErrorWithDescription:nil];
				NSLog(@"%s exception while finding:%@",__FUNCTION__,exception);
				return NO;
			}
			match = [enumerator nextObject];
		}

		if (!match) {
			// this should not happen, but might
			[self signalErrorWithDescription:NSLocalizedString(@"Not found.",@"Find string not found")];
			result = NO;
		} else {
			PlainTextDocument *document = self.targetPlainTextEditor.document;
			//		FullTextStorage *fullTextStorage = self.targetFullTextStorage;
			[[document session] pauseProcessing];
			[[document documentUndoManager] beginUndoGrouping];

            [self.targetTextView insertText:replaceString replacementRange:self.targetTextView.selectedRange];
			
			[[document documentUndoManager] endUndoGrouping];
			[[document session] startProcessing];
		}
	}
	return result;
}

- (void)lockDocument:(PlainTextDocument *)aDocument {
    NSEnumerator *plainTextEditors=[[aDocument plainTextEditors] objectEnumerator];
    PlainTextEditor *editor=nil;
    while ((editor=[plainTextEditors nextObject])) {
        [editor lock];
    }
	[[aDocument session] pauseProcessing];
	[aDocument.documentUndoManager beginUndoGrouping];
}

- (void)unlockDocument:(PlainTextDocument *)aDocument {
	[aDocument.documentUndoManager endUndoGrouping];
	[[aDocument session] startProcessing];
    NSEnumerator *plainTextEditors=[[aDocument plainTextEditors] objectEnumerator];
    PlainTextEditor *editor=nil;
    while ((editor=[plainTextEditors nextObject])) {
        [editor unlock];
    }
}


- (void)startLongTextReplaceOperation {
	[self lockDocument:self.targetPlainTextEditor.document];
	[[FindReplaceController sharedInstance] setStatusString:[NSString stringWithFormat:NSLocalizedString(@"FIND_REPLACE_REPLACE_ALL_IN_PROGRESS",@"Status string indicating a replace all is in progress"), self.replaceCountForReplaceAll]];
	[self.targetTextView.window displayIfNeeded];
}

- (void)stopLongTextReplaceOperation {
	[self unlockDocument:self.targetPlainTextEditor.document];
    [[FindReplaceController sharedInstance] setStatusString:[NSString stringWithFormat:NSLocalizedString(@"%ld replaced",@"Number of replaced strings"), (long)self.replaceCountForReplaceAll]];
}

#define CHECK_END_MATCHES_INTERVAL 50
#define CHECK_END_MIN_TIME_ELAPSED 0.6

- (NSArray *)allSubranges {
	NSMutableArray *subranges = [NSMutableArray new];
	FullTextStorage *fullTextStorage = self.targetFullTextStorage;
	for (NSValue *rangeValue in self.targetTextView.searchScopeRanges) {
		SEEFindAndReplaceSubRange *subrange = [SEEFindAndReplaceSubRange subRangeWithTextStorage:fullTextStorage range:rangeValue.rangeValue];
		[subranges addObject:subrange];
	}
	return subranges;
}

- (BOOL)replaceAll {
	self.currentTextFinderActionType = NSTextFinderActionReplaceAll;
	BOOL result = [self validityCheckAndPrepare];
	if (result) {
		NSArray *subranges = [self allSubranges];
		FullTextStorage *fullTextStorage = self.targetFullTextStorage;
		NSMutableString *fullTextStorageString = fullTextStorage.mutableString;
		NSDictionary *typingAttributes = [self.targetPlainTextEditor.document typingAttributes];
		[self startLongTextReplaceOperation];
		self.replaceCountForReplaceAll = 0;
		OGRegularExpression *findExpression = self.findExpression;
		OGReplaceExpression *replaceExpression = self.replaceExpression;
		
		
		NSMutableArray *subrangesLeft = [subranges mutableCopy];
		NSMutableArray *matchesLeft = [NSMutableArray new];
		
		dispatch_queue_t main_queue = dispatch_get_main_queue();
		__weak __block dispatch_block_t weakReplaceSomeBlock = nil;
		dispatch_block_t replaceSomeBlock = ^{
			NSInteger replaceCount = 0;
			NSRange lastMatchAfterRange = NSMakeRange(0, 0);
			NSDate *startDate = [NSDate date];
			BOOL shouldStop = NO;
			@try {
				[fullTextStorage beginEditing];
				while (matchesLeft.count > 0 || subrangesLeft.count > 0) {
					if (matchesLeft.count == 0) {
						// grab next subrange and generate matches
						SEEFindAndReplaceSubRange *subrange = subrangesLeft.lastObject;
						[subrangesLeft removeLastObject];
						[matchesLeft addObjectsFromArray:[findExpression matchEnumeratorInString:subrange.textStorage.string options:subrange.ogreSearchTimeOptions range:subrange.range].allObjects];
					}
					
					OGRegularExpressionMatch *match = nil;
					while ((match = matchesLeft.lastObject)) {
						[matchesLeft removeLastObject];
						NSString *replaceString = [replaceExpression replaceMatchedStringOf:match];
						NSRange replaceRange = match.rangeOfMatchedString;
						lastMatchAfterRange = replaceRange;
						lastMatchAfterRange.length = replaceString.length;
						[fullTextStorageString replaceCharactersInRange:replaceRange withString:replaceString];
						[fullTextStorage addAttributes:typingAttributes range:lastMatchAfterRange];
						replaceCount++;
						
						if (replaceCount % CHECK_END_MATCHES_INTERVAL == 0) {
							if ([startDate timeIntervalSinceNow] < -CHECK_END_MIN_TIME_ELAPSED) {
								shouldStop = YES;
								break;
							}
						}
					}
					if (shouldStop) {
						break;
					}
				}
			} @catch (NSException *exception) {
				[self signalErrorWithDescription:nil];
				NSLog(@"%s exception while finding:%@",__FUNCTION__,exception);
			} @finally {
				BOOL finished = (matchesLeft.count == 0 && subrangesLeft.count == 0);
				self.replaceCountForReplaceAll += replaceCount;
				[fullTextStorage endEditing];
				if (finished) {
					[self.targetTextView setSelectedRange:lastMatchAfterRange];
					[self stopLongTextReplaceOperation];
				} else {
					[[FindReplaceController sharedInstance] setStatusString:[NSString stringWithFormat:NSLocalizedString(@"FIND_REPLACE_REPLACE_ALL_IN_PROGRESS_COUNT",@"intermediate string displayed for long replace all operations, has %@ placeholder"), @(self.replaceCountForReplaceAll)]];
					[self.targetTextView.window displayIfNeeded];
					[NSOperationQueue TCM_performBlockOnMainQueue:weakReplaceSomeBlock afterDelay:0.3];
				}
			}
		};
		weakReplaceSomeBlock = replaceSomeBlock;
		dispatch_async(main_queue, replaceSomeBlock);
		
	}
	return result;
}

- (NSArray *)allMatches {
	if (!self.findExpression) {
		self.currentTextFinderActionType = TCMTextFinderActionFindAll;
		if (![self validityCheckAndPrepare]) {
			return nil;
		}
	}
	
	NSMutableArray *result = [NSMutableArray new];
	for (SEEFindAndReplaceSubRange *subrange in [self allSubranges]) {
		[result addObjectsFromArray:[self.findExpression matchEnumeratorInString:subrange.textStorage.string options:subrange.ogreSearchTimeOptions range:subrange.range].allObjects];
	}
	return result;
}

- (BOOL)	showFindAllResults {
	self.currentTextFinderActionType = TCMTextFinderActionFindAll;
	BOOL result = [self validityCheckAndPrepare];
	
	if (result) {
		FindAllController *findall = [[FindAllController alloc] initWithFindAndReplaceContext:self];
		[(PlainTextDocument *)self.targetPlainTextEditor.document addFindAllController:findall];
		[findall findAll:self];
	}
	return result;
}

@end

@implementation SEEFindAndReplaceSubRange
+ (instancetype)subRangeWithTextStorage:(FullTextStorage *)aFullTextStorage range:(NSRange)aRange {
	SEEFindAndReplaceSubRange *result = [SEEFindAndReplaceSubRange new];
	result.textStorage = aFullTextStorage;
	result.range = aRange;
	return result;
}

+ (instancetype)subRangeWithCurrentSelectionOfTextView:(SEETextView *)aTextView {
	NSRange range = aTextView.selectedRange;
	FoldableTextStorage *foldableTextStorage = (FoldableTextStorage *)aTextView.textStorage;
	range = [foldableTextStorage fullRangeForFoldedRange:range];
	SEEFindAndReplaceSubRange *result = [SEEFindAndReplaceSubRange subRangeWithTextStorage:foldableTextStorage.fullTextStorage range:range];
	return result;
}

- (BOOL)isRangeLocationAtBeginningOfLine {
	BOOL result = YES;
	
	NSUInteger location = self.range.location;
	if (location > 0) {
		unichar previousCharacter = [self.textStorage.string characterAtIndex:location - 1];
		switch (previousCharacter) { // check if previous character is a newline character
			case 0x2028:
			case 0x2029:
			case '\n':
			case '\r':
				break;
			default:
				result = NO;
		}
	}
	return result;
}

- (BOOL)isRangeMaxAtEndOfLine {
	BOOL result = YES;
	
	NSUInteger location = NSMaxRange(self.range);
	NSString *string = self.textStorage.string;
	if (string.length > 0 &&
		location < string.length) {
		unichar previousCharacter = [self.textStorage.string characterAtIndex:location];
		switch (previousCharacter) { // check if previous character is a newline character
			case 0x2028:
			case 0x2029:
			case '\n':
			case '\r':
				break;
			default:
				result = NO;
		}
	}
	return result;
}

- (unsigned)ogreSearchTimeOptions {
	unsigned result = self.isRangeLocationAtBeginningOfLine ? 0 : OgreNotBOLOption;
	if (!self.isRangeMaxAtEndOfLine) {
		result |= OgreNotEOLOption;
	}
	return result;
}

@end

