//
//  SDAppController.m
//  seed
//
//  Created by Martin Ott on 3/14/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "SDAppController.h"
#import "SDDocument.h"


int fd = 0;
BOOL endRunLoop = NO;


@implementation SDAppController

- (id)init
{
    self = [super init];
    if (self) {
        // Set up pipe infrastructure for signal handling
        _signalPipe = [NSPipe pipe];
        fd = [[_signalPipe fileHandleForWriting] fileDescriptor];

        [[NSNotificationCenter defaultCenter]
                addObserver:self
                   selector:@selector(handleSignal:)
                       name:NSFileHandleReadCompletionNotification
                     object:[_signalPipe fileHandleForReading]];

        [[_signalPipe fileHandleForReading] readInBackgroundAndNotify];
        
        _documents = [[NSMutableArray alloc] init];
        
        /*
        _autosaveTimer = [NSTimer scheduledTimerWithTimeInterval:60 * 30
                                                          target:self 
                                                        selector:@selector(autosaveTimerFired:)
                                                        userInfo:nil
                                                         repeats:YES];
        [_autosaveTimer retain];
        */
    }
    return self;
}

- (void)dealloc
{
    [_autosaveTimer invalidate];
    [_autosaveTimer release];
    [_documents release];
    [super dealloc];
}

- (void)autosaveTimerFired:(NSTimer *)timer
{
    NSEnumerator *enumerator = [_documents objectEnumerator];
    SDDocument *document;
    while ((document = [enumerator nextObject])) {
        NSURL *fileURL = [document fileURL];
        if (fileURL) {
            NSLog(@"save document: %@", fileURL);
            NSError *error;
            if (![document saveToURL:fileURL error:&error]) {
                // check error
            }
        }
    }
}

- (void)handleSignal:(NSNotification *)notification
{
    NSData *rawRequest = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];

    NSLog(@"handleSignal: %@", rawRequest);

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSFileHandleConnectionAcceptedNotification
                                                  object:[_signalPipe fileHandleForReading]];
                                                  
    [self autosaveTimerFired:nil];
                                                  
    endRunLoop = YES;
}

#pragma mark -

- (void)openFile:(NSString *)filename modeIdentifier:(NSString *)modeIdentifier
{
    NSError *outError;
    NSURL *absoluteURL = [NSURL fileURLWithPath:filename];
    NSLog(@"read document: %@", absoluteURL);
    SDDocument *document = [(SDDocument *)[SDDocument alloc] initWithContentsOfURL:absoluteURL error:&outError];
    if (document) {
        [_documents addObject:document];
        [document setModeIdentifier:modeIdentifier];
        [[document session] setAccessState:TCMMMSessionAccessReadWriteState];
        [document setIsAnnounced:YES];
    } else {
        // check error
    }
}

- (void)openFiles:(NSArray *)filenames
{
    NSEnumerator *enumerator = [filenames objectEnumerator];
    NSString *filename;
    while ((filename = [enumerator nextObject])) {
        NSError *error;
        NSURL *absoluteURL = [NSURL fileURLWithPath:filename];
        NSLog(@"read document: %@", absoluteURL);
        SDDocument *document = [(SDDocument *)[SDDocument alloc] initWithContentsOfURL:absoluteURL error:&error];
        if (document) {
            [_documents addObject:document];
            [[document session] setAccessState:TCMMMSessionAccessReadWriteState];
            [document setIsAnnounced:YES];
        }
    }
}

@end
