//
//  SEEUserColorsPreviewView.h
//  SubEthaEdit
//
//  Created by Lisa Brodner on 16/04/14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SEEUserColorsPreviewView : NSView

@property (nonatomic, strong) NSNumber *userColorHue;
@property (nonatomic, strong) NSNumber *changesSaturation;
@property (nonatomic, strong) NSNumber *selectionSaturation;

- (void)updateWithUserDefaultsValues;

@end
