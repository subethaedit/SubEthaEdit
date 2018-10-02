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
#import "PlainTextDocument.h"
#import "PlainTextWindowControllerTabContext.h"
#import "SEEWebPreviewViewController.h"

@implementation NSWindow (NSWindowScriptingAdditions)
- (id)scriptSelection {
    if (![[self windowController] isKindOfClass:[PlainTextWindowController class]]) return nil;
    return [[[self windowController] activePlainTextEditor] scriptSelection];
}

- (void)setScriptSelection:(id)aSelection {
    if (![[self windowController] isKindOfClass:[PlainTextWindowController class]]) return;
    [[[self windowController] activePlainTextEditor] setScriptSelection:aSelection];
}

- (void)handleBeginUndoGroupCommand:(NSScriptCommand *)aCommand {
    [[[self windowController] document] handleBeginUndoGroupCommand:aCommand];
}

- (void)handleEndUndoGroupCommand:(NSScriptCommand *)aCommand {
    [[[self windowController] document] handleEndUndoGroupCommand:aCommand];
}


- (void)handleClearChangeMarksCommand:(NSScriptCommand *)aCommand {
    [[[self windowController] document] handleClearChangeMarksCommand:aCommand];
}

- (void)handleShowWebPreviewCommand:(NSScriptCommand *)command {
	PlainTextWindowController *windowController = self.windowController;
	[windowController.document handleShowWebPreviewCommand:command];
}

- (int)scriptedColumns {
    PlainTextWindowController *wc=(PlainTextWindowController *)[self windowController];
    if ([wc isKindOfClass:[PlainTextWindowController class]]) {
        return [[wc activePlainTextEditor] displayedColumns];
    } else {
        return -1;
    }
}

- (int)scriptedRows {
    PlainTextWindowController *wc=(PlainTextWindowController *)[self windowController];
    if ([wc isKindOfClass:[PlainTextWindowController class]]) {
        return [[wc valueForKeyPath:@"plainTextEditors.@sum.displayedRows"] intValue];
    } else {
        return -1;
    }
}

- (void)setScriptedColumns:(int)aColumns {
    PlainTextWindowController *wc=(PlainTextWindowController *)[self windowController];
    if ([wc isKindOfClass:[PlainTextWindowController class]]) {
        [wc setSizeByColumns:aColumns rows:[self scriptedRows]];
    }
}


- (void)setScriptedRows:(int)aRows {
    PlainTextWindowController *wc=(PlainTextWindowController *)[self windowController];
    if ([wc isKindOfClass:[PlainTextWindowController class]]) {
        [wc setSizeByColumns:[[wc activePlainTextEditor] displayedColumns] rows:aRows];
    }
}

@end
