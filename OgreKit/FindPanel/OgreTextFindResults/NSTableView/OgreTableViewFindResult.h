/*
 * Name: OgreTableViewFindResult.h
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

@class OgreTableView;

@interface OgreTableViewFindResult : OgreFindResultBranch 
{
    OgreTableView   *_tableView;
    NSMutableArray  *_components;
}

- (id)initWithTableView:(OgreTableView*)tableView;

@end
