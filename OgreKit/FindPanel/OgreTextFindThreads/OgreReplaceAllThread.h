/*
 * Name: OgreReplaceAllThread.h
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

#import <OgreKit/OgreTextFindThread.h>

@class OGRegularExpressionMatch, OGRegularExpressionEnumerator, OgreFindResult;
@class OgreTextFindThread;

@interface OgreReplaceAllThread : OgreTextFindThread 
{
    NSArray                         *matchArray;
    
    OGReplaceExpression             *repex;
    
    unsigned                        aNumberOfReplaces, aNumberOfMatches;
    
    NSString                        *progressMessage, *progressMessagePlural, *remainingTimeMesssage, *replacedString;
}

@end
