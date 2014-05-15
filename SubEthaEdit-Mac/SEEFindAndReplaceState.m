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

NSString * const kFindAndReplaceKeyFindString = @"find";
NSString * const kFindAndReplaceKeyReplaceString = @"replace";
NSString * const kFindAndReplaceKeyShouldWrap = @"wraps";
NSString * const kFindAndReplaceKeyCaseSensitive = @"caseSensitive";
NSString * const kFindAndReplaceKeyUseRegex = @"useRegex";
NSString * const kFindAndReplaceKeyRegexOptions = @"regexOptions";
NSString * const kFindAndReplaceKeySyntax = @"syntax";
NSString * const kFindAndReplaceKeyEscapeCharacter = @"escapeCharacter";
NSString * const kFindAndReplaceKeyCaptureGroups = @"captureGroups";
NSString * const kFindAndReplaceKeyLineContext = @"lineContext";
NSString * const kFindAndReplaceKeyMultiline = @"multiline";
NSString * const kFindAndReplaceKeyExtended = @"extended";
NSString * const kFindAndReplaceKeyIgnoreEmptyMatches = @"ignoreEmptyMatches";
NSString * const kFindAndReplaceKeyOnlyLongestMatch = @"onlyLongestMatch";

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
	ONIG_OPTION_ON(options, OPTION); \
} else { \
	ONIG_OPTION_OFF(options, OPTION); \
} \
self.regexOptions = options

- (instancetype)copyWithZone:(NSZone *)zone {
	SEEFindAndReplaceState *result = [SEEFindAndReplaceState new];
	[result takeValuesFromDictionaryRepresentation:self.dictionaryRepresentation];
	return result;
}

- (unsigned int)regexOptionsForExpressionBuilding {
	unsigned int result = 0;
	if (self.useRegex) {
		result = self.regexOptions;
	}
	if (!self.caseSensitive) {
		ONIG_OPTION_ON(result, ONIG_OPTION_IGNORECASE);
	}
	return result;
}

- (BOOL)regularExpressionOptionCaptureGroups {
	BOOL result = (!ONIG_IS_OPTION_ON(self.regexOptions,ONIG_OPTION_DONT_CAPTURE_GROUP)) &&
		ONIG_IS_OPTION_ON(self.regexOptions, ONIG_OPTION_CAPTURE_GROUP);
	return result;
}

- (void)setRegularExpressionOptionCaptureGroups:(BOOL)anOption {
	unsigned options = self.regexOptions;
	if (anOption) {
		ONIG_OPTION_ON(options, ONIG_OPTION_CAPTURE_GROUP);
		ONIG_OPTION_OFF(options, ONIG_OPTION_DONT_CAPTURE_GROUP);
	} else {
		ONIG_OPTION_OFF(options, ONIG_OPTION_CAPTURE_GROUP);
		ONIG_OPTION_ON(options, ONIG_OPTION_DONT_CAPTURE_GROUP);
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
		ONIG_OPTION_ON(options, ONIG_OPTION_SINGLELINE);
		ONIG_OPTION_OFF(options, ONIG_OPTION_NEGATE_SINGLELINE);
	} else {
		ONIG_OPTION_OFF(options, ONIG_OPTION_SINGLELINE);
		ONIG_OPTION_ON(options, ONIG_OPTION_NEGATE_SINGLELINE);
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

+ (NSDictionary *)TCMSyntaxToStringDictionary {
	static NSDictionary *s_dictionary = nil;
	if (!s_dictionary) {
		s_dictionary = @{
		   @(OgreRubySyntax):@"Ruby",
		   @(OgrePerlSyntax):@"Perl",
		   @(OgreJavaSyntax):@"Java",
		   @(OgreGNURegexSyntax):@"GNU Regex",
		   @(OgreGrepSyntax):@"Grep",
		   @(OgreEmacsSyntax):@"Emacs",
		   @(OgrePOSIXExtendedSyntax):@"POSIX extended",
		   @(OgrePOSIXBasicSyntax):@"POSIX basic",
		   @(OgreSimpleMatchingSyntax):@"Ogre simple",
		   };
	}
	return s_dictionary;
}

+ (NSString *)regularExpressionSyntaxStringForSyntax:(OgreSyntax)aSyntax {
	NSString *result = [self TCMSyntaxToStringDictionary][@(aSyntax)];
	if (!result) {
		result = @"Ruby";
	}
	return result;
}

+ (OgreSyntax)syntaxForRegularExpressionSyntaxString:(NSString *)aSyntaxString {
	__block OgreSyntax result = OgreRubySyntax;
	NSDictionary *dictionary = [self TCMSyntaxToStringDictionary];
	[dictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber *syntaxNumber, NSString *syntaxName, BOOL *stop) {
		if ([syntaxName caseInsensitiveCompare:aSyntaxString] == NSOrderedSame) {
			*stop = YES;
			result = syntaxNumber.integerValue;
		}
	}];
	return result;
}


- (NSString *)regularExpressionSyntaxString {
	NSString *result = [self.class regularExpressionSyntaxStringForSyntax:self.regularExpressionSyntax];
	return result;
}

#pragma mark - serialization

- (NSDictionary *)dictionaryRepresentation {
	NSDictionary *result =
	@{
	  kFindAndReplaceKeyFindString : self.findString ?: @"",
	  kFindAndReplaceKeyReplaceString : self.replaceString ?: @"",
	  kFindAndReplaceKeyCaseSensitive : @(self.caseSensitive),
	  kFindAndReplaceKeyShouldWrap : @(self.shouldWrap),
	  kFindAndReplaceKeyUseRegex : @(self.useRegex),
	  kFindAndReplaceKeyRegexOptions :
		  @{
			  kFindAndReplaceKeySyntax : self.regularExpressionSyntaxString,
			  kFindAndReplaceKeyEscapeCharacter : self.regularExpressionEscapeCharacter,
			  kFindAndReplaceKeyExtended : @(self.regularExpressionOptionExtended),
			  kFindAndReplaceKeyLineContext : @(self.regularExpressionOptionLineContext),
			  kFindAndReplaceKeyMultiline : @(self.regularExpressionOptionMultiline),
			  kFindAndReplaceKeyCaptureGroups : @(self.regularExpressionOptionCaptureGroups),
			  kFindAndReplaceKeyIgnoreEmptyMatches : @(self.regularExpressionOptionIgnoreEmptyMatches),
			  kFindAndReplaceKeyOnlyLongestMatch : @(self.regularExpressionOptionOnlyLongestMatch),
		},
	  
	};
	
	return result;
}

/*! @param aPropertyKey key string for the property to be set
	@param aValue the value to be set
	@param aDefaultValue default value to be set if aValue is nil. if this is also nil, the property is not set */
- (void)TCM_setValue:(id)aValue forKey:(NSString *)aPropertyKey defaultValue:(id)aDefaultValue {
	id value = aValue ? aValue : aDefaultValue;
	if (value) {
		[self setValue:value forKey:aPropertyKey];
	} else {
		// just for debugging
	}
}

- (void)takeValuesFromDictionaryRepresentation:(NSDictionary *)aDictionaryRepresentation {
	[self TCM_setValue:aDictionaryRepresentation[kFindAndReplaceKeyFindString]
				forKey:@"findString" defaultValue:@""];
	[self TCM_setValue:aDictionaryRepresentation[kFindAndReplaceKeyReplaceString]
				forKey:@"replaceString" defaultValue:@""];
	[@{
	   kFindAndReplaceKeyCaseSensitive : @"caseSensitive",
	   kFindAndReplaceKeyUseRegex : @"useRegex",
	   kFindAndReplaceKeyShouldWrap : @"shouldWrap",
	   } enumerateKeysAndObjectsUsingBlock:^(id dictionaryKey, id propertyKey, BOOL *stop) {
		[self TCM_setValue:aDictionaryRepresentation[dictionaryKey] forKey:propertyKey defaultValue:nil];
	}];
	
	NSDictionary *regexOptions = aDictionaryRepresentation[kFindAndReplaceKeyRegexOptions];
	[self TCM_setValue:@([self.class syntaxForRegularExpressionSyntaxString:regexOptions[kFindAndReplaceKeySyntax]])
				forKey:@"regularExpressionSyntax" defaultValue:nil];
	[@{
	   kFindAndReplaceKeyEscapeCharacter : @"regularExpressionEscapeCharacter",
	   kFindAndReplaceKeyExtended : @"regularExpressionOptionExtended",
	   kFindAndReplaceKeyLineContext : @"regularExpressionOptionLineContext",
	   kFindAndReplaceKeyMultiline : @"regularExpressionOptionMultiline",
	   kFindAndReplaceKeyCaptureGroups : @"regularExpressionOptionCaptureGroups",
	   kFindAndReplaceKeyIgnoreEmptyMatches : @"regularExpressionOptionIgnoreEmptyMatches",
	   kFindAndReplaceKeyOnlyLongestMatch : @"regularExpressionOptionOnlyLongestMatch",
	   } enumerateKeysAndObjectsUsingBlock:^(id dictionaryKey, id propertyKey, BOOL *stop) {
		   [self TCM_setValue:regexOptions[dictionaryKey] forKey:propertyKey defaultValue:nil];
	   }];
}

- (NSString *)menuTitleDescription {
	NSMutableArray *components = [NSMutableArray new];
	[components addObject:[NSString stringWithFormat:@"›%@‹", self.findString]];
	if (self.replaceString.length) {
		[components addObject:[NSString stringWithFormat:@"›%@‹", self.replaceString]];
	}
	NSString *result = [components componentsJoinedByString:@" ➞ "];
	return result;
}

- (void)setReplaceString:(NSString *)replaceString {
	_replaceString = replaceString ?: @"";
}

@end
