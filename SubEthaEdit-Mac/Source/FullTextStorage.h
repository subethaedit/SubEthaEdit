//  FullTextStorage.h
//  Created by Dominik Wagner on 04.01.09.

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>
#import "AbstractFoldingTextStorage.h"

@class FoldableTextStorage;

extern NSString * const SEESearchScopeAttributeName;

@interface FullTextStorage : AbstractFoldingTextStorage 
@property (nonatomic, readonly, weak) FoldableTextStorage *foldableTextStorage;

+ (OGRegularExpression *)wrongLineEndingRegex:(LineEnding)aLineEnding;
- (instancetype)initWithFoldableTextStorage:(FoldableTextStorage *)inTextStorage;

#pragma mark -
- (NSString *)positionStringForRange:(NSRange)aRange;
- (NSString *)rangeStringForRange:(NSRange)aRange;
- (int)lineNumberForLocation:(NSUInteger)location;
- (NSMutableArray *)lineStarts;
- (void)setLineStartsOnlyValidUpTo:(NSUInteger)aLocation;
- (NSRange)findLine:(int)aLineNumber;

#pragma mark - line endings and encoding
- (LineEnding)lineEnding;
- (void)setLineEnding:(LineEnding)newLineEnding;
- (void)setShouldWatchLineEndings:(BOOL)aFlag;
- (BOOL)hasMixedLineEndings;
- (void)setHasMixedLineEndings:(BOOL)aFlag;
- (NSStringEncoding)encoding;
- (void)setEncoding:(NSStringEncoding)anEncoding;
- (NSArray *)selectionOperationsForRangesUnconvertableToEncoding:(NSStringEncoding)encoding;

- (BOOL)nextLineNeedsIndentation:(NSRange)aLineRange;
- (void)reindentRange:(NSRange)aRange usingTabStringPerLevel:(NSString *)aTabString;
- (NSRange)startRangeForStateAndIndex:(NSUInteger)aLocation;
- (NSString *)autoendForIndex:(NSUInteger)aLocation;

#pragma mark - SearchScopes
- (void)addSearchScopeAttributeValue:(id)aValue inRange:(NSRange)aRange;
- (void)removeSearchScopeAttributeValue:(id)aValue fromRange:(NSRange)aRange;
- (NSArray *)searchScopeRangesForAttributeValue:(id)aValue;


#pragma mark -
//- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString synchronize:(BOOL)inSynchronizeFlag;
//- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString;
- (void)removeAttribute:(NSString *)anAttribute range:(NSRange)aRange synchronize:(BOOL)aSynchronizeFlag;
- (NSRange)foldableRangeForCharacterAtIndex:(unsigned long int)index;
// returns longest range of continous comments, even when whitespace is inbetween those comments
- (NSRange)continuousCommentRangeAtIndex:(unsigned long int)anIndex;

- (void)replaceCharactersInRange:(NSRange)inRange withAttributedString:(NSAttributedString *)inAttributedString synchronize:(BOOL)inSynchronizeFlag;

// disables synchronisation until linear attribute changing ends;
- (void)beginLinearAttributeChanges;
- (void)endLinearAttributeChanges;

- (NSDictionary *)dictionaryRepresentation;
- (void)setContentByDictionaryRepresentation:(NSDictionary *)aRepresentation;

- (NSUInteger)numberOfLines;
- (NSUInteger)numberOfCharacters;
- (NSUInteger)numberOfWords;

#pragma mark -

- (BOOL)hasMixedLineEndingsInRange:(NSRange)aRange;
- (void)validateHasMixedLineEndings;

@end
