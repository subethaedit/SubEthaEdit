//
//  LayoutManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Apr 06 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LayoutManager : NSLayoutManager {
    struct {
        BOOL showsChangeMarks;
        BOOL showsInvisibles;
    } I_flags;
    NSLayoutManager *I_invisiblesLayoutManager;
    NSTextStorage *I_invisiblesTextStorage;
#if defined(CODA)
	NSColor *I_invisibleCharacterColor;
#endif //defined(CODA)
}

- (BOOL)showsChangeMarks;
- (void)setShowsChangeMarks:(BOOL)showsChangeMarks;
- (BOOL)showsInvisibles;
- (void)setShowsInvisibles:(BOOL)aFlag;

- (void)removeTemporaryAttributes:(id)anObjectEnumerable forCharacterRange:(NSRange)aRange;

@end

#if defined(CODA)
@interface LayoutManager (Coda)
- (void)setInvisibleCharacterColor:(NSColor*)aColor;
- (NSColor*)invisibleCharacterColor;
@end
#endif //defined(CODA)