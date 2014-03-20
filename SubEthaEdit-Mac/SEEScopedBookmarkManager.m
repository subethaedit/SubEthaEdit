//
//  SEEScopedBookmarkManager.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 19.03.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEScopedBookmarkManager.h"
#import "UKXattrMetadataStore.h"


static NSString * const SEEScopedBookmarksKey = @"de.codingmonkeys.subethaedit.security.scopedBookmarks";


@interface SEEScopedBookmarkManager ()
@property (nonatomic, strong) NSMutableDictionary *lookupDict;
@property (nonatomic, strong) NSMutableArray *bookmarkURLs;
@property (nonatomic, strong) NSMutableArray *accessingURLs;
@end


@interface NSURL (TCMNSURLAddition)

+ (NSURL *)nearestParentDirectoryOfURL:(NSURL *)aURL inList:(NSArray *)aURLList;

@end

@implementation NSURL (TCMNSURLAddition)

// can also return self
+ (NSURL *)nearestParentDirectoryOfURL:(NSURL *)aURL inList:(NSArray *)aURLList {
	NSURL *result = nil;
	if (aURL) {
		NSString *urlPath = [aURL path];
		NSString *oldURLPath = nil;

		// if you really want the nearest then you have to sort the list
		do {
			for (NSURL *url in aURLList) {
				if ([[url path] isEqualToString:urlPath]) {
					result = url;
					break;
				}
			}
			oldURLPath = urlPath;
			urlPath = [urlPath stringByDeletingLastPathComponent];

		} while (!result && ![oldURLPath isEqualToString:urlPath]);
	}
	return result;
}

@end

@implementation SEEScopedBookmarkManager

+ (instancetype)sharedManager {
	static id sSharedManager = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		sSharedManager = [[[self class] alloc] init];
	});
	return sSharedManager;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        self.lookupDict = [NSMutableDictionary dictionary];
		self.accessingURLs = [NSMutableArray array];

		[self readBookmarksFromUserDefaults];
    }
    return self;
}


- (NSArray *)readSecurityScopedBookmarksAttachedToDocument:(NSDocument *)document error:(NSError **)outError {
	if (outError) {
		*outError = nil;
	}

	NSMutableArray *bookmarkURLs = nil;
	NSURL *documentURL = document.fileURL;

	NSData *plistData = [UKXattrMetadataStore dataForKey:SEEScopedBookmarksKey
												  atPath:[documentURL path]
											traverseLink:YES];

	if (plistData) {
		NSError *bookmarkSerialisationError = nil;
		NSArray *scopedBookmarks = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:nil error:&bookmarkSerialisationError];

		if (bookmarkSerialisationError) {
			if (outError) {
				*outError = bookmarkSerialisationError;
			} else {
				DEBUGLOG(@"FileIOLogDomain", AlwaysLogLevel, @"Error deserializing security scoped bookmarks: %@", bookmarkSerialisationError);
			}
		} else {
			bookmarkURLs = [NSMutableArray array];
			for (NSData *bookmarkData in scopedBookmarks) {
				NSError *bookmarkResolvingError = nil;
				BOOL bookmarkIsStale = NO;

				NSURL *url = [NSURL URLByResolvingBookmarkData:bookmarkData
													   options:NSURLBookmarkResolutionWithSecurityScope
												 relativeToURL:documentURL
										   bookmarkDataIsStale:&bookmarkIsStale
														 error:&bookmarkResolvingError];

				if (bookmarkResolvingError) {
					DEBUGLOG(@"FileIOLogDomain", AlwaysLogLevel, @"Error resolving security scoped bookmark: %@", bookmarkResolvingError);
				}

				if (url) {
					[bookmarkURLs addObject:url];

					if (bookmarkIsStale) {
						DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Bookmark was stale for URL: %@", url);
					}
				}
			}
		}
	}
	return bookmarkURLs;
}


- (BOOL)writeSecurityScopedBookmarks:(NSArray *)bookmarkURLs toURL:(NSURL *)anURL attachedToDocument:(NSDocument *)document error:(NSError **)outError {
	if (outError) {
		*outError = nil;
	}

	BOOL result = YES;

	NSURL *documentURL = document.fileURL;

	if (!anURL) {
		anURL = documentURL;
	}

	if (bookmarkURLs.count > 0) {
		NSMutableArray *bookmarks = [NSMutableArray array];
		for (NSURL *bookmarkURL in bookmarkURLs) {
			NSError *bookmarkGenerationError = nil;
			NSData *persistentBookmarkData = [bookmarkURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
												   includingResourceValuesForKeys:@[NSURLLocalizedNameKey]
																	relativeToURL:documentURL
																			error:&bookmarkGenerationError];

			if (persistentBookmarkData) {
				[bookmarks addObject:persistentBookmarkData];
			} else {
				if (bookmarkGenerationError) {
					DEBUGLOG(@"FileIOLogDomain", AlwaysLogLevel, @"Error generating security scoped bookmark: %@", bookmarkGenerationError);
				}
			}
		}

		if (result) {
			NSError *bookmarkSerialisationError = nil;
			NSData *bookmarksData = [NSPropertyListSerialization dataWithPropertyList:bookmarks format:NSPropertyListBinaryFormat_v1_0 options:0 error:&bookmarkSerialisationError];

			if (bookmarksData) {
				[UKXattrMetadataStore setData:bookmarksData
									   forKey:SEEScopedBookmarksKey
									   atPath:[anURL path]
								 traverseLink:YES];
			} else {
				if (outError) {
					*outError = bookmarkSerialisationError;
					result = NO;
				}
			}
		}
	} else {
		[UKXattrMetadataStore removeDataForKey:SEEScopedBookmarksKey
										atPath:[anURL path]
								  traverseLink:YES];
	}
	
	return result;
}



- (void)readBookmarksFromUserDefaults {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSArray *readBookmarks = [userDefaults objectForKey:SEEScopedBookmarksKey];
	NSMutableArray *bookmarkURLs = [NSMutableArray array];

	for (NSData *bookmarkData in readBookmarks) {
		NSError *bookmarkResolvingError = nil;
		BOOL bookmarkIsStale = NO;

		NSURL *url = [NSURL URLByResolvingBookmarkData:bookmarkData
											   options:NSURLBookmarkResolutionWithSecurityScope
										 relativeToURL:nil
								   bookmarkDataIsStale:&bookmarkIsStale
												 error:&bookmarkResolvingError];

		if (bookmarkResolvingError) {
			DEBUGLOG(@"FileIOLogDomain", AlwaysLogLevel, @"Error resolving security scoped bookmark: %@", bookmarkResolvingError);
		}

		if (url) {
			[bookmarkURLs addObject:url];

			if (bookmarkIsStale) {
				DEBUGLOG(@"FileIOLogDomain", SimpleLogLevel, @"Bookmark was stale for URL: %@", url);
			}
		}
	}
	self.bookmarkURLs = bookmarkURLs;
}


- (void)writeBookmarksToUserDefaults {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSArray *bookmarkURLs = self.bookmarkURLs.copy;

	if (bookmarkURLs.count > 0) {
		NSMutableArray *bookmarks = [NSMutableArray array];
		for (NSURL *bookmarkURL in bookmarkURLs) {
			NSError *bookmarkGenerationError = nil;
			NSData *persistentBookmarkData = [bookmarkURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
												   includingResourceValuesForKeys:@[NSURLLocalizedNameKey]
																	relativeToURL:nil
																			error:&bookmarkGenerationError];

			if (persistentBookmarkData) {
				[bookmarks addObject:persistentBookmarkData];
			} else {
				if (bookmarkGenerationError) {
					DEBUGLOG(@"FileIOLogDomain", AlwaysLogLevel, @"Error generating security scoped bookmark: %@", bookmarkGenerationError);
				}
			}
		}
		[userDefaults setObject:bookmarks forKey:SEEScopedBookmarksKey];
	} else {
		[userDefaults removeObjectForKey:SEEScopedBookmarksKey];
	}

}


- (BOOL)startAccessingURL:(NSURL *)aURL {
	BOOL result = NO;
	if (aURL.isFileURL) {
		NSURL *parentURL = [self.lookupDict objectForKey:aURL];
		if (! parentURL) {
			parentURL = [NSURL nearestParentDirectoryOfURL:aURL inList:self.bookmarkURLs];
		}

		if (parentURL) {
			result = [parentURL startAccessingSecurityScopedResource];
		}

		if (result) {
			[self.accessingURLs addObject:aURL];
			[self.lookupDict setObject:parentURL forKey:aURL];

		} else {
			if ([aURL checkResourceIsReachableAndReturnError:nil]) {
				NSError *error = nil;
				NSData *data = [NSData dataWithContentsOfURL:aURL options:NSDataReadingMappedAlways error:&error];

				if (data) {
					// file is readable in this session via a different opening mechanism
					// the next time is is used after app relaunch the user might get asked for permission
					result = YES;

				} else {
					// the file is not readable and we assume that it is because of permissions,
					// so we ask the user to allow us to use the file
					NSOpenPanel *openPanel = [NSOpenPanel openPanel];
					openPanel.canChooseDirectories = YES;
					openPanel.canChooseFiles = YES;
					openPanel.directoryURL = aURL;
					// TODO: localize and write proper text
					openPanel.prompt = @"Allow";
					openPanel.title = @"Allow resource access";

					NSInteger openPanelResult = [openPanel runModal];
					if (openPanelResult == NSFileHandlingPanelOKButton) {
						NSURL *choosenURL = openPanel.URL;

						// creating the security scoped bookmark url so that accessing works <3
						NSData *bookmarkData = [choosenURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
						NSURL *bookmarkURL = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:nil error:nil];

						result = [bookmarkURL startAccessingSecurityScopedResource];

						// checking if the selected url helps with opening permissions of our file
						data = [NSData dataWithContentsOfURL:aURL options:NSDataReadingMappedAlways error:&error];
						if (!data) {
							[bookmarkURL stopAccessingSecurityScopedResource];
							result = NO;

						} else {
							[self.accessingURLs addObject:aURL];
							[self.lookupDict setObject:bookmarkURL forKey:aURL];
							[self.bookmarkURLs addObject:bookmarkURL];

							[self writeBookmarksToUserDefaults];
						}
					}
				}
			}
		}
	}
	return result;
}

- (void)stopAccessingURL:(NSURL *)aURL {
	if (aURL) {
		NSUInteger foundIndex = [self.accessingURLs indexOfObject:aURL];
		if (foundIndex != NSNotFound) {
			NSURL *accessedBookmarkURL = [self.lookupDict objectForKey:aURL];
			NSAssert(accessedBookmarkURL != nil, @"There should aways be an URL in the lookup table");
			[accessedBookmarkURL stopAccessingSecurityScopedResource];
			[self.accessingURLs removeObjectAtIndex:foundIndex];
		}
	}
}

@end
