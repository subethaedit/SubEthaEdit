//
//  SEEFolderDocument.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 06/11/13.
//  Copyright (c) 2013 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SEEFolderDocument : NSDocument

@property (nonatomic, readwrite, strong) NSURL *representedFolderURL;
@property (nonatomic, readwrite, strong) NSArray *folderItems;

@end
