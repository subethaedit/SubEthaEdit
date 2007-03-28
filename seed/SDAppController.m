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
    }
    return self;
}

- (void)dealloc
{
    [_documents release];
    [super dealloc];
}

- (void)handleSignal:(NSNotification *)notification
{
    NSData *rawRequest = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];

    NSLog(@"handleSignal: %@", rawRequest);

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSFileHandleConnectionAcceptedNotification
                                                  object:[_signalPipe fileHandleForReading]];
                                                  
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
                                                  
    endRunLoop = YES;
}

#pragma mark -

- (void)openFiles:(NSArray *)filenames
{
    NSEnumerator *enumerator = [filenames objectEnumerator];
    NSString *filename;
    while ((filename = [enumerator nextObject])) {
        NSError *error;
        NSURL *absoluteURL = [NSURL fileURLWithPath:filename];
        NSLog(@"read document: %@", absoluteURL);
        SDDocument *document = [[SDDocument alloc] initWithContentsOfURL:absoluteURL error:&error];
        if (document) {
            [_documents addObject:document];
            [[document session] setAccessState:TCMMMSessionAccessReadWriteState];
            [document setIsAnnounced:YES];
        }
    }
}

@end
