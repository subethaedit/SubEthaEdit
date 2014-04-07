//
//  NSDateTCMAdditions.h
//  TCMFoundation
//
//  Created by Michael Ehrmann on 10.10.13.
//  Copyright 2013 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDate (NSDateTCMAdditions) 

- (NSString *)rfc1123DateTimeString;
- (NSString *)W3CDTFLongDateTimeString;
- (NSString *)W3CDTFLongDateString;

@end
