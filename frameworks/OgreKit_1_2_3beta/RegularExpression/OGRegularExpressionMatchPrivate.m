/*
 * Name: OGRegularExpressionMatchPrivate.m
 * Project: OgreKit
 *
 * Creation Date: Sep 01 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionPrivate.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OGRegularExpressionMatchPrivate.h>
#import <OgreKit/OGRegularExpressionEnumerator.h>
#import <OgreKit/OGRegularExpressionEnumeratorPrivate.h>


@implementation OGRegularExpressionMatch (Private)

/* 非公開メソッド */
- (id)initWithRegion:(OnigRegion*)region 
	index:(unsigned)anIndex
	enumerator:(OGRegularExpressionEnumerator*)enumerator
	locationCache:(unsigned)locationCache 
	utf8LocationCache:(unsigned)utf8LocationCache 
	utf8TerminalOfLastMatch:(unsigned)utf8TerminalOfLastMatch 
	parentMatch:(OGRegularExpressionMatch*)parentMatch 
{
#ifdef DEBUG_OGRE
	NSLog(@"-initWithRegion: of OGRegularExpressionMatch");
#endif
	self = [super init];
	if (self) {
		// parent (A OGRegularExpression instance has a region containing _region)
		_parentMatch = [parentMatch retain];
		
		// match result region
		_region = region;	// retain
	
		// 生成主
		_enumerator = [enumerator retain];
		
		// 既に分かっているNSStringの長さとUTF8Stringの長さの対応
		_locationCache = locationCache;
		_utf8LocationCache = utf8LocationCache;		// >= _region->beg[0]が必要条件
		// 最後にマッチした文字列の終端位置
		_utf8TerminalOfLastMatch = utf8TerminalOfLastMatch;
		// マッチした順番
		_index = anIndex;
		
		// 頻繁に利用するものはキャッシュする。保持はしない。
		// 検索対象文字列
		_swappedTargetString     = [_enumerator swappedTargetString];
		_utf8SwappedTargetString = [_enumerator utf8SwappedTargetString];
		// 検索範囲
		NSRange	searchRange = [_enumerator searchRange];
		_searchRange.location = searchRange.location;
		_searchRange.length   = searchRange.length;
		// 代替\文字を保持
		_escapeCharacter = [[_enumerator regularExpression] escapeCharacter];
	}
	
	return self;
}

- (void)dealloc
{
#ifdef DEBUG_OGRE
	NSLog(@"-dealloc of OGRegularExpressionMatch");
#endif
	// 解放
	[_enumerator release];

	// リージョンの開放
	if (_parentMatch != nil) {
		[_parentMatch release];
	} else if (_region != NULL) {
		onig_region_free(_region, 1 /* free self */);
	}
	
	[super dealloc];
}


@end
