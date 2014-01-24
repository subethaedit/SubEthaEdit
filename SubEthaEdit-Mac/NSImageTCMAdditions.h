//
//  NSImageTCMAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (NSImageTCMAdditions) 

/** 
	@return an resolution independent image based on the pdf, filled with either the fillColor or the selectionColor (implicidly the menu selection color currently) depending on the name. The name has to be <pdf-filename-without-extension>_<Normal[Disabled]|Selected[Disabled]>
	@param scaleFactor the image will be the size of the bounding box of the PDF in points times the scale factor. Note: you can't have images with different scale factors but the same pdf name currently (as this would return the wrong image named for the second caller)
 
 */

+ (NSImage *)pdfBasedImageNamed:(NSString *)aName fillColor:(NSColor *)aFillColor scaleFactor:(CGFloat)aScaleFactor;
+ (NSImage *)clearedImageWithSize:(NSSize)aSize;
- (NSImage *)resizedImageWithSize:(NSSize)aSize;
- (NSImage *)dimmedImage;

@end
