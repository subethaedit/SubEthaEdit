//
//  SEEFindAndReplaceState.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 28.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import "SEEFindAndReplaceState.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif


@implementation SEEFindAndReplaceState

- (instancetype)init {
	self = [super init];
	if (self) {
		self.findString = @"";
		self.replaceString = @"";
		self.regexOptions = OgreSingleLineOption | OgreMultilineOption | OgreFindNotEmptyOption | OgreCaptureGroupOption;
		self.caseSensitive = NO;
		self.regularExpressionSyntax = OgreRubySyntax;
		self.scope = kSEEFindAndReplaceScopeDocument;
		self.useRegex = NO;
		self.regularExpressionEscapeCharacter = OgreBackslashCharacter;
		self.shouldWrap = YES;
	}
	return self;
}

@end
