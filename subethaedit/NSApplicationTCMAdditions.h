//
//  NSApplicationTCMAdditions.h
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Sep 20 2004.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSApplication (NSApplicationTCMAdditions)

- (id)TCM_handleOpenScriptCommand:(NSScriptCommand *)command;
- (id)TCM_handlePrintScriptCommand:(NSScriptCommand *)command;

@end
