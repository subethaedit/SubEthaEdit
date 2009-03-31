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
}

- (NSString *)windowNibName {
    return @"DebugAttributesInspector";
}

- (void)textViewDidChangeSelection:(NSNotification *)aNotification {
    NSTextView *textView = [aNotification object];
    if ([[textView window] firstResponder] == textView && [[textView window] isMainWindow]) {
        [O_attributesContentController setContent:[NSMutableArray array]];
        NSTextStorage *textStorage = [textView textStorage];
        NSRange selectedRange = [textView selectedRange];
        NSRange wholeRange = NSMakeRange(0,[textStorage length]);
        if (selectedRange.location < NSMaxRange(wholeRange)) {
            NSDictionary *attributes = [textStorage attributesAtIndex:selectedRange.location effectiveRange:NULL];
            NSEnumerator *attributeEnumerator = [attributes keyEnumerator];
            NSString *key=nil;
            while ((key = [attributeEnumerator nextObject])) {
                NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject:key forKey:@"attributeName"];
                NSString *value = [[attributes objectForKey:key] description];
                if (value) {
                    [dictionary setObject:value forKey:@"contentValue"];
                }
                [O_attributesContentController addObject:dictionary];
            }
            NSMutableDictionary *bonusDictionary = [NSMutableDictionary dictionaryWithObject:@"Foldable Range" forKey:@"attributeName"];
            [bonusDictionary setObject:NSStringFromRange([[(FoldableTextStorage *)textStorage fullTextStorage] foldableRangeForCharacterAtIndex:selectedRange.location]) forKey:@"contentValue"];
            [O_attributesContentController addObject:bonusDictionary];
        }
        [O_attributesContentController rearrangeObjects];
    }
}

@end
