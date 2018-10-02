//
//  DebugAttributeInspectorController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 04.06.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "DebugAttributeInspectorController.h"
#import "FullTextStorage.h"
#import "FoldableTextStorage.h"


@implementation DebugAttributeInspectorController

- (void)windowDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChangeSelection:) name:NSTextViewDidChangeSelectionNotification object:nil];
   	NSSortDescriptor *descriptor = [[[NSSortDescriptor alloc] initWithKey:@"attributeName" ascending:YES] autorelease];
   	[O_attributesContentController setSortDescriptors:[NSArray arrayWithObject:descriptor]];
   	[O_foldingTextStorageAttributesContentController setSortDescriptors:[NSArray arrayWithObject:descriptor]];
}

- (NSString *)windowNibName {
    return @"DebugAttributesInspector";
}

- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
	if ([[self window] isVisible]) {
		NSTextView *textView = [aNotification object];
		if ([[textView window] firstResponder] == textView && [[textView window] isMainWindow]) {
			NSArrayController *controller = nil;
			NSTextStorage *textStorage = [textView textStorage];
			NSTextStorage *firstTextStorage = textStorage;
			do {
				BOOL isFoldableTextStorage = [textStorage isKindOfClass:[FoldableTextStorage class]];
				controller = isFoldableTextStorage ? O_foldingTextStorageAttributesContentController : O_attributesContentController;
				[controller setContent:[NSMutableArray array]];
				NSRange selectedRange = [textView selectedRange];
				if (!isFoldableTextStorage && [firstTextStorage respondsToSelector:@selector(fullRangeForFoldedRange:)]) {
					selectedRange = [(id)firstTextStorage fullRangeForFoldedRange:selectedRange];
				}
				NSRange wholeRange = NSMakeRange(0,[textStorage length]);
				if (selectedRange.location < NSMaxRange(wholeRange)) {
					NSDictionary *attributes = [textStorage attributesAtIndex:selectedRange.location effectiveRange:NULL];
					NSEnumerator *attributeEnumerator = [attributes keyEnumerator];
					NSString *key=nil;
					while ((key = [attributeEnumerator nextObject])) {
						NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject:key forKey:@"attributeName"];
						NSString *value = [[attributes objectForKey:key] description];
						if (value) {
							value = [[value stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"  " withString:@""];
							[dictionary setObject:value forKey:@"contentValue"];
						}
						[controller addObject:dictionary];
						if ([key isEqualToString:@"HighlightingStack"]) {
							NSMutableDictionary *dict = [NSMutableDictionary dictionary];
							[dict setObject:@"StateStack" forKey:@"attributeName"];
							[dict setObject:[[[attributes objectForKey:key] valueForKeyPath:@"state"] componentsJoinedByString:@" | "] forKey:@"contentValue"];
							[controller addObject:dict];
						}
					}
					if (isFoldableTextStorage) {
						NSMutableDictionary *bonusDictionary = [NSMutableDictionary dictionaryWithObject:@"Foldable Range" forKey:@"attributeName"];
						// convert location to fulltextstorage before asking
						selectedRange = [(id)textStorage fullRangeForFoldedRange:selectedRange];
						[bonusDictionary setObject:NSStringFromRange([[(FoldableTextStorage *)textStorage fullTextStorage] foldableRangeForCharacterAtIndex:selectedRange.location]) forKey:@"contentValue"];
						[controller addObject:bonusDictionary];
					}
				}
				[controller rearrangeObjects];
			} while ([textStorage respondsToSelector:@selector(fullTextStorage)] && (textStorage = [(id)textStorage fullTextStorage]));
		}
	}
}

@end
