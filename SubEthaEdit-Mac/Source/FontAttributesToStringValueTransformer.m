//  FontDescriptorToStringValueTransformer.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 02 2004.

#import "FontAttributesToStringValueTransformer.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation FontAttributesToStringValueTransformer
+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;   
}

- (id)transformedValue:(id)aValue {
    if (![aValue isKindOfClass:[NSDictionary class]]) return nil;
    NSDictionary *attributes=(NSDictionary  *)aValue;
    NSFont *font=[NSFont fontWithName:[attributes objectForKey:NSFontNameAttribute] size:[[attributes objectForKey:NSFontSizeAttribute] floatValue]];
    return [NSString stringWithFormat:@"%@, %.1f",[font displayName],[font pointSize]];
}

@end
