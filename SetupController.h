//
//  SetupController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Thu May 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>


extern NSString * const SetupDonePrefKey;
extern NSString * const SerialNumberPrefKey;
extern NSString * const LicenseeNamePrefKey;
extern NSString * const LicenseeOrganizationPrefKey;


@interface SetupController : NSWindowController {
    IBOutlet NSTabView *O_tabView;
    IBOutlet NSButton *O_goBackButton;
    IBOutlet NSButton *O_continueButton;
    
    IBOutlet NSTabViewItem *O_welcomeTabItem;
    IBOutlet NSTabViewItem *O_licenseTabItem;
    IBOutlet NSTabViewItem *O_purchaseTabItem;
    IBOutlet NSTabViewItem *O_doneTabItem;
    
    IBOutlet NSWindow *O_licenseConfirmationSheet;
    BOOL hasAgreedToLicense;
    BOOL isFirstRun;
    
    IBOutlet NSButton *O_noncommercialRadioButton;
    IBOutlet NSButton *O_commercialRadioButton;
    IBOutlet NSTextField *O_licenseeNameField;
    IBOutlet NSTextField *O_licenseeOrganizationField;
    IBOutlet NSTextField *O_serialNumberField;
    IBOutlet NSTextField *O_purchaseHintField;
    IBOutlet NSTextView *O_licenseTextView;
    
    IBOutlet NSTabView *O_doneTabView;
}

+ (SetupController *)sharedInstance;

- (IBAction)continueDone:(id)sender;
- (IBAction)goBack:(id)sender;
- (IBAction)commercialChanged:(id)sender;

- (IBAction)agreeLicense:(id)sender;
- (IBAction)disagreeLicense:(id)sender;
- (IBAction)purchaseNow:(id)sender;

@end
