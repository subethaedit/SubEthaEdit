//
//  Controller.h
//  BEEPSample
//
//  Created by Martin Ott on Tue Feb 17 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@class TCMBEEPListener,TCMBEEPSimpleSendProfile,TCMBEEPSession;

@interface Controller : NSObject {

    IBOutlet NSTextField *O_peerAddressTextField;
    IBOutlet NSTextField *O_ports;
    
    IBOutlet NSTextField *O_messageTextField;
    IBOutlet NSTextView  *O_receivedTextView;
    
    IBOutlet NSButton *O_connectButton;
    IBOutlet NSButton *O_listenerControlButton;
    
    TCMBEEPListener *I_listener;
    TCMBEEPSimpleSendProfile *I_sendProfile,*I_receiveProfile;
    TCMBEEPSession  *I_activeSession;
}

- (IBAction)connect:(id)aSender;
- (IBAction)toggleListener:(id)aSender;
- (IBAction)sendMessage:(id)aSender;

@end
