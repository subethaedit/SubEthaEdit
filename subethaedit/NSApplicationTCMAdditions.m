//
//  NSApplicationTCMAdditions.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Sep 20 2004.
//  Copyright 2004 TheCodingMonkeys. All rights reserved.
//

#import "NSApplicationTCMAdditions.h"
#import "DocumentController.h"


@implementation NSApplication (NSApplicationTCMAdditions)

- (id)TCM_handleOpenScriptCommand:(NSScriptCommand *)command {
    return [[DocumentController sharedInstance] handleOpenScriptCommand:command];
}

- (id)TCM_handlePrintScriptCommand:(NSScriptCommand *)command {
    return [[DocumentController sharedInstance] handlePrintScriptCommand:command];
}

@end
