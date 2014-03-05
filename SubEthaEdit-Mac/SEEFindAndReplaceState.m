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

@dynamic regularExpressionOptionCaptureGroups, regularExpressionOptionExtended, regularExpressionOptionIgnoreEmptyMatches, regularExpressionOptionLineContext, regularExpressionOptionMultiline, regularExpressionOptionOnlyLongestMatch;

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
		self.statusString = @"";
	}
	return self;
}

// const unsigned	OgreNoneOption				= ONIG_OPTION_NONE;
//const unsigned OgreSingleLineOption		= ONIG_OPTION_SINGLELINE;
//const unsigned OgreMultilineOption			= ONIG_OPTION_MULTILINE;
//const unsigned OgreIgnoreCaseOption		= ONIG_OPTION_IGNORECASE;
//const unsigned OgreExtendOption			= ONIG_OPTION_EXTEND;
//const unsigned OgreFindLongestOption		= ONIG_OPTION_FIND_LONGEST;
//const unsigned OgreFindNotEmptyOption		= ONIG_OPTION_FIND_NOT_EMPTY;
//const unsigned OgreNegateSingleLineOption	= ONIG_OPTION_NEGATE_SINGLELINE;
//const unsigned OgreDontCaptureGroupOption	= ONIG_OPTION_DONT_CAPTURE_GROUP;
//const unsigned OgreCaptureGroupOption		= ONIG_OPTION_CAPTURE_GROUP;


#define REGEXOPTION_SET_OPTION(OPTION,VALUE) 	unsigned options = self.regexOptions; \
if (VALUE) { \
	options = ONIG_OPTION_ON(options, OPTION); \
} else { \
	options = ONIG_OPTION_OFF(options, OPTION); \
} \
self.regexOptions = options


- (BOOL)regularExpressionOptionCaptureGroups {
	BOOL result = (!ONIG_IS_OPTION_ON(self.regexOptions,ONIG_OPTION_DONT_CAPTURE_GROUP)) &&
		ONIG_IS_OPTION_ON(self.regexOptions, ONIG_OPTION_CAPTURE_GROUP);
	return result;
}

- (void)setRegularExpressionOptionCaptureGroups:(BOOL)anOption {
	unsigned options = self.regexOptions;
	if (anOption) {
		options = ONIG_OPTION_ON(options, ONIG_OPTION_CAPTURE_GROUP);
		options = ONIG_OPTION_OFF(options, ONIG_OPTION_DONT_CAPTURE_GROUP);
	} else {
		options = ONIG_OPTION_OFF(options, ONIG_OPTION_CAPTURE_GROUP);
		options = ONIG_OPTION_ON(options, ONIG_OPTION_DONT_CAPTURE_GROUP);
	}
	self.regexOptions = options;
}

- (BOOL)regularExpressionOptionLineContext {
	BOOL result = (!ONIG_IS_OPTION_ON(self.regexOptions,ONIG_OPTION_NEGATE_SINGLELINE)) &&
	ONIG_IS_OPTION_ON(self.regexOptions, ONIG_OPTION_SINGLELINE);
	return result;
}

- (void)setRegularExpressionOptionLineContext:(BOOL)anOption {
	unsigned options = self.regexOptions;
	if (anOption) {
		options = ONIG_OPTION_ON(options, ONIG_OPTION_SINGLELINE);
		options = ONIG_OPTION_OFF(options, ONIG_OPTION_NEGATE_SINGLELINE);
	} else {
		options = ONIG_OPTION_OFF(options, ONIG_OPTION_SINGLELINE);
		options = ONIG_OPTION_ON(options, ONIG_OPTION_NEGATE_SINGLELINE);
	}
	self.regexOptions = options;
}


- (BOOL)regularExpressionOptionExtended {
	BOOL result = ONIG_IS_OPTION_ON(self.regexOptions, ONIG_OPTION_EXTEND);
	return result;
}

- (void)setRegularExpressionOptionExtended:(BOOL)anOption {
	REGEXOPTION_SET_OPTION(ONIG_OPTION_EXTEND,anOption);
}

- (BOOL)regularExpressionOptionIgnoreEmptyMatches {
	BOOL result = ONIG_IS_OPTION_ON(self.regexOptions, ONIG_OPTION_FIND_NOT_EMPTY);
	return result;
}

- (void)setRegularExpressionOptionIgnoreEmptyMatches:(BOOL)anOption {
	REGEXOPTION_SET_OPTION(ONIG_OPTION_FIND_NOT_EMPTY,anOption);
}

- (BOOL)regularExpressionOptionOnlyLongestMatch {
	BOOL result = ONIG_IS_OPTION_ON(self.regexOptions, ONIG_OPTION_FIND_LONGEST);
	return result;
}

- (void)setRegularExpressionOptionOnlyLongestMatch:(BOOL)anOption {
	REGEXOPTION_SET_OPTION(ONIG_OPTION_FIND_LONGEST,anOption);
}

- (BOOL)regularExpressionOptionMultiline {
	BOOL result = ONIG_IS_OPTION_ON(self.regexOptions, ONIG_OPTION_MULTILINE);
	return result;
}

- (void)setRegularExpressionOptionMultiline:(BOOL)anOption {
	REGEXOPTION_SET_OPTION(ONIG_OPTION_MULTILINE,anOption);
}


/* 	OgreSimpleMatchingSyntax = 0,
 OgrePOSIXBasicSyntax,
 OgrePOSIXExtendedSyntax,
 OgreEmacsSyntax,
 OgreGrepSyntax,
 OgreGNURegexSyntax,
 OgreJavaSyntax,
 OgrePerlSyntax,
 OgreRubySyntax
*/

+ (NSString *)regularExpressionSyntaxStringForSyntax:(OgreSyntax)aSyntax {
	switch (aSyntax) {
		case OgreRubySyntax:
			return @"Ruby";
		case OgrePerlSyntax:
			return @"Perl";
		case OgreJavaSyntax:
			return @"Java";
		case OgreGNURegexSyntax:
			return @"GNU Regex";
		case OgreGrepSyntax:
			return @"Grep";
		case OgreEmacsSyntax:
			return @"Emacs";
		case OgrePOSIXExtendedSyntax:
			return @"POSIX extended";
		case OgrePOSIXBasicSyntax:
			return @"POSIX basic";
		case OgreSimpleMatchingSyntax:
			return @"Ogre simple";
	}
}

- (NSString *)regularExpressionSyntaxString {
	NSString *result = [self.class regularExpressionSyntaxStringForSyntax:self.regularExpressionSyntax];
	return result;
}

@end
