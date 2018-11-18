//  SymbolTableEntry.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 16 2004.

#import <Cocoa/Cocoa.h>

@class SelectionOperation;

@interface SymbolTableEntry : NSObject {
    NSString *I_name;
    int       I_fontTraitMask;
    NSImage  *I_image;
    NSString *I_type;
    SelectionOperation *I_jumpRangeSelectionOperation;
    SelectionOperation *I_rangeSelectionOperation;
    int      I_indentationLevel;
    BOOL I_isSeparator;
}

+ (SymbolTableEntry *)symbolTableEntryWithName:(NSString *)aName fontTraitMask:(int)aMask image:(NSImage *)anImage type:(NSString *)aType indentationLevel:(int)anIndentationLevel jumpRange:(NSRange)aJumpRange range:(NSRange)aRange;
+ (SymbolTableEntry *)symbolTableEntrySeparator;

- (NSString *)name;
- (void)setName:(NSString *)name;
- (int)fontTraitMask;
- (void)setFontTraitMask:(int)aMask;
- (NSImage *)image;
- (void)setImage:(NSImage *)anImage;
- (NSString *)type;
- (void)setType:(NSString *)aType;
- (SelectionOperation *)jumpRangeSelectionOperation;
- (NSRange)jumpRange;
- (void)setJumpRange:(NSRange)aJumpRange;
- (SelectionOperation *)rangeSelectionOperation;
- (NSRange)range;
- (void)setRange:(NSRange)aRange;
- (void)setIndentationLevel:(int)aIndentationLevel;
- (int)indentationLevel;
- (void)setIsSeparator:(BOOL)aFlag;
- (BOOL)isSeparator;
@end
