//  SEEScopedBookmarkManager.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 19.03.14.

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEEScopedBookmarkManager.h"
#import "SEEScopedBookmarkAccessoryViewController.h"
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


@implementation NSString ( TCMNSStringPathAddition )

/**
 @param aPaths must be absolute paths.
 @return the longest common sub path of self with inPath.
 */

- (NSString *)TCM_commonSubPathWithPath:(NSString *)aPath
{
    if (!aPath || self.length == 0 || aPath.length == 0) return nil;

    NSArray *pathComponents1 = [self pathComponents];
    NSArray *pathComponents2 = [aPath pathComponents];

    __block NSInteger lastIdenticalComponentNumber = -1;

    // Determine last identical component
    [pathComponents1 enumerateObjectsUsingBlock:^(id pathComponent1, NSUInteger index, BOOL *stop) {
        if ([pathComponents2 count] > index) {
            NSString *pathComponent2 = (NSString *)[pathComponents2 objectAtIndex:index];

            if ([pathComponent1 isEqualToString:pathComponent2]) {
                lastIdenticalComponentNumber = index;
            } else {
                *stop = YES;
            }
        } else {
            *stop = YES;
        }
    }];

    // Create sub path
    if (lastIdenticalComponentNumber >= 0) {
        NSRange subRange = NSMakeRange(0, lastIdenticalComponentNumber + 1);
        NSArray *subPathComponents = [pathComponents1 subarrayWithRange:subRange];
        return [NSString pathWithComponents:subPathComponents];
    }

    return @"/";
}


/**
 Whether aPath is a path prefix of self. Both strings must be absolute paths.
 @param aPath must be an absolute path and should be standartised
 @return Whether aPath is a path prefix of self. Both strings must be absolute paths.
 */

- (BOOL)hasPathPrefix:(NSString *)aPath {
    return [[aPath TCM_commonSubPathWithPath:self] isEqualToString:aPath];
}

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


// to use this 2 methods include com.apple.security.files.bookmarks.document-scope YES in the entitlements. This is disabled for now, because methods are not used
/*
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
			NSNumber *isBookmarkFileWritable = nil;
			NSURLBookmarkCreationOptions fileBookmarkOptions = NSURLBookmarkCreationWithSecurityScope;
			[bookmarkURL getResourceValue:&isBookmarkFileWritable forKey:NSURLIsWritableKey error:nil];
			if (! isBookmarkFileWritable.boolValue) {
				fileBookmarkOptions = NSURLBookmarkCreationWithSecurityScope | NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess;
			}

			NSError *bookmarkGenerationError = nil;
			NSData *persistentBookmarkData = [bookmarkURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
												   includingResourceValuesForKeys:nil
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
*/


- (void)resetBookmarksInUserDefaults {
	for (NSURL *accessingURL in self.accessingURLs) {
		NSURL *accessedBookmarkURL = self.lookupDict[accessingURL];
		[accessedBookmarkURL stopAccessingSecurityScopedResource];
	}
	[self.lookupDict removeAllObjects];
	[self.accessingURLs removeAllObjects];
	[self.bookmarkURLs removeAllObjects];

	[self writeBookmarksToUserDefaults];
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
				DEBUGLOG(@"FileIOLogDomain", AlwaysLogLevel, @"Bookmark was stale for URL: %@", url);
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

			NSData *persistentBookmarkData = nil;
			if ([bookmarkURL startAccessingSecurityScopedResource]) {

				NSNumber *isBookmarkFileWritable = nil;
				NSURLBookmarkCreationOptions fileBookmarkOptions = NSURLBookmarkCreationWithSecurityScope;
				[bookmarkURL getResourceValue:&isBookmarkFileWritable forKey:NSURLIsWritableKey error:nil];
				if (! isBookmarkFileWritable.boolValue) {
					fileBookmarkOptions = NSURLBookmarkCreationWithSecurityScope | NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess;
				}

				persistentBookmarkData = [bookmarkURL bookmarkDataWithOptions:fileBookmarkOptions
											   includingResourceValuesForKeys:nil
																relativeToURL:nil
																		error:&bookmarkGenerationError];
				[bookmarkURL stopAccessingSecurityScopedResource];
			}

			if (persistentBookmarkData) {
				[bookmarks addObject:persistentBookmarkData];
			} else {
				if (bookmarkGenerationError) {
					DEBUGLOG(@"FileIOLogDomain", AlwaysLogLevel, @"Error generating security scoped bookmark: %@", bookmarkGenerationError);
				}
			}
		}
		[userDefaults setObject:bookmarks forKey:SEEScopedBookmarksKey];
		[userDefaults synchronize];
	} else {
		[userDefaults removeObjectForKey:SEEScopedBookmarksKey];
		[userDefaults synchronize];
	}

}


- (BOOL)hasBookmarkForURL:(NSURL *)aURL {
	NSString* path = [aURL path];
	for (NSURL* bookmarkURL in self.bookmarkURLs) {
		if ([path hasPathPrefix:[bookmarkURL path]]) {
			return YES;
		}
	}
	return NO;
}


- (BOOL)canAccessURL:(NSURL *)aURL {
	BOOL result = [self startAccessingURL:aURL persist:NO creatable:NO bookmarkGenerationBlock:NULL];
	return result;
}


- (NSString *)previewAccessMessageString {
	NSString *localizedMessageFormat = NSLocalizedStringWithDefaultValue(@"ScopedBookmarkAllowFileMessageFormatString",
																		 nil,
																		 [NSBundle mainBundle],
																		 @"To preview your web content it is neccessary that you provide access to %@. Please choose a folder that includes all files used by your source file.",
																		 @"Message that gets displayed when SEE needs the user to grant access to an unopend file.");
	return localizedMessageFormat;
}


- (BOOL)startAccessingURL:(NSURL *)aURL {
	return [self startAccessingURL:aURL persist:YES creatable:NO bookmarkGenerationBlock:^NSURL *(NSURL *urlToBeAccessed) {
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = YES;
		openPanel.canChooseFiles = YES;
		openPanel.directoryURL = [urlToBeAccessed URLByDeletingLastPathComponent];

		openPanel.prompt = NSLocalizedStringWithDefaultValue(@"ScopedBookmarkAllowFilePrompt", nil, [NSBundle mainBundle], @"Allow", @"Default button title of the allow open panel");
		openPanel.title = NSLocalizedStringWithDefaultValue(@"ScopedBookmarkAllowFileTitle", nil, [NSBundle mainBundle], @"Allow File Access", @"Window title of the allow open panel");

		{
			SEEScopedBookmarkAccessoryViewController *viewController = [[SEEScopedBookmarkAccessoryViewController alloc] initWithNibName:@"SEEScopedBookmarkAccessoryViewController" bundle:nil];
			viewController.accessedFileName = [urlToBeAccessed lastPathComponent];
			viewController.message = self.previewAccessMessageString;
			NSView *view = viewController.view;
			view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
			openPanel.accessoryView = viewController.view;
			[openPanel TCM_setAssociatedValue:viewController forKey:@"accessoryViewController"];
		}

		NSModalResponse openPanelResult = [openPanel runModal];
		if (openPanelResult == NSModalResponseOK) {
			NSURL *choosenURL = openPanel.URL;
			// creating the security scoped bookmark url so that accessing works <3

			NSNumber *isBookmarkFileWritable = nil;
			NSURLBookmarkCreationOptions fileBookmarkOptions = NSURLBookmarkCreationWithSecurityScope;
			[choosenURL getResourceValue:&isBookmarkFileWritable forKey:NSURLIsWritableKey error:nil];
			if (! isBookmarkFileWritable.boolValue) {
				fileBookmarkOptions = NSURLBookmarkCreationWithSecurityScope | NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess;
			}

			NSData *bookmarkData = [choosenURL bookmarkDataWithOptions:fileBookmarkOptions includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
			NSURL *bookmarkURL = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:nil error:nil];
			return bookmarkURL;
		}
		return nil;
	}];
}


- (NSString *)scriptedFileAccessMessageString {
	NSString *localizedMessageFormat = NSLocalizedStringWithDefaultValue(@"ScopedBookmarkAllowScriptedFileMessageFormatString",
																		 nil,
																		 [NSBundle mainBundle],
																		 @"AppleScript wants to access %@. Click allow to continue the running script.",
																		 @"Message that gets displayed when SEE needs the user to grant access to an unopend file via applecript.");
	return localizedMessageFormat;
}


- (BOOL)startAccessingScriptedFileURL:(NSURL *)aURL {
	return [self startAccessingURL:aURL persist:NO creatable:YES bookmarkGenerationBlock:^NSURL *(NSURL *urlToBeAccessed) {
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		openPanel.canChooseDirectories = YES;
		openPanel.canChooseFiles = YES;
		openPanel.directoryURL = urlToBeAccessed;

		openPanel.prompt = NSLocalizedStringWithDefaultValue(@"ScopedBookmarkAllowFilePrompt", nil, [NSBundle mainBundle], @"Allow", @"Default button title of the allow open panel");
		openPanel.title = NSLocalizedStringWithDefaultValue(@"ScopedBookmarkAllowFileTitle", nil, [NSBundle mainBundle], @"Allow File Access", @"Window title of the allow open panel");

		{
			SEEScopedBookmarkAccessoryViewController *viewController = [[SEEScopedBookmarkAccessoryViewController alloc] initWithNibName:@"SEEScopedBookmarkAccessoryViewController" bundle:nil];
			viewController.accessedFileName = [urlToBeAccessed lastPathComponent];
			viewController.message = self.scriptedFileAccessMessageString;

			NSView *view = viewController.view;
			view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
			openPanel.accessoryView = viewController.view;
			[openPanel TCM_setAssociatedValue:viewController forKey:@"accessoryViewController"];
		}

		NSModalResponse openPanelResult = [openPanel runModal];
		if (openPanelResult == NSModalResponseOK) {
			NSURL *choosenURL = openPanel.URL;
			// creating the security scoped bookmark url so that accessing works <3
			NSNumber *isBookmarkFileWritable = nil;
			NSURLBookmarkCreationOptions fileBookmarkOptions = NSURLBookmarkCreationWithSecurityScope;
			[choosenURL getResourceValue:&isBookmarkFileWritable forKey:NSURLIsWritableKey error:nil];
			if (! isBookmarkFileWritable.boolValue) {
				fileBookmarkOptions = NSURLBookmarkCreationWithSecurityScope | NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess;
			}

			NSData *bookmarkData = [choosenURL bookmarkDataWithOptions:fileBookmarkOptions includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
			NSURL *bookmarkURL = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:nil error:nil];
			return bookmarkURL;
		}
		return nil;
	}];
}

- (BOOL)startAccessingURL:(NSURL *)aURL persist:(BOOL)persistFlag creatable:(BOOL)shouldCreatable bookmarkGenerationBlock:(BookmarkGenerationBlock)block {
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

			NSError *resourceAvailabilityError = nil;
			// errorcode 260 in NSCocaErrorDomain means "File not found"
			if ([aURL checkResourceIsReachableAndReturnError:&resourceAvailabilityError]) {
				NSError *error = nil;
				NSData *data = [NSData dataWithContentsOfURL:aURL options:NSDataReadingMappedAlways error:&error];

				if (data) {
					// file is readable in this session via a different opening mechanism
					// the next time is is used after app relaunch the user might get asked for permission
					result = YES;

				} else {
					if (block) {
                        result = NO;
                        
                        // breaking the call from webcore rendering in to webcore again
                        dispatch_async(dispatch_get_main_queue(), ^{

                            // the file is not readable and we assume that it is because of permissions,
                            // so we ask the user to allow us to use the file
                            NSURL *bookmarkURL = block(aURL);
                            if (bookmarkURL) {
                                BOOL success =
                                [bookmarkURL startAccessingSecurityScopedResource];
                                
                                NSError *error = nil;
                                // checking if the selected url helps with opening permissions of our file
                                NSData *data = [NSData dataWithContentsOfURL:aURL options:NSDataReadingMappedAlways error:&error];
                                if (!data) {
                                    [bookmarkURL stopAccessingSecurityScopedResource];
                                    success = NO;
                                } else {
                                    [self.accessingURLs addObject:aURL];
                                    [self.lookupDict setObject:bookmarkURL forKey:aURL];
                                    
                                    if (persistFlag) {
                                        [self.bookmarkURLs addObject:bookmarkURL];
                                        [self writeBookmarksToUserDefaults];
                                    }
                                    if (success) {
                                        // TODO: call back out and reload stuff - if success
                                    }
                                }
                            }

                        });
                        
					}
				}
			} else if (shouldCreatable && [resourceAvailabilityError.domain isEqualToString:NSCocoaErrorDomain] && resourceAvailabilityError.code == 260) {
				if (block) {
					// the file is not readable and we assume that it is because of permissions,
					// so we ask the user to allow us to use the file
					NSURL *bookmarkURL = block([aURL URLByDeletingLastPathComponent]);
					if (bookmarkURL) {
						result = [bookmarkURL startAccessingSecurityScopedResource];
						[self.accessingURLs addObject:aURL];
						[self.lookupDict setObject:bookmarkURL forKey:aURL];

						if (persistFlag) {
							[self.bookmarkURLs addObject:bookmarkURL];
							[self writeBookmarksToUserDefaults];
						}
					}
				}
			} else {
				if (! ([resourceAvailabilityError.domain isEqualToString:NSCocoaErrorDomain] && resourceAvailabilityError.code == 260)) {
					NSLog(@"%s - Error while accessing resource %@ : %@", __FUNCTION__, aURL, resourceAvailabilityError);
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


- (NSString *)description {
	return [NSString stringWithFormat:@"%@ - Available security scoped bookmarks:\n%@", [super description], self.bookmarkURLs];
}

@end
