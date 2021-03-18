//  FontDescriptorToStringValueTransformer.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Fri Apr 02 2004.

#import "FontAttributesToStringValueTransformer.h"
#import "DocumentMode.h"

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
    NSFont *font=[DocumentMode fontForAttributeDict:attributes];
    return [NSString stringWithFormat:@"%@, %.1f",[font displayName],[font pointSize]];
}

@end
