//
//  SEEWorkspace.h
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 03.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <Foundation/Foundation.h>



@class SEEWorkspace;

@protocol SEEWorkspaceDocument
@property (nonatomic, weak) SEEWorkspace *workspace;

@optional
-(BOOL) requiresWorkspace;

@end

@interface SEEWorkspace : NSObject {
    NSMutableArray <NSDocument<SEEWorkspaceDocument> *> *_documents;
}

@property (nonatomic, readonly) NSURL *baseURL;
@property (nonatomic, readonly) NSArray <NSDocument<SEEWorkspaceDocument> *>*documents;

-(instancetype)initWithBaseURL:(NSURL *)url;

-(BOOL)containsDocument:(NSDocument *)doc;

-(BOOL)containsURL:(NSURL *)url;

-(void)addDocument:(NSDocument<SEEWorkspaceDocument> *)doc;
-(void)removeDocument:(NSDocument<SEEWorkspaceDocument> *)doc;

@end


