/*
 * Name: MyOutlineView.h
 * Project: OgreKit
 *
 * Creation Date: Jun 06 2004
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>

@protocol MyOutlineViewDelegate
- (void)deleteKeyDownInOutlineView:(NSOutlineView*)outlineView;
@end

@interface MyOutlineView : OgreOutlineView
{
}
@end
