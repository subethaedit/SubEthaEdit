/*
 * Name: OgreReplaceAndFindThread.m
 * Project: OgreKit
 *
 * Creation Date: May 20 2004
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreReplaceAndFindThread.h>
#import <OgreKit/OgreFindResultLeaf.h>
#import <OgreKit/OgreFindResultBranch.h>


@implementation OgreReplaceAndFindThread

/* Methods implemented by subclasses of OgreTextFindThread */
- (SEL)didEndSelectorForFindPanelController
{
    return @selector(didEndReplaceAndFind:);
}

- (BOOL)shouldPreprocessFindingInFirstLeaf
{
    return YES;
}

- (BOOL)preprocessFindingInFirstLeaf:(OgreTextFindLeaf*)aLeaf
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@" -preprocessFindingInFirstLeaf: of %@", [self className]);
#endif
	unsigned	options = [self options];
	unsigned	notEOLAndBOLDisabledOptions = options & ~(OgreNotBOLOption | OgreNotEOLOption);  // NotBOLオプションが指定されている場合に正しく置換されない問題を避ける。
	
    OGRegularExpressionMatch    *match;
    NSString                    *string = [aLeaf string];
    if (string == nil) {
        match = nil;
    } else {
        match = [[self regularExpression] matchInString:string 
            options:notEOLAndBOLDisabledOptions 
            range:[aLeaf selectedRange]];
    }
    
    if (match != nil) {
        [aLeaf beginRegisteringUndoWithCapacity:1];
        [aLeaf beginEditing];
        
        NSRange     matchRange = [match rangeOfMatchedString];
        NSString    *replacedString = [[self replaceExpression] replaceMatchedStringOf:match];
        [aLeaf replaceCharactersInRange:matchRange withString:replacedString];
        
        [aLeaf endEditing];
        [aLeaf endRegisteringUndo];
        [aLeaf setSelectedRange:NSMakeRange(matchRange.location, [replacedString length])];
        [aLeaf jumpToSelection];
        
        [[self result] setType:OgreTextFindResultSuccess];
    } else {
    
        [[self result] setType:OgreTextFindResultFailure];
    }
    
    return ![self replacingOnly];
}

- (BOOL)replacingOnly
{
    return _replacingOnly;
}

- (void)setReplacingOnly:(BOOL)replacingOnly
{
    _replacingOnly = replacingOnly;
}


@end
