//
//  SetupController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu May 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "SetupController.h"

#define kApplicationMenuItemTag 999
#define kQuitMenuItemTag 998

static SetupController *sharedInstance = nil;

@implementation SetupController

+ (SetupController *)sharedInstance {
    return sharedInstance;
}

- (id)init {
    self = [super initWithWindowNibName:@"Setup"];
    return self;
}

- (void)awakeFromNib {
    sharedInstance = self;
}

- (void)windowDidLoad {
    hasAgreedToLicense = NO;
    [O_goBackButton setEnabled:NO];
    [O_tabView selectFirstTabViewItem:self];
    
    [[self window] center];
}

- (IBAction)continueDone:(id)sender {
    [O_goBackButton setEnabled:YES];

    if ([[O_tabView selectedTabViewItem] isEqual:O_licenseTabItem] && !hasAgreedToLicense) {
        [NSApp beginSheet:O_licenseConfirmationSheet 
           modalForWindow:[self window] 
            modalDelegate:self 
           didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
              contextInfo:nil];

        return;
    }
    
    if ([[O_tabView selectedTabViewItem] isEqual:O_purchaseTabItem]) {
    
    }
    
    if ([[O_tabView selectedTabViewItem] isEqual:O_doneTabItem]) {
        [NSApp stopModal];
        [self close];
    } else {
        [O_tabView selectNextTabViewItem:self];
    }
    
    if ([[O_tabView selectedTabViewItem] isEqual:O_doneTabItem]) {
        [O_continueButton setTitle:NSLocalizedString(@"Done", @"Button Title Done")];
    }
}

- (IBAction)goBack:(id)sender {
    [O_tabView selectPreviousTabViewItem:self];
    [O_continueButton setTitle:NSLocalizedString(@"Continue", @"Button title Continue")];
    
    if ([[O_tabView selectedTabViewItem] isEqual:O_welcomeTabItem]) {
        [O_goBackButton setEnabled:NO];
    }
}

#define kAgreeLicenseReturnCode 1
#define kDisagreeLicenseReturnCode 0

- (IBAction)agreeLicense:(id)sender {
    hasAgreedToLicense = YES;
    [NSApp endSheet:O_licenseConfirmationSheet returnCode:kAgreeLicenseReturnCode];
}

- (IBAction)disagreeLicense:(id)sender {
    [NSApp endSheet:O_licenseConfirmationSheet returnCode:kDisagreeLicenseReturnCode];
}

#pragma mark -

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (kAgreeLicenseReturnCode == returnCode) {
        [O_tabView selectNextTabViewItem:self];
    }
    [sheet close];
}

@end
