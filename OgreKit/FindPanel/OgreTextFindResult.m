/*
 * Name: OgreTextFindResult.m
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

#import <OgreKit/OgreTextFindResult.h>
#import <OgreKit/OgreTextFindProgressSheet.h>

@implementation OgreTextFindResult

+ (id)textFindResultWithType:(OgreTextFindResultType)resultType 
	target:(id)targetFindingIn 
	resultInfo:(id)resultInfo
{
	return [[[[self class] alloc] initWithType:resultType target:targetFindingIn resultInfo:resultInfo] autorelease];
}

- (id)initWithType:(OgreTextFindResultType)resultType 
	target:(id)targetFindingIn 
	resultInfo:(id)resultInfo
{
	self = [super init];
	if (self != nil) {
		_target = targetFindingIn;
		_resultType = resultType;
		_resultInfo = [resultInfo retain];
		_alertSheet = nil;
		_exception = nil;
	}
	return self;
}

- (void)dealloc
{
	[_resultInfo release];
	[_exception release];
	[_alertSheet release];
	[super dealloc];
}

- (BOOL)isSuccess
{
	switch(_resultType) {
		case OgreTextFindResultSuccess:
			return YES;
		case OgreTextFindResultFailure:
		case OgreTextFindResultError:
		default:
			return NO;
	}
}

/* result Informaion (OgreFindResult instance, error reason)*/
- (id)resultInfo
{
	return _resultInfo;
}

- (void)setAlertSheet:(id)aSheet exception:(NSException*)anException
{
	_alertSheet = [aSheet retain];
	_exception = [anException retain];
}

- (BOOL)alertIfErrorOccurred;
{
	if ((_resultType != OgreTextFindResultError) || (_exception == nil)) return NO;  // no error
	
	if (_alertSheet == nil) {
		// create an alert sheet
		_alertSheet = [[OgreTextFinder sharedTextFinder] alertSheetOnTarget:_target];
	}
	[_alertSheet showErrorAlert:[_exception name] message:[_exception reason]];
	
	return YES;
}


@end
