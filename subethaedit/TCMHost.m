//
//  TCMHost.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 03 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMHost.h"
#import <CoreFoundation/CoreFoundation.h>


void myCallback(CFHostRef myHost, CFHostInfoType typeInfo, const CFStreamError *error, void *myInfoPointer);


@interface TCMHost (TCMHostPrivateAdditions)

- (void)TCM_handleHostCallback:(CFHostRef)host typeInfo:(CFHostInfoType)typeInfo error:(const CFStreamError *)error;

@end


@implementation TCMHost

+ (TCMHost *)hostWithName:(NSString *)name
{
    return [[[TCMHost alloc] initWithName:name] autorelease];
}

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
    
        I_host = CFHostCreateWithName(NULL, (CFStringRef)name);
        if (I_host == nil) {
            return nil;
        }
        
        CFHostClientContext context = {0, self, NULL, NULL, NULL};
        CFHostSetClient(I_host, myCallback, &context);
        CFHostScheduleWithRunLoop(I_host, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        
        I_addresses = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    [I_addresses release];
    [super dealloc];
}

- (void)setDelegate:(id)delegate
{
    I_delegate = delegate;
}

- (id)delegate
{
    return I_delegate;
}

- (NSArray *)addresses
{
    return I_addresses;
}

- (void)checkReachability
{
    CFHostStartInfoResolution(I_host, kCFHostReachability, NULL);
}

- (void)resolve
{
    CFHostStartInfoResolution(I_host, kCFHostAddresses, NULL);
}

- (void)TCM_handleHostCallback:(CFHostRef)host typeInfo:(CFHostInfoType)typeInfo error:(const CFStreamError *)error
{
    NSLog(@"handleHostCallback");
    
    if (error && error->error != 0) {
        NSLog(@"error");
    } else if (typeInfo == kCFHostAddresses) {
        Boolean hasBeenResolved;
        CFArrayRef addressArray = CFHostGetAddressing(host, &hasBeenResolved);
        NSLog(@"hasBeenResolved: %@", (hasBeenResolved ? @"YES" : @"NO"));
        NSLog(@"addresses: %@", [(NSArray *)addressArray description]);
    } else if (typeInfo == kCFHostReachability) {
        
    }
}

@end


void myCallback(CFHostRef myHost, CFHostInfoType typeInfo, const CFStreamError *error, void *myInfoPointer)
{
    TCMHost *host = (TCMHost *)myInfoPointer;
    [host TCM_handleHostCallback:myHost typeInfo:typeInfo error:error];
}