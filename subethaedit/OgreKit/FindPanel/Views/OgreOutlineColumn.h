/*
 * Name: OgreOutlineColumn.h
 * Project: OgreKit
 *
 * Creation Date: Jun 13 2004
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <AppKit/AppKit.h>


@interface OgreOutlineColumn : NSTableColumn 
{
}

- (int)ogreNumberOfChildrenOfItem:(id)item;
- (BOOL)ogreIsItemExpandable:(id)item;
- (id)ogreChild:(int)index ofItem:(id)item;
- (id)ogreObjectValueForItem:(id)item;
- (void)ogreSetObjectValue:(id)anObject forItem:(id)item;

@end
