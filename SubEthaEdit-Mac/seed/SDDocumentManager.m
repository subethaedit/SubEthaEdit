//
//  SDDocumentManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "SDAppController.h"
#import "SDDocumentManager.h"
#import "SDDocument.h"
#import "TCMMMBEEPSessionManager.h"
#import "FileManagementProfile.h"

static SDDocumentManager *S_sharedInstance=nil;

@implementation SDDocumentManager

+ (id)sharedInstance {
    if (!S_sharedInstance) {
        S_sharedInstance = [[SDDocumentManager alloc] init];
    }
    return S_sharedInstance;
}

- (NSString *)stateFilePath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *result = [defaults stringForKey:@"state_file_path"];
    if (result) return result;
    return [[defaults stringForKey:@"base_location"] stringByAppendingPathComponent:@"/state.plist"];
}

- (void)addDocumentsFromPath:(NSString *)aFilePath {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSEnumerator *entries = [fm enumeratorAtPath:aFilePath]; // this is a deep enumerator traversing subdirectories
    NSString *entry = nil;
    while ((entry=[entries nextObject])) {
        BOOL wasDirectory = NO;
        NSString *path = [aFilePath stringByAppendingPathComponent:entry];
        if ([fm fileExistsAtPath:path isDirectory:&wasDirectory]) {
            if (!wasDirectory) {
                SDDocument *document = [[[SDDocument alloc] initWithURL:[NSURL fileURLWithPath:path] onDisk:YES] autorelease];
                if (document) {
                    [self addDocument:document];
                }
            }
        }
    }
}

- (id)init {
    if (S_sharedInstance) {
        [self dealloc];
        return S_sharedInstance;
    }
    if ((self=[super init])) {
        S_sharedInstance = self;
        _fileManagementProfiles = [NSMutableSet new];
        _documentIDsWithPendingChanges = [NSMutableSet new];
        _flags.hasScheduledFileUpdate = NO;
        _documents = [NSMutableArray new];
        _availableDocumentsByID = [NSMutableDictionary new];
        NSString *documentRoot = [[NSUserDefaults standardUserDefaults] objectForKey:@"document_root"];
        if (!documentRoot) documentRoot = BASE_LOCATION @"/Documents";
        _documentRootPath = [documentRoot retain];
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL wasDirectory = NO;
        if (![fm fileExistsAtPath:_documentRootPath isDirectory:&wasDirectory]) {
            [fm createDirectoryAtPath:_documentRootPath attributes:nil];
        }        
        [[TCMMMBEEPSessionManager sharedInstance] registerHandler:self forIncomingProfilesWithProfileURI:@"http://www.codingmonkeys.de/BEEP/SeedFileManagement"];
        
        // iterate over directory and create a document for every File on disk
        [self addDocumentsFromPath:_documentRootPath];
        
        // load state from disk
        NSDictionary *stateDict = [NSDictionary dictionaryWithContentsOfFile:[self stateFilePath]];
        NSEnumerator *documentStates = [[stateDict objectForKey:@"documentStates"] objectEnumerator];
        NSDictionary *entry = nil;
        while ((entry = [documentStates nextObject])) {
            NSString *file = [entry objectForKey:@"FilePath"];
            if (file) {
                SDDocument *document = [self documentForRelativePath:file];
                if (!document) {
                    document = [self addDocumentWithRelativePath:file];
                }
                NSNumber *changeCount = [entry objectForKey:@"changeCount"];
                if (changeCount) {
                    [document setValue:changeCount forKey:@"changeCount"];
                }
                NSString *fileID = [entry objectForKey:@"FileID"];
                if (fileID) {
                    [document setUniqueID:fileID];
                }
                NSString *mode = [entry objectForKey:@"ModeIdentifier"];
                if (mode) {
                    [document setModeIdentifier:mode];
                }
                
                NSString *IANACharSetName = [entry objectForKey:@"Encoding"];
                NSStringEncoding encoding = NSUTF8StringEncoding;
                if (IANACharSetName) {
                    encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)IANACharSetName));
                    [document setStringEncoding:encoding];
                }
                NSNumber *accessState = [entry objectForKey:@"AccessState"];
                if (accessState) {
                    [document setValue:accessState forKey:@"accessState"];
                }
                NSNumber *isAnnounced = [entry objectForKey:@"IsAnnounced"];
                if (isAnnounced) {
                    [document setIsAnnounced:[isAnnounced boolValue]];
                }
            }
        }
        
        NSLog(@"%s - documents after load of state: %@",__FUNCTION__,_documents);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentDidChangeChangeCount:) name:SDDocumentDidChangeChangeCountNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(demonWillTerminate:) name:DemonWillTerminateNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [_fileManagementProfiles release];
    [_availableDocumentsByID release];
    [_documents release];
    [_documentRootPath release];
    [super dealloc];
}

- (void)addDocument:(SDDocument *)aDocument {
    [_documents addObject:aDocument];
    [_availableDocumentsByID setObject:aDocument forKey:[aDocument uniqueID]];
}

- (void)removeDocument:(SDDocument *)aDocument {
    [_documents removeObject:aDocument];
    [_availableDocumentsByID removeObjectForKey:[aDocument uniqueID]];
}

- (NSString *)documentRootPath {
    return _documentRootPath;
}


- (NSArray *)documents {
    return _documents;
}

- (SDDocument *)documentForRelativePath:(NSString *)aPath {
    NSArray *matchingDocuments = [_documents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathRelativeToDocumentRoot = %@",aPath]];
//    NSLog(@"%s %@ matches %d documents",__FUNCTION__,aPath,[matchingDocuments count]);
    return [matchingDocuments lastObject];
}


- (id)addDocumentWithContentsOfURL:(NSURL *)aContentURL encoding:(NSStringEncoding)anEncoding error:(NSError **)outError {
    NSLog(@"read document: %@", aContentURL);
    SDDocument *document = [(SDDocument *)[SDDocument alloc] initWithContentsOfURL:aContentURL encoding:anEncoding error:outError];
    if (document) {
        [self addDocument:document];
    }
    return document;
}

- (id)addDocumentWithRelativePath:(NSString *)aPath {
    SDDocument *document = [[[SDDocument alloc] initWithURL:[NSURL fileURLWithPath:[_documentRootPath stringByAppendingPathComponent:aPath]] onDisk:NO] autorelease];
    if (document) {
        [self addDocument:document];
    }
    return document;
}

- (void)demonWillTerminate:(NSNotification *)aNotification {
    NSMutableDictionary *stateDict = [NSMutableDictionary dictionary];
    NSMutableArray *documentStates = [NSMutableArray array];
    [stateDict setObject:documentStates forKey:@"documentStates"];
    NSEnumerator *documents = [_documents objectEnumerator];
    SDDocument *document = nil;
    while ((document = [documents nextObject])) {
        [documentStates addObject:[document dictionaryRepresentation]];
    }
    [stateDict writeToFile:[self stateFilePath] atomically:YES];
}

#pragma mark -
#pragma mark ### BEEPSession interaction ###

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didOpenChannelWithProfile:(TCMBEEPProfile *)aProfile data:(NSData *)inData {
//    NSLog(@"%s %@",__FUNCTION__,[aProfile class]);
    [aProfile setDelegate:self];
    [_fileManagementProfiles addObject:aProfile];
}

#pragma mark -
#pragma mark ### FileManagementProfile interaction ###

- (void)documentDidChangeChangeCount:(NSNotification *)aNotification {
    [_documentIDsWithPendingChanges addObject:[(SDDocument *)[aNotification object] uniqueID]];
    if (!_flags.hasScheduledFileUpdate) {
        [self performSelector:@selector(sendFileUpdates) withObject:nil afterDelay:0.0];
        _flags.hasScheduledFileUpdate = YES;
    }
}

- (void)sendFileUpdates {
    _flags.hasScheduledFileUpdate = NO;
    NSMutableDictionary *fileUpdateDictionary = [NSMutableDictionary dictionary];
    NSEnumerator *fileIDs = [_documentIDsWithPendingChanges objectEnumerator];
    NSString *fileID = nil;
    while ((fileID=[fileIDs nextObject])) {
        SDDocument *document = [_availableDocumentsByID objectForKey:fileID];
        if (document) {
            [fileUpdateDictionary setObject:[document dictionaryRepresentation] forKey:fileID];
        } else {
            [fileUpdateDictionary setObject:@"removed" forKey:fileID];
        }
    }
    [_documentIDsWithPendingChanges removeAllObjects];
    
    NSEnumerator *profiles = [_fileManagementProfiles objectEnumerator];
    FileManagementProfile *profile = nil;
    while ((profile = [profiles nextObject])) {
        if ([profile didSendFILLST]) {
            [profile sendFileUpdates:fileUpdateDictionary];
        }
    }
}

- (void)profileDidClose:(TCMBEEPProfile *)aProfile {
    [aProfile setDelegate:nil];
    [_fileManagementProfiles removeObject:aProfile];
}

- (void)profileDidFail:(TCMBEEPProfile *)aProfile withError:(NSError *)anError {
    [self profileDidClose:aProfile];
}


- (NSArray *)fileListForProfile:(FileManagementProfile *)aProfile {
    NSMutableArray *result = [NSMutableArray array];
    NSEnumerator *documents = [_availableDocumentsByID objectEnumerator];
    id document = nil;
    while ((document=[documents nextObject])) {
        [result addObject:[document dictionaryRepresentation]];
    }
    return result;
}

- (id)profile:(FileManagementProfile *)aProfile didRequestNewDocumentWithAttributes:(NSDictionary *)attributes error:(NSError **)error {
    NSString *relativePath = [attributes objectForKey:@"FilePath"];
    if ([self documentForRelativePath:relativePath]) {
        return nil;
    }
    SDDocument * document = [self addDocumentWithRelativePath:relativePath];
    if (!document) return nil;
    if ([attributes objectForKey:@"Encoding"]) {
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)[attributes objectForKey:@"Encoding"]));
        [document setStringEncoding:encoding];
    }
    if ([attributes objectForKey:@"Content"]) {
        [document setContentString:[attributes objectForKey:@"Content"]];
    }
    if ([attributes objectForKey:@"ModeIdentifier"]) {
        [document setModeIdentifier:[attributes objectForKey:@"ModeIdentifier"]];
    }
    if ([attributes objectForKey:@"AccessState"]) {
        [[document session] setAccessState:[[attributes objectForKey:@"AccessState"] intValue]];
    }
    [document setIsAnnounced:YES];
    return document;
}

- (id)profile:(FileManagementProfile *)aProfile didRequestChangeOfAttributes:(NSDictionary *)aNewAttributes ofDocumentWithID:(NSString *)aFileID error:(NSError **)outError {
    SDDocument *document = [_availableDocumentsByID objectForKey:aFileID];
    if (!document) {
        *outError = [NSError errorWithDomain:@"DocumentManagementDomain" code:123 userInfo:nil];
        return nil;
    }
    NSNumber *newAccessState = [aNewAttributes objectForKey:@"AccessState"];
    if (newAccessState) {
        [document setValue:newAccessState forKey:@"accessState"];
    }
    NSNumber *newIsAnnounced = [aNewAttributes objectForKey:@"IsAnnounced"];
    if (newIsAnnounced) {
        [document setValue:newIsAnnounced forKey:@"isAnnounced"];
    }
    NSString *newEncoding = [aNewAttributes objectForKey:@"Encoding"];
    if (newEncoding) {
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)newEncoding));
        if (![document setStringEncoding:encoding]) {
            *outError = [NSError errorWithDomain:@"DocumentManagementDomain" code:123 userInfo:nil];
        }
    }
    NSString *newMode = [aNewAttributes objectForKey:@"Mode"];
    if (newMode) {
        [document setModeIdentifier:newMode];
    }
    return document;
}


@end
