
#import "TCMStatusImageFromMappingStatusValueTransformer.h"


@implementation TCMStatusImageFromMappingStatusValueTransformer
+ (Class)transformedValueClass {
    return [NSImage class];
}

- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        switch([value intValue]) {
            case 2: return [NSImage imageNamed:@"DotGreen"];
            case 1: return [NSImage imageNamed:@"DotYellow"];
            default: return [NSImage imageNamed:@"DotRed"];
        }
    } else {
        return [NSImage imageNamed:@"GenericQuestionMarkIcon.icns"];
    }
}
@end
