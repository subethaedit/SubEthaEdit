//
//  AvailableServicesController.h
//  RendezCon
//
//  Created by Dominik Wagner on Mon Dec 22 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AvailableServicesController : NSObject {
    IBOutlet NSArrayController *I_availableServicesArrayController;
    IBOutlet NSArrayController *I_servicesToBrowseForArrayController;
    IBOutlet NSTableView *I_tableView;
    NSNetServiceBrowser *I_browser;
    IBOutlet NSPanel *I_panel;
}

-(IBAction)addServiceToBrowseFor:(id)aSender;

@end
