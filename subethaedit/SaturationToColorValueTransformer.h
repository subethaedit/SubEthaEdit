//
//  SaturationColorValueTransformer.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 29 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SaturationToColorValueTransformer : NSValueTransformer {
    NSColor *I_backgroundColor;
}

- (id)initWithColor:(NSColor *)aColor;

@end
