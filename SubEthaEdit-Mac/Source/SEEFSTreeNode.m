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
@property (nonatomic) BOOL isHidden;

@end

static NSArray *resourceValueKeys;

@implementation SEEFSTreeNode {
    __weak SEEFSTreeNode *parent;
    NSURL *url;
    NSArray *children;
}

+(void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        resourceValueKeys = @[NSURLIsDirectoryKey, NSURLIsHiddenKey];
    });
}

- (instancetype)initWithURL:(NSURL *)anURL parent:(SEEFSTreeNode *)aParent
{
    self = [super init];
    if (self) {
        url = anURL;
        parent = aParent;
        
        NSDictionary<NSURLResourceKey, id> *values = [url resourceValuesForKeys:resourceValueKeys
                             error:nil];
        
        self.isFolder = [((NSNumber *)values[NSURLIsDirectoryKey]) boolValue];
        self.isHidden = [((NSNumber *)values[NSURLIsHiddenKey]) boolValue];
        

    }
    return self;
}

- (NSString *)name {
    return url.lastPathComponent;
}

- (NSArray *)children {
    if(!children) {
        NSArray *contents = [NSFileManager.defaultManager contentsOfDirectoryAtURL:url
                                                        includingPropertiesForKeys:resourceValueKeys
                                                                           options:0
                                                                             error:nil];
        NSMutableArray * _children = [NSMutableArray arrayWithCapacity:contents.count];
        for (NSURL *url in contents) {
            SEEFSTreeNode *node = [[SEEFSTreeNode alloc] initWithURL:url parent:self];
            node.includeHidden = self.includeHidden;
            [_children addObject:node];
        }
        
        [_children filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SEEFSTreeNode * evaluatedObject, NSDictionary<NSString *,id> * bindings) {
            if(evaluatedObject.isHidden && !self.includeHidden) {
                return NO;
            }
            return YES;
        }]];
        
        children = _children;
        
        
    }
    
    return children;
}

- (NSImage *)icon {
    return [[NSWorkspace sharedWorkspace] iconForFile:url.filePathURL.path];
}

- (BOOL)isLeaf {
    return !_isFolder;
}

-(BOOL)isRoot {
    return parent == nil;
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
    return [self nodeForPath:path onlyIfCached:NO];
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

- (NSIndexPath *)indexPath {
    NSIndexPath *indexPath = parent.indexPath;
    
    if (parent) {
        NSUInteger ownIndex = [parent.children indexOfObject:self];
        indexPath = [indexPath indexPathByAddingIndex:ownIndex];
    } else {
        indexPath = [NSIndexPath indexPathWithIndex:0];
    }
    
    return indexPath;
}

-(void)setIncludeHidden:(BOOL)includeHidden {
    [self willChangeValueForKey:@"includeHidden"];
    _includeHidden = includeHidden;
    [self reloadIncludingChildren:YES];
    [self didChangeValueForKey:@"includeHidden"];
    
}

- (void)reloadIncludingChildren:(BOOL)includeChildren {
    [self willChangeValueForKey:@"children"];
    children = nil;
    [self didChangeValueForKey:@"children"];
}

@end
