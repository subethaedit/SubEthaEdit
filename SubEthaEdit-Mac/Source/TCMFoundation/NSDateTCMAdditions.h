//  NSDateTCMAdditions.h
//  TCMFoundation
//
//  Created by Michael Ehrmann on 10.10.13.

#import <Foundation/Foundation.h>

@interface NSDate (NSDateTCMAdditions)
@property (nonatomic, readonly) NSString *rfc1123DateTimeString;
@property (nonatomic, readonly) NSString *W3CDTFLongDateTimeString;
@property (nonatomic, readonly) NSString *W3CDTFLongDateString;
@end
