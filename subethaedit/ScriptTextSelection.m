//
//  TextSelection.m
//  SubEthaEdit
//
//  Created by Martin Ott on 2/21/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "ScriptTextSelection.h"
#import "FoldableTextStorage.h"
#import "PlainTextDocument.h"
#import "PlainTextEditor.h"


@implementation ScriptTextSelection

- (void)setStartIndex:(int)anIndex {
    I_startCharacterIndex = anIndex;
}

+ (id)insertionPointWithTextStorage:(FoldableTextStorage *)aTextStorage index:(int)anIndex {
    ScriptTextSelection *selection=[[[ScriptTextSelection alloc] initWithTextStorage:aTextStorage editor:nil] autorelease];
    [selection setStartIndex:anIndex];
    return selection;
}

+ (id)scriptTextSelectionWithTextStorage:(FoldableTextStorage *)aTextStorage editor:(PlainTextEditor *)anEditor
{
    return [[[ScriptTextSelection alloc] initWithTextStorage:aTextStorage editor:anEditor] autorelease];
}

- (id)initWithTextStorage:(FoldableTextStorage *)aTextStorage editor:(PlainTextEditor *)anEditor {
    if ((self = [super initWithTextStorage:aTextStorage])) {
        I_editor      = [anEditor retain];
    }
    return self;
}

- (void)dealloc
{
    [I_editor release];
    [super dealloc];
}

- (NSRange)rangeRepresentation {
    if (I_editor) {
        return [[I_editor textView] selectedRange];
    } else {
        return NSMakeRange(I_startCharacterIndex,0);
    }
}

- (void)setScriptedStartCharacterIndex:(int)aValue {
    // NSLog(@"%s: %d", __FUNCTION__, aValue);
    if (I_editor && aValue > 0) {
        NSTextView *textView = [I_editor textView];
        NSRange range = [textView selectedRange];
        int newValue = aValue-1;
        if (newValue>[I_textStorage length]) {
            newValue=[I_textStorage length];
            [textView setSelectedRange:NSMakeRange(newValue,0)];
        } else {
            if (newValue<0) newValue = 0;
            if (NSMaxRange(range)<=newValue) {
                [textView setSelectedRange:NSMakeRange(newValue,0)];
            } else {
                int positionChange = (int)newValue - range.location;
                range.length -= positionChange;
                range.location = newValue;
                [textView setSelectedRange:range];
            }
        }
    }
}

- (void)setScriptedNextCharacterIndex:(int)aValue {
    // NSLog(@"%s: %d", __FUNCTION__, aValue);
    if (I_editor && aValue > 0) {
        NSTextView *textView = [I_editor textView];
        NSRange range = [textView selectedRange];
        int newValue = aValue-1;
        if (newValue<0) {
            [textView setSelectedRange:NSMakeRange(0,0)];
        } else if (newValue>(int)[I_textStorage length]) {
            range.length = [I_textStorage length]-range.location;
            [textView setSelectedRange:range];
        } else {
            if (newValue <= range.location) {
                [textView setSelectedRange:NSMakeRange(newValue,0)];
            } else {
                range.length = newValue-range.location;
                [textView setSelectedRange:range];
            }
        }
    }
}

- (void)setScriptedLength:(int)aValue {
    // NSLog(@"%s: %d", __FUNCTION__, aValue);
    if (I_editor && aValue >= 0) {
        NSTextView *textView = [I_editor textView];
        NSRange range = [textView selectedRange];
        range.length = aValue;
        if (NSMaxRange(range)>[I_textStorage length]) {
            range.length -= NSMaxRange(range)-[I_textStorage length];
        }
        [textView setSelectedRange:range];
    }
}

- (void)setScriptedContents:(id)value {
    // NSLog(@"%s: %d", __FUNCTION__, value);
    NSRange range=[self rangeRepresentation];
    [[I_textStorage delegate] replaceTextInRange:range withString:value];
    if (I_editor) {
        [[I_editor textView] setSelectedRange:NSMakeRange(range.location,[(NSString*)value length])];
    }
}

- (id)objectSpecifier
{
    NSScriptClassDescription *containerDescription;
    NSScriptObjectSpecifier  *containerSpecifier;
    NSScriptObjectSpecifier  *resultSpecifier;
    if (I_editor) {
        containerDescription = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[NSWindow class]];
        containerSpecifier   = [[[I_editor textView] window] objectSpecifier];
        
        resultSpecifier = 
            [[[NSPropertySpecifier alloc] initWithContainerClassDescription:containerDescription
                                                         containerSpecifier:containerSpecifier
                                                                        key:@"scriptSelection"] autorelease];
        
    } else {
        containerDescription = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[I_textStorage class]];
        containerSpecifier   = [I_textStorage objectSpecifier];
        
        resultSpecifier = 
            [[[NSIndexSpecifier alloc] initWithContainerClassDescription:containerDescription
                                                      containerSpecifier:containerSpecifier
                                                                     key:@"insertionPoints"
                                                                   index:I_startCharacterIndex] autorelease];
    }
    return resultSpecifier;
}

@end
