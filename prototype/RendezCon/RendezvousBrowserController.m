//
//  RendezvousBrowserController.m
//  rendezvous
//
//  Created by Dominik Wagner on Wed Nov 19 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//
#import "RendezvousBrowserController.h"
#import "sys/socket.h"
#import "netinet/in.h"
#import "netinet6/in6.h"
#import "arpa/inet.h"

@implementation RendezvousBrowserController

#pragma mark -
#pragma mark ### init, dealloc & co ###

+ (void)initialize {
    NSUserDefaultsController *defaultsController=[NSUserDefaultsController sharedUserDefaultsController];
    NSString *path=[[NSBundle mainBundle] pathForResource:@"initialDefaults" ofType:@"plist"];
    NSMutableDictionary *initialDefaults=[NSMutableDictionary dictionaryWithContentsOfFile:path];
    [defaultsController setInitialValues:initialDefaults];
}

- (id)init {
    self=[super init];
    if (self) {
        I_foundNetServices   =[NSMutableArray      new];
        I_netServiceBrowsers =[NSMutableDictionary new];
        I_servicesToBrowseFor=[[[[NSUserDefaultsController sharedUserDefaultsController] values] 
                                    valueForKeyPath:@"servicesToBrowseFor"] mutableCopy];
    }
    return self;
}

- (void)awakeFromNib {
    // this would have been nice to be done in interface Builder
    // or are we to provide an extra ojbectcontroller for this object to bind again, 
    // and this here is pure evil?
    [O_serviceController setContent:I_foundNetServices];
    [O_serviceController bind:@"contentArray" toObject:self withKeyPath:@"foundNetServices" options:nil];
    
    [O_servicesController setContent:I_servicesToBrowseFor];
    [O_servicesController bind:@"contentArray" toObject:self withKeyPath:@"servicesToBrowseFor" options:nil];
    
    // now start browsing for the services we should be browsing for
    [self startBrowsing];
//    [self addObserver:self forKeyPath:@"servicesToBrowseFor" 
//              options:(NSKeyValueObservingOptionNew |
//                       NSKeyValueObservingOptionOld)
//              context:nil];

    [O_addressTableView setTarget:self];
    [O_addressTableView setDoubleAction:@selector(simpleURLDoubleAction:)];
}

- (void)dealloc {
    [self stopBrowsing];
    [I_netServiceBrowsers  release];
    [I_foundNetServices    release];
    [I_servicesToBrowseFor release];
}

#pragma mark -
#pragma mark ### KeyValueObserving ###

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    return NO;
}


//// - (void)observeValueForKeyPath:(NSString *)aKeyPath
////                       ofObject:(id)aObject 
////                         change:(NSDictionary *)aChange
////                        context:(void *)aContext
//// {
////     NSLog(@"Path: %@, value: %@",aKeyPath, [aChange descriptionInStringsFileFormat]);
//// }


-(NSMutableArray *)foundNetServices {
    return I_foundNetServices;
}

-(NSMutableArray *)servicesToBrowseFor {
    return I_servicesToBrowseFor;
}

-(void)setServicesToBrowseFor:(NSMutableArray *)aArray {
    NSLog(@"here");
    // i don't know exactly if this is the correct indexset, could not find exact documentation on this
    [self willChange:NSKeyValueChangeReplacement 
        valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[I_servicesToBrowseFor count])] 
        forKey:@"servicesToBrowseFor"];
    [I_servicesToBrowseFor autorelease];
    I_servicesToBrowseFor=[aArray retain];
    [self  didChange:NSKeyValueChangeReplacement 
        valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[I_servicesToBrowseFor count])] 
        forKey:@"servicesToBrowseFor"];
}

#pragma mark -

-(void)startBrowsing {
    NSEnumerator *services=[I_servicesToBrowseFor objectEnumerator];
    NSDictionary *service=nil;
    while ((service=[services nextObject])) {
        if ([[service objectForKey:@"shouldSearchFor"] boolValue]) {
            [self searchForServicesOfType:[service objectForKey:@"serviceType"]];
        }
    }
}

- (void)stopBrowsing {
    [[I_netServiceBrowsers allValues] makeObjectsPerformSelector:@selector(stop)];
    [[I_netServiceBrowsers allValues] makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
    [I_netServiceBrowsers removeAllObjects];
    NSIndexSet *set=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[I_foundNetServices count])];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"foundNetServices"];
    [I_foundNetServices removeAllObjects];
    [self  didChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"foundNetServices"];
}

-(void)removeServicesOfType:(NSString *)aServiceType {
    unsigned serviceIndex;
    NSMutableIndexSet *indexes=[NSMutableIndexSet indexSet];
    for (serviceIndex=[I_foundNetServices count]-1;serviceIndex>=0;serviceIndex--) {
        if ([[(NSNetService *)[[I_foundNetServices objectAtIndex:serviceIndex] objectForKey:@"Service"] type] 
                isEqualToString:aServiceType]) {
            [indexes addIndex:serviceIndex];
        }
    }
    if ([indexes count]) {
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"foundNetServices"];
        // why is there no removeObjectsInIndexSet in NSArray?
        unsigned *indexList=malloc(sizeof(unsigned)*[indexes count]);
        NSRange indexRange=NSMakeRange(0,NSNotFound);
        [indexes getIndexes:indexList maxCount:[indexes count] inIndexRange:&indexRange];
        [I_foundNetServices removeObjectsFromIndices:indexList numIndices:[indexes count]];
        free(indexList);
        [self  didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"foundNetServices"];
    }
}

- (void)searchForServicesOfType:(NSString *)aServiceType {
    if (![I_netServiceBrowsers objectForKey:aServiceType]) {
        NSNetServiceBrowser *browser=[[NSNetServiceBrowser new] autorelease];
        [browser setDelegate:self];
        [browser searchForServicesOfType:aServiceType inDomain:@""];
        [I_netServiceBrowsers setObject:browser forKey:aServiceType];
    }
}

- (void)stopSearchingForServicesOfType:(NSString *)aServiceType {
    NSNetServiceBrowser *browser;
    if ((browser=[I_netServiceBrowsers objectForKey:aServiceType])) {
        [browser stop];
        [browser setDelegate:nil];
        [I_netServiceBrowsers removeObjectForKey:aServiceType];
    }
    [self removeServicesOfType:aServiceType];
}

#pragma mark -
#pragma mark ### Actions ###

- (IBAction)stopAndRestart:(id)aSender {
    [self stopBrowsing];
    [self startBrowsing];
}

- (IBAction)simpleURLDoubleAction:(id)aSender {

    NSString *address=[[[O_addressesController selectedObjects] objectAtIndex:0] objectForKey:@"description"];
    NSString *service=[(NSNetService *)[[[O_serviceController selectedObjects] objectAtIndex:0] objectForKey:@"Service"] type];
    NSString *scheme =[service substringWithRange:NSMakeRange(1,[service rangeOfString:@"."].location-1)];
    NSString *url=[NSString stringWithFormat:@"%@://%@/",scheme,address];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

#pragma mark -
#pragma mark ### NSNetServiceBrowser delegate methods ###

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    int serviceIndex=0;
    for (serviceIndex=[I_foundNetServices count]-1;serviceIndex>=0;serviceIndex--) {
        NSMutableDictionary *entryOfLoop=[I_foundNetServices objectAtIndex:serviceIndex];
        NSNetService *netServiceOfLoop=[entryOfLoop objectForKey:@"Service"];
        if (([netServiceOfLoop isEqualTo:aNetService])) {
            [entryOfLoop setObject:[NSNumber numberWithInt:[[entryOfLoop objectForKey:@"count"] intValue]+1] forKey:@"count"];
            break;
        }
    }
    if (serviceIndex<0) {
        [aNetService setDelegate:self];
        [aNetService resolve];
        // only resolve for 30 seconds, to not harm the network more that it is worth
        // normally you would resolve until you did connect and start resolving just 
        // before you want to connect, but as we only browse the
        // network without connecting, we limit the resolve time
        [aNetService performSelector:@selector(stop) withObject:nil afterDelay:30.];
    
        NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
        [dictionary setObject:aNetService forKey:@"Service"];
        [dictionary setObject:[aNetService name] forKey:@"name"];
        [dictionary setObject:[NSNumber numberWithInt:1] forKey:@"count"];
    
        NSIndexSet *set=[NSIndexSet indexSetWithIndex:[I_foundNetServices count]];
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:set forKey:@"foundNetServices"];
        [I_foundNetServices addObject:dictionary];
        [self  didChange:NSKeyValueChangeInsertion valuesAtIndexes:set forKey:@"foundNetServices"];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    int serviceIndex;
    for (serviceIndex=[I_foundNetServices count]-1; serviceIndex>=0; serviceIndex--) {
        NSMutableDictionary *entryOfLoop=[I_foundNetServices objectAtIndex:serviceIndex];
        NSNetService *netServiceOfLoop=[entryOfLoop objectForKey:@"Service"];
        // keep in mind that the NSNetService objects that come through the 
        // delegate methods of NSNetServiceBrowsers maybe equal to each other
        // but never are identical / the same objects
        if (([netServiceOfLoop isEqualTo:aNetService])) {
            if ([[[I_foundNetServices objectAtIndex:serviceIndex] objectForKey:@"count"] intValue]==1) {
                // Keep in mind that you get potentially a netservice reported for every interface you have
                // so you should only remove the service in your application if your count is at zero again
                // otherwise you remove services that are still reachable
                [netServiceOfLoop stop];
                NSIndexSet *set=[NSIndexSet indexSetWithIndex:serviceIndex];
                [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"foundNetServices"];
                [I_foundNetServices removeObjectAtIndex:serviceIndex];
                [self  didChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"foundNetServices"];
            } else {
                [entryOfLoop setObject:[NSNumber numberWithInt:[[entryOfLoop objectForKey:@"count"] intValue]-1] forKey:@"count"];
            }
            break;
        }
    }
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    NSLog(@"NetServiceBrowserdidStopSearch");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
{
    NSLog(@"NetServiceBrowser didNotSearch:");
}

#pragma mark -
#pragma mark ### NSNetService delegate methods ###

- (void)netServiceDidResolveAddress:(NSNetService *)aNetService 
{
    NSMutableArray *array=[NSMutableArray array];
    NSEnumerator *addresses=[[aNetService addresses] objectEnumerator];
    NSData *address;
    while ((address=[addresses nextObject])) {
        struct sockaddr *socketAddress=(struct sockaddr *)[address bytes];
        NSString *ipAddr=nil;
        if (socketAddress->sa_family == AF_INET) {
            ipAddr=[NSString stringWithCString:inet_ntoa(((struct in_addr)((struct sockaddr_in *)socketAddress)->sin_addr))];
            int port = ((struct sockaddr_in *)socketAddress)->sin_port;
            ipAddr=[ipAddr stringByAppendingFormat:@":%d",port];
        } else if (socketAddress->sa_family == AF_INET6) {
            // IPv6 Address are "FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF" at max, which is 40 bytes (0-terminated)
            char temp[40];
            if (inet_ntop(AF_INET6,&(((struct sockaddr_in6 *)socketAddress)->sin6_addr),temp,40)) {
                ipAddr=[NSString stringWithCString:temp];
            } else {
                ipAddr=@"IPv6";
            }
            int port = ((struct sockaddr_in6 *)socketAddress)->sin6_port;
            ipAddr=[NSString stringWithFormat:@"[%@]:%d",ipAddr,port];
        } else {
            ipAddr=@"neither IPv6 nor IPv4";
        }
        if (ipAddr)
            [array addObject:[NSDictionary dictionaryWithObject:ipAddr forKey:@"description"]];
    }
    int netServiceLoop;
    for (netServiceLoop=[I_foundNetServices count]-1; netServiceLoop>=0; netServiceLoop--) {
        NSNetService *netServiceOfLoop;
        netServiceOfLoop=[[I_foundNetServices objectAtIndex:netServiceLoop] objectForKey:@"Service"];
        if (([netServiceOfLoop isEqualTo:aNetService])) {
            NSMutableString *string=[NSMutableString string];
            if ([[aNetService protocolSpecificInformation] length]>0) {
                NSArray *textRecords=[[aNetService protocolSpecificInformation] componentsSeparatedByString:@"\001"];
                int loop=0;
                for (loop=0;loop<[textRecords count];loop++) {
                    [string appendFormat:@"(%d)\t%d: %@\n",[(NSString *)[textRecords objectAtIndex:loop] length],loop+1,[textRecords objectAtIndex:loop]];
                }
            }
            [[I_foundNetServices objectAtIndex:netServiceLoop] setObject:array  forKey:@"addresses"];
            [[I_foundNetServices objectAtIndex:netServiceLoop] setObject:string forKey:@"protocolSpecificInformation"];
        }
    }
}

#pragma mark -
#pragma mark ### NSWindow delegate methods ###

-(void)windowWillClose:(NSNotification *)aNotification {
    [NSApp terminate:self];
}

#pragma mark -
#pragma mark ### NSApplication delegate methods ###

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[[NSUserDefaultsController sharedUserDefaultsController] values] 
        setValue:I_servicesToBrowseFor forKey:@"servicesToBrowseFor"];
    // could have gone for 
    // [[NSUserDefaults standardUserDefaults] setObject:I_servicesToBrowseFor forKey:@"servicesToBrowseFor"];
    // which is a bit shorter and actually nicer
}
@end
