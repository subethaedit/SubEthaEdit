//
//  SetupController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu May 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "SetupController.h"
#import <AddressBook/AddressBook.h>

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
    isFirstRun = YES;
    [O_goBackButton setEnabled:NO];
    [O_commercialRadioButton setState:NSOffState];
    [O_noncommercialRadioButton setState:NSOffState];
    [O_tabView selectFirstTabViewItem:self];
    
    [O_licenseeNameField setDelegate:self];
    [O_licenseeOrganizationField setDelegate:self];
    [O_serialNumberField setDelegate:self];
    [O_licenseeNameField setEnabled:NO];
    [O_licenseeOrganizationField setEnabled:NO];
    [O_serialNumberField setEnabled:NO];    
    [O_purchaseHintField setObjectValue:@""];
    
    ABPerson *meCard = [[ABAddressBook sharedAddressBook] me];
    NSString *myName = nil;
    
    if (meCard) {
        NSString *firstName = [meCard valueForProperty:kABFirstNameProperty];
        NSString *lastName  = [meCard valueForProperty:kABLastNameProperty];            
    
        if ((firstName != nil) && (lastName != nil)) {
            myName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        } else if (firstName != nil) {
            myName = firstName;
        } else if (lastName!=nil) {
            myName = lastName;
        } else {
            myName = NSFullUserName();
        }
            
        NSString *organization = [meCard valueForProperty:kABOrganizationProperty];
        [O_licenseeOrganizationField setObjectValue:organization];
    } else {
        myName = NSFullUserName();
    }
    [O_licenseeNameField setObjectValue:myName];
        
    NSString *licensePath = [[NSBundle mainBundle] pathForResource:@"License" ofType:@"rtf"];
    [[O_licenseTextView textStorage] readFromURL:[NSURL fileURLWithPath:licensePath] options:nil documentAttributes:nil];
        
    [[self window] center];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    [NSApp stopModal];
    if (![[O_tabView selectedTabViewItem] isEqual:O_doneTabItem] && isFirstRun) {
        [NSApp terminate:self];
    }
    if ([[O_tabView selectedTabViewItem] isEqual:O_doneTabItem]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:SetupDonePrefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)validateContinueButtonInPurchaseTab {
    if ([O_noncommercialRadioButton state] == NSOffState && [O_commercialRadioButton state] == NSOffState) {
        [O_continueButton setEnabled:NO];
        return;
    }
    
    if ([O_noncommercialRadioButton state] == NSOnState) {
        [O_continueButton setEnabled:YES];
        return;
    }

    if ([O_commercialRadioButton state] == NSOnState) {
        if ([[O_licenseeNameField stringValue] length] > 0 && [[O_serialNumberField stringValue] length] > 0) {
            [O_continueButton setEnabled:YES];
        } else {
            [O_continueButton setEnabled:NO];
        }
    }
}    
    
- (IBAction)showWindow:(id)sender {
    [[self window] center];
    hasAgreedToLicense = YES;
    isFirstRun = NO;
    [O_goBackButton setEnabled:NO];
    
    [O_commercialRadioButton setState:NSOnState];
    [O_noncommercialRadioButton setState:NSOffState];
    [O_licenseeNameField setEnabled:YES];
    [O_licenseeOrganizationField setEnabled:YES];
    [O_serialNumberField setEnabled:YES];    
    
    [self validateContinueButtonInPurchaseTab];
    [O_continueButton setTitle:NSLocalizedString(@"Continue", @"Button title Continue")];
    [O_tabView selectTabViewItem:O_purchaseTabItem];
    [super showWindow:self];
}

- (IBAction)continueDone:(id)sender {

    if ([[O_tabView selectedTabViewItem] isEqual:O_licenseTabItem] && !hasAgreedToLicense) {
        [NSApp beginSheet:O_licenseConfirmationSheet 
           modalForWindow:[self window] 
            modalDelegate:self 
           didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
              contextInfo:nil];

        return;
    }
    
    if ([[O_tabView selectedTabViewItem] isEqual:O_purchaseTabItem] && [O_commercialRadioButton state] == NSOnState) {
        NSString *serial = [O_serialNumberField stringValue];
        NSString *name = [O_licenseeNameField stringValue];
        NSString *organization = [O_licenseeOrganizationField stringValue];
        if (name && [name length] > 0 && [serial isValidSerial]) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:serial forKey:SerialNumberPrefKey];
            [defaults setObject:name forKey:LicenseeNamePrefKey];
            if (organization) {
                [defaults setObject:organization forKey:LicenseeOrganizationPrefKey];
            }
            [defaults synchronize];
        } else {
            if (![serial isValidSerial]) {
                [O_purchaseHintField setObjectValue:NSLocalizedString(@"Invalid Serial Number", nil)];
            }
            NSBeep();
            return;        
        }
    }
    
    if ([[O_tabView selectedTabViewItem] isEqual:O_doneTabItem]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:SetupDonePrefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [NSApp stopModal];
        [self close];
        if (isFirstRun) {
            [[NSDocumentController sharedDocumentController] newDocument:self];
        }
    } else {
        [O_tabView selectNextTabViewItem:self];
    }
    
    [O_goBackButton setEnabled:YES];

    if ([[O_tabView selectedTabViewItem] isEqual:O_purchaseTabItem]) {
        [self validateContinueButtonInPurchaseTab];
    }
    
    if ([[O_tabView selectedTabViewItem] isEqual:O_doneTabItem]) {
        [O_continueButton setTitle:NSLocalizedString(@"Done", @"Button Title Done")];
        if ([O_commercialRadioButton state] == NSOnState) {
            [O_doneTabView selectTabViewItemWithIdentifier:@"commercial"];
            [O_goBackButton setEnabled:NO];
        } else if ([O_noncommercialRadioButton state] == NSOnState) {
            [O_doneTabView selectTabViewItemWithIdentifier:@"noncommercial"];
        }
    }
}

- (IBAction)goBack:(id)sender {
    [O_continueButton setEnabled:YES];
    [O_tabView selectPreviousTabViewItem:self];
    [O_continueButton setTitle:NSLocalizedString(@"Continue", @"Button title Continue")];
    
    if ([[O_tabView selectedTabViewItem] isEqual:O_welcomeTabItem]) {
        [O_goBackButton setEnabled:NO];
    }

    if (!isFirstRun && [[O_tabView selectedTabViewItem] isEqual:O_purchaseTabItem]) {
        [O_goBackButton setEnabled:NO];
    }
}

- (IBAction)commercialChanged:(id)sender {
    [O_purchaseHintField setObjectValue:@""];

    if ([sender isEqual:O_commercialRadioButton]) {
        if ([O_commercialRadioButton state] == NSOnState) {
            [O_noncommercialRadioButton setState:NSOffState];
        } else {
            [O_noncommercialRadioButton setState:NSOnState];
        }
    } else {
        if ([O_noncommercialRadioButton state] == NSOnState) {
            [O_commercialRadioButton setState:NSOffState];
        } else {
            [O_commercialRadioButton setState:NSOnState];
        }    
    }
    
    if ([O_commercialRadioButton state] == NSOnState) {
        [O_licenseeNameField setEnabled:YES];
        [O_licenseeOrganizationField setEnabled:YES];
        [O_serialNumberField setEnabled:YES];
    } else {
        [O_licenseeNameField setEnabled:NO];
        [O_licenseeOrganizationField setEnabled:NO];
        [O_serialNumberField setEnabled:NO];    
    }
    
    [self validateContinueButtonInPurchaseTab];
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

- (void)controlTextDidChange:(NSNotification *)aNotification {
    [self validateContinueButtonInPurchaseTab];
}
#pragma mark -

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (kAgreeLicenseReturnCode == returnCode) {
        [O_tabView selectNextTabViewItem:self];
    }
    if ([[O_tabView selectedTabViewItem] isEqual:O_purchaseTabItem]) {
        [self validateContinueButtonInPurchaseTab];
    }
    [sheet close];
}

@end
