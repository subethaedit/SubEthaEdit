//
//  RendezvousBrowserController.m
//  RendezCon
//
//  Created by Dominik Wagner on Wed Nov 19 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, 
//  are permitted provided that the following conditions are met:
//
//  - Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//
//  - Redistributions in binary form must reproduce the above copyright notice, 
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  - Neither the name of the TheCodingMonkeys nor the names of its contributors
//    may be used to endorse or promote products derived from this software without 
//    specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
//  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
//  OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
//  POSSIBILITY OF SUCH DAMAGE.

#import "RendezvousBrowserController.h"
#import "sys/socket.h"
#import "netinet/in.h"
#import "netinet6/in6.h"
#import "arpa/inet.h"

@implementation RendezvousBrowserController

#pragma mark -
#pragma mark ### init, dealloc & co ###

+ (void)initialize
{
    // Using the NSUserDefaultsController here has no benefits over the NSUserDefaults
    // But since this is intended to be Controller Sample Code...
    NSUserDefaultsController *defaultsController=
        [NSUserDefaultsController sharedUserDefaultsController];
    NSString *path=[[NSBundle mainBundle] pathForResource:@"initialDefaults" ofType:@"plist"];
    NSMutableDictionary *initialDefaults=[NSMutableDictionary dictionaryWithContentsOfFile:path];
    [defaultsController setInitialValues:initialDefaults];
}

- (id)init
{
    self=[super init];
    if (self) {
        I_foundNetServices   =[NSMutableArray      new];
        I_netServiceBrowsers =[NSMutableDictionary new];
        I_servicesToBrowseFor=[[[[NSUserDefaultsController sharedUserDefaultsController] values] 
                                    valueForKeyPath:@"servicesToBrowseFor"] mutableCopy];
    }
    return self;
}

- (void)awakeFromNib
{
    // this would have been nice to be done in Interface Builder. An constant like 
    // IBAction would be nice (IBBinding?)
    // Or are we to provide an extra Objectcontroller for this object to bind again, 
    // and this here is pure evil?
    [O_serviceController setContent:I_foundNetServices];
    [O_serviceController bind:@"contentArray" toObject:self 
        withKeyPath:@"foundNetServices" options:nil];
    
    // Originally I intended to bind this directly to the NSUserDefaultsController
    // But it turned out that objects that are not on top level of the NSUserDefaults
    // are immutable
    [O_servicesController setContent:I_servicesToBrowseFor];
    [O_servicesController bind:@"contentArray" toObject:self 
        withKeyPath:@"servicesToBrowseFor" options:nil];
    
    // now start browsing for the services we should be browsing for
    [self startBrowsing];
//    [self addObserver:self forKeyPath:@"foundNetServices" 
//              options:(NSKeyValueObservingOptionNew |
//                       NSKeyValueObservingOptionOld)
//              context:nil];

    [O_addressTableView setTarget:self];
    [O_addressTableView setDoubleAction:@selector(simpleURLDoubleAction:)];
    
    NSTableColumn *column=[[O_servicesTableView tableColumns] objectAtIndex:0];
    NSCell *cell=[column dataCell];
    [cell setTarget:self];
    [cell setAction:@selector(didChangeStatusOfServiceToBrowse:)];
    
}

- (void)dealloc
{
    [self stopBrowsing];
    [I_netServiceBrowsers  release];
    [I_foundNetServices    release];
    [I_servicesToBrowseFor release];
}

#pragma mark -
#pragma mark ### KeyValueObserving ###

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
    return NO;
}

// - (void)observeValueForKeyPath:(NSString *)aKeyPath
//                       ofObject:(id)aObject 
//                         change:(NSDictionary *)aChange
//                        context:(void *)aContext
// {
//     NSLog(@"Path: %@, value: %@",aKeyPath, [aChange descriptionInStringsFileFormat]);
// }

- (NSMutableArray *)foundNetServices
{
    return I_foundNetServices;
}

- (NSMutableArray *)servicesToBrowseFor
{
    return I_servicesToBrowseFor;
}

- (void)setServicesToBrowseFor:(NSMutableArray *)aArray
{
    // I don't know exactly if this is the correct indexset,
    // I could not find exact documentation on this
    // But If I Observe myself, than this is the only combination that does not throw exceptions
    [self willChange:NSKeyValueChangeReplacement 
        valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[I_servicesToBrowseFor count])] 
        forKey:@"servicesToBrowseFor"];
    [I_servicesToBrowseFor autorelease];
    I_servicesToBrowseFor=[aArray retain];
    [self  didChange:NSKeyValueChangeReplacement 
        valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[aArray count])] 
        forKey:@"servicesToBrowseFor"];
}

#pragma mark -

- (void)startBrowsing
{
    NSEnumerator *services=[I_servicesToBrowseFor objectEnumerator];
    NSDictionary *service=nil;
    while ((service=[services nextObject])) {
        if ([[service objectForKey:@"shouldSearchFor"] boolValue]) {
            [self searchForServicesOfType:[service objectForKey:@"serviceType"]];
        }
    }
}

- (void)stopBrowsing
{
    [[I_netServiceBrowsers allValues] makeObjectsPerformSelector:@selector(stop)];
    [[I_netServiceBrowsers allValues] makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
    [I_netServiceBrowsers removeAllObjects];
    NSIndexSet *set=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[I_foundNetServices count])];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"foundNetServices"];
    [I_foundNetServices removeAllObjects];
    [self  didChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"foundNetServices"];
}

- (void)removeServicesOfType:(NSString *)aServiceType
{
    int serviceIndex;
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

- (void)searchForServicesOfType:(NSString *)aServiceType
{
    if (![I_netServiceBrowsers objectForKey:aServiceType]) {
        NSNetServiceBrowser *browser=[[NSNetServiceBrowser new] autorelease];
        [browser setDelegate:self];
        [browser searchForServicesOfType:aServiceType inDomain:@""];
        [I_netServiceBrowsers setObject:browser forKey:aServiceType];
    }
}

- (void)stopSearchingForServicesOfType:(NSString *)aServiceType
{
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

- (IBAction)didChangeStatusOfServiceToBrowse:(id)aSender
{
    // originally I intended to do
    // [O_servicesController selectedObjects];
    // but the array controller changes the selection after the action is sent
    NSDictionary *dictionary=[[O_servicesController arrangedObjects] objectAtIndex:[O_servicesTableView selectedRow]];
    if (dictionary) {
        if ([dictionary objectForKey:@"serviceType"]) {
            // this relys on the fact, that the controller changed the value of the 
            // content already. I don't know if I'm allowed to assume this.
           if ([[dictionary objectForKey:@"shouldSearchFor"] boolValue]) {
                [self searchForServicesOfType:[dictionary objectForKey:@"serviceType"]];
            } else {
                [self stopSearchingForServicesOfType:[dictionary objectForKey:@"serviceType"]];
            }
        }
    }
}

- (IBAction)stopAndRestart:(id)aSender
{
    [self stopBrowsing];
    [self startBrowsing];
}

- (IBAction)simpleURLDoubleAction:(id)aSender
{
    NSString *address=[[[O_addressesController selectedObjects] objectAtIndex:0] objectForKey:@"addressAsString"];
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
            [entryOfLoop setObject:[NSNumber numberWithInt:[[entryOfLoop objectForKey:@"count"] intValue]+1] 
                            forKey:@"count"];
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
    
        // since we know nothing about the observability of NSNetService is not actually observable, 
        // we copy the values we display into the dictionary
        NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
        [dictionary setObject:aNetService forKey:@"Service"];
        [dictionary setObject:[aNetService name]   forKey:@"name"];
        [dictionary setObject:[aNetService type]   forKey:@"type"];
        [dictionary setObject:[aNetService domain] forKey:@"domain"];
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
    int netServiceIndex;
    for (netServiceIndex=[I_foundNetServices count]-1; netServiceIndex>=0; netServiceIndex--) {
        NSMutableDictionary *entryOfLoop=[I_foundNetServices objectAtIndex:netServiceIndex];
        NSNetService   *netServiceOfLoop=[entryOfLoop objectForKey:@"Service"];
        if (([netServiceOfLoop isEqualTo:aNetService])) {
            NSMutableArray *array=[entryOfLoop objectForKey:@"addresses"];
            if (!array) {
                array=[NSMutableArray array];
                [entryOfLoop setObject:array forKey:@"addresses"];
            }
            // Loop over the new addresses and translate them into strings
            NSArray *addresses=[aNetService addresses];
            int index=0;
            for (index=[array count];index<[addresses count];index++) {
                struct sockaddr *socketAddress=(struct sockaddr *)[[addresses objectAtIndex:index] bytes];
                // IPv6 Addresses are "FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF" at max, which is 40 bytes (0-terminated)
                // IPv4 Addresses are "255.255.255.255" at max which is smaller
                char stringBuffer[40];
                NSString *addressAsString=nil;
                if (socketAddress->sa_family == AF_INET) {
                    if (inet_ntop(AF_INET,&((struct in_addr)((struct sockaddr_in *)socketAddress)->sin_addr),stringBuffer,40)) {
                        addressAsString=[NSString stringWithCString:stringBuffer];
                    } else {
                        addressAsString=@"IPv4 un-ntopable";
                    }
                    int port = ((struct sockaddr_in *)socketAddress)->sin_port;
                    addressAsString=[addressAsString stringByAppendingFormat:@":%d",port];
                } else if (socketAddress->sa_family == AF_INET6) {
                     if (inet_ntop(AF_INET6,&(((struct sockaddr_in6 *)socketAddress)->sin6_addr),stringBuffer,40)) {
                        addressAsString=[NSString stringWithCString:stringBuffer];
                    } else {
                        addressAsString=@"IPv6 un-ntopable";
                    }
                    int port = ((struct sockaddr_in6 *)socketAddress)->sin6_port;
                    addressAsString=[NSString stringWithFormat:@"[%@]:%d",addressAsString,port];
                } else {
                    addressAsString=@"neither IPv6 nor IPv4";
                }
                if (addressAsString)
                    [array addObject:[NSDictionary dictionaryWithObject:addressAsString forKey:@"addressAsString"]];
            }
            // note that the protcolSpecificInformation is also a result of an resolve,
            // it is not available when you first get the NSNetService from the NSNetServiceBrowser
            if ([[aNetService protocolSpecificInformation] length]>0) {
                NSMutableString *string=[NSMutableString string];
                NSArray *textRecords=[[aNetService protocolSpecificInformation] componentsSeparatedByString:@"\001"];
                int loop=0;
                for (loop=0;loop<[textRecords count];loop++) {
                    [string appendFormat:@"(%d)\t%d: %@\n",[(NSString *)[textRecords objectAtIndex:loop] length],loop+1,[textRecords objectAtIndex:loop]];
                }
                [entryOfLoop setObject:string forKey:@"protocolSpecificInformationForTextView"];
                [entryOfLoop setObject:[aNetService protocolSpecificInformation] forKey:@"protocolSpecificInformation"];
            }
            [entryOfLoop setObject:array forKey:@"addresses"];
            break;
        }
    }
}

#pragma mark -
#pragma mark ### NSWindow delegate methods ###

-(void)windowWillClose:(NSNotification *)aNotification
{
    [NSApp terminate:self];
}

#pragma mark -
#pragma mark ### NSApplication delegate methods ###

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    NSUserDefaultsController* defaultsController=[NSUserDefaultsController sharedUserDefaultsController];
    [[defaultsController values] setValue:I_servicesToBrowseFor forKey:@"servicesToBrowseFor"];
    [defaultsController save:self];
    // could have gone for 
    // [[NSUserDefaults standardUserDefaults] setObject:I_servicesToBrowseFor forKey:@"servicesToBrowseFor"];
    // which is a bit shorter and actually nicer
}

@end
