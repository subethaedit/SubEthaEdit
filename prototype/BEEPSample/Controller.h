//
//  Controller.h
//  BEEPSample
//
//  Created by Martin Ott on Tue Feb 17 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@class TCMBEEPListener;

@interface Controller : NSObject {

    IBOutlet NSTextField *O_peerAddressTextField;
    IBOutlet NSTextField *O_ports;
    
    IBOutlet NSButton *O_connectButton;
    IBOutlet NSButton *O_listenerControlButton;
    
    TCMBEEPListener *I_listener;
}

- (IBAction)connect:(id)aSender;
- (IBAction)toggleListener:(id)aSender;

@end
