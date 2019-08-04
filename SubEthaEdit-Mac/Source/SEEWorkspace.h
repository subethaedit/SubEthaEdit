//
//  SEEWorkspace.h
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 03.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SEEWorkspace : NSObject {
    NSMutableArray <NSDocument *> *documents;
}

@property (nonatomic, readonly) NSURL *baseURL;
@property (nonatomic, readonly) NSArray <NSDocument *>*openDocuments;

-(instancetype)initWithBaseURL:(NSURL *)url;

-(BOOL)containsDocument:(NSDocument *)doc;

@end

NS_ASSUME_NONNULL_END
