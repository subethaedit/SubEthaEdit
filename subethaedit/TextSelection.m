//
//  TextSelection.m
//  SubEthaEdit
//
//  Created by Martin Ott on 2/21/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "TextSelection.h"
#import "TextStorage.h"
#import "PlainTextDocument.h"
#import "PlainTextEditor.h"


@implementation TextSelection

+ (id)selectionForEditor:(id)editor
{
    return [[[TextSelection alloc] initForEditor:editor] autorelease];
}

- (id)initForEditor:(id)editor
{
    self = [super init];
    if (self) {
        I_editor = [editor retain];
        I_subTextStorage = [[TextStorage alloc] initWithContainerTextStorage:(TextStorage *)[[editor textView] textStorage] 
                                                                       range:[[editor textView] selectedRange]];
    }
    return self;
}

- (void)dealloc
{
    [I_subTextStorage release];
    I_subTextStorage = nil;
    [I_editor release];
    I_editor = nil;
    [super dealloc];
}

- (NSNumber *)scriptedLength {
    return [I_subTextStorage scriptedLength];
}

- (NSNumber *)scriptedCharacterOffset {
    return [I_subTextStorage scriptedCharacterOffset];
}

- (NSNumber *)scriptedStartLine {
    return [I_subTextStorage scriptedStartLine];
}

- (NSNumber *)scriptedEndLine {
    return [I_subTextStorage scriptedEndLine];
}

- (id)contents
{
    return I_subTextStorage;
}

- (void)setContents:(id)string
{
    if ([string isKindOfClass:[NSString class]]) {
        NSTextView *textView = [I_editor textView];
        NSTextStorage *textStorage = [textView textStorage];
        PlainTextDocument *document = [textStorage delegate];
        [document replaceTextInRange:[textView selectedRange] withString:string];
    }
}

- (void)replaceValueAtIndex:(unsigned)index inPropertyWithKey:(NSString *)key withValue:(id)value
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)insertValue:(id)value atIndex:(unsigned)index inPropertyWithKey:(NSString *)key
{
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"value: %@, index: %d, key: %@", value, index, key);
}

- (id)objectSpecifier
{
    NSTextView *textView = [I_editor textView];
    NSRange range = [textView selectedRange];

    if (range.length > 0) {
        NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[PlainTextDocument class]];
        NSScriptObjectSpecifier *containerSpecifier = [[[I_editor windowController] document] objectSpecifier];

        NSIndexSpecifier *startSpecifier = [[NSIndexSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                                                    containerSpecifier:containerSpecifier
                                                                                                   key:@"text"
                                                                                                 index:range.location];

        NSIndexSpecifier *endSpecifier = [[NSIndexSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                                                  containerSpecifier:containerSpecifier
                                                                                                 key:@"text"
                                                                                               index:NSMaxRange(range) - 1];

        NSRangeSpecifier *rangeSpecifier = [[NSRangeSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                                                    containerSpecifier:containerSpecifier
                                                                                                   key:@"text"
                                                                                        startSpecifier:[startSpecifier autorelease]
                                                                                          endSpecifier:[endSpecifier autorelease]];   

        return [rangeSpecifier autorelease];
        
    } else {
        NSScriptObjectSpecifier *containerSpecifier = [[textView textStorage] objectSpecifier];
        NSIndexSpecifier *indexSpecifier = [[NSIndexSpecifier alloc] initWithContainerClassDescription:[containerSpecifier keyClassDescription]
                                                                                    containerSpecifier:containerSpecifier
                                                                                                   key:@"insertionPoints"
                                                                                                 index:range.location];
                                                                                                 
        return [indexSpecifier autorelease];
    }
}

@end
