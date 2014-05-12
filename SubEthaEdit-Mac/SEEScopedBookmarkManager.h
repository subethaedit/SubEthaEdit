//
//  SEEScopedBookmarkManager.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 19.03.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSURL * (^BookmarkGenerationBlock)(NSURL *);

@interface SEEScopedBookmarkManager : NSObject

+ (instancetype)sharedManager;

- (void)resetBookmarksInUserDefaults;

- (BOOL)hasBookmarkForURL:(NSURL *)aURL;

- (BOOL)startAccessingURL:(NSURL *)aURL;
- (void)stopAccessingURL:(NSURL *)aURL;

@end
