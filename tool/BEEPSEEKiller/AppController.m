//
//  AppController.m
//  BEEPSEEKiller
//
//  Created by Dominik Wagner on 29.03.05.
//  Copyright (c) 2005 TheCodingMonkeys. All rights reserved.
//

#import "AppController.h"
#import "sys/socket.h"
#import "netinet/in.h"
#import "netinet6/in6.h"
#import "arpa/inet.h"

#import "dns_sd.h"
#import "nameser.h"

#pragma mark -
#pragma mark ### NSString Additions ###

@interface NSString (NSStringNetworkingAdditions)
+ (NSString *)stringWithAddressData:(NSData *)aAddressData;
@end

@implementation NSString (NSStringNetworkingAdditions) 

+ (NSString *)stringWithAddressData:(NSData *)aAddressData {
    struct sockaddr *socketAddress=(struct sockaddr *)[aAddressData bytes];
    // IPv6 Addresses are "FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF" at max, which is 40 bytes (0-terminated)
    // IPv4 Addresses are "255.255.255.255" at max which is smaller
    char stringBuffer[40];
    NSString *addressAsString=nil;
    if (socketAddress->sa_family == AF_INET) {
        if (inet_ntop(AF_INET,&((struct in_addr)((struct sockaddr_in *)socketAddress)->sin_addr),stringBuffer,40)) {
            addressAsString=[NSString stringWithUTF8String:stringBuffer];
        } else {
            addressAsString=@"IPv4 un-ntopable";
        }
        int port = ((struct sockaddr_in *)socketAddress)->sin_port;
        addressAsString=[addressAsString stringByAppendingFormat:@":%d",port];
    } else if (socketAddress->sa_family == AF_INET6) {
         if (inet_ntop(AF_INET6,&(((struct sockaddr_in6 *)socketAddress)->sin6_addr),stringBuffer,40)) {
            addressAsString=[NSString stringWithUTF8String:stringBuffer];
        } else {
            addressAsString=@"IPv6 un-ntopable";
        }
        int port = ((struct sockaddr_in6 *)socketAddress)->sin6_port;
        // Suggested IPv6 format (see http://www.faqs.org/rfcs/rfc2732.html)
        addressAsString=[NSString stringWithFormat:@"[%@]:%d",addressAsString,port]; 
    } else {
        addressAsString=@"neither IPv6 nor IPv4";
    }
    return [[addressAsString copy] autorelease];
}

@end


@implementation AppController

- (id)init {
    if ((self=[super init])) {
        I_services=[NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    [self stopRendezvousBrowsing];
    [I_services release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    DEBUGLOG(@"fuckitdomain", AlwaysLogLevel, @"applicationDidFinishLaunching:");    
    [O_servicesController bind:@"contentArray" toObject:self withKeyPath:@"I_services" options:nil];
    [self startRendezvousBrowsing];
}

- (void)stopRendezvousBrowsing {
    [I_browser setDelegate:nil];
    [I_browser stopSearch];
    [I_browser release];
    I_browser=nil;
}

- (void)startRendezvousBrowsing {
    [self stopRendezvousBrowsing];
    I_browser=[[TCMRendezvousBrowser alloc] initWithServiceType:@"_see._tcp." domain:@""];
    [I_browser setDelegate:self];
    [I_browser startSearch];
}

- (NSArray *)addressArrayForAddressArray:(NSArray *)anAddressArray {
    NSMutableArray *result=[NSMutableArray array];
    NSEnumerator *addresses=[anAddressArray objectEnumerator];
    NSData *address=nil;
    while ((address=[addresses nextObject])) {
        [result addObject:[NSDictionary dictionaryWithObjectsAndKeys:address,@"address",[NSString stringWithAddressData:address],@"addressAsString",nil]];
    }
    return result;
}

#pragma mark -
#pragma mark ### TCMRendezvousBrowser Delegate ###
- (void)rendezvousBrowserWillSearch:(TCMRendezvousBrowser *)aBrowser {

}

- (void)rendezvousBrowserDidStopSearch:(TCMRendezvousBrowser *)aBrowser {

}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didNotSearch:(NSError *)anError {
    DEBUGLOG(@"RendezvousLogDomain", AlwaysLogLevel, @"Mist: %@",anError);
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didFindService:(NSNetService *)aNetService {
    DEBUGLOG(@"RendezvousLogDomain", AlwaysLogLevel, @"foundservice: %@",aNetService);
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didResolveService:(NSNetService *)aNetService {
//    [I_data addObject:[NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"resolved %@%@",[aNetService name],[aNetService domain]] forKey:@"serviceName"]];
    [[self mutableArrayValueForKey:@"I_services"] addObject:
            [NSMutableDictionary dictionaryWithObjectsAndKeys:aNetService,@"service",
                [self addressArrayForAddressArray:[aNetService addresses]],@"addresses",
                nil]];
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didChangeCountOfResolved:(BOOL)wasResolved service:(NSNetService *)aNetService {
}


- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didRemoveResolved:(BOOL)wasResolved service:(NSNetService *)aNetService {
    NSMutableArray *services=[self mutableArrayValueForKey:@"I_services"];
    unsigned count=[services count];
    while (count--) {
        NSNetService *service=[[services objectAtIndex:count] objectForKey:@"service"];
        if (service==aNetService) {
            [services removeObjectAtIndex:count];
        }
    }
}


@end
