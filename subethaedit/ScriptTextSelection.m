//
//  TextSelection.m
//  SubEthaEdit
//
//  Created by Martin Ott on 2/21/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "ScriptTextSelection.h"
#import "TextStorage.h"
#import "PlainTextDocument.h"
#import "PlainTextEditor.h"


@implementation ScriptTextSelection

- (void)setStartIndex:(int)anIndex {
    I_startCharacterIndex = anIndex;
}

+ (id)insertionPointWithTextStorage:(TextStorage *)aTextStorage index:(int)anIndex {
    ScriptTextSelection *selection=[[[ScriptTextSelection alloc] initWithTextStorage:aTextStorage editor:nil] autorelease];
    [selection setStartIndex:anIndex];
    return selection;
}

+ (id)scriptTextSelectionWithTextStorage:(TextStorage *)aTextStorage editor:(PlainTextEditor *)anEditor
{
    return [[[ScriptTextSelection alloc] initWithTextStorage:aTextStorage editor:anEditor] autorelease];
}

- (id)initWithTextStorage:(TextStorage *)aTextStorage editor:(PlainTextEditor *)anEditor {
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

- (void)setScriptedContents:(id)value {
    NSLog(@"%s: %d", __FUNCTION__, value);
    NSRange range=[self rangeRepresentation];
    [[I_textStorage delegate] replaceTextInRange:range withString:value];
    if (I_editor) {
        [[I_editor textView] setSelectedRange:NSMakeRange(range.location,[value length])];
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
