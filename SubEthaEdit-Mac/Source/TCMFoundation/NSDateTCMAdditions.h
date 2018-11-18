//  NSDateTCMAdditions.h
//  TCMFoundation
//
//  Created by Michael Ehrmann on 10.10.13.

#import <Foundation/Foundation.h>


@interface NSDate (NSDateTCMAdditions) 

- (NSString *)rfc1123DateTimeString;
- (NSString *)W3CDTFLongDateTimeString;
- (NSString *)W3CDTFLongDateString;

@end
