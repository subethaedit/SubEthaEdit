//  TCMMMUserSEEAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.

#import <AppKit/AppKit.h>
#import "TCMMillionMonkeys/TCMMMUser.h"


@interface TCMMMUser (TCMMMUserSEEAdditions) 

- (NSColor *)changeColor;
- (NSColor *)changeHighlightColorWithWhiteBackground;
- (NSColor *)changeHighlightColorForBackgroundColor:(NSColor *)backgroundColor;

- (NSString *)vcfRepresentation;

- (NSString *)initials;

- (NSColor *)color;

#pragma mark - User Image
- (NSImage *)image;
- (NSData *)imageData;
- (void)setImage:(NSImage *)aImage;

- (void)setDefaultImage;
- (BOOL)hasDefaultImage;
- (NSImage *)defaultImage;

- (BOOL)writeImageToUrl:(NSURL *)aURL; // add <file name>.png
- (BOOL)readImageFromUrl:(NSURL *)aURL;

- (BOOL)removePersistedUserImage;
+ (NSURL *)applicationSupportURLForUserImage;

@end
