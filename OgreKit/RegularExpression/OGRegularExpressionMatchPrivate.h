/*
 * Name: OGRegularExpressionMatchPrivate.h
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

#import <Foundation/Foundation.h>
#import <OgreKit/OGRegularExpressionMatch.h>

@interface OGRegularExpressionMatch (Private)

/*********
 * 初期化 *
 *********/
- (id)initWithRegion:(OnigRegion*)region 
	index:(unsigned)anIndex
	enumerator:(OGRegularExpressionEnumerator*)enumerator
	terminalOfLastMatch:(unsigned)terminalOfLastMatch;

- (NSString*)_targetString;
- (NSString*)_escapeCharacter;
- (NSRange)_searchRange;
- (OnigRegion*)_region;

@end
