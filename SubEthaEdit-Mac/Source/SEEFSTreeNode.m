//
//  SEEFSTreeNode.m
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 19.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import "SEEFSTreeNode.h"

@interface FSEvent : NSObject

@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) FSEventStreamEventFlags eventFlags;
@property (nonatomic, readonly) FSEventStreamEventId eventIds;

@end

@interface SEEFSTreeNode ()
@property (nonatomic) BOOL isFolder;
@end


@implementation SEEFSTreeNode {
    NSURL *url;
    NSArray *children;
}

- (instancetype)initWithURL:(NSURL *)anURL
{
    self = [super init];
    if (self) {
        url = anURL;
        
        NSDictionary<NSURLResourceKey, id> *values = [url resourceValuesForKeys:@[NSURLIsDirectoryKey]
                             error:nil];
        
        self.isFolder = [((NSNumber *)values[NSURLIsDirectoryKey]) boolValue];
        

    }
    return self;
}



- (NSString *)name {
    return url.lastPathComponent;
}

- (NSArray *)children {
    if(!children) {
        NSArray *contents = [NSFileManager.defaultManager contentsOfDirectoryAtURL:url
                                                        includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                                           options:0
                                                                             error:nil];
        NSMutableArray * _children = [NSMutableArray arrayWithCapacity:contents.count];
        for (NSURL *url in contents) {
            [_children addObject:[[SEEFSTreeNode alloc] initWithURL:url]];
        }
        children = [_children sortedArrayUsingComparator:^NSComparisonResult(SEEFSTreeNode *obj1, SEEFSTreeNode *obj2) {
            NSComparisonResult result = NSOrderedSame;
            if (obj1.isLeaf && !obj2.isLeaf) {
                result = NSOrderedDescending;
            } else if(!obj1.isLeaf && obj2.isLeaf) {
                result = NSOrderedAscending;
            } else {
                result = [obj1.name compare:obj2.name];
            }
            
            return result;
        }];
    }
    
    return children;
}

- (NSImage *)icon {
    return [[NSWorkspace sharedWorkspace] iconForFile:url.filePathURL.path];
}

- (BOOL)isLeaf {
    return !_isFolder;
}

-(NSURL *)url {
    return url;
}

- (SEEFSTreeNode *)nodeNamed:(NSString *)name {
    return [self nodeNamed:name onlyIfCached:NO];
}

- (SEEFSTreeNode *)nodeNamed:(NSString *)name onlyIfCached:(BOOL)cached{
    NSArray *_children = cached ? children : self.children;
    for (SEEFSTreeNode* node in _children) {
        if([node.name isEqualToString:name]) {
            return node;
        }
    }
    return nil;
}

- (SEEFSTreeNode * )nodeForPath:(NSString *)path {
    return [self nodeNamed:path onlyIfCached:NO];
}

- (SEEFSTreeNode *)nodeForPath:(NSString *)path onlyIfCached:(BOOL)cached {
    NSMutableArray <NSString *>* components = [[path pathComponents] mutableCopy];
    NSArray <NSString *>* ownComponents = url.pathComponents;
    
    if ([components.lastObject isEqualToString:@"/"]) {
        [components removeLastObject];
    }
    
    if (ownComponents.count <= components.count) {
        
        NSRange r = NSMakeRange(0, ownComponents.count);
        NSRange rest = NSMakeRange(ownComponents.count, components.count - ownComponents.count);
        if([ownComponents isEqualToArray:[components subarrayWithRange:r]]) {
            
            SEEFSTreeNode *currentNode = self;
            for (NSString *component in [components subarrayWithRange:rest]) {
                currentNode = [currentNode nodeNamed:component onlyIfCached:cached];
            }
            return currentNode;
        }
    }
    return nil;
}

- (void)reload {
    [self willChangeValueForKey:@"children"];
    children = nil;
    [self didChangeValueForKey:@"children"];
}

@end
