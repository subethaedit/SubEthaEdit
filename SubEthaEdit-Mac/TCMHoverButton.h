//
//  TCMHoverButton.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.05.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TCMHoverButton : NSButton

@property (nonatomic, strong) NSImage *hoverImage;
@property (nonatomic, strong) NSImage *normalImage;
@property (nonatomic, strong) NSImage *pressedImage;


/*! @param aPrefix the prefix of the images. the internal images will be set using imageNamed: with the suffixes @"Normal", @"Hover" and @"Pressed" */
- (void)setImagesByPrefix:(NSString *)aPrefix;

@end
