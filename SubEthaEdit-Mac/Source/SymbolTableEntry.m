//  SymbolTableEntry.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 16 2004.

#import "SymbolTableEntry.h"
#import "SelectionOperation.h"

@implementation SymbolTableEntry

- (void)setIsSeparator:(BOOL)aFlag {
    I_isSeparator=aFlag;  
}

+ (SymbolTableEntry *)symbolTableEntryWithName:(NSString *)aName fontTraitMask:(int)aMask image:(NSImage *)anImage type:(NSString *)aType  indentationLevel:(int)anIndentationLevel jumpRange:(NSRange)aJumpRange range:(NSRange)aRange {
    SymbolTableEntry *result=[[SymbolTableEntry new] autorelease];
    [result setName:aName];
    [result setFontTraitMask:aMask];
    [result setImage:anImage];
    [result setType:aType];
    [result setJumpRange:aJumpRange];
    [result setRange:aRange];
    [result setIndentationLevel:anIndentationLevel];
    [result setIsSeparator:NO];
    return result;
}

+ (SymbolTableEntry *)symbolTableEntrySeparator {
    SymbolTableEntry *result=[[SymbolTableEntry new] autorelease];
    [result setIsSeparator:YES];
    return result;
}

- (id)init {
    self = [super init];
    if (self) {
        I_jumpRangeSelectionOperation=[SelectionOperation new];
        I_rangeSelectionOperation    =[SelectionOperation new];
    }
    return self;
}

- (void)dealloc {
    [I_jumpRangeSelectionOperation release];
    [I_rangeSelectionOperation     release];
    [I_name release];
    [I_image release];
    [I_type release];
    [super dealloc];
}

- (NSString *)name {
    return I_name;
}
- (void)setName:(NSString *)aName {
    [I_name autorelease];
    I_name = [aName copy];
}
- (int)fontTraitMask {
    return I_fontTraitMask;
}
- (void)setFontTraitMask:(int)aMask {
    I_fontTraitMask = aMask;
}
- (NSImage *)image {
    return I_image;
}
- (void)setImage:(NSImage *)anImage {
    [I_image autorelease];
    I_image = [anImage retain];
}

- (NSString *)type {
    return I_type;
}
- (void)setType:(NSString *)aType {
    [I_type autorelease];
    I_type = [aType copy];
}
- (SelectionOperation *)jumpRangeSelectionOperation {
    return I_jumpRangeSelectionOperation;
}
- (NSRange)jumpRange {
    return [I_jumpRangeSelectionOperation selectedRange];
}
- (void)setJumpRange:(NSRange)aJumpRange {
    [I_jumpRangeSelectionOperation setSelectedRange:aJumpRange];
}
- (SelectionOperation *)rangeSelectionOperation {
    return I_rangeSelectionOperation;
}
- (NSRange)range {
    return [I_rangeSelectionOperation selectedRange];
}
- (void)setRange:(NSRange)aRange {
    [I_rangeSelectionOperation setSelectedRange:aRange];
}

- (void)setIndentationLevel:(int)indentationLevel {
    I_indentationLevel=indentationLevel;
}

- (int)indentationLevel {
    return I_indentationLevel;
}

- (BOOL)isSeparator {
    return I_isSeparator;
}

-(NSComparisonResult)sortByRange:(SymbolTableEntry *)other {
    NSRange me = [self range];
    NSRange he = [other range];
    if (he.location<me.location) return NSOrderedDescending;
    else if (he.location>me.location) return NSOrderedAscending;
    else return NSOrderedSame;
}

@end
