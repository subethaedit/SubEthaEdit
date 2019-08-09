//  PlainTextLoadProgress.m
//  SubEthaEdit
//
//  Created by Martin Ott on 1/17/07.

#import "PlainTextLoadProgress.h"
#import "TCMMMSession.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation PlainTextLoadProgress

- (id)init
{
    self = [super initWithNibName:@"PlainTextLoadProgress" bundle:nil];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startAnimation
{
    [self.progressIndicatorOutlet setIndeterminate:YES];
    [self.progressIndicatorOutlet startAnimation:self];
}

- (void)stopAnimation
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.progressIndicatorOutlet stopAnimation:self];
}

- (void)setStatusText:(NSString *)string
{
    [self.loadStatusFieldOutlet setStringValue:string];
}

- (NSView *)loadProgressView
{
    return self.view;
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
        [self.progressIndicatorOutlet setIndeterminate:NO];
        [self.progressIndicatorOutlet setDoubleValue:[[aNotification object] percentOfSessionReceived]];
    }
}

@end
