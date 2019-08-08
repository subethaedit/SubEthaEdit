//  TCMRendezvousBrowser.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.

#import "TCMRendezvousBrowser.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

static NSString *kDidResolveKey=@"DidResolve";
static NSString *kServiceCountKey=@"Count";
static NSString *kServiceKey=@"Service";

@implementation NSNetService (TCMRendezvousBrowserAdditions) 
- (NSString *)uniqueServiceString {
    NSString *string=[NSString stringWithFormat:@"%@%@%@",[self name],[self type],[self domain]];
    return string;
}
@end


@implementation TCMRendezvousBrowser

- (id)initWithServiceType:(NSString *)aServiceType domain:(NSString *)aDomain {
    if ((self=[super init])) {
        I_serviceType=[aServiceType copy];
        I_domain=[aDomain copy];
        [self setResolvesServices:YES];
        I_foundServiceEntries=[NSMutableDictionary new];
        I_serviceBrowser=[NSNetServiceBrowser new];
        [I_serviceBrowser setDelegate: self];
    }
    return self;
}

- (void)dealloc {
    [self stopSearch];
}

- (void)startSearch {
    [I_serviceBrowser searchForServicesOfType:I_serviceType inDomain:I_domain];
}
- (void)stopSearch {
    NSEnumerator *entries=[I_foundServiceEntries objectEnumerator];
    NSMutableDictionary *entry=nil;
    while ((entry=[entries nextObject])) {
        NSNetService *netService=[entry objectForKey:kServiceKey];
        if ([netService delegate]==self) {
            [netService setDelegate:nil];
            [netService stop];
            [NSObject cancelPreviousPerformRequestsWithTarget:netService selector:@selector(stop) object:nil];
        }
    }
    [I_serviceBrowser stop];
}

#pragma mark -
#pragma mark ### Accessors ####

- (NSString *)domain {
    return I_domain;
}

- (NSString *)serviceType {
    return I_serviceType;
}

- (NSMutableDictionary *)entryForService:(NSNetService *)aService {
    return [I_foundServiceEntries objectForKey:[aService uniqueServiceString]];
}

- (void)removeEntryForService:(NSNetService *)aService {
    [I_foundServiceEntries removeObjectForKey:[aService uniqueServiceString]];
}

- (void)setEntry:(NSMutableDictionary *)aEntry forService:(NSNetService *)aService {
    [I_foundServiceEntries setObject:aEntry forKey:[aService uniqueServiceString]];
}

#pragma mark -
#pragma mark ### NSNetServiceBrowser delegate methods ###

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser {
    id delegate=[self delegate];
    if ([delegate respondsToSelector:@selector(rendezvousBrowserWillSearch:)]) {
        [delegate rendezvousBrowserWillSearch:self];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict {
    id delegate=[self delegate];
    if ([delegate respondsToSelector:@selector(rendezvousBrowser:didNotSearch:)]) {
        [delegate rendezvousBrowser:self didNotSearch:[NSError errorWithDomain:[errorDict objectForKey:NSNetServicesErrorDomain] code:[[errorDict objectForKey:NSNetServicesErrorCode] intValue] userInfo:errorDict]];
    }

}
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
           didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    
    NSMutableDictionary *serviceEntry=[self entryForService:aNetService];
    if (serviceEntry) {
        [serviceEntry 
            setObject:[NSNumber numberWithInt:[[serviceEntry objectForKey:kServiceCountKey] intValue] +1] 
            forKey:kServiceCountKey];
        NSNetService *netService=[serviceEntry objectForKey:kServiceKey];
        if ([self resolvesServices] && [[serviceEntry objectForKey:@"LastResolveStart"] timeIntervalSinceNow] < -60) {
			[netService resolveWithTimeout:30.];
            [serviceEntry setObject:[NSDate date] forKey:@"LastResolveStart"];
            DEBUGLOG(@"RendezvousLogDomain",DetailedLogLevel,@"resolves again because of different service count");
        }
        id delegate=[self delegate];
        if ([delegate respondsToSelector:@selector(rendezvousBrowser:didChangeCountOfResolved:service:)]) {
            [delegate rendezvousBrowser:self didChangeCountOfResolved:[[serviceEntry objectForKey:kDidResolveKey] boolValue] service:netService];
        }
    } else {
        serviceEntry=[NSMutableDictionary dictionary];
        [serviceEntry setObject:aNetService forKey:kServiceKey];
        [serviceEntry setObject:[NSNumber numberWithInt:1] forKey:kServiceCountKey];
        if ([self resolvesServices]) {
            [aNetService setDelegate:self];
			[aNetService resolveWithTimeout:30.];
            [serviceEntry setObject:[NSDate date] forKey:@"LastResolveStart"];
        }
        id delegate=[self delegate];
        if ([delegate respondsToSelector:@selector(rendezvousBrowser:didFindService:)]) {
            [delegate rendezvousBrowser:self didFindService:aNetService];
        }
        [self setEntry:serviceEntry forService:aNetService];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
         didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    NSMutableDictionary *serviceEntry=[self entryForService:aNetService];
    if (!serviceEntry) {
        //NSLog(@"A service that not has been found was removed: %@",[aNetService description]);
    } else {
        int newCount=[[serviceEntry objectForKey:kServiceCountKey] intValue]-1;
        if (newCount<=0) {
            NSNetService *netService=[serviceEntry objectForKey:kServiceKey];
            if ([self resolvesServices]) {
                [netService setDelegate:nil];
                [netService stop];
                [NSObject cancelPreviousPerformRequestsWithTarget:netService selector:@selector(stop) object:nil];
            }
            id delegate=[self delegate];
            if ([delegate respondsToSelector:@selector(rendezvousBrowser:didRemoveResolved:service:)]) {
                [delegate rendezvousBrowser:self didRemoveResolved:([serviceEntry objectForKey:kDidResolveKey]!=nil) service:netService];
            }
            [self removeEntryForService:aNetService];
        } else {
            [serviceEntry setObject:[NSNumber numberWithInt:newCount] forKey:kServiceCountKey];
            id delegate=[self delegate];
            if ([delegate respondsToSelector:@selector(rendezvousBrowser:didChangeCountOfResolved:service:)]) {
                NSNetService *netService=[serviceEntry objectForKey:kServiceKey];
                [delegate rendezvousBrowser:self didChangeCountOfResolved:[[serviceEntry objectForKey:kDidResolveKey] boolValue] service:netService];
            }
        }
    }
}

#pragma mark -
#pragma mark ### NSNetService delegate methods ###

- (void)netServiceDidResolveAddress:(NSNetService *)aNetService  {
    NSMutableDictionary *serviceEntry=[self entryForService:aNetService];
    if (!serviceEntry) {
        //NSLog(@"A service that not has been found was resolved: %@",[aNetService description]);
    } else {
        NSNetService *netService=[serviceEntry objectForKey:kServiceKey];
        [netService setDelegate:nil];
        [serviceEntry setObject:[NSNumber numberWithBool:YES] forKey:kDidResolveKey];
        id delegate=[self delegate];
        if ([delegate respondsToSelector:@selector(rendezvousBrowser:didResolveService:)]) {
            [delegate rendezvousBrowser:self didResolveService:netService];
        }
    }
}


@end
