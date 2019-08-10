//  SymbolTableEntry.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 16 2004.

#import "SymbolTableEntry.h"
#import "SelectionOperation.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation SymbolTableEntry

+ (SymbolTableEntry *)symbolTableEntryWithName:(NSString *)aName fontTraitMask:(int)aMask image:(NSImage *)anImage type:(NSString *)aType  indentationLevel:(int)anIndentationLevel jumpRange:(NSRange)aJumpRange range:(NSRange)aRange {
    SymbolTableEntry *result=[SymbolTableEntry new];
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
    SymbolTableEntry *result=[SymbolTableEntry new];
    [result setIsSeparator:YES];
    return result;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        I_jumpRangeSelectionOperation=[SelectionOperation new];
        I_rangeSelectionOperation    =[SelectionOperation new];
    }
    return self;
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

-(NSComparisonResult)sortByRange:(SymbolTableEntry *)other {
    NSRange me = [self range];
    NSRange he = [other range];
    if (he.location<me.location) return NSOrderedDescending;
    else if (he.location>me.location) return NSOrderedAscending;
    else return NSOrderedSame;
}

@end
