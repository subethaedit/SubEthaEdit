/*
 * Name: OgreAttachableWindowAcceptor.h
 * Project: OgreKit
 *
 * Creation Date: Aug 31 2004
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2004 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>

@protocol OgreAttachableWindowAccepteeProtocol;

@protocol OgreAttachableWindowAcceptorProtocol
- (BOOL)isAttachableAcceptorEdge:(NSRectEdge)edge toAcceptee:(NSWindow<OgreAttachableWindowAccepteeProtocol>*)acceptee;
@end

@interface OgreAttachableWindowAcceptor : NSPanel <OgreAttachableWindowAcceptorProtocol>
@end
