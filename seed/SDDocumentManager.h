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
}

+ (id)sharedInstance;

- (NSArray *)documents;
- (void)addDocument:(SDDocument *)aDocument;
- (void)removeDocument:(SDDocument *)aDocument;
- (id)addDocumentWithContentsOfURL:(NSURL *)aContentURL encoding:(NSStringEncoding)anEncoding error:(NSError **)outError;
- (id)addDocumentWithSubpath:(NSString *)aPath encoding:(NSStringEncoding)anEncoding error:(NSError **)outError;

@end
