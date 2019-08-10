//  TCMRendezvousBrowser.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.

#import <Foundation/Foundation.h>

@interface NSNetService (TCMRendezvousBrowserAdditions) 
- (NSString *)uniqueServiceString;
@end


@interface TCMRendezvousBrowser : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate> {
    id I_delegate;
    struct {
        BOOL resolvesServices;
    } I_flags;
    NSString *I_serviceType;
    NSString *I_domain;
    
    NSMutableDictionary *I_foundServiceEntries;
    NSNetServiceBrowser *I_serviceBrowser;
}

- (instancetype)initWithServiceType:(NSString *)aServiceType domain:(NSString *)aDomain;

- (void)startSearch;
- (void)stopSearch;

/*"Accessors"*/
- (void)setDelegate:(id)aDelegate;
- (id)delegate;

- (void)setResolvesServices:(BOOL)resolves;
- (BOOL)resolvesServices;
- (NSString *)domain;
- (NSString *)serviceType;

@end

@interface NSObject (TCMRendezvousBrowserDelegateMethods) 

- (void)rendezvousBrowserWillSearch:(TCMRendezvousBrowser *)aBrowser;
- (void)rendezvousBrowserDidStopSearch:(TCMRendezvousBrowser *)aBrowser;
- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didNotSearch:(NSError *)anError;
- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didFindService:(NSNetService *)aNetService;
- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didResolveService:(NSNetService *)aNetService;
- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didChangeCountOfResolved:(BOOL)wasResolved service:(NSNetService *)aNetService;
- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didRemoveResolved:(BOOL)wasResolved service:(NSNetService *)aNetService;

@end
