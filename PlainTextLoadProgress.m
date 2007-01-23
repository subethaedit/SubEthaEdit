//
//  PlainTextLoadProgress.m
//  SubEthaEdit
//
//  Created by Martin Ott on 1/17/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "PlainTextLoadProgress.h"
#import "TCMMMSession.h"


@implementation PlainTextLoadProgress

- (id)init
{
    self = [super init];
    if (self) {
        (void)[NSBundle loadNibNamed:@"PlainTextLoadProgress" owner:self];
    }
    return self;
}

- (void)startAnimation
{
    [_progressIndicator startAnimation:self];
}

- (void)stopAnimation
{
    [_progressIndicator stopAnimation:self];
}

- (void)setStatusText:(NSString *)string
{
    [_loadStatusField setStringValue:string];
}

- (NSView *)loadProgressView
{
    return _loadProgressView;
}

#pragma mark -

- (void)updateProgress:(NSNotification *)aNotification
{
    [_progressIndicator setDoubleValue:[[aNotification object] percentOfSessionReceived]];
}

@end
