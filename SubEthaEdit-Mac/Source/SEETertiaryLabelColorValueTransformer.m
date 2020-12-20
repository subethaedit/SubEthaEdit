//  SEETertiaryLabelColorValueTransformer.m
//  SubEthaEdit
//
//  Created by Jan Cornelissen on 06/12/2020.

#import "SEETertiaryLabelColorValueTransformer.h"

@implementation SEETertiaryLabelColorValueTransformer

+ (Class)transformedValueClass {
    return [NSColor class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    NSNumber *val = value;
    NSColor *newColor = [val boolValue] ? [NSColor tertiaryLabelColor] : [NSColor labelColor];
    return newColor;
}

@end
