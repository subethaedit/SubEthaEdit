//
//  FullTextStorage.h
//  TextEdit
//
//  Created by Dominik Wagner on 04.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FoldableTextStorage;

@interface FullTextStorage : NSTextStorage {
	NSMutableAttributedString *I_internalAttributedString;
	FoldableTextStorage *I_foldableTextStorage;
}

- (id)initWithFoldableTextStorage:(FoldableTextStorage *)inTextStorage;

#pragma mark basic methods for synchronization
- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString synchronize:(BOOL)inSynchroFlag;
- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange synchronize:(BOOL)inSynchronizeFlag;

@end
