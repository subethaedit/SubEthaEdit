//
//  SEEFSTreeNode.h
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 19.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@interface SEEFSTreeNode : NSObject
- (instancetype)initWithURL:(NSURL *)anURL;

- (NSString *)name;
- (NSImage *)icon;
- (NSArray *)children;
- (NSURL *)url;
- (BOOL)isLeaf;
- (void)reload;

- (SEEFSTreeNode * )nodeForPath:(NSString *)path;
- (SEEFSTreeNode * )nodeForPath:(NSString *)path onlyIfCached:(BOOL)cached;
@end


