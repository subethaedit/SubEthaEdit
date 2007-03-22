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
- (NSString *)vcfRepresentation;

#pragma mark -

- (NSImage *)colorImage;
- (NSImage *)image;
- (NSImage *)image48;
- (NSImage *)image32;
- (NSImage *)image16;
- (NSImage *)image32Dimmed;

@end
