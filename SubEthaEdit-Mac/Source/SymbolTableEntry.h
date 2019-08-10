//  SymbolTableEntry.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 16 2004.

#import <Cocoa/Cocoa.h>

@class SelectionOperation;

@interface SymbolTableEntry : NSObject {
    SelectionOperation *I_jumpRangeSelectionOperation;
    SelectionOperation *I_rangeSelectionOperation;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int fontTraitMask;
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) int indentationLevel;
@property (nonatomic, assign) BOOL isSeparator;


+ (SymbolTableEntry *)symbolTableEntryWithName:(NSString *)aName fontTraitMask:(int)aMask image:(NSImage *)anImage type:(NSString *)aType indentationLevel:(int)anIndentationLevel jumpRange:(NSRange)aJumpRange range:(NSRange)aRange;
+ (SymbolTableEntry *)symbolTableEntrySeparator;

- (SelectionOperation *)jumpRangeSelectionOperation;
- (NSRange)jumpRange;
- (void)setJumpRange:(NSRange)aJumpRange;
- (SelectionOperation *)rangeSelectionOperation;
- (NSRange)range;
- (void)setRange:(NSRange)aRange;
@end
