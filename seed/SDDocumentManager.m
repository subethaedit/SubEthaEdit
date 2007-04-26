//
//  SDDocumentManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

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

- (id)init {
    if (S_sharedInstance) {
        [self dealloc];
        return S_sharedInstance;
    }
    if ((self=[super init])) {
        S_sharedInstance = self;
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
    }
    return self;
}

- (void)dealloc {
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

- (void)checkFileSystem {
    
}


- (NSArray *)documents {
    return _documents;
}

- (id)addDocumentWithContentsOfURL:(NSURL *)aContentURL encoding:(NSStringEncoding)anEncoding error:(NSError **)outError {
    NSLog(@"read document: %@", aContentURL);
    SDDocument *document = [(SDDocument *)[SDDocument alloc] initWithContentsOfURL:aContentURL encoding:anEncoding error:outError];
    if (document) {
        [self addDocument:document];
    }
    return document;
}

- (id)addDocumentWithSubpath:(NSString *)aPath encoding:(NSStringEncoding)anEncoding error:(NSError **)outError {
    if ([aPath rangeOfString:@".."].location != NSNotFound) return nil;
    NSString *filePathString = [_documentRootPath stringByAppendingPathComponent:aPath];
    NSURL *fileURL = [NSURL fileURLWithPath:filePathString];
    SDDocument *document = [self addDocumentWithContentsOfURL:fileURL encoding:anEncoding error:outError];
    if (!document) {
        document = [[SDDocument alloc] init];
        [document setFileURL:fileURL];
        [document setStringEncoding:anEncoding];
        [self addDocument:document];
    }
    return document;
}

#pragma mark -
#pragma mark ### BEEPSession interaction ###

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didOpenChannelWithProfile:(TCMBEEPProfile *)aProfile data:(NSData *)inData {
    NSLog(@"%s %@",__FUNCTION__,[aProfile class]);
    [aProfile setDelegate:self];
}

#pragma mark -
#pragma mark ### FileManagementProfile interaction ###

- (NSArray *)directoryListingForProfile:(FileManagementProfile *)aProfile {
    NSMutableArray *result = [NSMutableArray array];
    NSEnumerator *documents = [_availableDocumentsByID objectEnumerator];
    id document = nil;
    while ((document=[documents nextObject])) {
        [result addObject:[document dictionaryRepresentation]];
    }
    return result;
}

- (BOOL)profile:(FileManagementProfile *)aProfile didRequestNewDocumentWithAttributes:(NSDictionary *)attributes error:(NSError **)error {
    NSStringEncoding encoding = NSUTF8StringEncoding;
    if ([attributes objectForKey:@"Encoding"]) {
        encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)[attributes objectForKey:@"Encoding"]));
    }
    id document = [self addDocumentWithSubpath:[attributes objectForKey:@"FilePath"] encoding:encoding error:error];
    if (!document) return NO;
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
    return YES;
}

@end
