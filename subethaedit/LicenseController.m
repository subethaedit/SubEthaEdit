//
//  LicenseController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu May 13 2004.
//  Copyright (c) 2004-2006 TheCodingMonkeys. All rights reserved.
//

#import "LicenseController.h"
#import "AppController.h"
#import "GeneralPreferences.h"
#import <AddressBook/AddressBook.h>


static LicenseController *sharedInstance = nil;

@implementation LicenseController

// first stop method - correct any tempering that happened here
+ (BOOL)shouldRun {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    
    NSString *serial = [defaults stringForKey:SerialNumberPrefKey];
    NSString *name = [defaults stringForKey:LicenseeNamePrefKey];
    
    if (name && [serial isValidSerial]) {
        return NO;
    }
        
    NSString *otherKey = @"NSRandom SeedBase";
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
    
    BOOL setStartDate = NO;
    
    NSDate *firstStartDate = [defaults objectForKey:@"FirstStartDate"];
    if (![firstStartDate isKindOfClass:[NSDate class]]) firstStartDate = nil;
    NSNumber *otherDateInterval = [defaults objectForKey:otherKey];
    NSDate *otherDate = nil;
    if ([otherDateInterval isKindOfClass:[NSNumber class]]) {
        otherDate = [NSDate dateWithTimeIntervalSince1970:[otherDateInterval doubleValue]];
    }

    if (firstStartDate==nil && otherDate==nil) {
//        NSLog(@"Both Dates are nil!");
        // fresh start so lets set the firstStart Date
        firstStartDate = currentDate;
        setStartDate = YES;
    } else if (firstStartDate && otherDate) {
//        NSLog(@"Both Dates are set!");
        NSTimeInterval difference=[firstStartDate timeIntervalSinceDate:otherDate];
//        NSLog(@"difference was %.30f", difference);
        if (ABS(difference)>1.) {
//            NSLog(@"first: %@ wasn't equal to other: %@", firstStartDate, otherDate);
            if (difference > 0) firstStartDate = otherDate;
            setStartDate = YES;
        }
    } else {
        if (otherDate) {
            firstStartDate = otherDate;
        }
        setStartDate = YES;
    } 

    NSString *cfBundleVersionKey = @"CFBundleVersion";
    NSString *previousCFBundleVersion = [defaults stringForKey:cfBundleVersionKey];
    NSString *previousVersion = [defaults stringForKey:SetupVersionPrefKey];
    NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *cfBundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:cfBundleVersionKey];
    if (![bundleVersion   isEqualToString:previousVersion] || 
        ![cfBundleVersion isEqualToString:previousCFBundleVersion]) {
        if (![bundleVersion   isEqualToString:previousVersion] && 
            ![cfBundleVersion isEqualToString:previousCFBundleVersion]) {
            firstStartDate = currentDate;
            setStartDate = YES;
        }
        [defaults setObject:bundleVersion   forKey:SetupVersionPrefKey];
        [defaults setObject:cfBundleVersion forKey:cfBundleVersionKey];
    }

    if (setStartDate) {
//        NSLog(@"setting start date to %@, %f", firstStartDate, [firstStartDate timeIntervalSince1970]);
        [defaults setObject:firstStartDate forKey:@"FirstStartDate"];
        [defaults setObject:[NSNumber numberWithDouble:[firstStartDate timeIntervalSince1970]] forKey:otherKey];
    }
    
    [currentDate release];
    
    return YES;
}

+ (int)daysLeft {
    NSDate *firstStartDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"FirstStartDate"];
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
    NSTimeInterval runningInterval = [currentDate timeIntervalSinceDate:firstStartDate];
    [currentDate release];
    int daysLeft = 31 - ABS((runningInterval / (60 * 60 * 24)));
    return daysLeft;
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
    
    if (name != nil && [name length] > 0 && serial != nil && [serial isValidSerial]) {
        [O_licenseeNameField setObjectValue:name];
        if (organization != nil) [O_licenseeOrganizationField setObjectValue:organization];
        [O_serialNumberField setObjectValue:serial];
        unichar bulletCharacters[] = {0x2022, 0x2022, 0x2022, 0x2022, 0x2022, 0x2022, 
                                      0x2022, 0x2022, 0x2022, 0x2022, 0x2022, 0x2022, 
                                      0x2022, 0x2022, 0x2022, 0x2022, 0x2022, 0x2022};
        NSString *bulletString = [NSString stringWithCharacters:bulletCharacters length:18];

        [O_serialNumberField setObjectValue:bulletString];
        [O_registerButton setEnabled:NO];
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

    NSString *serialNumberString = [[[O_serialNumberField stringValue]uppercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([[O_licenseeNameField stringValue] length] > 0 && [serialNumberString length] == 18 && [serialNumberString isValidSerial]) {
        [O_serialNumberField setStringValue:serialNumberString];
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
    
    NSMenu *mainMenu = [NSApp mainMenu];
    NSMenu *appMenu = [[mainMenu itemWithTag:AppMenuTag] submenu];
    NSMenuItem *enterSerialMenuItem = [appMenu itemWithTag:EnterSerialMenuItemTag];
    [appMenu removeItem:enterSerialMenuItem];
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
