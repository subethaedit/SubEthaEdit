/*
 * Name: OgreTextFinder.h
 * Project: OgreKit
 *
 * Creation Date: Sep 20 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGReplaceExpression.h>
#import <OgreKit/OgreTextFindThread.h>
#import <OgreKit/OgreTextFindThreadCenter.h>

// OgreTextFinderLocalizable.stringsを使用したローカライズ
#define OgreTextFinderLocalizedString(key)	[[OgreTextFinder ogreKitBundle] localizedStringForKey:(key) value:(key) table:@"OgreTextFinderLocalizable"]

@class OgreTextFinder, OgreFindPanelController, OgreTextFindResult, OgreFindResult, OgreTextFindThread, OgreTextFindThreadCenter;

@protocol OgreTextFindDataSource
/* OgreTextFinderが検索対象を知りたいときにresponder chain経由で呼ばれる 
   document windowのdelegateがimplementすることを想定している */
- (void)tellMeTargetToFindIn:(id)sender;
@end

@protocol OgreTextFindThreadClient
/* OgreTextFindThreadでの処理が完了したときにOgreTextFinderから呼ばれる */
- (BOOL)didEndFindAll:(id)anObject;
- (BOOL)didEndReplaceAll:(id)anObject;
- (BOOL)didEndHighlight:(id)anObject;
@end

@protocol OgreTextFinderProtocol
/* OgreTextFindThreadでの処理が完了したときにOgreTextFindThreadCenterから非同期的に通知される */
- (oneway void)didEndThread;
@end

@interface OgreTextFinder : NSObject <OgreTextFinderProtocol>
{
	IBOutlet OgreFindPanelController	*findPanelController;	// FindPanelController
    IBOutlet NSMenu						*findMenu;				// Find manu
	
	OgreSyntax		_syntax;				// 正規表現の構文
	NSString		*_escapeCharacter;		// escape character
	
	id				_targetToFindIn;		// 検索対象
	NSMutableArray	*_busyTargetArray;		// 使用中ターゲット
	OgreTextFindThreadCenter	*_threadCenter;	// OgreTextFindThreadCenter

	NSDictionary	*_history;				// 検索履歴等
	BOOL			_saved;					// 履歴等が保存されたかどうか
}

/* OgreKit.framework bundle instance */
+ (NSBundle*)ogreKitBundle;

/* Shared Instance */
+ (id)sharedTextFinder;

/* nib name of Find Panel/Find Panel Controller */
- (NSString*)findPanelNibName;

/* Show Find Panel */
- (IBAction)showFindPanel:(id)sender;

/*************
 * Accessors *
 *************/
// 検索対象
- (void)setTargetToFindIn:(id)targe;
- (id)targetToFindIn;

// Find Panel Controller
- (void)setFindPanelController:(OgreFindPanelController*)findPanelController;
- (OgreFindPanelController*)findPanelController;

// escape character
- (void)setEscapeCharacter:(NSString*)character;
- (NSString*)escapeCharacter;

// syntax
- (void)setSyntax:(OgreSyntax)syntax;
- (OgreSyntax)syntax;

/* Find/Replace/Highlight... */
- (OgreTextFindResult*)find:(NSString*)expressionString 
	options:(unsigned)options
	fromTop:(BOOL)isTop
	forward:(BOOL)forward
	wrap:(BOOL)isWrap;

- (OgreTextFindResult*)findAll:(NSString*)expressionString 
	color:(NSColor*)highlightColor 
	options:(unsigned)options
	inSelection:(BOOL)inSelection;

- (OgreTextFindResult*)replace:(NSString*)expressionString 
	withString:(NSString*)replaceString
	options:(unsigned)options;

- (OgreTextFindResult*)replaceAll:(NSString*)expressionString 
	withString:(NSString*)replaceString
	options:(unsigned)options
	inSelection:(BOOL)inSelection;

- (OgreTextFindResult*)hightlight:(NSString*)expressionString 
	color:(NSColor*)highlightColor 
	options:(unsigned)options
	inSelection:(BOOL)inSelection;

- (OgreTextFindResult*)unhightlight;

- (NSString*)selectedString;
- (BOOL)isSelectionEmpty;

- (BOOL)jumpToSelection;

/* create an alert sheet */
- (id)alertSheetOnTarget:(id)aTerget;

/*******************
 * Private Methods *
 *******************/
// 前回保存された履歴
- (NSDictionary*)history;
// currentを起点に名前がnameのmenu itemを探す。
- (NSMenuItem*)findMenuItemNamed:(NSString*)name startAt:(NSMenu*)current;

// ターゲットが使用中かどうか
- (BOOL)isBusyTarget:(id)target;
// 使用中にする
- (void)makeTargetBusy:(id)target;
// 使用中でなくする
- (void)makeTargetFree:(id)target;

/* create a thread */
// OgreTextFindThreadCenterの生成
- (void)createThreadCenter;

/* Undo/Redoについてプリミティブな置換 */
- (void)undoableReplaceCharactersInRange:(NSRange)aRange 
	withAttributedString:(NSAttributedString*)aString 
	inTarget:(id)aTarget 
	jumpToSelection:(BOOL)jumpToSelection;

@end

