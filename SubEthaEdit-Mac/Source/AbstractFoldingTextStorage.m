//  AbstractFoldingTextStorage.m
//  TextEdit
//
//  Created by Dominik Wagner on 19.01.09.

#import "AbstractFoldingTextStorage.h"

@implementation AbstractFoldingTextStorage

- (instancetype)init {
	if ((self = [super init])) {
		I_fixingCounter = 0;
	}
	return self;
}

- (NSMutableAttributedString *)internalMutableAttributedString {
	return nil;
}

- (BOOL)readFromData:(NSData *)inData encoding:(NSStringEncoding)anEncoding {
	// try to create the NSString that we take our contents from
	NSString *contentString = [[NSString alloc] initWithBytesNoCopy:(void *)[inData bytes] length:[inData length] encoding:anEncoding freeWhenDone:NO];
	if (contentString) {
		[self replaceCharactersInRange:NSMakeRange(0,[self length]) withString:contentString];
		return YES;
	} else {
		return NO;
	}
}


// methods for having data in them in the gdb stacktraces

//- (NSDictionary *)attributesAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)aRange inRange:(NSRange)rangeLimit {
//	return [super attributesAtIndex:index longestEffectiveRange:aRange inRange:rangeLimit];
//}
//
//- (id)attribute:(NSString *)attributeName atIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange {
//	return [super attribute:attributeName atIndex:index effectiveRange:aRange];
//}
//
//- (id)attribute:(NSString *)attributeName atIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)aRange inRange:(NSRange)rangeLimit {
//	return [super attribute:attributeName atIndex:index longestEffectiveRange:aRange inRange:rangeLimit];
//}
//
#pragma mark synchronization deadlock preventing methods

- (void)fixFontAttributeInRange:(NSRange)inRange {
	I_fixingCounter ++;
	[super fixFontAttributeInRange:inRange];
	I_fixingCounter --;
}

- (void)fixAttributesInRange:(NSRange)inRange {
	I_fixingCounter ++;
//	NSLog(@"%s %@ %@ - my length: %d",__FUNCTION__,[self class], NSStringFromRange(inRange), [self length]);
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
