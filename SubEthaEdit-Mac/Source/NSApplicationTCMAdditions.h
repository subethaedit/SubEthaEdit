//
//  NSApplicationTCMAdditions.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Sep 20 2004.
//  Copyright 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSApplication (NSApplicationTCMAdditions)

- (id)TCM_handleOpenScriptCommand:(NSScriptCommand *)command;
- (id)TCM_handlePrintScriptCommand:(NSScriptCommand *)command;
- (id)TCM_handleSeeScriptCommand:(NSScriptCommand *)command;

- (NSURL *)sandboxContainerURL;
- (id)scriptSelection;
- (void)setScriptSelection:(id)selection;
- (NSArray *)scriptedModes;

@end
