//
//  OGEscapeCharacterFormatter.h
//  OgreKit
//
//  Created by Isao Sonobe on Sat Feb 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OGRegularExpression, OGRegularExpressionMatch;

/* 入力された文字列を頭の1文字にするformatter */
@protocol OgreAFPCEscapeCharacterFormatterDelegate
- (NSString*)escapeCharacter;
- (BOOL)shouldEquateYenWithBackslash;
@end

@interface OgreAFPCEscapeCharacterFormatter : NSFormatter
{
	id <OgreAFPCEscapeCharacterFormatterDelegate> _delegate;
	
	OGRegularExpression *_backslashRegex, *_yenRegex;
}

// 必須メソッド
//- (NSString*)stringForObjectValue:(id)anObject;
//- (NSAttributedString*)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary*)attributes;
// エラー判定
//- (BOOL)getObjectValue:(id*)obj forString:(NSString*)string errorDescription:(NSString**)error;

// delegate
- (void)setDelegate:(id)aDelegate;
// 変換
- (NSString*)equateInString:(NSString*)string;
- (NSString*)equateYenWithBackslash:(OGRegularExpressionMatch*)aMatch contextInfo:(id)contextInfo;

@end
