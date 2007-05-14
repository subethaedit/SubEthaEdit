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
#import "SDDirectory.h"

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(BEEPSessionDidReceiveGreeting:)
        name:TCMBEEPSessionDidReceiveGreetingNotification object:nil];
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
//        NSLog(@"handleSignal: %d", signal);
        if (signal == SIGTERM || signal == SIGINT) {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:NSFileHandleConnectionAcceptedNotification
                                                          object:[_signalPipe fileHandleForReading]];
                                                          
            [self autosaveTimerFired:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:DemonWillTerminateNotification object:self]; 
            [[TCMMMBEEPSessionManager sharedInstance] terminateAllBEEPSessions];                                             
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
        NSLog(@"%s %@",__FUNCTION__,configPlist);
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
            
            
            NSDictionary *directoryDictionary = [configPlist objectForKey:@"Directory"];
            if (directoryDictionary) {
                SDDirectory *directory = [SDDirectory sharedInstance];
                [directory addEntriesFromDictionaryRepresentation:directoryDictionary];
                NSLog(@"%s dictionaryLoaded:%@",__FUNCTION__,directory);
            } else {
                SDDirectory *directory = [SDDirectory sharedInstance];
                id tcmgroup = [directory makeGroupWithShortName:@"tcm"];
                id shdwgroup = [directory makeGroupWithShortName:@"shdw"];
                id tcmshdwgroup = [directory makeGroupWithShortName:@"tcm+shdw"];
                [tcmgroup addToGroup:tcmshdwgroup];
                [shdwgroup addToGroup:tcmshdwgroup];
                id user = [directory makeUserWithShortName:@"dom"];
                [user setFullName:@"Dominik Wagner"];
                [user addToGroup:shdwgroup];
                [user addToGroup:tcmgroup];
                [user setValue:@"dom" forKey:@"password"];
                user = [directory makeUserWithShortName:@"map"];
                [user setValue:@"map" forKey:@"password"];
                [user addToGroup:tcmgroup];
                user = [directory makeUserWithShortName:@"mbo"];
                [user setValue:@"mbo" forKey:@"password"];
                [user addToGroup:tcmgroup];
                user = [directory makeUserWithShortName:@"mist"];
                user = [directory makeUserWithShortName:@"enzo"];
                [user setValue:@"enzo" forKey:@"password"];
                [user addToGroup:shdwgroup];
                NSLog(@"%s %@",__FUNCTION__,directory);
                NSDictionary *rep=[directory dictionaryRepresentation];
                NSLog(@"%s %@",__FUNCTION__,rep);
                SDDirectory *remoteDirectory = [SDDirectory new];
                [remoteDirectory addEntriesFromDictionaryRepresentation:rep];
                NSLog(@"%s reloaded Rep: %@",__FUNCTION__,rep);
                
                NSLog(@"is dom member of tcm? %@",[[remoteDirectory userForShortName:@"dom"] isMemberOfGroup:[remoteDirectory groupForShortName:@"tcm"]]?@"YES":@"NO");
                NSLog(@"is mbo member of shdw? %@",[[remoteDirectory userForShortName:@"mbo"] isMemberOfGroup:[remoteDirectory groupForShortName:@"shdw"]]?@"YES":@"NO");
                NSLog(@"is mbo member of tcm+shdw? %@",[[remoteDirectory userForShortName:@"mbo"] isMemberOfGroup:[remoteDirectory groupForShortName:@"tcm+shdw"]]?@"YES":@"NO");
                NSLog(@"is mist member of everyone? %@",[[remoteDirectory userForShortName:@"mist"] isMemberOfGroup:[remoteDirectory groupForShortName:kSDDirectoryGroupEveryoneGroupShortName]]?@"YES":@"NO");
                
                rep = [directory shortDictionaryRepresentation];
                NSLog(@"%s shortRepresentation: %@",__FUNCTION__,rep);
remoteDirectory = [SDDirectory new];
                [remoteDirectory addEntriesFromDictionaryRepresentation:rep];
                NSLog(@"%s reloaded Rep: %@",__FUNCTION__,rep);
                
                NSLog(@"is dom member of tcm? %@",[[remoteDirectory userForShortName:@"dom"] isMemberOfGroup:[remoteDirectory groupForShortName:@"tcm"]]?@"YES":@"NO");
                NSLog(@"is mbo member of shdw? %@",[[remoteDirectory userForShortName:@"mbo"] isMemberOfGroup:[remoteDirectory groupForShortName:@"shdw"]]?@"YES":@"NO");
                NSLog(@"is mbo member of tcm+shdw? %@",[[remoteDirectory userForShortName:@"mbo"] isMemberOfGroup:[remoteDirectory groupForShortName:@"tcm+shdw"]]?@"YES":@"NO");
                NSLog(@"is mist member of everyone? %@",[[remoteDirectory userForShortName:@"mist"] isMemberOfGroup:[remoteDirectory groupForShortName:kSDDirectoryGroupEveryoneGroupShortName]]?@"YES":@"NO");
            }
        }
    }
}

#pragma mark -
#pragma mark ### authentication handling ###

- (void)BEEPSessionDidReceiveGreeting:(NSNotification *)aNotification {
//    NSLog(@"%s %@",__FUNCTION__,[aNotification object]);
    [[[aNotification object] authenticationServer] setDelegate:self];
}

- (int)authenticationResultForServer:(TCMBEEPAuthenticationServer *)aServer user:(NSString 
*)aUser password:(NSString *)aPassword {
    if ([aPassword isEqualToString:[[[SDDirectory sharedInstance] userForShortName:aUser] password]]) {
        return SASL_OK;
    } else {
        return SASL_BADAUTH;
    }
}


@end
