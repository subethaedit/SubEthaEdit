/*
 * Name: OgreTextFindThread.h
 * Project: OgreKit
 *
 * Creation Date: Sep 26 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OGRegularExpression.h>

// スレッドに割り当てられた作業の種類
typedef enum _OgreTextFindThreadType {
	OgreFindNothingThread = 0,
	OgreFindAllThread, 
	OgreReplaceAllThread, 
	OgreHighlightThread
} OgreTextFindThreadType;

@class	OgreTextFindThreadCenter, OgreTextFindProgressSheet;

@interface OgreTextFindThread : NSObject
{
	OgreTextFindThreadCenter	*_threadCenter;		// 結果の送り先
	
	OgreTextFindProgressSheet	*_progressSheet;	// 進歩状況表示用シート
	BOOL	_cancelled;								// キャンセルされたかどうか。two-phase termination。
	
	OgreTextFindThreadType		_command;			// 作業の種類
	id							_target;			// 検索対象 (今のところNSTextViewのみ)
	NSString					*_text;				// 検索対象文字列
	OGRegularExpression			*_regex;			// 検索パターン
	unsigned					_options;			// 検索オプション
	NSString					*_replaceString;	// 置換文字列
	NSColor						*_color;			// ハイライトカラー
	BOOL						_inSelection;		// 選択範囲内検索かどうか
}

/* 初期化 */
- (id)initWithCenter:(OgreTextFindThreadCenter*)aCenter;
/* 処理開始 */
- (void)start:(OgreTextFindThreadType)command 
	target:(id)target 
	regularExpression:(OGRegularExpression*)regularExpression 
	options:(unsigned)options 
	replaceString:(NSString*)replaceString 
	color:(NSColor*)highlightColor 
	inSelection:(BOOL)inSelection 
	progressSheet:(OgreTextFindProgressSheet*)progressSheet;
/* Cancel */
- (void)cancel:(id)sender;
/* 完了したことをシートに表示 */
- (void)showDone:(double)progression count:(int)count time:(NSTimeInterval)processTime cancelled:(BOOL)cancelled;
/* 完了 */
- (void)sendResult:(id)result;

@end
