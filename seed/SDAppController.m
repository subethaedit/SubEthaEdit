//
//  SDAppController.m
//  seed
//
//  Created by Martin Ott on 3/14/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "SDAppController.h"
#import "SDDocument.h"
#import "SDDocumentManager.h"
#import "TCMBEEP.h"
#import "TCMMillionMonkeys.h"
#import "FileManagementProfile.h"

NSString * const DemonWillTerminateNotification = @"DemonWillTerminateNotification";

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
            if (![document writeToURL:fileURL error:&error]) {
                // check error
            }
        }
    }
}

- (void)handleSignal:(NSNotification *)notification
{
    NSData *rawRequest = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    int dataSize = sizeof(int);
    unsigned length = [rawRequest length];
    unsigned location = 0;
    for (location = 0; location < length; location += dataSize) {
        int signal = *((int *)([rawRequest bytes]+location));
        NSLog(@"handleSignal: %d", signal);
        if (signal == SIGTERM) {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:NSFileHandleConnectionAcceptedNotification
                                                          object:[_signalPipe fileHandleForReading]];
                                                          
            [self autosaveTimerFired:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:DemonWillTerminateNotification object:self];                                              
            endRunLoop = YES;
            break;
        } else if (signal == SIGINFO) {
            NSMutableArray *outputLines = [NSMutableArray array];
            NSString *shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
            [outputLines addObject:[NSMutableString stringWithFormat:@"=== seed %@ (%@) state information ===",shortVersion,bundleVersion]];
            [outputLines addObject:[[TCMMMBEEPSessionManager sharedInstance] description]];
            [outputLines addObject:@"--- Documents:"];
            [outputLines addObject:[[[SDDocumentManager sharedInstance] documents] description]];
            [outputLines addObject:@"--- All Users:"];
            NSEnumerator *users = [[[TCMMMUserManager sharedInstance] allUsers] objectEnumerator];
            TCMMMUser *user = nil;
            while ((user=[users nextObject])) {
                [outputLines addObject:[user shortDescription]];
            }
            [outputLines addObject:@"=== seed information end ==="];
            NSLog([outputLines componentsJoinedByString:@"\n"]);
        }
    }
    [[_signalPipe fileHandleForReading] readInBackgroundAndNotify];
}

#pragma mark -

- (void)readConfig:(NSString *)configPath {
    NSLog(@"%s %@",__FUNCTION__,configPath);
    if (configPath) {
        NSDictionary *configPlist = [NSDictionary dictionaryWithContentsOfFile:[configPath stringByExpandingTildeInPath]];
        if (configPlist) {
            SDDocumentManager *dm=[SDDocumentManager sharedInstance];
            NSLog(@"%s %@",__FUNCTION__, configPlist);
            NSEnumerator *enumerator = [[configPlist objectForKey:@"InitialFiles"] objectEnumerator];
            NSDictionary *entry;
            while ((entry = [enumerator nextObject])) {
                NSString *file = [entry objectForKey:@"file"];
                
                SDDocument *document = [dm documentForRelativePath:file];
                if (!document) {
                    document = [dm addDocumentWithRelativePath:file];
                }
                NSString *mode = [entry objectForKey:@"mode"];
                if (mode) {
                    [document setModeIdentifier:mode];
                }
                
                NSString *IANACharSetName = [entry objectForKey:@"encoding"];
                NSStringEncoding encoding = NSUTF8StringEncoding;
                if (IANACharSetName) {
                    encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)IANACharSetName));
                    [document setStringEncoding:encoding];
                }
                if (document) {
                    [[document session] setAccessState:TCMMMSessionAccessReadWriteState];
                    [document setIsAnnounced:YES];
                }
            }
        }
    }
}

@end
