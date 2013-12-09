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

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError **)outError
{
    self.fileWrapper = fileWrapper;
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
