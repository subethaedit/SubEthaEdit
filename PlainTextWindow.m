//
//  PlainTextWindow.m
//  SubEthaEdit
//
//  Created by Martin Ott on 11/23/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "PlainTextWindow.h"
#import "PlainTextWindowController.h"
#import "BacktracingException.h"

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

- (NSPoint)cascadeTopLeftFromPoint:(NSPoint)aPoint {
    static NSPoint offsetPoint = {0.,0.};
    if (NSEqualPoints(offsetPoint,NSZeroPoint)) {
        NSPoint firstPoint = [super cascadeTopLeftFromPoint:NSZeroPoint];
        NSPoint secondPoint = [super cascadeTopLeftFromPoint:firstPoint];
        offsetPoint.x = MAX(10.,MIN(ABS(secondPoint.x-firstPoint.x),70.));
        offsetPoint.y = MAX(10.,MIN(ABS(secondPoint.y-firstPoint.y),70.));
    }

    NSRect visibleFrame = [[self screen] visibleFrame];

    if (NSEqualPoints(aPoint,NSZeroPoint)) {
        aPoint = NSMakePoint(visibleFrame.origin.x,NSMaxY(visibleFrame));
    }

    NSPoint result = aPoint;
    result.x += offsetPoint.x;
    result.y -= offsetPoint.y;
    if (result.x + [self frame].size.width > visibleFrame.size.width) {
        result.x = visibleFrame.origin.x;
    }

    float toHighDifference = visibleFrame.origin.y - (result.y - [self frame].size.height);
    if (toHighDifference > 0) {
        result.y = NSMaxY(visibleFrame);
    }
    return result;
}


@end
