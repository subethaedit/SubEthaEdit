//  TCMHost.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Mar 03 2004.

#import "TCMHost.h"

#import <CoreFoundation/CoreFoundation.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <sys/socket.h>

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

void myCallback(CFHostRef myHost, CFHostInfoType typeInfo, const CFStreamError *error, void *myInfoPointer);


@interface TCMHost ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDictionary *userInfo;
@property (nonatomic, strong) NSData *address;

- (void)TCM_handleHostCallback:(CFHostRef)host typeInfo:(CFHostInfoType)typeInfo error:(const CFStreamError *)error;

@end

#pragma mark -

@implementation TCMHost

+ (TCMHost *)hostWithName:(NSString *)name port:(unsigned short)port userInfo:(NSDictionary *)userInfo {
    return [[TCMHost alloc] initWithName:name port:port userInfo:userInfo];
}

+ (TCMHost *)hostWithAddressData:(NSData *)addr port:(unsigned short)port userInfo:(NSDictionary *)userInfo {
    return [[TCMHost alloc] initWithAddressData:addr port:port userInfo:userInfo];
}

- (instancetype)initWithName:(NSString *)name port:(unsigned short)port userInfo:(NSDictionary *)userInfo {
    self = [super init];
    if (self) {
    
        I_host = CFHostCreateWithName(NULL, (__bridge CFStringRef)name);
        if (I_host == nil) {
			self = nil;
            return nil;
        }
        
        [self setName:name];
        [self setUserInfo:userInfo];
        I_port = port;
        CFHostClientContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
        CFHostSetClient(I_host, myCallback, &context);
        CFHostScheduleWithRunLoop(I_host, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        
        I_addresses = [NSMutableArray new];
        I_names = [NSMutableArray new];
    }
    return self;
}

- (instancetype)initWithAddressData:(NSData *)addr port:(unsigned short)port userInfo:(NSDictionary *)userInfo {
    self = [super init];
    if (self) {
    
        I_host = CFHostCreateWithAddress(NULL, (__bridge CFDataRef)addr);
        if (I_host == nil) {
			self = nil;
			return nil;
        }
        
        [self setAddress:addr];
        [self setUserInfo:userInfo];
        I_port = port;
        CFHostClientContext context = {0, (__bridge void * _Nullable)(self), NULL, NULL, NULL};
        CFHostSetClient(I_host, myCallback, &context);
        CFHostScheduleWithRunLoop(I_host, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        
        I_addresses = [NSMutableArray new];
        [I_addresses addObject:addr];
        I_names = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    CFHostUnscheduleFromRunLoop(I_host, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    CFHostSetClient(I_host, NULL, NULL);
    CFRelease(I_host);
}

- (NSArray *)addresses {
    return I_addresses;
}

- (NSArray *)names {
    return I_names;
}

- (void)checkReachability {
    CFHostStartInfoResolution(I_host, kCFHostReachability, NULL);
}

- (void)resolve {
    CFHostStartInfoResolution(I_host, kCFHostAddresses, NULL);
}

- (void)reverseLookup {
    CFHostStartInfoResolution(I_host, kCFHostNames, NULL);
}

- (void)cancel {
    CFHostCancelInfoResolution(I_host, kCFHostAddresses);
}

- (void)TCM_handleHostCallback:(CFHostRef)host typeInfo:(CFHostInfoType)typeInfo error:(const CFStreamError *)error {
    //NSLog(@"handleHostCallback");
    id delegate = [self delegate];
    
    if (error && error->error != 0) {
        //NSLog(@"error");
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
        //NSLog(@"hasBeenResolved: %@", (hasBeenResolved ? @"YES" : @"NO"));
        NSEnumerator *addresses = [(NSArray *)CFBridgingRelease(addressArray) objectEnumerator];
        NSData *address;
        while ((address = [addresses nextObject])) {            
            NSMutableData *mutableAddressData = [address mutableCopy];
            struct sockaddr *address = (struct sockaddr *)[mutableAddressData mutableBytes];
            if (address->sa_family == AF_INET) {
                ((struct sockaddr_in *)address)->sin_port = htons(I_port);
            } else if (address->sa_family == AF_INET6) {
                ((struct sockaddr_in6 *)address)->sin6_port = htons(I_port);
            }
            //NSLog(@"resolved address: %@", [NSString stringWithAddressData:mutableAddressData]);
            [I_addresses addObject:mutableAddressData];
        }
        if ([delegate respondsToSelector:@selector(hostDidResolveAddress:)]) {
            [delegate hostDidResolveAddress:self];
        }
    } else if (typeInfo == kCFHostNames) {
        Boolean hasBeenResolved;
        NSArray *names = (NSArray *)CFBridgingRelease(CFHostGetNames(host, &hasBeenResolved));
        //NSLog(@"finished reverse lookup: %@", names);
        [I_names removeAllObjects];
        [I_names addObjectsFromArray:names];
        if ([delegate respondsToSelector:@selector(hostDidResolveName:)]) {
            [delegate hostDidResolveName:self];
        }
    } else if (typeInfo == kCFHostReachability) {
        
    }
}

@end

#pragma mark -

void myCallback(CFHostRef myHost, CFHostInfoType typeInfo, const CFStreamError *error, void *myInfoPointer) {
    TCMHost *host = (__bridge TCMHost *)myInfoPointer;
    [host TCM_handleHostCallback:myHost typeInfo:typeInfo error:error];
}
