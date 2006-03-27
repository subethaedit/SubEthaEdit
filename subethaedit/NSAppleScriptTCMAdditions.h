//
//  NSAppleScriptAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 27.03.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSAppleEventDescriptor (NSAppleEventDescriptorTCMAdditions)
+ (NSAppleEventDescriptor *)appleEventToCallSubroutine:(NSString *)aSubroutineName;
- (NSDictionary *)dictionaryValue;
@end
