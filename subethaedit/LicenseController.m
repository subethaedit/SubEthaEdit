//
//  LicenseController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu May 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "LicenseController.h"
#import "GeneralPreferences.h"
#import <AddressBook/AddressBook.h>


static LicenseController *sharedInstance = nil;

@implementation LicenseController

+ (int)daysLeft {
    NSDate *firstStartDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"FirstStartDate"];
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
    NSTimeInterval runningInterval = [currentDate timeIntervalSinceDate:firstStartDate];
    [currentDate release];
    int daysLeft = 30 - ABS((runningInterval / (60 * 60 * 24)));
    return daysLeft;
}

+ (BOOL)shouldRun {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *serial = [defaults stringForKey:SerialNumberPrefKey];
    NSString *name = [defaults stringForKey:LicenseeNamePrefKey];
    
    if (name && [serial isValidSerial]) {
        return NO;
    }
        
    NSDate *firstStartDate = [defaults objectForKey:@"FirstStartDate"];
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];

    if (firstStartDate == nil) {
        [defaults setObject:currentDate forKey:@"FirstStartDate"];
    }
    
    NSString *previousVersion = [defaults stringForKey:SetupVersionPrefKey];
    NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if ([previousVersion compare:bundleVersion] != NSOrderedSame) {
        [defaults setObject:currentDate forKey:@"FirstStartDate"];
        [defaults setObject:bundleVersion forKey:SetupVersionPrefKey];
    }
    
    return YES;
}

+ (LicenseController *)sharedInstance {
    return sharedInstance;
}

- (id)init {
    self = [super initWithWindowNibName:@"License"];
    return self;
}

- (void)awakeFromNib {
    sharedInstance = self;
}

- (void)TCM_fillInRegistrationInfo {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *serial = [defaults stringForKey:SerialNumberPrefKey];
    NSString *name = [defaults stringForKey:LicenseeNamePrefKey];
    NSString *organization = [defaults stringForKey:LicenseeOrganizationPrefKey];
    
    if (name != nil && serial != nil) {
        [O_licenseeNameField setObjectValue:name];
        if (organization != nil) [O_licenseeOrganizationField setObjectValue:organization];
        [O_serialNumberField setObjectValue:serial];
        if ([[O_licenseeNameField stringValue] length] > 0 && [[O_serialNumberField stringValue] isValidSerial]) {
            [O_registerButton setEnabled:YES];
        } else {
            [O_registerButton setEnabled:NO];
        }
    } else {
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
    }
}

- (void)windowDidLoad {
    [O_registerButton setEnabled:NO];
    [O_licenseeNameField setDelegate:self];
    [O_licenseeOrganizationField setDelegate:self];
    [O_serialNumberField setDelegate:self];
    
    [self TCM_fillInRegistrationInfo];        
    [[self window] center];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    [NSApp stopModal];
}
    
- (IBAction)showWindow:(id)sender {
    [self TCM_fillInRegistrationInfo];
    [[self window] center];
    [super showWindow:self];
}

#pragma mark -

- (void)controlTextDidChange:(NSNotification *)aNotification {
    if ([[O_licenseeNameField stringValue] length] > 0 && [[O_serialNumberField stringValue] length] == 18 && [[O_serialNumberField stringValue] isValidSerial]) {
        [O_registerButton setEnabled:YES];
    } else {
        [O_registerButton setEnabled:NO];
    }
}

#pragma mark -

- (IBAction)ok:(id)sender {
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
    }
    [NSApp stopModal];
    [self close];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:NSLocalizedString(@"Thank you very much for purchasing SubEthaEdit!", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    (void)[alert runModal];
    [alert release];
}

- (IBAction)cancel:(id)sender {
    [NSApp stopModal];
    [self close];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *serial = [defaults stringForKey:SerialNumberPrefKey];
    NSString *name = [defaults stringForKey:LicenseeNamePrefKey];
    
    if (name && [serial isValidSerial]) {
        return;
    }
    
    if ([LicenseController daysLeft] < 1) {
        [NSApp terminate:self];
    }
}

@end
