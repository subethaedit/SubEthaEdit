/*
 * Name: MyTableRowModel.h
 * Project: OgreKit
 *
 * Creation Date: Jun 18 2004
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>


@interface MyTableRowModel : NSObject 
{
    NSString    *_foo;
    NSString    *_bar;
}

- (NSString*)foo;
- (void)setFoo:(NSString*)newFoo;
- (NSString*)bar;
- (void)setBar:(NSString*)newBar;

- (void)dump;

@end
