/*
 * Name: OgreFindPanelController.h
 * Project: OgreKit
 *
 * Creation Date: Sep 13 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>

@class OgreTextFinder, OgreFindResult;

@interface OgreFindPanelController : NSResponder
{
	IBOutlet OgreTextFinder		*textFinder;
	IBOutlet NSPanel			*findPanel;
}

- (IBAction)showFindPanel:(id)sender;
- (void)close;

- (OgreTextFinder*)textFinder;
- (void)setTextFinder:(OgreTextFinder*)aTextFinder;

- (NSPanel*)findPanel;
- (void)setFindPanel:(NSPanel*)aPanel;

- (NSDictionary*)history;

@end
