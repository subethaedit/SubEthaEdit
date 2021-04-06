//
//  SEPLogger.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 09.04.09.
//  Copyright 2009 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SEPLogger : NSObject {
}
+ (void)logWithFormat:(NSString *)format,...;
+ (void)registerLogger:(id)aLogger;

@end

@interface NSObject (SEPLoggerClientAdditions)
- (void)logString:(NSString *)aString;
@end


@interface NSString (SEPLoggerStringAdditions)
- (NSString *)stringByLeftPaddingUpToLength:(int)aLength;
@end
