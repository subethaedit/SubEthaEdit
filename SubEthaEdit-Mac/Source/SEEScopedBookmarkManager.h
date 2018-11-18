//  SEEScopedBookmarkManager.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 19.03.14.

#import <Foundation/Foundation.h>

typedef NSURL * (^BookmarkGenerationBlock)(NSURL *);

@interface SEEScopedBookmarkManager : NSObject

+ (instancetype)sharedManager;

- (void)resetBookmarksInUserDefaults;

- (BOOL)hasBookmarkForURL:(NSURL *)aURL;
- (BOOL)canAccessURL:(NSURL *)aURL;

- (BOOL)startAccessingURL:(NSURL *)aURL;
- (BOOL)startAccessingScriptedFileURL:(NSURL *)aURL;
- (void)stopAccessingURL:(NSURL *)aURL;

@end
