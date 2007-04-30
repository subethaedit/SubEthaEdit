//
//  SDDocumentManager.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define BASE_LOCATION @"/Library/SeeServer"

@class SDDocument;
@interface SDDocumentManager : NSObject {
    NSMutableArray *_documents;
    NSString *_documentRootPath;
    NSMutableDictionary *_availableDocumentsByID;
    NSMutableSet *_fileManagementProfiles;
    NSMutableSet *_documentIDsWithPendingChanges;
    struct {
        BOOL hasScheduledFileUpdate;
    } _flags;
}

+ (id)sharedInstance;

- (NSString *)documentRootPath;

- (NSArray *)documents;
- (SDDocument *)documentForRelativePath:(NSString *)aPath;
- (void)addDocument:(SDDocument *)aDocument;
- (void)removeDocument:(SDDocument *)aDocument;
- (id)addDocumentWithContentsOfURL:(NSURL *)aContentURL encoding:(NSStringEncoding)anEncoding error:(NSError **)outError;
- (id)addDocumentWithRelativePath:(NSString *)aPath;

@end
