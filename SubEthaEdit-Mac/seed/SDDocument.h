//
//  SDDocument.h
//  SubEthaEdit
//
//  Created by Martin Ott on 3/23/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

/*
Documents:
==========
Documents are created for each file that exists in the Document Root of the server. Initially Documents aren't loaded - so the contents are on disk. The DocumentManager loads files when they are announced. 

*/

#import <Foundation/Foundation.h>
#import "TCMMMSession.h"

extern NSString * const SDDocumentDidChangeChangeCountNotification;

@interface SDDocument : NSObject <SEEDocument> {
    @private
    NSMutableAttributedString *_attributedString;
    TCMMMSession *_session;
    NSURL *_fileURL;
    NSString *_modeIdentifier;
    NSStringEncoding _stringEncoding;
    struct {
        BOOL isAnnounced;
        BOOL onDisk;
    } _flags;
    int _changeCount;
}

- (id)initWithURL:(NSURL *)absoluteURL onDisk:(BOOL)aFlag;
- (BOOL)readFromDisk:(NSError **)outError;
- (BOOL)writeToDisk:(NSError **)outError;

- (id)initWithContentsOfURL:(NSURL *)absoluteURL encoding:(NSStringEncoding)anEncoding error:(NSError **)outError;
- (id)initWithContentsOfURL:(NSURL *)absoluteURL error:(NSError **)outError;

- (BOOL)readFromURL:(NSURL *)absoluteURL error:(NSError **)outError;
- (BOOL)writeToURL:(NSURL *)absoluteURL error:(NSError **)outError;

- (NSURL *)fileURL;
- (void)setFileURL:(NSURL *)absoluteURL;

- (void)setContentString:(NSString *)aString;
- (NSDictionary *)dictionaryRepresentation;

- (NSString *)pathRelativeToDocumentRoot;

- (void)setUniqueID:(NSString *)aUUIDString;
- (NSString *)uniqueID;

- (NSString *)modeIdentifier;
- (void)setModeIdentifier:(NSString *)identifier;

- (NSStringEncoding)stringEncoding;
- (BOOL)setStringEncoding:(NSStringEncoding)anEncoding;

- (void)setAccessState:(TCMMMSessionAccessState)aState;
- (TCMMMSessionAccessState)accessState;

- (TCMMMSession *)session;
- (void)setSession:(TCMMMSession *)session;

- (BOOL)isAnnounced;
- (BOOL)setIsAnnounced:(BOOL)flag;

- (NSDictionary *)textStorageDictionaryRepresentation;

@end

#import "DocumentSharedMethods.h"
