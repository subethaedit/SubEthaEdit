//
//  SetupController.h
//  SubEthaEdit
//
//  Created by Martin Ott on Thu May 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AppKit/AppKit.h>


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
}

- (IBAction)continueDone:(id)sender;
- (IBAction)goBack:(id)sender;

- (IBAction)agreeLicense:(id)sender;
- (IBAction)disagreeLicense:(id)sender;

@end
