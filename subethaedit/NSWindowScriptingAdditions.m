//
//  NSWindowScriptingAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 03.05.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "NSWindowScriptingAdditions.h"
#import "PlainTextWindowController.h"
#import "PlainTextEditor.h"

@implementation NSWindow (NSWindowScriptingAdditions)
- (id)scriptSelection {
    if (![[self windowController] isKindOfClass:[PlainTextWindowController class]]) return nil;
    return [[[self windowController] activePlainTextEditor] scriptSelection];
}

- (void)setScriptSelection:(id)aSelection {
    if (![[self windowController] isKindOfClass:[PlainTextWindowController class]]) return;
    [[[self windowController] activePlainTextEditor] setScriptSelection:aSelection];
}
@end
