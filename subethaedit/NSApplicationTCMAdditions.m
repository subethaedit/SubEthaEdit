//
//  NSApplicationTCMAdditions.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Sep 20 2004.
//  Copyright 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import "NSApplicationTCMAdditions.h"
#import "DocumentController.h"
#import "TextSelection.h"
#import "TextStorage.h"
#import "PlainTextDocument.h"
#import "PlainTextWindowController.h"
#import "PlainTextEditor.h"

@implementation NSApplication (NSApplicationTCMAdditions)

- (id)TCM_handleOpenScriptCommand:(NSScriptCommand *)command {
    return [[DocumentController sharedInstance] handleOpenScriptCommand:command];
}

- (id)TCM_handlePrintScriptCommand:(NSScriptCommand *)command {
    return [[DocumentController sharedInstance] handlePrintScriptCommand:command];
}

- (id)TCM_handleSeeScriptCommand:(NSScriptCommand *)command {
    return [[DocumentController sharedInstance] handleSeeScriptCommand:command];
}

- (id)selection {
    NSArray *orderedWindows = [NSApp orderedWindows];
    if ([orderedWindows count] > 0) {
        NSWindow *window = [orderedWindows objectAtIndex:0];
        PlainTextWindowController *windowController = [window windowController];
        
        PlainTextDocument *document = [windowController document];
        if ([document isProxyDocument]) {
            return nil;
        }
    
        PlainTextEditor *editor = [windowController activePlainTextEditor];
        return [TextSelection selectionForEditor:editor];
    }

    return nil;
}

@end
