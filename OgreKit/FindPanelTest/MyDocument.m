/*
 * Name: MyObject.m
 * Project: OgreKit
 *
 * Creation Date: Sep 29 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import "MyDocument.h"


@implementation MyDocument

// 検索対象となるTextViewをOgreTextFinderに教える。
// 検索させたくない場合はnilをsetする。
// 定義を省略した場合、main windowのfirst responderがNSTextViewならばそれを採用する。
- (void)tellMeTargetToFindIn:(id)textFinder
{
	[textFinder setTargetToFindIn:textView];
}


/* ここから下はFind Panelに関係しないコード */
- (NSString*)windowNibName {
    return @"MyDocument";
}

- (NSData*)dataRepresentationOfType:(NSString*)type {
	// 改行コードを(置換すべきなら)置換し、保存する。
	NSString *aString = [textView string];
	if ([aString newlineCharacter] != _newlineCharacter) {
		aString = [OGRegularExpression replaceNewlineCharactersInString:aString 
			withCharacter:_newlineCharacter];
	}
	
    return [aString dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)loadDataRepresentation:(NSData*)data ofType:(NSString*)type {
	// ファイルから読み込む。(UTF8決めうち。)
	_tmpString = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	// 改行コードの種類を得る。
	_newlineCharacter = [_tmpString newlineCharacter];
	if (_newlineCharacter == OgreNonbreakingNewlineCharacter) {
		// 改行のない場合はOgreUnixNewlineCharacterとみなす。
		//NSLog(@"nonbreaking");
		_newlineCharacter = OgreUnixNewlineCharacter;
	}
	
	// 改行コードを(置換すべきなら)置換する。
	if (_newlineCharacter != OgreUnixNewlineCharacter) {
		[_tmpString replaceNewlineCharactersWithCharacter:OgreUnixNewlineCharacter];
	}
	//NSLog(@"newline character: %d (-1:Nonbreaking 0:LF(Unix) 1:CR(Mac) 2:CR+LF(Windows) 3:UnicodeLineSeparator 4:UnicodeParagraphSeparator)", _newlineCharacter, [OgreTextFinder newlineCharacterInString:_tmpString]);
	//NSLog(@"%@", [OGRegularExpression chomp:_tmpString]);
	
    return YES;
}

- (void)windowControllerDidLoadNib:(NSWindowController*)controller
{
	if (_tmpString) {
		[textView setString:_tmpString];
		[_tmpString release];
	} else {
		_newlineCharacter = OgreUnixNewlineCharacter;	// デフォルトの改行コード
	}
}

// 改行コードの変更
- (void)setNewlineCharacter:(OgreNewlineCharacter)aNewlineCharacter
{
	_newlineCharacter = aNewlineCharacter;
}

@end
