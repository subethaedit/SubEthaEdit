//
//  SDDocument.h
//  SubEthaEdit
//
//  Created by Martin Ott on 3/23/07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMMMSession.h"


@interface SDDocument : NSObject <SEEDocument> {
    @private
    NSMutableAttributedString *_attributedString;
    TCMMMSession *_session;
    NSURL *_fileURL;
    NSString *_modeIdentifier;
    NSStringEncoding _stringEncoding;
    struct {
        BOOL isAnnounced;
    } _flags;
}

- (id)initWithContentsOfURL:(NSURL *)absoluteURL encoding:(NSStringEncoding)anEncoding error:(NSError **)outError;
- (id)initWithContentsOfURL:(NSURL *)absoluteURL error:(NSError **)outError;

- (BOOL)readFromURL:(NSURL *)absoluteURL error:(NSError **)outError;
- (BOOL)saveToURL:(NSURL *)absoluteURL error:(NSError **)outError;

- (NSURL *)fileURL;
- (void)setFileURL:(NSURL *)absoluteURL;

- (NSString *)modeIdentifier;
- (void)setModeIdentifier:(NSString *)identifier;

- (NSStringEncoding)stringEncoding;
- (void)setStringEncoding:(NSStringEncoding)anEncoding;

- (TCMMMSession *)session;
- (void)setSession:(TCMMMSession *)session;

- (BOOL)isAnnounced;
- (void)setIsAnnounced:(BOOL)flag;

@end
