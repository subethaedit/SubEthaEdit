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


// Rendezvous reference:
// http://developer.apple.com/macosx/rendezvous/

#import "RendezvousBrowserController.h"
#import "sys/socket.h"
#import "netinet/in.h"
#import "netinet6/in6.h"
#import "arpa/inet.h"

#import "dns_sd.h"
#import "nameser.h"
#import <CoreFoundation/CoreFoundation.h>


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

#pragma mark -
#pragma mark ### Utilities ###

void SetProtocolSpecificInformationInServiceDictionary(NSString *aString,NSMutableDictionary *aDictionary) {
    NSMutableString *string=[NSMutableString string];
    NSArray *textRecords=[aString componentsSeparatedByString:@"\001"];
    int loop=0;
    for (loop=0;loop<[textRecords count];loop++) {
        [string appendFormat:@"(%d)\t%d: %@\n",[(NSString *)[textRecords objectAtIndex:loop] length],loop+1,[textRecords objectAtIndex:loop]];
    }
    [aDictionary setObject:string  forKey:@"protocolSpecificInformationForTextView"];
    [aDictionary setObject:aString forKey:@"protocolSpecificInformation"];

}

#pragma mark -
#pragma mark ### Callbacks ###

void dns_service_query_record_callback (
    DNSServiceRef       DNSServiceRef,
    DNSServiceFlags     flags,
    uint32_t            interfaceIndex,
    DNSServiceErrorType errorCode,
    const char          *fullname,    
    uint16_t            rrtype,
    uint16_t            rrclass,
    uint16_t            rdlen,
    const void          *rdata,
    uint32_t            ttl,
    void                *context  
    ) {
    
    // this callback works as in browsing and domain enumeration, 
    // although the header file does not state this
    
    if (flags & kDNSServiceFlagsAdd) {
        char textInCocoaFormat[1400];
        char *textPosition=textInCocoaFormat;
        char *txt_record=(char *)rdata;
        while (rdlen) {
            unsigned char len=*txt_record;
            txt_record++; rdlen--;
            while (rdlen && len) {
                *textPosition=*txt_record;
                txt_record++; rdlen--;len--; textPosition++;
            }
            if (rdlen) {
                *textPosition='\001';
                textPosition++;
            }
        }
        *textPosition=0;
        NSMutableDictionary *serviceDictionary=(NSMutableDictionary *)context;
        [serviceDictionary setObject:[NSNumber numberWithInt:[[serviceDictionary objectForKey:@"resolveCount"] intValue]+1]
                              forKey:@"resolveCount"];
        NSString *text=[NSString stringWithUTF8String:textInCocoaFormat];
        SetProtocolSpecificInformationInServiceDictionary(text,serviceDictionary);
    }
}

void socket_read_callback (CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, 
                           const void *data, void *info) {
    DNSServiceErrorType error = DNSServiceProcessResult((DNSServiceRef)info);
    if (error) {
        NSLog(@"Error: %d", error);
    }
}


@implementation RendezvousBrowserController

#pragma mark -
#pragma mark ### init, dealloc & co ###

+ (void)initialize {
    // Using the NSUserDefaultsController here has no benefits over the NSUserDefaults
    // But since this is intended to be Controller sample code...
    NSUserDefaultsController *defaultsController=
        [NSUserDefaultsController sharedUserDefaultsController];
    NSString *path=[[NSBundle mainBundle] pathForResource:@"initialDefaults" ofType:@"plist"];
    NSMutableDictionary *initialDefaults=[NSMutableDictionary dictionaryWithContentsOfFile:path];
    [defaultsController setInitialValues:initialDefaults];
}

- (id)init {
    self=[super init];
    if (self) {
        I_foundNetServices   =[NSMutableArray      new];
        I_netServiceBrowsers =[NSMutableDictionary new];
        I_servicesToBrowseFor=[NSMutableArray      new];
        
        I_shouldResolveTXTRecordDictionary=[NSMutableDictionary new];

        // Deep copy the array to make it and its content mutable
        NSEnumerator *services=[[[[NSUserDefaultsController sharedUserDefaultsController] values] 
                                    valueForKeyPath:@"servicesToBrowseFor"] objectEnumerator];
        NSDictionary *entry;
        while ((entry=[services nextObject])) {
            [I_servicesToBrowseFor addObject:[[entry mutableCopy] autorelease]];
            if ([[entry objectForKey:@"shouldResolveTXTRecord"] boolValue]) {
                NSString *serviceType=[entry objectForKey:@"serviceType"];
                if (serviceType && [serviceType length]>0) {
                    [I_shouldResolveTXTRecordDictionary setObject:[NSNumber numberWithBool:YES] forKey:serviceType]; 
                }
            }
        }
    }
    return self;
}

- (void)awakeFromNib {
    // It would be nicer if this could be done in Interface Builder. A constant like 
    // IBAction would be cool (IBBinding?).
    // Or should we provide an additional NSObjectController for this object to bind against, 
    // and this method is purely evil?
    [O_foundServicesController bind:@"contentArray" toObject:self 
        withKeyPath:@"foundNetServices" options:nil];
    
    // Originally I intended to bind this directly to the NSUserDefaultsController
    // But it turned out that objects that are not on top level of the NSUserDefaults
    // are immutable
    [O_servicesToBrowseForController bind:@"contentArray" toObject:self 
        withKeyPath:@"servicesToBrowseFor" options:nil];
    
    NSEnumerator *servicesToBrowseFor=[I_servicesToBrowseFor objectEnumerator];
    NSMutableDictionary *service=nil;
    while (service=[servicesToBrowseFor nextObject]) {
        [service addObserver:self forKeyPath:@"shouldSearchFor" options:0 context:nil];
        [service addObserver:self forKeyPath:@"shouldResolveTXTRecord" options:0 context:nil];
    }

    [self addObserver:self forKeyPath:@"foundNetServices" options:0 context:nil];

    // Now start browsing for the services we should be browsing for
    [self startBrowsing];

    [O_addressTableView setTarget:self];
    [O_addressTableView setDoubleAction:@selector(simpleURLDoubleAction:)];
    
    NSCell *cell=[[O_servicesTableView tableColumnWithIdentifier:@"shouldSearch"] dataCell];
    [cell setTarget:self];
    [cell setAction:@selector(didChangeStatusOfServiceToBrowse:)];  
}

- (void)dealloc {
    [self stopBrowsing];
    [I_netServiceBrowsers  release];
    [I_foundNetServices    release];
    [I_servicesToBrowseFor release];
    [super dealloc];
}


#pragma mark -
#pragma mark ### KeyValueObserving ###

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    // We do the notifications ourselves because it
    // a) is better style
    // b) helps understanding Key Value Observing
    return NO;
}

- (NSMutableArray *)foundNetServices {
    return I_foundNetServices;
}

// Implement the indexed Accessors for better performance
// if you implement only the set and get Accessors, than on every
// change the whole Array is set again
// I'm wondering if there is a more convenient way to do this
// since the NSMutableArray object itself is quite aware of the 
// changes that are made to it.

- (unsigned int)countOfServicesToBrowseFor {
    return [I_servicesToBrowseFor count];
}

- (NSMutableDictionary *)objectInServicesToBrowseForAtIndex:(unsigned int)aIndex {
    return [I_servicesToBrowseFor objectAtIndex:aIndex];
}

- (void)insertObject:(NSMutableDictionary *)aObject inServicesToBrowseForAtIndex:(unsigned int)aIndex {
    NSIndexSet *set=[NSIndexSet indexSetWithIndex:aIndex];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:set forKey:@"servicesToBrowseFor"];
    // add us as observer
    [aObject addObserver:self forKeyPath:@"shouldSearchFor" options:0 context:nil];
    [aObject addObserver:self forKeyPath:@"shouldResolveTXTRecord" options:0 context:nil];
    [I_servicesToBrowseFor insertObject:aObject atIndex:aIndex];
    [self  didChange:NSKeyValueChangeInsertion valuesAtIndexes:set forKey:@"servicesToBrowseFor"];
}

- (void)removeObjectFromServicesToBrowseForAtIndex:(unsigned)aIndex {
    NSIndexSet *set=[NSIndexSet indexSetWithIndex:aIndex];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"servicesToBrowseFor"];
    // remove us as observer
    [[I_servicesToBrowseFor objectAtIndex:aIndex] removeObserver:self forKeyPath:@"shouldSearchFor"];    
    [[I_servicesToBrowseFor objectAtIndex:aIndex] removeObserver:self forKeyPath:@"shouldResolveTXTRecord"];    
    [I_servicesToBrowseFor removeObjectAtIndex:aIndex];
    [self  didChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"servicesToBrowseFor"];
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)aObject 
                        change:(NSDictionary *)aChange context:(void *)aContext {

    if ([aKeyPath isEqualToString:@"shouldSearchFor"]) {
        NSNumber *shouldSearchFor=[aObject valueForKey:@"shouldSearchFor"];
        if ([shouldSearchFor boolValue]) {
            [self searchForServicesOfType:[aObject valueForKey:@"serviceType"]];
        } else {
            [self stopSearchingForServicesOfType:[aObject valueForKey:@"serviceType"]];
        }
    } else if ([aKeyPath isEqualToString:@"foundNetServices"]) {
        [O_foundServicesBox setTitle:[NSString stringWithFormat:@"Found Services (%d)",[I_foundNetServices count]]];
    } else if ([aKeyPath isEqualToString:@"shouldResolveTXTRecord"]) {
        BOOL shouldResolveTXTRecord=[[aObject valueForKey:@"shouldResolveTXTRecord"] boolValue];
        NSString *serviceType=[aObject valueForKey:@"serviceType"];
        if (serviceType && [serviceType length]>0) {
            if (shouldResolveTXTRecord) {
                [I_shouldResolveTXTRecordDictionary setObject:[NSNumber numberWithBool:YES]
                                                       forKey:serviceType];
            } else {
                [I_shouldResolveTXTRecordDictionary removeObjectForKey:serviceType];
            }
            NSEnumerator *serviceDictionaries=[I_foundNetServices objectEnumerator];
            NSMutableDictionary *serviceDictionary=nil;
            while ((serviceDictionary=[serviceDictionaries nextObject])) {
                if ([serviceType isEqualToString:[serviceDictionary objectForKey:@"type"]]) {
                    if (shouldResolveTXTRecord) {
                        [self startResolvingTXTRecord:serviceDictionary];
                    } else {
                        [self stopResolvingTXTRecord:serviceDictionary];
                    }
                }
            }
        }
    }
}


#pragma mark -

- (void)startResolvingTXTRecord:(NSMutableDictionary *)aServiceDictionary {
    if ([aServiceDictionary objectForKey:@"DNSQueryService"]==nil) {
        char buffer[kDNSServiceMaxDomainName];
        DNSServiceErrorType error;
        NSNetService *netService=[aServiceDictionary objectForKey:@"Service"];
        error=DNSServiceConstructFullName(buffer,[[netService name] UTF8String],
                                          [[netService type] UTF8String],[[netService domain] UTF8String]);
        if (error==kDNSServiceErr_NoError) {
            DNSServiceRef dnsService=nil;
                error=DNSServiceQueryRecord(&dnsService,0,0,buffer,
                                            ns_t_txt,ns_c_in,dns_service_query_record_callback,aServiceDictionary);
            if (error==kDNSServiceErr_NoError) {                
                CFSocketNativeHandle fd = DNSServiceRefSockFD(dnsService);
                CFSocketContext context= {0,dnsService,NULL,NULL,NULL};
                CFSocketRef   socketRef = CFSocketCreateWithNative(NULL,fd,kCFSocketReadCallBack,
                                                                   socket_read_callback,&context);
                CFRunLoopSourceRef socketSource = CFSocketCreateRunLoopSource(NULL,socketRef,0);

                CFRunLoopAddSource (CFRunLoopGetCurrent(),socketSource,kCFRunLoopCommonModes);
                [aServiceDictionary setObject:[NSValue valueWithPointer:socketRef]    forKey:@"DNSQuerySocketRef"];
                [aServiceDictionary setObject:[NSValue valueWithPointer:socketSource] forKey:@"DNSQuerySource"];
                [aServiceDictionary setObject:[NSValue valueWithPointer:dnsService]   forKey:@"DNSQueryService"];
            }
        }
    }
}

- (void)stopResolvingTXTRecord:(NSMutableDictionary *)aServiceDictionary {
    if ([aServiceDictionary objectForKey:@"DNSQueryService"]) {
        DNSServiceRef      dnsService  =(DNSServiceRef)     [[aServiceDictionary objectForKey:@"DNSQueryService"] pointerValue];
        CFRunLoopSourceRef socketSource=(CFRunLoopSourceRef)[[aServiceDictionary objectForKey:@"DNSQuerySource"]  pointerValue];
        CFSocketRef        socketRef   =(CFSocketRef)       [[aServiceDictionary objectForKey:@"DNSQuerySocketRef"]    pointerValue];

        CFRunLoopRemoveSource(CFRunLoopGetCurrent(),socketSource,kCFRunLoopCommonModes);
        CFRelease(socketSource);
                
        // if you don't invalidate the socket, then a CFSocketCreateWithNative with a SocketNativeHandle
        // you already used once won't overwrite the context. Before invalidating we make sure
        // that invalidating does not close the socket, as the DNSService is responsible for it.
        CFSocketSetSocketFlags(socketRef,CFSocketGetSocketFlags(socketRef)&(~kCFSocketCloseOnInvalidate));
        CFSocketInvalidate(socketRef);
        CFRelease(socketRef);

        DNSServiceRefDeallocate(dnsService);

        [aServiceDictionary removeObjectForKey:@"DNSQueryService"];
        [aServiceDictionary removeObjectForKey:@"DNSQuerySource"];
        [aServiceDictionary removeObjectForKey:@"DNSQuerySocketRef"];
    }
}

- (void)startBrowsing {
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
    NSEnumerator *serviceDictionaries=[I_foundNetServices objectEnumerator];
    NSMutableDictionary *serviceDictionary;
    while ((serviceDictionary=[serviceDictionaries nextObject])) {
        [self stopResolvingTXTRecord:serviceDictionary];
    }
    NSIndexSet *set=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[I_foundNetServices count])];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"foundNetServices"];
    [I_foundNetServices removeAllObjects];
    [self  didChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"foundNetServices"];
}

- (void)removeServicesOfType:(NSString *)aServiceType {
    int serviceIndex;
    NSMutableIndexSet *indexes=[NSMutableIndexSet indexSet];
    for (serviceIndex=[I_foundNetServices count]-1;serviceIndex>=0;serviceIndex--) {
        if ([[(NSNetService *)[[I_foundNetServices objectAtIndex:serviceIndex] objectForKey:@"Service"] type] 
                isEqualToString:aServiceType]) {
            [self stopResolvingTXTRecord:[I_foundNetServices objectAtIndex:serviceIndex]];
            [indexes addIndex:serviceIndex];
        }
    }
    if ([indexes count]) {
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"foundNetServices"];
        // Why is there no removeObjectsInIndexSet in NSArray?
        unsigned *indexList=malloc(sizeof(unsigned)*[indexes count]);
        NSRange indexRange=NSMakeRange(0,NSNotFound);
        [indexes getIndexes:indexList maxCount:[indexes count] inIndexRange:&indexRange];
        [I_foundNetServices removeObjectsFromIndices:indexList numIndices:[indexes count]];
        free(indexList);
        [self  didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"foundNetServices"];
    }
}

- (void)searchForServicesOfType:(NSString *)aServiceType {
    if (![I_netServiceBrowsers objectForKey:aServiceType] && aServiceType!=nil) {
        NSNetServiceBrowser *browser=[[NSNetServiceBrowser new] autorelease];
        [browser setDelegate:self];
        [browser searchForServicesOfType:aServiceType inDomain:@""];
        [I_netServiceBrowsers setObject:browser forKey:aServiceType];
    }
}

- (void)stopSearchingForServicesOfType:(NSString *)aServiceType {
    NSNetServiceBrowser *browser;
    if (aServiceType!=nil && (browser=[I_netServiceBrowsers objectForKey:aServiceType])) {
        [browser stop];
        [browser setDelegate:nil];
        [I_netServiceBrowsers removeObjectForKey:aServiceType];
    }
    [self removeServicesOfType:aServiceType];
}

#pragma mark -
#pragma mark ### Actions ###

- (IBAction)didChangeStatusOfServiceToBrowse:(id)aSender {
    // Originally I intended to do
    // [O_servicesToBrowseForController selectedObjects];
    // but the array controller doesn't change the selection until after the action was sent
    NSDictionary *dictionary=[[O_servicesToBrowseForController arrangedObjects] 
                                objectAtIndex:[O_servicesTableView selectedRow]];

    if (dictionary) {
        if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) {
            NSNumber *state=[dictionary objectForKey:@"shouldSearchFor"];
            // This relies on the fact, that the controller changed the value of the 
            // content already. I don't know if I'm allowed to assume this.
            NSEnumerator *servicesToBrowseFor=[I_servicesToBrowseFor objectEnumerator];
            NSMutableDictionary *serviceToBrowseFor=nil;
            while ((serviceToBrowseFor=[servicesToBrowseFor nextObject])) {
                if (![[serviceToBrowseFor objectForKey:@"shouldSearchFor"] isEqualTo:state]) {
                    [serviceToBrowseFor setObject:state forKey:@"shouldSearchFor"];
                }
            }
        }
    }
}

- (IBAction)restartAll:(id)aSender {
    [self stopBrowsing];
    [self startBrowsing];
}

- (IBAction)simpleURLDoubleAction:(id)aSender {
    NSArray *selectedObjects=[O_addressesController selectedObjects];
    if ([selectedObjects count]) {
        NSString     *address=[[selectedObjects objectAtIndex:0] objectForKey:@"addressAsString"];
        NSString *serviceType=[(NSNetService *)[[[O_foundServicesController selectedObjects] objectAtIndex:0] objectForKey:@"Service"] type];
        NSString      *scheme=[serviceType substringWithRange:NSMakeRange(1,[serviceType rangeOfString:@"."].location-1)];
        NSString         *url=[NSString stringWithFormat:@"%@://%@/",scheme,address];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    }
}

- (IBAction)resolveSelectedNetServiceAgain:(id)aSender {
    // This is what you should do, if you connected to a NetService, lost
    // connection, but the NetService is still around
    NSArray *selectedObjects=[O_foundServicesController selectedObjects];
    if ([selectedObjects count]) {
        NSMutableDictionary *entry=[selectedObjects objectAtIndex:0];
        NSNetService *oldService=[entry objectForKey:@"Service"];
                
        [oldService stop];
        [oldService setDelegate:nil];
        [entry removeObjectForKey:@"addresses"];
        [entry removeObjectForKey:@"protocolSpecificInformationForTextView"];
        [entry removeObjectForKey:@"protocolSpecificInformation"];

        NSNetService *newService=[[NSNetService alloc] initWithDomain:[oldService domain] type:[oldService type] name:[oldService name]];
        [entry setObject:[newService autorelease] forKey:@"Service"];
        [newService setDelegate:self];
        [newService resolve];
        [newService performSelector:@selector(stop) withObject:nil afterDelay:30.];
    }
}


- (IBAction)showReleaseNotes:(id)aSender {
    [[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"ReleaseNotes" ofType:@"rtf"]];
}

#pragma mark -
#pragma mark ### NSNetServiceBrowser delegate methods ###

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
           didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    int serviceIndex=0;
    for (serviceIndex=[I_foundNetServices count]-1;serviceIndex>=0;serviceIndex--) {
        NSMutableDictionary *entryOfLoop=[I_foundNetServices objectAtIndex:serviceIndex];
        NSNetService   *netServiceOfLoop=[entryOfLoop objectForKey:@"Service"];
        if (([netServiceOfLoop isEqualTo:aNetService])) {
            [entryOfLoop setObject:[NSNumber numberWithInt:[[entryOfLoop objectForKey:@"count"] intValue]+1] 
                            forKey:@"count"];
            break;
        }
    }
    
    // Did not find NetService in Array?
    if (serviceIndex<0) {
        [aNetService setDelegate:self];
        [aNetService resolve];
        // Only resolve for 30 seconds, to not harm the network more than necessary.
        // "Normally" you would resolve until you did connect and start resolving just 
        // before you want to connect, but as we only browse the
        // network without connecting, we limit the resolve time
        [aNetService performSelector:@selector(stop) withObject:nil afterDelay:30.];
    
        // Since we don't know if NSNetService is observable, 
        // we copy the values that we're displaying into the dictionary
        NSMutableDictionary *dictionary=[NSMutableDictionary dictionary];
        [dictionary setObject:aNetService                forKey:@"Service"];
        [dictionary setObject:[aNetService name]         forKey:@"name"];
        [dictionary setObject:[aNetService type]         forKey:@"type"];
        [dictionary setObject:[aNetService domain]       forKey:@"domain"];
        [dictionary setObject:[NSNumber numberWithInt:1] forKey:@"count"];
    
        NSIndexSet *set=[NSIndexSet indexSetWithIndex:[I_foundNetServices count]];
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:set forKey:@"foundNetServices"];
        [I_foundNetServices addObject:dictionary];
        [self  didChange:NSKeyValueChangeInsertion valuesAtIndexes:set forKey:@"foundNetServices"];

        if ([[I_shouldResolveTXTRecordDictionary objectForKey:[aNetService type]] boolValue]) {
            [self startResolvingTXTRecord:dictionary];
        }
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
         didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    int serviceIndex;
    for (serviceIndex=[I_foundNetServices count]-1; serviceIndex>=0; serviceIndex--) {
        NSMutableDictionary *entryOfLoop=[I_foundNetServices objectAtIndex:serviceIndex];
        NSNetService *netServiceOfLoop=[entryOfLoop objectForKey:@"Service"];
        // Keep in mind that the NSNetService objects that we receive via the 
        // delegate methods of NSNetServiceBrowsers may be equal to each other
        // but never are identical / the same objects
        if (([netServiceOfLoop isEqualTo:aNetService])) {
            if ([[[I_foundNetServices objectAtIndex:serviceIndex] objectForKey:@"count"] intValue]==1) {
                // Keep in mind that you get potentially one NSNetService reported for every interface.
                // I.e. you should only remove the service in your application if your count is at zero again
                // otherwise you remove services that are still reachable.
                [netServiceOfLoop stop];
                NSIndexSet *set=[NSIndexSet indexSetWithIndex:serviceIndex];
                [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"foundNetServices"];
                [I_foundNetServices removeObjectAtIndex:serviceIndex];
                [self  didChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"foundNetServices"];
            } else {
                [entryOfLoop setObject:[NSNumber numberWithInt:[[entryOfLoop objectForKey:@"count"] intValue]-1] 
                                forKey:@"count"];
            }
            break;
        }
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict {
    NSLog(@"netServiceBrowser:%@ didNotSearch:%@",[aNetServiceBrowser description],[errorDict description]);
}

#pragma mark -
#pragma mark ### NSNetService delegate methods ###

- (void)netServiceDidResolveAddress:(NSNetService *)aNetService  {
    int netServiceIndex;
    for (netServiceIndex=[I_foundNetServices count]-1; netServiceIndex>=0; netServiceIndex--) {
        NSMutableDictionary *entryOfLoop=[I_foundNetServices objectAtIndex:netServiceIndex];
        NSNetService   *netServiceOfLoop=[entryOfLoop objectForKey:@"Service"];
        if (([netServiceOfLoop isEqualTo:aNetService])) {
            [entryOfLoop setObject:[NSNumber numberWithInt:[[entryOfLoop objectForKey:@"resolveCount"] intValue]+1]
                         forKey:@"resolveCount"];
            NSMutableArray *array=[entryOfLoop objectForKey:@"addresses"];
            if (!array) {
                array=[NSMutableArray array];
                [entryOfLoop setObject:array forKey:@"addresses"];
            }
            // Loop over the new addresses and translate them into strings
            NSArray *addresses=[aNetService addresses];
            int index=0;
            for (index=[array count];index<[addresses count];index++) {
                NSString *addressAsString=[NSString stringWithAddressData:[addresses objectAtIndex:index]];
                if (addressAsString)
                    [array addObject:[NSDictionary dictionaryWithObject:addressAsString forKey:@"addressAsString"]];
            }
            // Note that the protcolSpecificInformation is also a result of an resolve,
            // it is not available when you first get the NSNetService from the NSNetServiceBrowser
            if ([[aNetService protocolSpecificInformation] length]>0) {
                SetProtocolSpecificInformationInServiceDictionary([aNetService protocolSpecificInformation],entryOfLoop);
            }
            // Trigger UI update in addresses table view.
            // Why is this necessary?
            [entryOfLoop setObject:array forKey:@"addresses"];
            break;
        }
    }
}

#pragma mark -
#pragma mark ### NSWindow delegate methods ###

- (void)windowWillClose:(NSNotification *)aNotification {
    [NSApp terminate:self];
}

#pragma mark -
#pragma mark ### NSApplication delegate methods ###

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    NSUserDefaultsController* defaultsController=[NSUserDefaultsController sharedUserDefaultsController];
    [[defaultsController values] setValue:I_servicesToBrowseFor forKey:@"servicesToBrowseFor"];
    // Could have gone for 
    // [[NSUserDefaults standardUserDefaults] setObject:I_servicesToBrowseFor forKey:@"servicesToBrowseFor"];
}

@end
