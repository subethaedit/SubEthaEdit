/*
 * Name: OgreTextFindThreadCenter.h
 * Project: OgreKit
 *
 * Creation Date: Oct 02 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>

/*
	Consumer-Producer patternを少し変形したもの
	
	OgreTextFinder:				Consumer
		(OgreTextFindThreadを生成し、Find All・Replace All・Highlightの作業をまかせる)
	OgreTextFindThreadCenter:	Depository
		(キューを常に監視するスレッドを持ち、結果が得られたらOgreTextFinderに非同期的に知らせる)
		(OgreTextFindThreadCenterからOgreTextFinderへのメッセージ送信にはproxyを使用するが、
		 逆の場合にはproxyを用いないで同期的に送信する。)
	OgreTextFindThread:			Producer
		(OgreTextFinderの下請けで別スレッドでFind All・Replace All・Highlightの作業をする)
	
	(変形した理由: 律儀にtargetのproxyを通して(非同期的に)置換やハイライト処理を行うと非常に遅いため。
	 そのため、targetの操作はproxyを通さず直に行い、完了通知のみ非同期的に行うことにした。)
 */
 
@class OgreTextFinder, OgreTextFindProgressSheet;

@interface OgreTextFindThreadCenter : NSObject
{
	id	_proxy; // textFinderのproxy
	
	NSMutableArray	*_resultQueue;		// Find All・Replace All・Highlightの作業結果を保持するキュー
	unsigned		_numberOfResults;   // その数
	NSLock			*_queueLock;		// キューのロック
	NSConditionLock	*_producerLock;		// Producer側のロック
}

/* 初期化 */
- (id)initWithTextFinder:(OgreTextFinder*)textFinder;
/* キュー監視用スレッドの生成 */
- (void)connectToTextFinder:(OgreTextFinder*)textFinder;
- (void)connectWithPorts:(NSArray*)ports;

/* キューを監視し追加されたらtextFinderに知らせる */
- (void)watchOnQueue;

/* キュー操作 */
- (void)getResult:(id*)result command:(OgreTextFindThreadType*)command target:(id*)target progressSheet:(OgreTextFindProgressSheet**)sheet;
- (void)putResult:(id)result command:(OgreTextFindThreadType)command target:(id)target progressSheet:(OgreTextFindProgressSheet*)sheet;

@end
