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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAcceptSession:) name:TCMMMBEEPSessionManagerDidAcceptSessionNotification object:nil];
    }
    return self;
}

- (void)didAcceptSession:(NSNotification *)aNotification {
    NSLog(@"%s",__FUNCTION__);
    TCMBEEPSession *session=[[aNotification userInfo] objectForKey:@"Session"];
    if ([[session peerProfileURIs] containsObject:@"http://www.codingmonkeys.de/BEEP/SeedFileManagement"]) {
        NSLog(@"%s contained http://www.codingmonkeys.de/BEEP/SeedFileManagement",__FUNCTION__);
        [session startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SeedFileManagement"] andData:nil sender:self];
    }
}

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didOpenChannelWithProfile:(TCMBEEPProfile *)aProfile data:(NSData *)aData
{
    NSLog(@"%s %@ %@",__FUNCTION__,aBEEPSession, aProfile);
    [(FileManagementProfile *)aProfile askForDirectoryListing];
    [(FileManagementProfile *)aProfile requestNewFileWithAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"ascii",@"Encoding",
            @"hallogallo.html",@"FilePath",
            @"tri tra trullalala der kasperle ist wieder da!\n\n\nfoobar\n",@"Content",
            @"SEEMode.Conference",@"ModeIdentifier",
            [NSNumber numberWithInt:TCMMMSessionAccessReadWriteState],@"AccessState",
         nil]];
    [(FileManagementProfile *)aProfile askForDirectoryListing];

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

- (void)readConfig:(NSString *)configPath {
    NSLog(@"%s %@",__FUNCTION__,configPath);
    if (configPath) {
        NSDictionary *configPlist = [NSDictionary dictionaryWithContentsOfFile:[configPath stringByExpandingTildeInPath]];
        if (configPlist) {
            NSLog(@"%s %@",__FUNCTION__, configPlist);
            NSEnumerator *enumerator = [[configPlist objectForKey:@"InitialFiles"] objectEnumerator];
            NSDictionary *entry;
            while ((entry = [enumerator nextObject])) {
                NSString *file = [entry objectForKey:@"file"];
                NSString *mode = [entry objectForKey:@"mode"];
                NSString *IANACharSetName = [entry objectForKey:@"encoding"];
                NSStringEncoding encoding = NSUTF8StringEncoding;
                if (IANACharSetName) {
                    encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)IANACharSetName));
                }
                NSError *error = nil;
                SDDocument *document = [[SDDocumentManager sharedInstance] addDocumentWithSubpath:file encoding:encoding error:&error];
                if (document) {
                    if (mode) [document setModeIdentifier:mode];
                    [[document session] setAccessState:TCMMMSessionAccessReadWriteState];
                    [document setIsAnnounced:YES];
                }
            }
        }
    }
}

@end
