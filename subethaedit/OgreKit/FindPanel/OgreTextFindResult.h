/*
 * Name: OgreTextFindResult.h
 * Project: OgreKit
 *
 * Creation Date: Apr 18 2004
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionMatch.h>
#import <OgreKit/OgreTextFinder.h>

typedef enum {
	OgreTextFindResultFailure = 0, 
	OgreTextFindResultSuccess = 1, 
	OgreTextFindResultError = 2
} OgreTextFindResultType;

@interface OgreTextFindResult : NSObject
{
	OgreTextFindResultType		_resultType;
	id							_target;
	id							_resultInfo;
	NSException					*_exception;
	id							_alertSheet;
}

+ (id)textFindResultWithType:(OgreTextFindResultType)resultType 
	target:(id)targetFindingIn 
	resultInfo:(id)resultInfo;

- (id)initWithType:(OgreTextFindResultType)resultType 
	target:(id)targetFindingIn 
	resultInfo:(id)resultInfo;

- (BOOL)isSuccess;				/* success or failure(including error) */
- (id)resultInfo;				/* result Informaion (OgreFindResult instance)*/

- (BOOL)alertIfErrorOccurred;

- (void)setAlertSheet:(id)aSheet exception:(NSException*)anException;

@end
