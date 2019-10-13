//  LayoutManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.

#import <Cocoa/Cocoa.h>

@interface LayoutManager : NSLayoutManager {
    NSLayoutManager *I_invisiblesLayoutManager;
    NSTextStorage *I_invisiblesTextStorage;
}

@property (nonatomic) BOOL showsChangeMarks;
@property (nonatomic) BOOL showsInvisibles;
@property (nonatomic) BOOL showsInconsistentIndentation;
@property (nonatomic) BOOL usesTabs;


- (void)removeTemporaryAttributes:(id)anObjectEnumerable forCharacterRange:(NSRange)aRange;

- (void)forceTextViewGeometryUpdate;

@property (nonatomic, strong) NSColor *invisibleCharacterColor;
@property (nonatomic, strong) NSColor *inactiveSelectionColor;
@end
