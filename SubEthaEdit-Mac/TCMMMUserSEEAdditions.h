//
//  TCMMMUserSEEAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "TCMMillionMonkeys/TCMMMUser.h"


@interface TCMMMUser (TCMMMUserSEEAdditions) 

- (NSColor *)changeColor;
- (NSColor *)changeColorDesaturated;
- (NSColor *)changeHighlightColorWithWhiteBackground;
- (NSColor *)changeHighlightColorForBackgroundColor:(NSColor *)backgroundColor;

- (NSString *)vcfRepresentation;

- (NSString *)initials;

#pragma mark -
- (NSColor *)color;

- (void)recacheImages;

- (NSImage *)image;
- (NSData *)imageData;
- (void)setImage:(NSImage *)aImage;
- (void)setDefaultImage;
- (BOOL)hasDefaultImage;

- (BOOL)writeImageToUrl:(NSURL *)aURL; // add <file name>.png

@end
