/*
 * Name: OgreTextViewUndoer.h
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

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreTextFindBranch.h>
#import <OgreKit/OgreTextFindLeaf.h>

@class OgreTableView;

@interface OgreTableViewAdapter : OgreTextFindBranch <OgreTextFindTargetAdapter>
{
    OgreTableView   *_tableView;
}

- (id)initWithTarget:(id)aTableView;

@end
