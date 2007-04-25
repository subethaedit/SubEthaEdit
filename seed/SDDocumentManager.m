//
//  SDDocumentManager.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "SDDocumentManager.h"
#import "SDDocument.h"

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
        _documents = [NSMutableArray new];
        NSString *documentRoot = [[NSUserDefaults standardUserDefaults] objectForKey:@"document_root"];
        if (!documentRoot) documentRoot = BASE_LOCATION @"/Documents";
        _documentRootPath = [documentRoot retain];
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL wasDirectory = NO;
        if (![fm fileExistsAtPath:_documentRootPath isDirectory:&wasDirectory]) {
            [fm createDirectoryAtPath:_documentRootPath attributes:nil];
        }
        S_sharedInstance = self;
    }
    return self;
}

- (void)dealloc {
    [_documents release];
    [_documentRootPath release];
    [super dealloc];
}

- (void)addDocument:(SDDocument *)aDocument {
    [_documents addObject:aDocument];
}

- (void)removeDocument:(SDDocument *)aDocument {
    [_documents removeObject:aDocument];
}

- (NSArray *)documents {
    return _documents;
}

- (id)addDocumentWithContentsOfURL:(NSURL *)aContentURL error:(NSError **)outError {
    NSLog(@"read document: %@", aContentURL);
    SDDocument *document = [(SDDocument *)[SDDocument alloc] initWithContentsOfURL:aContentURL error:outError];
    if (document) {
        [self addDocument:document];
    }
    return document;
}

- (id)addDocumentWithSubpath:(NSString *)aPath error:(NSError **)outError {
    if ([aPath rangeOfString:@".."].location != NSNotFound) return nil;
    NSString *filePathString = [_documentRootPath stringByAppendingPathComponent:aPath];
    NSURL *fileURL = [NSURL fileURLWithPath:filePathString];
    SDDocument *document = [self addDocumentWithContentsOfURL:fileURL error:outError];
    if (!document) {
        document = [[SDDocument alloc] init];
        [document setFileURL:fileURL];
        [self addDocument:document];
    }
    return document;
}



@end
