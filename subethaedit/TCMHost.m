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
- (void)setName:(NSString *)name;

@end

#pragma mark -

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
        
        [self setName:name];
        CFHostClientContext context = {0, self, NULL, NULL, NULL};
        CFHostSetClient(I_host, myCallback, &context);
        CFHostScheduleWithRunLoop(I_host, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        
        I_addresses = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    [I_name release];
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

- (void)setName:(NSString *)name
{
    [I_name autorelease];
    I_name = [name copy];
}

- (NSString *)name
{
    return I_name;
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
    id delegate = [self delegate];
    
    if (error && error->error != 0) {
        NSLog(@"error");
        if ([delegate respondsToSelector:@selector(host:didNotResolve:)]) {
            NSString *domain = @"TCMHost";
            if (error->domain == kCFStreamErrorDomainNetDB) 
                domain = @"NetDBDomain";
            else if (error->domain == kCFStreamErrorDomainSystemConfiguration)
                domain = @"SystemConfigurationDomain";
            [delegate host:self didNotResolve:[NSError errorWithDomain:domain code:error->error userInfo:nil]];
        }
    } else if (typeInfo == kCFHostAddresses) {
        Boolean hasBeenResolved;
        CFArrayRef addressArray = CFHostGetAddressing(host, &hasBeenResolved);
        NSLog(@"hasBeenResolved: %@", (hasBeenResolved ? @"YES" : @"NO"));
        NSEnumerator *addresses = [(NSArray *)addressArray objectEnumerator];
        NSData *address;
        while ((address = [addresses nextObject])) {
            NSLog(@"resolved address: %@", [NSString stringWithAddressData:address]);
            [I_addresses addObject:address];
        }
        if ([delegate respondsToSelector:@selector(hostDidResolveAddress:)]) {
            [delegate hostDidResolveAddress:self];
        }
    } else if (typeInfo == kCFHostReachability) {
        
    }
}

@end

#pragma mark -

void myCallback(CFHostRef myHost, CFHostInfoType typeInfo, const CFStreamError *error, void *myInfoPointer)
{
    TCMHost *host = (TCMHost *)myInfoPointer;
    [host TCM_handleHostCallback:myHost typeInfo:typeInfo error:error];
}