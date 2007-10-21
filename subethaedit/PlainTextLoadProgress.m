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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)startAnimation
{
    [_progressIndicator setIndeterminate:YES];
    [_progressIndicator startAnimation:self];
}

- (void)stopAnimation
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)registerForSession:(TCMMMSession *)aSession {
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(updateProgress:) 
                                                 name:TCMMMSessionDidReceiveContentNotification
                                               object:aSession];
}

#pragma mark -

- (void)updateProgress:(NSNotification *)aNotification
{
    if ([[aNotification object] percentOfSessionReceived] > 0.0) {
        [_progressIndicator setIndeterminate:NO];
        [_progressIndicator setDoubleValue:[[aNotification object] percentOfSessionReceived]];
    }
}

@end
