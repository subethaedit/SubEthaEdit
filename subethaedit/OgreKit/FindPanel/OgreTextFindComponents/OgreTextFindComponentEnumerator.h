/*
 * Name: OgreTextFindComponentEnumerator.h
 * Project: OgreKit
 *
 * Creation Date: Jun 05 2004
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>

@class OgreTextFindBranch;

@interface OgreTextFindComponentEnumerator : NSEnumerator
{
    OgreTextFindBranch  *_branch;
    int                 *_indexes, _nextIndex, _count;
    int                 _terminalIndex;
    BOOL                _inSelection;
}

- (id)initWithBranch:(OgreTextFindBranch*)aBranch inSelection:(BOOL)inSelection;
- (void)setTerminalIndex:(int)index;
- (void)setStartIndex:(int)index;

@end
