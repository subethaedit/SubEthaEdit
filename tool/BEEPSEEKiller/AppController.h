//
//  AppController.h
//  BEEPSEEKiller
//
//  Created by Dominik Wagner on 29.03.05.
//  Copyright (c) 2005 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <TCMFoundation/TCMRendezvousBrowser.h>

@interface AppController : NSObject {
    TCMRendezvousBrowser *I_browser;
    NSMutableArray *I_services;
    IBOutlet NSArrayController *O_servicesController;
    IBOutlet NSArrayController *O_addressesController;
    TCMBEEPSession *I_BEEPSession;
    IBOutlet NSTextView *O_resultTextView;
    int I_testNumber;
    NSArray *I_testDescriptions;
    NSString *I_userID;
    IBOutlet NSPopUpButton *O_popUpButton;
}

+ (id)sharedInstance;

- (IBAction)connect:(id)aSender;
- (IBAction)stop:(id)aSender;

- (void)stopRendezvousBrowsing;
- (void)startRendezvousBrowsing;

- (NSString *)userID;
- (void)setUserID:(NSString *)aString;

- (NSArray *)testDescriptions;
- (void)setTestNumber:(int)aNumber;
- (int)testNumber;

@end
