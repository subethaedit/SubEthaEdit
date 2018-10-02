//
//  AbstractFoldingTextStorage.h
//  TextEdit
//
//  Created by Dominik Wagner on 19.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AbstractFoldingTextStorage : NSTextStorage {
	int I_fixingCounter;
	id I_otherTextStorage;
}

- (NSMutableAttributedString *)internalMutableAttributedString;

#pragma mark basic methods for synchronization
- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString synchronize:(BOOL)inSynchronizeFlag;
- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange synchronize:(BOOL)inSynchronizeFlag;

- (BOOL)readFromData:(NSData *)inData encoding:(NSStringEncoding)anEncoding;

@end
	