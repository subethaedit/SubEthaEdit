
#import "TCMPortStringFromPublicPortValueTransformer.h"
#import <TCMPortMapper/TCMPortMapper.h>

@implementation TCMPortStringFromPublicPortValueTransformer
+ (Class)transformedValueClass {
    return [NSString class];
}

- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        switch([value intValue]) {
            case 0: return NSLocalizedString(@"unmapped",@"");
            default: return [NSString stringWithFormat:@"%d",[value intValue]];
        }
    } else {
        return @"NaN";
    }
}

@end

@implementation TCMReplacedStringFromPortMappingReferenceStringValueTransformer
+ (Class)transformedValueClass {
    return [NSString class];
}

- (id)transformedValue:(id)value {
//    NSLog(@"%s %@",__FUNCTION__,value);
    if ([value respondsToSelector:@selector(lastObject)]) value = [value lastObject];
    if ([value respondsToSelector:@selector(mappingStatus)] &&
        [value mappingStatus]==TCMPortMappingStatusMapped &&
        [[TCMPortMapper sharedInstance] externalIPAddress]) {
        NSMutableString *string = [[[[value userInfo] objectForKey:@"referenceString"] mutableCopy] autorelease];
//        NSLog(@"%s %@",__FUNCTION__,string);
        if (string) {
            if ([string rangeOfString:@"[IP]"].location!=NSNotFound)
                [string replaceCharactersInRange:[string rangeOfString:@"[IP]"] withString:[[TCMPortMapper sharedInstance] externalIPAddress]];
            if ([string rangeOfString:@"[PORT]"].location!=NSNotFound)
                [string replaceCharactersInRange:[string rangeOfString:@"[PORT]"] withString:[NSString stringWithFormat:@"%d",[value externalPort]]];
        }
        return string;
    } else {
        return @"";
    }
}

@end

