//
//  SEEFolderDocument.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 06/11/13.
//  Copyright (c) 2013 TheCodingMonkeys. All rights reserved.
//

#import "SEEFolderDocument.h"

@implementation SEEFolderDocument

- (id)init
{
    self = [super init];
    return self;
}

- (NSString *)windowNibName
{
    return @"SEEFolderDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
	NSFileManager *fileManager = [NSFileManager defaultManager];

    self.representedFolderURL = url;
	self.folderItems = [fileManager contentsOfDirectoryAtURL:url includingPropertiesForKeys:[NSArray array] options:0 error:nil];
    return YES;
}

- (BOOL)isEntireFileLoaded
{
    return NO;
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

@end
