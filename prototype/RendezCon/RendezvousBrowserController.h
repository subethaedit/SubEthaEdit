//
//  RendezvousBrowserController.h
//  rendezvous
//
//  Created by Dominik Wagner on Wed Nov 19 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface RendezvousBrowserController : NSObject {
    IBOutlet NSArrayController   *O_serviceController;
    IBOutlet NSArrayController   *O_servicesController;
    IBOutlet NSArrayController   *O_addressesController;
    IBOutlet NSTableView         *O_addressTableView;
    IBOutlet NSTableView         *O_servicesTableView;
    NSMutableArray      *I_foundNetServices;
    NSMutableArray *I_servicesToBrowseFor;
    NSMutableDictionary *I_netServiceBrowsers;
}

#pragma mark -
#pragma mark ### Accessors ###
- (NSMutableArray *)foundNetServices;
- (NSMutableArray *)servicesToBrowseFor;
- (void)setServicesToBrowseFor:(NSMutableArray *)aArray;

#pragma mark -
#pragma mark ### Actions ###
- (IBAction)stopAndRestart:(id)aSender;

#pragma mark -
- (void)startBrowsing;
- (void) stopBrowsing;
- (void)          removeServicesOfType:(NSString *)aServiceType;
- (void)       searchForServicesOfType:(NSString *)aServiceType;
- (void)stopSearchingForServicesOfType:(NSString *)aServiceType;

@end
