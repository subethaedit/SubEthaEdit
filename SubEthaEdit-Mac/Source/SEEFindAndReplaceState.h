//  SEEFindAndReplaceState.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 28.02.14.

#import <Foundation/Foundation.h>
#import "OgreKit/OgreKit.h"
/*! Model object to hold all the necessary information regarding the search and replace state */

@interface SEEFindAndReplaceState : NSObject <NSCopying>

@property (nonatomic, strong) NSString *findString;
@property (nonatomic, strong) NSString *replaceString;
@property (nonatomic) unsigned regexOptions;
@property (nonatomic, getter=isCaseSensitive) BOOL caseSensitive;
@property (nonatomic) BOOL useRegex;
@property (nonatomic) BOOL shouldWrap;
/*! currently used OGRE dialect. */
@property (nonatomic) OgreSyntax regularExpressionSyntax;
@property (nonatomic, readonly) unsigned regexOptionsForExpressionBuilding;

@property (nonatomic, readonly) NSString *regularExpressionSyntaxString;
@property (nonatomic, copy) NSString *statusString;

/*! default is OgreBackslashCharacter (@"\\"), only other option is OgreGUIYenCharacter (@"\xc2\xa5") */
@property (nonatomic, strong) NSString *regularExpressionEscapeCharacter;


+ (NSString *)regularExpressionSyntaxStringForSyntax:(OgreSyntax)aSyntax;
+ (OgreSyntax)syntaxForRegularExpressionSyntaxString:(NSString *)aSyntaxString;


@property (nonatomic) BOOL regularExpressionOptionCaptureGroups;
@property (nonatomic) BOOL regularExpressionOptionLineContext;
@property (nonatomic) BOOL regularExpressionOptionMultiline;
@property (nonatomic) BOOL regularExpressionOptionExtended;
@property (nonatomic) BOOL regularExpressionOptionIgnoreEmptyMatches;
@property (nonatomic) BOOL regularExpressionOptionOnlyLongestMatch;


/* serialization */
@property (nonatomic, readonly) NSDictionary *dictionaryRepresentation;
- (void)takeValuesFromDictionaryRepresentation:(NSDictionary *)aDictionaryRepresentation;

/* user representation */
- (NSString *)menuTitleDescription;

@end
