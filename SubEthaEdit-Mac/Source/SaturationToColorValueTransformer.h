//  SaturationColorValueTransformer.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Mar 29 2004.

#import <Foundation/Foundation.h>


@interface SaturationToColorValueTransformer : NSValueTransformer {
    NSColor *I_backgroundColor;
}

- (instancetype)initWithColor:(NSColor *)aColor;

@end
