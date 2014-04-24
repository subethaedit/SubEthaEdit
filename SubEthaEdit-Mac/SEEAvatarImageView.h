//
//  SEEAvatarImageView.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 10.04.14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SEEAvatarImageView : NSView
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, strong) NSColor *borderColor;
@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, copy) NSString *initials;

@property (nonatomic, copy) NSString *hoverString;
- (void)enableHoverImage;
- (void)disableHoverImage;
@end
