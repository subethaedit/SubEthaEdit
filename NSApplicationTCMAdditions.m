//
//  NSApplicationTCMAdditions.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Sep 20 2004.
//  Copyright 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import "NSApplicationTCMAdditions.h"
#import "DocumentController.h"
#import "DocumentMode.h"
#import "DocumentModeManager.h"
#import "ScriptTextSelection.h"
#import "FoldableTextStorage.h"
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

- (id)scriptSelection {
    NSArray *orderedDocuments = [NSApp orderedDocuments];
    if ([orderedDocuments count] > 0) {
        PlainTextDocument *document = [orderedDocuments objectAtIndex:0];
        return [document scriptSelection];
    }

    return nil;
}

- (void)setScriptSelection:(id)aSelection {
    NSArray *orderedDocuments = [NSApp orderedDocuments];
    if ([orderedDocuments count] > 0) {
        PlainTextDocument *document = [orderedDocuments objectAtIndex:0];
        return [document setScriptSelection:aSelection];
    }
}

- (NSArray *)scriptedModes {
    DocumentModeManager *manager = [DocumentModeManager sharedInstance];
    NSDictionary *availableModes = [manager availableModes];
    
    NSMutableArray *modes = [NSMutableArray array];
    NSEnumerator *enumerator = [availableModes keyEnumerator];
    NSString *identifier;
    while ((identifier = [enumerator nextObject])) {
        [modes addObject:[manager documentModeForIdentifier:identifier]];
    }
    
    return modes;
}

- (id)valueInScriptedModesWithUniqueID:(id)uniqueID {
    return [[DocumentModeManager sharedInstance] documentModeForIdentifier:uniqueID];
}

- (id)valueInScriptedModesWithName:(NSString *)name {
    return [[DocumentModeManager sharedInstance] documentModeForName:name];
}

- (IBAction)terminateForRestart:(id)aSender {
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSEnumerator *documents  =[[[DocumentController sharedInstance] documents] objectEnumerator];
    NSDocument *document = nil;
    while ((document=[documents nextObject])) {
        if ([document respondsToSelector:@selector(autosaveForRestart)]) {
            [document performSelector:@selector(autosaveForRestart)];
        }
    }
    [NSApp stop:aSender];
}

@end
