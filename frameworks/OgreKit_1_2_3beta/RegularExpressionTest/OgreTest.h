/*
 * Name: OgreTest.h
 * Project: OgreKit
 *
 * Creation Date: Sep 7 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Cocoa/Cocoa.h>

@interface OgreTest : NSObject
{
    IBOutlet NSTextField *replaceTextField;
    IBOutlet NSTextField *patternTextField;
    IBOutlet NSTextView *resultTextView;
    IBOutlet NSTextField *targetTextField;
	IBOutlet NSTextField *escapeCharacterTextField;
}
- (IBAction)match:(id)sender;
- (IBAction)replace:(id)sender;

- (void)replaceTest;
- (void)categoryTest;

@end
