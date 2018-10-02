//  NSAppleScriptAdditions.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 27.03.06.

#import <Cocoa/Cocoa.h>


@interface NSAppleEventDescriptor (NSAppleEventDescriptorTCMAdditions)
+ (NSAppleEventDescriptor *)appleEventToCallSubroutine:(NSString *)aSubroutineName;
- (NSDictionary *)dictionaryValue;
@end
