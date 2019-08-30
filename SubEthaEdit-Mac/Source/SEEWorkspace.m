//
//  SEEWorkspace.m
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 03.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "SEEWorkspace.h"

@implementation SEEWorkspace {
    NSMutableArray <NSDocument<SEEWorkspaceDocument> *> *_documents;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        NSAssert(url.isFileURL, @"Workspaces can only be instanciated on file URLs");
        _baseURL = [url.absoluteURL copy];
        _documents = [NSMutableArray new];
    }
    return self;
}

-(BOOL)containsDocument:(NSDocument<SEEWorkspaceDocument> *)doc {
    return [self.documents containsObject:doc];
}

-(BOOL)containsURL:(NSURL *)url {
    if( url.isFileURL ) {
        NSArray *baseComponents = _baseURL.pathComponents;
        NSArray *components = url.absoluteURL.pathComponents;
        
        NSUInteger index = 0;
        if (components.count >= baseComponents.count) {
            for (NSString *baseComponent in baseComponents) {
                if (![baseComponent isEqualToString:components[index]]) {
                    return NO;
                }
                index++;
            }
            return YES;
        }
    }
    return NO;
}

-(NSArray<NSDocument *> *)documents {
    return [_documents copy];
}

-(void)addDocument:(NSDocument<SEEWorkspaceDocument> *)doc {
    [_documents addObject:doc];
    doc.workspace = self;
}

-(void)removeDocument:(NSDocument<SEEWorkspaceDocument> *)doc {
    [_documents removeObject:doc];
    doc.workspace = nil;
}

@end
