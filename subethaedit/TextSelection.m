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
    }
    return self;
}

- (void)dealloc
{
    [I_editor release];
    I_editor = nil;
    [super dealloc];
}

- (NSData *)characterRange
{
    NSTextView *textView = [I_editor textView];
    NSRange range = [textView selectedRange];
    
    Point p;
    if (range.length == 0) {
        p.v = range.location;
        p.h = range.location;
    } else {
        p.v = NSMaxRange(range);
        p.h = range.location + 1;
    }
    
    return [NSData dataWithBytes:&p length:sizeof(p)];
}

- (id)contents
{
    NSTextView *textView = [I_editor textView];
    NSRange range = [textView selectedRange];
    
    NSAttributedString *attributedSubstring = [[textView textStorage] attributedSubstringFromRange:range];
    return [[[NSTextStorage alloc] initWithAttributedString:attributedSubstring] autorelease];
}

- (void)setContents:(id)string
{
    NSTextView *textView = [I_editor textView];
    [textView insertText:string];
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
