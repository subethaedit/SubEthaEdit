//
//  PlainTextWindow.m
//  SubEthaEdit
//
//  Created by Martin Ott on 11/23/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "PlainTextWindow.h"
#import "PlainTextWindowController.h"


@implementation PlainTextWindow

- (IBAction)performClose:(id)sender
{
    if ([[self windowController] isKindOfClass:[PlainTextWindowController class]]) {
        [(PlainTextWindowController *)[self windowController] closeAllTabs];
    } else {
        [super performClose:sender];
    }
}

- (void)setDocumentEdited:(BOOL)flag
{
    NSDocument *document = [[self windowController] document];
    if (document) {
        [super setDocumentEdited:[document isDocumentEdited]];
    } else {
        [super setDocumentEdited:flag];
    }
}

@end
