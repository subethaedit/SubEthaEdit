/*
 * Name: WildcardController.h
 * Project: OgreKit
 *
 * Creation Date: Oct 07 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>


@interface WildcardController : NSObject
{
    IBOutlet id wildcardWindow;
    IBOutlet id findNameTextField;
    IBOutlet id ignoreCaseCheckBox;
    IBOutlet id regexCheckBox;
    IBOutlet id replaceNameTextField;
    IBOutlet id showFinderCheckBox;
    IBOutlet id statusTextField;
    IBOutlet id findPopUp;
    IBOutlet id replaceTitle;
    IBOutlet id desktopCheckBox;
    IBOutlet id renameButton;
	
	BOOL	_findInComment;
	int		_targetWindowID;
}

/* accessors */
- (unsigned)options;
- (NSString*)escapeCharacter;
- (OgreSyntax)syntax;
- (OGRegularExpression*)regex;

/* IB actions */
- (IBAction)copy:(id)sender;
- (IBAction)rename:(id)sender;
- (IBAction)select:(id)sender;
- (IBAction)trash:(id)sender;
// 検索種類の変更
- (IBAction)changePopUp:(id)sender;

/* update */
// _findInCommentに合わせてタイトル等を更新する。
- (void)updateButtonTitle;

/* AppleScript */
// 検索対象となる項目名・コメントの一覧を得る。
- (void)getAllItemsInTargetWindow:(NSArray**)allItems comments:(NSArray**)comments;
// AppleScriptを実行する。
- (void)doAppleScriptString:(NSString*)aSctiptString trimLine:(NSString*)aMessage activateFinder:(BOOL)isActivate;
// Finderを最前面に持ってくる。
- (void)activateFinder;

/* alert sheet */
// エラー表示
- (void)showErrorAlert:(NSString*)title message:(NSString*)message;
// 項目を削除していいか確認する
- (void)confirmDecisionToTrash:(NSString*)message contextInfo:(void*)contextInfo;
// 項目をリネーム・リバイズしていいか確認する
- (void)confirmDecisionToRename:(NSString*)aMessage contextInfo:(void*)contextInfo findInComment:(BOOL)findInComment;

/* utility */
// yenとdouble quotationをyenで退避する
+ (NSString*)escapeUnsafeCharacters:(NSString*)aString;

@end
