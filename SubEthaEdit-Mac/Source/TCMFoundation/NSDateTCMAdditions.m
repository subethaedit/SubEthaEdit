//  NSDateTCMAdditions.m
//  TCMFoundation
//
//  Created by Michael Ehrmann on 10.10.13.

#import "NSDateTCMAdditions.h"


@implementation NSDate (NSDateTCMAdditions)

- (NSString *)rfc1123DateTimeString
{
    static NSDateFormatter *sRFC1123DateFormatter = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

        sRFC1123DateFormatter = [[NSDateFormatter alloc] init];
        [sRFC1123DateFormatter setLocale:enUSPOSIXLocale];
        [sRFC1123DateFormatter setDateFormat:@"ccc, dd MMM yyyy HH:mm:ss zzz"];
        [sRFC1123DateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];

		[enUSPOSIXLocale release];
	});

	NSString *result = [sRFC1123DateFormatter stringFromDate:self];
    return result;
}


- (NSString *)W3CDTFLongDateTimeString
{
    static NSDateFormatter *sW3CDTFLongDateTimeFormatter = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

        sW3CDTFLongDateTimeFormatter = [[NSDateFormatter alloc] init];
        [sW3CDTFLongDateTimeFormatter setLocale:enUSPOSIXLocale];
        [sW3CDTFLongDateTimeFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [sW3CDTFLongDateTimeFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];

		[enUSPOSIXLocale release];
	});

	NSString *result = [sW3CDTFLongDateTimeFormatter stringFromDate:self];
    return result;
}


- (NSString *)W3CDTFLongDateString
{
    static NSDateFormatter *sW3CDTFLongDateFormatter = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

        sW3CDTFLongDateFormatter = [[NSDateFormatter alloc] init];
        [sW3CDTFLongDateFormatter setLocale:enUSPOSIXLocale];
        [sW3CDTFLongDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'"];
        [sW3CDTFLongDateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];

		[enUSPOSIXLocale release];
	});

	NSString *result = [sW3CDTFLongDateFormatter stringFromDate:self];
    return result;
}


@end
