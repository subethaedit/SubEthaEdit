//
//  AppController.h
//  BEEPSEEKiller
//
//  Created by Dominik Wagner on 29.03.05.
//  Copyright (c) 2005 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMRendezvousBrowser.h"

@interface AppController : NSObject {
    TCMRendezvousBrowser *I_browser;
    NSMutableArray *I_services;
    IBOutlet NSArrayController *O_servicesController;
    IBOutlet NSArrayController *O_addressesController;
}

- (IBAction)connect:(id)aSender;
- (void)stopRendezvousBrowsing;
- (void)startRendezvousBrowsing;

@end
