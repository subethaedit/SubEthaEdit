//  ScriptLine.m
//  SubEthaEdit
//
//  Created by Martin Ott on 5/2/06.

#import "ScriptLine.h"
#import "FoldableTextStorage.h"
#import "PlainTextDocument.h"

@implementation ScriptLine

+ (id)scriptLineWithTextStorage:(FullTextStorage *)aTextStorage lineNumber:(int)aLineNumber {
    return [[ScriptLine alloc] initWithTextStorage:aTextStorage lineNumber:aLineNumber];
}

- (instancetype)initWithTextStorage:(FullTextStorage *)aTextStorage lineNumber:(int)aLineNumber {
    if ((self = [super initWithTextStorage:aTextStorage])) {
        I_lineNumber = aLineNumber;
    }
    return self;
}

- (NSRange)rangeRepresentation {
    NSUInteger startIndex;
    NSUInteger lineEndIndex;
    NSUInteger contentsEndIndex;
    [[I_textStorage string] getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:[I_textStorage findLine:I_lineNumber]];
    return NSMakeRange(startIndex, lineEndIndex - startIndex);
}

- (NSRange)innerRangeRepresentation {
    NSUInteger startIndex;
    NSUInteger lineEndIndex;
    NSUInteger contentsEndIndex;
    [[I_textStorage string] getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:[I_textStorage findLine:I_lineNumber]];
    return NSMakeRange(startIndex, contentsEndIndex - startIndex);
}

- (id)objectSpecifier {
//    NSLog(@"%s", __FUNCTION__);
    
    NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[FoldableTextStorage class]];
    NSScriptObjectSpecifier *containerSpecifier = [I_textStorage objectSpecifier];

    NSIndexSpecifier *indexSpecifier = 
        [[NSIndexSpecifier alloc] initWithContainerClassDescription:containerClassDesc
                                                  containerSpecifier:containerSpecifier
                                                                 key:@"scriptedLines"
                                                               index:I_lineNumber-1];
                                                               
    return indexSpecifier;
}


- (id)scriptedInnerContents {
    return [[I_textStorage string] substringWithRange:[self innerRangeRepresentation]];
}

- (void)setScriptedInnerContents:(id)value {
    // NSLog(@"%s: %@", __FUNCTION__, value);
    [(id)[I_textStorage delegate] replaceTextInRange:[self innerRangeRepresentation] withString:value];
}


@end
