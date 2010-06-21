//
//  LicenseController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Thu May 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>


extern NSString * const SetupDonePrefKey;
extern NSString * const SetupVersionPrefKey;
extern NSString * const SerialNumberPrefKey;
extern NSString * const LicenseeNamePrefKey;
extern NSString * const LicenseeOrganizationPrefKey;


@interface LicenseController : NSWindowController <NSTextFieldDelegate> {
    IBOutlet NSTextField *O_licenseeNameField;
    IBOutlet NSTextField *O_licenseeOrganizationField;
    IBOutlet NSTextField *O_serialNumberField;
    
    IBOutlet NSButton *O_registerButton;
    IBOutlet NSButton *O_cancelButton;
}

+ (BOOL)shouldRun;
+ (int)daysLeft;
+ (LicenseController *)sharedInstance;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;

@end
