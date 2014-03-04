//
//  SEEFindAndReplaceState.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 28.02.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OgreKit/OgreKit.h"
/*! Model object to hold all the necessary information regarding the search and replace state */

typedef NS_ENUM(int8_t, SEEFindAndReplaceScope) {
	kSEEFindAndReplaceScopeDocument = 0,
	kSEEFindAndReplaceScopeSelection = 1,
};

@interface SEEFindAndReplaceState : NSObject

@property (nonatomic, strong) NSString *findString;
@property (nonatomic, strong) NSString *replaceString;
@property (nonatomic) SEEFindAndReplaceScope scope;
@property (nonatomic) unsigned regexOptions;
@property (nonatomic, getter=isCaseSensitive) BOOL caseSensitive;
@property (nonatomic) BOOL useRegex;
@property (nonatomic) BOOL shouldWrap;
/*! currently used OGRE dialect. */
@property (nonatomic) OgreSyntax regularExpressionSyntax;

@property (nonatomic, readonly) NSString *regularExpressionSyntaxString;

/*! default is OgreBackslashCharacter (@"\\"), only other option is OgreGUIYenCharacter (@"\xc2\xa5") */
@property (nonatomic, strong) NSString *regularExpressionEscapeCharacter;


+ (NSString *)regularExpressionSyntaxStringForSyntax:(OgreSyntax)aSyntax;

// TODO: helper accessors for regex options


@end
