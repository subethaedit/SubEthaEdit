//
//  SetupController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu May 13 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "SetupController.h"
#import "GeneralPreferences.h"
#import <AddressBook/AddressBook.h>

#import "MoreUNIX.h"
#import "MoreSecurity.h"
#import "MoreCFQ.h"

#import <sys/stat.h>


static SetupController *sharedInstance = nil;

@implementation SetupController

- (void)TCM_finishSetup {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [defaults setObject:version forKey:SetupVersionPrefKey];
    [defaults synchronize];
}

#pragma mark -

BOOL TCM_scanVersionString(NSString *string, int *major, int *minor) {
    BOOL result;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    result = ([scanner scanInt:major]
        && [scanner scanString:@"." intoString:nil]
        && [scanner scanInt:minor]);
            
    //NSLog(@"major: %d, minor: %d", *major, *minor);
    return result;
}

+ (BOOL)shouldRun {
    int major = 0;
    int minor = 0;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *version = [defaults stringForKey:SetupVersionPrefKey];
    if (version) {
        NSString *bundleShortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        int bundleMajor = 0;
        int bundleMinor = 0;
        if (TCM_scanVersionString(bundleShortVersion, &bundleMajor, &bundleMinor)
            && TCM_scanVersionString(version, &major, &minor)) {
            if (bundleMajor == major && bundleMinor > minor) {
                return YES;
            }
        }
    } else {
        return YES;
    }
    
    return NO;
}

+ (SetupController *)sharedInstance {
    return sharedInstance;
}

+ (BOOL)installCommandLineTool {
    OSStatus err;
    CFURLRef tool = NULL;
    AuthorizationRef auth = NULL;
    NSDictionary *request = nil;
    NSDictionary *response = nil;
    BOOL result = NO;


    err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth);
    if (err == noErr) {
        // If we were doing preauthorization, this is where we'd do it.
    }
    
    if (err == noErr) {
        err = MoreSecCopyHelperToolURLAndCheckBundled(
            CFBundleGetMainBundle(), 
            CFSTR("SubEthaEditHelperToolTemplate"), 
            kApplicationSupportFolderType, 
            CFSTR("SubEthaEdit"), 
            CFSTR("SubEthaEditHelperTool"), 
            &tool);

        // If the home directory is on an volume that doesn't support 
        // setuid root helper tools, ask the user whether they want to use 
        // a temporary tool.
        
        if (err == kMoreSecFolderInappropriateErr) {
            err = MoreSecCopyHelperToolURLAndCheckBundled(
                CFBundleGetMainBundle(), 
                CFSTR("SubEthaEditHelperToolTemplate"), 
                kTemporaryFolderType, 
                CFSTR("SubEthaEdit"), 
                CFSTR("SubEthaEditHelperTool"), 
                &tool);
        }
    }
    
    // Create the request dictionary for a file descriptor
                                    
    if (err == noErr) {
        NSString *pathForSeeTool = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"see"];
        NSNumber *filePermissions = [NSNumber numberWithUnsignedShort:(S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH)];
        NSDictionary *targetAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                        filePermissions, NSFilePosixPermissions,
                                        @"root", NSFileOwnerAccountName,
                                        @"wheel", NSFileGroupOwnerAccountName,
                                        nil];
                                        
        request = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"CopyFiles", @"CommandName",
                            pathForSeeTool, @"SourceFile",
                            SEE_TOOL_PATH, @"TargetFile",
                            targetAttrs, @"TargetAttributes",
                            nil];
    }

    // Go go gadget helper tool!

    if (err == noErr) {
        err = MoreSecExecuteRequestInHelperTool(tool, auth, (CFDictionaryRef)request, (CFDictionaryRef *)(&response));
    }
    
    // Extract information from the response.

    if (err == noErr) {
        //NSLog(@"response: %@", response);

        err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
        if (err == noErr) {
        }
    }
    
    // Clean up after first call of helper tool
        
    if (response) {
        [response release];
        response = nil;
    }

    // Create the request dictionary for exchanging file contents
                                    
    if (err == noErr) {
        NSString *pathForSeeManpage = [[NSBundle mainBundle] pathForResource:@"see.1" ofType:nil];
        NSNumber *filePermissions = [NSNumber numberWithUnsignedShort:(S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)];
        NSDictionary *targetAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                        filePermissions, NSFilePosixPermissions,
                                        @"root", NSFileOwnerAccountName,
                                        @"wheel", NSFileGroupOwnerAccountName,
                                        nil];
                                        
        request = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"CopyFiles", @"CommandName",
                            pathForSeeManpage, @"SourceFile",
                            SEE_MANPAGE_PATH, @"TargetFile",
                            targetAttrs, @"TargetAttributes",
                            nil];
    }

    // Go go gadget helper tool!

    if (err == noErr) {
        err = MoreSecExecuteRequestInHelperTool(tool, auth, (CFDictionaryRef)request, (CFDictionaryRef *)(&response));
    }
    
    // Extract information from the response.
    
    if (err == noErr) {
        //NSLog(@"response: %@", response);

        err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
        if (err == noErr) {
            result = YES;
        }
    }
    
    // Clean up after second call of helper tool.
    if (response) {
        [response release];
    }


    CFQRelease(tool);
    if (auth != NULL) {
        (void)AuthorizationFree(auth, kAuthorizationFlagDestroyRights);
    }
    
    return result;
}


+ (BOOL)removeCommandLineTool {
    OSStatus err;
    CFURLRef tool = NULL;
    AuthorizationRef auth = NULL;
    NSDictionary *request = nil;
    NSDictionary *response = nil;
    BOOL result = NO;


    err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &auth);
    if (err == noErr) {
        // If we were doing preauthorization, this is where we'd do it.
    }
    
    if (err == noErr) {
        err = MoreSecCopyHelperToolURLAndCheckBundled(
            CFBundleGetMainBundle(), 
            CFSTR("SubEthaEditHelperToolTemplate"), 
            kApplicationSupportFolderType, 
            CFSTR("SubEthaEdit"), 
            CFSTR("SubEthaEditHelperTool"), 
            &tool);

        // If the home directory is on an volume that doesn't support 
        // setuid root helper tools, ask the user whether they want to use 
        // a temporary tool.
        
        if (err == kMoreSecFolderInappropriateErr) {
            err = MoreSecCopyHelperToolURLAndCheckBundled(
                CFBundleGetMainBundle(), 
                CFSTR("SubEthaEditHelperToolTemplate"), 
                kTemporaryFolderType, 
                CFSTR("SubEthaEdit"), 
                CFSTR("SubEthaEditHelperTool"), 
                &tool);
        }
    }
    
    // Create the request dictionary for a file descriptor

    if (err == noErr) {
        NSArray *files = [NSArray arrayWithObjects:SEE_TOOL_PATH, SEE_MANPAGE_PATH, nil];
        request = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"RemoveFiles", @"CommandName",
                            files, @"Files",
                            nil];
    }

    // Go go gadget helper tool!

    if (err == noErr) {
        err = MoreSecExecuteRequestInHelperTool(tool, auth, (CFDictionaryRef)request, (CFDictionaryRef *)(&response));
    }
    
    // Extract information from the response.

    if (err == noErr) {
        //NSLog(@"response: %@", response);

        err = MoreSecGetErrorFromResponse((CFDictionaryRef)response);
        if (err == noErr) {
            result = YES;
        }
    }
            
    if (response) {
        [response release];
        response = nil;
    }
        
    CFQRelease(tool);
    if (auth != NULL) {
        (void)AuthorizationFree(auth, kAuthorizationFlagDestroyRights);
    }
    
    return result;
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
    hasInstalledTool = NO;
    isFirstRun = YES;

    NSDictionary *setupDict = [NSDictionary dictionaryWithContentsOfFile:
                                [[NSBundle mainBundle] pathForResource:@"Setup" ofType:@"plist"]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *version = [defaults stringForKey:SetupVersionPrefKey];
    if (version || [defaults boolForKey:SetupDonePrefKey]) {
        shouldMakeNewDocument = NO;
        BOOL isLicensed = NO;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *serial = [defaults stringForKey:SerialNumberPrefKey];
        NSString *name = [defaults stringForKey:LicenseeNamePrefKey];
        if (name && [serial isValidSerial]) {
            isLicensed = YES;
        }
        
        if (isLicensed) {
            [self setItemOrder:[setupDict objectForKey:@"UpdateLicensed"]];
        } else {
            [self setItemOrder:[setupDict objectForKey:@"Update"]];
        }
    } else {
        shouldMakeNewDocument = YES;
        [self setItemOrder:[setupDict objectForKey:@"FirstRun"]];
    }

    itemIndex = 0;
    
    [O_goBackButton setEnabled:NO];
    [O_commercialRadioButton setState:NSOffState];
    [O_noncommercialRadioButton setState:NSOffState];
    [O_useCommandLineToolCheckbox setState:NSOnState];
    
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
        
    [O_tabView selectTabViewItemWithIdentifier:[itemOrder objectAtIndex:0]];
    [[self window] center];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    [NSApp stopModal];
    BOOL isLastItem = [[[O_tabView selectedTabViewItem] identifier] isEqualToString:[itemOrder lastObject]];
    if (!isLastItem && isFirstRun) {
        [NSApp terminate:self];
    }
    if (isLastItem) {
        [self TCM_finishSetup];
    }
}

- (void)setItemOrder:(NSArray *)array {
    [itemOrder autorelease];
    itemOrder = [array retain];
}

- (NSArray *)itemOrder {
    return itemOrder;
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
    shouldMakeNewDocument = NO;
    isFirstRun = NO;
    [O_goBackButton setEnabled:NO];
    
    [O_commercialRadioButton setState:NSOnState];
    [O_noncommercialRadioButton setState:NSOffState];
    [O_licenseeNameField setEnabled:YES];
    [O_licenseeOrganizationField setEnabled:YES];
    [O_serialNumberField setEnabled:YES];    
    
    [self validateContinueButtonInPurchaseTab];
    [O_continueButton setTitle:NSLocalizedString(@"Continue", @"Button title Continue")];
    
    NSDictionary *setupDict = [NSDictionary dictionaryWithContentsOfFile:
                                [[NSBundle mainBundle] pathForResource:@"Setup" ofType:@"plist"]];
    [self setItemOrder:[setupDict objectForKey:@"EnterSerialNumber"]];
    itemIndex = 0;
    
    [O_tabView selectTabViewItemWithIdentifier:[itemOrder objectAtIndex:0]];
    [super showWindow:self];
}

- (IBAction)continueDone:(id)sender {

    if ([[[O_tabView selectedTabViewItem] identifier] isEqualToString:@"installtool"] && !hasInstalledTool) {
        if ([O_useCommandLineToolCheckbox state] == NSOnState) {
             (void)[SetupController installCommandLineTool];
             hasInstalledTool = YES;
             [O_useCommandLineToolCheckbox setEnabled:NO];
        }
    }
    
    if ([[[O_tabView selectedTabViewItem] identifier] isEqualToString:@"license"] && !hasAgreedToLicense) {
        [NSApp beginSheet:O_licenseConfirmationSheet 
           modalForWindow:[self window] 
            modalDelegate:self 
           didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
              contextInfo:nil];

        return;
    }
    
    if ([[[O_tabView selectedTabViewItem] identifier] isEqualToString:@"purchase"] && [O_commercialRadioButton state] == NSOnState) {
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
    
    if ([[[O_tabView selectedTabViewItem] identifier] isEqualToString:[itemOrder lastObject]]) {
        [self TCM_finishSetup];
        [NSApp stopModal];
        [self close];
        if ((isFirstRun && shouldMakeNewDocument)
            || [[NSUserDefaults standardUserDefaults] boolForKey:OpenDocumentOnStartPreferenceKey]) {
            [[NSDocumentController sharedDocumentController] newDocument:self];
        }
    } else {
        [O_tabView selectTabViewItemWithIdentifier:[itemOrder objectAtIndex:++itemIndex]];
    }
    
    [O_goBackButton setEnabled:YES];

    if ([[O_tabView selectedTabViewItem] isEqual:O_purchaseTabItem]) {
        [self validateContinueButtonInPurchaseTab];
    }
    
    if ([[[O_tabView selectedTabViewItem] identifier] isEqualToString:@"done"]) {
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
    [O_tabView selectTabViewItemWithIdentifier:[itemOrder objectAtIndex:--itemIndex]];
    [O_continueButton setTitle:NSLocalizedString(@"Continue", @"Button title Continue")];
    
    if ([[[O_tabView selectedTabViewItem] identifier] isEqualToString:[itemOrder objectAtIndex:0]]) {
        [O_goBackButton setEnabled:NO];
    }

    if (!isFirstRun && [[[O_tabView selectedTabViewItem] identifier] isEqualToString:@"purchase"]) {
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

- (IBAction)purchaseNow:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.codingmonkeys.de/subethaedit/purchase/"]];
}

#pragma mark -

- (void)controlTextDidChange:(NSNotification *)aNotification {
    [self validateContinueButtonInPurchaseTab];
}
#pragma mark -

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (kAgreeLicenseReturnCode == returnCode) {
        [O_tabView selectTabViewItemWithIdentifier:[itemOrder objectAtIndex:++itemIndex]];
    }
    if ([[O_tabView selectedTabViewItem] isEqual:O_purchaseTabItem]) {
        [self validateContinueButtonInPurchaseTab];
    }
    [sheet close];
}

@end
