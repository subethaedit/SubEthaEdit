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
    NSMutableArray *unfilteredChildren;
    NSMutableArray *children;
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
        children = [NSMutableArray new];
        [self reloadChildrenRecursive:NO];
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

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if ([other isKindOfClass:[SEEFSTreeNode class]]){
        SEEFSTreeNode *o = other;
        return [self.url isEqual: o.url] && (parent == o->parent) && (self.includeHidden == o.includeHidden);
    } else {
        return NO;
    }
}

- (NSUInteger)hash
{
    return self.url.hash + parent.hash;
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
    NSIndexPath *indexPath = nil;
    
    
    if (parent) {
        NSUInteger ownIndex = [parent.children indexOfObject:self];
        NSIndexPath *parentIndexPath = parent.indexPath;

        if(parentIndexPath) {
            indexPath = [parentIndexPath indexPathByAddingIndex:ownIndex];
        } else {
            indexPath = [NSIndexPath indexPathWithIndex:ownIndex];
        }
    }
    
    return indexPath;
}

-(void)setIncludeHidden:(BOOL)includeHidden {
    [self willChangeValueForKey:@"includeHidden"];
    _includeHidden = includeHidden;
    [self reloadChildrenRecursive:YES];
    [self didChangeValueForKey:@"includeHidden"];
}

- (void)reloadChildrenRecursive:(BOOL)recursive {
    [self willChangeValueForKey:@"children"];
    
    
    NSArray *contents = [NSFileManager.defaultManager contentsOfDirectoryAtURL:url
                                                           includingPropertiesForKeys:resourceValueKeys
                                                                              options:0
                                                                                error:nil];
    if(!children) {
        return;
    }
    
    for (NSURL *url in contents) {
        SEEFSTreeNode *node = [[SEEFSTreeNode alloc] initWithURL:url parent:self];
        node.includeHidden = self.includeHidden;
        
        if (![children containsObject:node]) {
            [children addObject:node];
        }
    }
    
    [children filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SEEFSTreeNode * evaluatedObject, NSDictionary<NSString *,id> * bindings) {
        
        if (![contents containsObject:evaluatedObject.url]) {
            return NO;
        }
        
        if(evaluatedObject.isHidden && !self.includeHidden) {
            return NO;
        }
        
        return YES;
    }]];
    
    if(recursive) {
        for (SEEFSTreeNode *node in children) {
            [node reloadChildrenRecursive:recursive];
        }
    }
    
    [self didChangeValueForKey:@"children"];
}

@end
