//
//  AbstractFoldingTextStorage.m
//  TextEdit
//
//  Created by Dominik Wagner on 19.01.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import "AbstractFoldingTextStorage.h"


@implementation AbstractFoldingTextStorage

- (id)init {
	if ((self = [super init])) {
		I_fixingCounter = 0;
		I_otherTextStorage = nil;
	}
	return self;
}

- (NSMutableAttributedString *)internalMutableAttributedString {
	return nil;
}


#pragma mark synchronization deadlock preventing methods

- (void)fixFontAttributeInRange:(NSRange)inRange {
	I_fixingCounter ++;
	[super fixFontAttributeInRange:inRange];
	I_fixingCounter --;
}

- (void)fixAttributesInRange:(NSRange)inRange {
	I_fixingCounter ++;
	[super fixAttributesInRange:inRange];
	I_fixingCounter --;
}

- (void)fixAttachmentAttributeInRange:(NSRange)inRange {
	I_fixingCounter ++;
	[super fixAttachmentAttributeInRange:inRange];
	I_fixingCounter --;
}

#pragma mark stubs for synchronizing subclasses

#pragma mark basic methods for synchronization
- (void)replaceCharactersInRange:(NSRange)aRange withString:(NSString *)aString synchronize:(BOOL)inSynchronizeFlag {};
- (void)setAttributes:(NSDictionary *)attributes range:(NSRange)aRange synchronize:(BOOL)inSynchronizeFlag {};


@end
