/*
 * Name: OGRegularExpressionEnumeratorPrivate.h
 * Project: OgreKit
 *
 * Creation Date: Sep 03 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>

// utf8stringのUTF8文字長
static inline unsigned Ogre_utf8charlen(unsigned char *const utf8string)
{
	unsigned char	byte = *utf8string;
	
	if ((byte & 0x80) == 0x00) return 1;	// 1 byte
	if ((byte & 0xe0) == 0xc0) return 2;	// 2 byte
	if ((byte & 0xf0) == 0xe0) return 3;	// 3 byte
	if ((byte & 0xf8) == 0xf0) return 4;	// 4 byte
	if ((byte & 0xfc) == 0xf8) return 4;	// 5 byte
	if ((byte & 0xfe) == 0xfc) return 4;	// 6 byte
	
	// subsequent byte in a multibyte code
	// 出会わないはずなので、出会ったら例外を起こす。
	[NSException raise:OgreEnumeratorException format:@"illegal byte code"];
	
	return 0;	// dummy
}

// utf8stringより１文字前のUTF8文字長
static inline unsigned Ogre_utf8prevcharlen(unsigned char *const utf8string)
{
	if ((*(utf8string - 1) & 0x80) == 0x00) return 1;  // 1 byte
	
	if ((*(utf8string - 1) & 0xc0) == 0x80) {
		if ((*(utf8string - 2) & 0xe0) == 0xc0) return 2;	// 2 bytes
		
		if ((*(utf8string - 2) & 0xc0) == 0x80) {
			if ((*(utf8string - 3) & 0xf0) == 0xe0) return 3;	// 3 bytes
			
			if ((*(utf8string - 3) & 0xc0) == 0x80) {
				if ((*(utf8string - 4) & 0xf8) == 0xf0) return 4;	// 4 bytes

				if ((*(utf8string - 4) & 0xc0) == 0x80) {
					if ((*(utf8string - 5) & 0xfc) == 0xf8) return 5;	// 5 bytes
					
					if ((*(utf8string - 5) & 0xc0) == 0x80) {
						if ((*(utf8string - 6) & 0xfe) == 0xfc) return 6;	// 6 bytes
					}
				}
			}
		}
	}
	
	// 出会わないはずなので、出会ったら例外を起こす。
	[NSException raise:OgreEnumeratorException format:@"illegal byte code"];
	
	return NULL;	// dummy
}


@class OGRegularExpression, OGRegularExpressionEnumerator;

@interface OGRegularExpressionEnumerator (Private)

/*********
 * 初期化 *
 *********/
- (id)initWithSwappedString:(NSString*)swappedTargetString 
	options:(unsigned)searchOptions 
	range:(NSRange)searchRange 
	regularExpression:(OGRegularExpression*)regex;

/*********************
 * private accessors *
 *********************/
- (void)_setUtf8TerminalOfLastMatch:(int)location;
- (void)_setIsLastMatchEmpty:(BOOL)yesOrNo;
- (void)_setStartLocation:(unsigned)location;
- (void)_setUtf8StartLocation:(unsigned)location;
- (void)_setNumberOfMatches:(unsigned)aNumber;

- (NSString*)swappedTargetString;
- (unsigned char*)utf8SwappedTargetString;

- (OGRegularExpression*)regularExpression;
- (void)setRegularExpression:(OGRegularExpression*)regularExpression;   // 注意! escapeCharacterは変えないように!

- (NSRange)searchRange;

/************
 * 破壊的操作 *
 ************/
- (NSString*)input;
- (void)less:(unsigned)aLength;

@end
