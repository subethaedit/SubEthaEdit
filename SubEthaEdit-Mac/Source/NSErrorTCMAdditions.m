//  NSErrorTCMAdditions.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 02.09.09.

#import "NSErrorTCMAdditions.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation NSError (NSErrorTCMAdditions)

-(BOOL)TCM_matchesCode:(int)aCode inDomain:(NSString*)aDomain {
    if ([self code]==aCode) {
        if (aDomain)
        {
            if ([[self domain] isEqualToString:aDomain]) return YES;
        } else return YES;
    }
    return NO;
}

-(BOOL)TCM_relatesToErrorCode:(int)aCode inDomain:(NSString*)aDomain {
    if ([self TCM_matchesCode:aCode inDomain:aDomain]) return YES;
    NSError *underlyingError = [[self userInfo] objectForKey:NSUnderlyingErrorKey];
    if (underlyingError) return [underlyingError TCM_relatesToErrorCode:aCode inDomain:aDomain];
    return NO;
}


@end
