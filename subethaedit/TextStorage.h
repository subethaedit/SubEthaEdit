//
//  TextStorage.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Thu Mar 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const BlockeditAttributeName ;
extern NSString * const BlockeditAttributeValue;

@interface TextStorage : NSTextStorage {
    NSMutableArray *I_lineStarts;
    unsigned int I_lineStartsValidUpTo;
    NSMutableAttributedString *I_contents;
    unsigned int I_encoding;

    struct {
        BOOL hasBlockeditRanges;
        BOOL  isBlockediting;
        BOOL didBlockedit;
        NSRange didBlockeditRange;
        NSRange didBlockeditLineRange;
    } I_blockedit;
}

- (int)lineNumberForLocation:(unsigned)location;
- (NSMutableArray *)lineStarts;
- (NSRange)findLine:(int)aLineNumber;
- (void)setLineStartsOnlyValidUpTo:(unsigned int)aLocation;

- (unsigned int)encoding;
- (void)setEncoding:(unsigned int)anEncoding;

- (BOOL)hasBlockeditRanges;
- (void)setHasBlockeditRanges:(BOOL)aFlag;
- (BOOL)isBlockediting;
- (void)setIsBlockediting:(BOOL)aFlag;
- (BOOL)didBlockedit;
- (void)setDidBlockedit:(BOOL)aFlag;
- (NSRange)didBlockeditRange;
- (void)setDidBlockeditRange:(NSRange)aRange;
- (NSRange)didBlockeditLineRange;
- (void)setDidBlockeditLineRange:(NSRange)aRange;

- (NSRange)blockChangeTextInRange:(NSRange)aRange replacementString:(NSString *)aReplacementString
                   paragraphRange:(NSRange)aParagraphRange inTextView:(NSTextView *)aTextView;

- (void)stopBlockedit;

@end

#pragma mark -

@interface NSObject (TextStorageDelegateAdditions)

- (NSDictionary *)blockeditAttributesForTextStorage:(TextStorage *)aTextStorage;
- (void)textStorageDidStopBlockedit:(TextStorage *)aTextStorage;
- (void)textStorageDidStartBlockedit:(TextStorage *)aTextStorage;
- (void)textStorage:(TextStorage *)aTextStorage didReplaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString;

@end