//  TCMRendezvousBrowser.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.

#import <Foundation/Foundation.h>

@interface NSNetService (TCMRendezvousBrowserAdditions) 
- (NSString *)uniqueServiceString;
@end


@interface TCMRendezvousBrowser : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate> {
    NSString *I_serviceType;
    NSString *I_domain;
    
    NSMutableDictionary *I_foundServiceEntries;
    NSNetServiceBrowser *I_serviceBrowser;
}

@property (nonatomic, weak) id delegate;
@property (nonatomic) BOOL resolvesServices;

- (instancetype)initWithServiceType:(NSString *)aServiceType domain:(NSString *)aDomain;

- (void)startSearch;
- (void)stopSearch;

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
