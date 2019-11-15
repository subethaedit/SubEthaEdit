//
//  SEEFSTree.h
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 24.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SEEFSTreeNode;



@interface SEEFSTree : NSObject
@property (nonatomic, readonly) SEEFSTreeNode *root;

- (instancetype)initWithURL:(NSURL *)anURL;

@end


