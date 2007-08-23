//
//  NSImageTCMAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (NSImageTCMAdditions) 

+ (NSImage *)clearedImageWithSize:(NSSize)aSize;
- (NSImage *)resizedImageWithSize:(NSSize)aSize;
- (NSImage *)dimmedImage;

@end
