//
//  OGEscapeCharacterFormatter.m
//  OgreKit
//
//  Created by Isao Sonobe on Sat Feb 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <OgreKit/OgreAFPCEscapeCharacterFormatter.h>
#import <OgreKit/OGRegularExpression.h>
#import <OgreKit/OGRegularExpressionMatch.h>


@implementation OgreAFPCEscapeCharacterFormatter

- (id)init
{
	if ((self = [super init]) != nil) {
		_backslashRegex = [[OGRegularExpression alloc] initWithString:@"\\\\" 
			options:OgreNoneOption 
			syntax:OgreGrepSyntax 
			escapeCharacter:OgreBackslashCharacter];
		_yenRegex = [[OGRegularExpression alloc] initWithString:OgreGUIYenCharacter 
			options:OgreNoneOption 
			syntax:OgreGrepSyntax 
			escapeCharacter:OgreBackslashCharacter];
	}
	
	return self;
}

- (void)dealloc
{
	[_backslashRegex release];
	[_yenRegex release];
	[super dealloc];
}

- (NSString*)stringForObjectValue:(id)anObject
{
    if (![anObject isKindOfClass: [NSString class]]) {
		return nil;
    }
	
	NSString	*string;
	if ([_delegate shouldEquateYenWithBackslash]) {
		string = [self equateInString:(NSString*)anObject];
	} else {
		string = anObject;
	}
	
	return string;
}

- (NSAttributedString*)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary*)attributes
{
    if (![anObject isKindOfClass: [NSString class]]) {
		return nil;
    }
	
	NSString	*string;
	if ([_delegate shouldEquateYenWithBackslash]) {
		string = [self equateInString:(NSString*)anObject];
	} else {
		string = anObject;
	}
	
	return [[[NSAttributedString alloc] initWithString:string attributes:attributes] autorelease];
}

- (BOOL)getObjectValue:(id*)obj forString:(NSString*)string errorDescription:(NSString**)error
{
	if ([_delegate shouldEquateYenWithBackslash]) {
		*obj = [self equateInString:string];
	} else {
		*obj = string;
	}
	
	return YES;
}

- (void)setDelegate:(id)aDelegate
{
	_delegate = aDelegate;  // 注意! retainしない。
}

- (NSString*)equateInString:(NSString*)string
{
	NSString			*escapeCharacter = [_delegate escapeCharacter];
	OGRegularExpression *regex;
	if ([escapeCharacter isEqualToString:OgreBackslashCharacter]) {
		regex = _yenRegex;
	} else {
		regex = _backslashRegex;
	}
	
	return [regex replaceAllMatchesInString:string 
		delegate:self 
		replaceSelector:@selector(equateYenWithBackslash:contextInfo:) 
		contextInfo:escapeCharacter];
}

- (NSString*)equateYenWithBackslash:(OGRegularExpressionMatch*)aMatch contextInfo:(id)contextInfo
{
	return contextInfo;
}

@end

