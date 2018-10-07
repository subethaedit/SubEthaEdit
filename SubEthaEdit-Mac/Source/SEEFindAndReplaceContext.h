//  SEEFindAndReplaceContext.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 24.03.14.

#import <Foundation/Foundation.h>

@class SEEFindAndReplaceContext;

#import "SEEFindAndReplaceState.h"
#import "PlainTextEditor.h"
#import "SEETextView.h"
#import "FindReplaceController.h"
#import "FullTextStorage.h"

/*!
	Class to store a search and replace context in for all find and replace operations, including find all windows
 */

@interface SEEFindAndReplaceContext : NSObject
@property (nonatomic, strong) SEEFindAndReplaceState *findAndReplaceState;
@property (nonatomic, strong) SEETextView *targetTextView;
@property (nonatomic) NSInteger currentTextFinderActionType;

@property (nonatomic, copy) NSString *localizedErrorDescriptionString;

+ (instancetype)contextWithTextView:(NSTextView *)aTextView state:(SEEFindAndReplaceState *)aState;

@property (nonatomic, readonly) BOOL textFinderActionWantsToReplaceText;

/*! derived and cached properties */
@property (nonatomic, strong) OGRegularExpression *findExpression;
@property (nonatomic, strong) OGReplaceExpression *replaceExpression;
@property (nonatomic, readonly) PlainTextEditor *targetPlainTextEditor;
@property (nonatomic, readonly) FullTextStorage *targetFullTextStorage;

/*! actions that can be performed with a find and replace context */

/*! dispatch method */
- (BOOL)performCurrentTextFinderAction;

/*! */
- (NSArray *)allMatches;

/*! actual action methods */
- (BOOL)findNextForward:(BOOL)isForward;
- (BOOL)replaceSelection;
- (BOOL)replaceAll;
- (BOOL)showFindAllResults;


@end
