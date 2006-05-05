//
//  ScriptTextBase.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.05.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "ScriptTextBase.h"
#import "TextStorage.h"
#import "PlainTextDocument.h"


@implementation ScriptTextBase

- (id)initWithTextStorage:(TextStorage *)aTextStorage {
    if ((self=[super init])) {
        I_textStorage = [aTextStorage retain];
    }
    return self;
}

- (void)dealloc {
    [I_textStorage release];
    [super dealloc];
}

- (NSRange)rangeRepresentation {
    return NSMakeRange(0,NSNotFound);
}
- (NSNumber *)scriptedLength {
    return [NSNumber numberWithInt:[self rangeRepresentation].length];
}

- (NSNumber *)scriptedStartCharacterIndex {
    return [NSNumber numberWithInt:[self rangeRepresentation].location +1];
}

- (NSNumber *)scriptedEndCharacterIndex {
    return [NSNumber numberWithInt:((int)NSMaxRange([self rangeRepresentation]))-1 +1];
}

- (NSNumber *)scriptedStartLine {
    return [NSNumber numberWithInt:[I_textStorage lineNumberForLocation:[self rangeRepresentation].location]];
}

- (NSNumber *)scriptedEndLine {
    return [NSNumber numberWithInt:[I_textStorage lineNumberForLocation:EndCharacterIndex([self rangeRepresentation])]];
}

- (id)scriptedContents
{
    return [[I_textStorage string] substringWithRange:[self rangeRepresentation]];
}

- (void)setScriptedContents:(id)value {
    NSLog(@"%s: %d", __FUNCTION__, value);
    [[I_textStorage delegate] replaceTextInRange:[self rangeRepresentation] withString:value];
}

@end
