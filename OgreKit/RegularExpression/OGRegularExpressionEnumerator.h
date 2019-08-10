/*
 * Name: OGRegularExpressionEnumerator.h
 * Project: OgreKit
 *
 * Creation Date: Sep 03 2003
 * Author: Isao Sonobe <sonoisa@gmail.com>
 * Copyright: Copyright (c) 2003-2018 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>

@class OGRegularExpression;

// Exception
extern NSString	* const OgreEnumeratorException;

@interface OGRegularExpressionEnumerator : NSEnumerator <NSCopying, NSCoding>
{
	OGRegularExpression	*_regex;				// 正規表現オブジェクト
	NSObject<OGStringProtocol>			*_targetString;			// 検索対象文字列
	unichar             *_UTF16TargetString;	// UTF16での検索対象文字列
	NSUInteger			_lengthOfTargetString;	// [_targetString length]
	NSRange				_searchRange;			// 検索範囲
	OnigOptionType		_searchOptions;			// 検索オプション
	NSInteger			_terminalOfLastMatch;	// 前回にマッチした文字列の終端位置  (_region->end[0] / sizeof(unichar))
	NSUInteger			_startLocation;			// マッチ開始位置
	BOOL				_isLastMatchEmpty;		// 前回のマッチが空文字列だったかどうか
	
	NSUInteger			_numberOfMatches;		// マッチした数
}

// 全マッチ結果を配列で返す。
- (NSArray*)allObjects;
// 次のマッチ結果を返す。
- (id)nextObject;

// description
- (NSString*)description;

@end
