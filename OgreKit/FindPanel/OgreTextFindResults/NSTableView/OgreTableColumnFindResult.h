/*
 * Name: OgreTableColumnFindResult.h
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

#import <OgreKit/OgreFindResultBranch.h>

@class OgreTableColumn;

@interface OgreTableColumnFindResult : OgreFindResultBranch 
{
    OgreTableColumn   *_tableColumn;
    NSMutableArray  *_components, *_flattenedComponents;
}

- (id)initWithTableColumn:(OgreTableColumn*)tableColumn;
- (void)targetIsMissing;

@end
