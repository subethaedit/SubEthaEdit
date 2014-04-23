//
//  SEECollaborationPreferenceModule.m
//  SubEthaEdit
//
//  Created by Lisa Brodner on 10/04/14.
//  Copyright (c) 2014 TheCodingMonkeys. All rights reserved.
//

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#import "SEECollaborationPreferenceModule.h"

#import "PreferenceKeys.h"

#import <AddressBook/AddressBook.h>
#import "TCMMMUserManager.h"
#import "TCMMMBEEPSessionManager.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"
#import "TCMMMPresenceManager.h"

#import <TCMPortMapper/TCMPortMapper.h>
#import "TCMMMBEEPSessionManager.h"

#import <Quartz/Quartz.h>

@interface SEECollaborationPreferenceModule ()
@property (nonatomic, strong) IKPictureTaker *imagePicker;
@property (nonatomic, strong) NSPopover *imagePopover;
@end

@implementation SEECollaborationPreferenceModule

#pragma mark - Preference Module - Basics
- (NSImage *)icon {
    return [NSImage imageNamed:@"PrefIconCollaboration"];
}

- (NSString *)iconLabel {
    return NSLocalizedStringWithDefaultValue(@"CollaborationPrefsIconLabel", nil, [NSBundle mainBundle], @"Collaboration", @"Label displayed below collaboration icon and used as window title.");
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.collaboration";
}

- (NSString *)mainNibName {
    return @"SEECollaborationPrefs";
}

- (void)mainViewDidLoad {
    // Initialize user interface elements to reflect current preference settings

	[self TCM_setupComboBoxes];
	
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    
    TCMMMUser *me = [TCMMMUserManager me];
    NSImage *myImage = [me image];
    [myImage setFlipped:NO];
    [self.O_nameTextField setStringValue:[me name]];
    [self.O_emailComboBox setStringValue:[[me properties] objectForKey:@"Email"]];

    [self.O_automaticallyMapPortButton setState:[defaults boolForKey:ShouldAutomaticallyMapPort]?NSOnState:NSOffState];
    [self.O_localPortTextField setStringValue:[NSString stringWithFormat:@"%d",[[TCMMMBEEPSessionManager sharedInstance] listeningPort]]];
	
    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperDidStartWork:) name:TCMPortMapperDidStartWorkNotification object:pm];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperDidFinishWork:) name:TCMPortMapperDidFinishWorkNotification object:pm];
    if ([pm isAtWork]) {
        [self portMapperDidStartWork:nil];
    } else {
        [self portMapperDidFinishWork:nil];
    }
	
	[self.O_disableNetworkingButton setState:[TCMMMBEEPSessionManager sharedInstance].isNetworkingDisabled ? NSOnState : NSOffState];
	[self.O_invisibleOnNetowrkButton setState:[[TCMMMPresenceManager sharedInstance] isVisible] ? NSOffState : NSOnState];
	
	SEEUserColorsPreviewView *preview = self.O_userColorsPreview;
	NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	[preview bind:@"userColorHue" toObject:defaultsController withKeyPath:@"values.MyColorHue" options:nil];
	[preview bind:@"changesSaturation" toObject:defaultsController withKeyPath:@"values.MyChangesSaturation" options:nil];
	[preview bind:@"showsChangesHighlight" toObject:defaultsController withKeyPath:@"values.HighlightChanges" options:nil];
	
	// avatar image view related things
	SEEAvatarImageView *avatarImageView = self.O_avatarImageView;
	avatarImageView.image = me.image; // is updated by the choose image method
	avatarImageView.initials = me.initials; // are updated by the change name method
	[avatarImageView bind:@"borderColor"     toObject:defaultsController withKeyPath:@"values.MyColorHue" options:@{ NSValueTransformerNameBindingOption : @"HueToColor"}];
	[avatarImageView bind:@"backgroundColor" toObject:defaultsController withKeyPath:@"values.MyChangesSaturation" options:@{ NSValueTransformerNameBindingOption : @"SaturationToWhiteColor" }];
	
	// invisible button for now - TODO: make nice hover and things
	NSButton *button = [[NSButton alloc] initWithFrame:avatarImageView.frame];
	[button setAction:@selector(chooseImage:)];
	[button setTarget:self];
	[button setTransparent:YES];
	[avatarImageView.superview addSubview:button positioned:NSWindowAbove relativeTo:avatarImageView];
	
	self.imagePicker = ({
		IKPictureTaker *imagePicker = [IKPictureTaker pictureTaker];
		
		[imagePicker setInputImage:myImage];

		[imagePicker setValue:@(NO) forKey:IKPictureTakerAllowsVideoCaptureKey];
		[imagePicker setValue:[NSValue valueWithSize:NSMakeSize(256., 256.)] forKey:IKPictureTakerOutputImageMaxSizeKey];
		[imagePicker setValue:@(YES) forKey:IKPictureTakerShowAddressBookPictureKey];
		[imagePicker setValue:[NSImage imageNamed:NSImageNameUser] forKey:IKPictureTakerShowEmptyPictureKey];
		[imagePicker setValue:@(YES) forKey:IKPictureTakerShowEffectsKey];

		/*
		 IKPictureTakerInformationalTextKey
		 A key for informational text. The associated value is an NSString or NSAttributedString object whose default value is "Drag Image Here".
		 */
		imagePicker;
	});

	self.imagePopover = ({
		NSViewController *vc = [[NSViewController alloc] init];
		vc.view = self.imagePicker.contentView; // this is evil
		
		NSPopover *popover = [[NSPopover alloc] init];
		popover.contentViewController = vc;
		popover;
	});
}

- (void)didSelect {
	[super didSelect];
	[self.O_userColorsPreview updateViewWithUserDefaultsValues];
}

#pragma mark - Port Mapper

- (void)portMapperDidStartWork:(NSNotification *)aNotification {
    [self.O_mappingStatusProgressIndicator startAnimation:self];
    [self.O_mappingStatusImageView setHidden:YES];
    [self.O_mappingStatusTextField setStringValue:NSLocalizedString(@"Checking port status...",@"Status of port mapping while trying")];
}

- (void)portMapperDidFinishWork:(NSNotification *)aNotification {
    [self.O_mappingStatusProgressIndicator stopAnimation:self];
    // since we only have one mapping this is fine
    TCMPortMapping *mapping = [[[TCMPortMapper sharedInstance] portMappings] anyObject];
    if ([mapping mappingStatus]==TCMPortMappingStatusMapped) {
        [self.O_mappingStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        [self.O_mappingStatusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Port mapped (%d)",@"Status of Port mapping when successful"), [mapping externalPort]]];
    } else {
        [self.O_mappingStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
        [self.O_mappingStatusTextField setStringValue:NSLocalizedString(@"Port not mapped",@"Status of Port mapping when unsuccessful or intentionally unmapped")];
    }
    [self.O_mappingStatusImageView setHidden:NO];
}

#pragma mark - Me Card
- (void)TCM_setupComboBoxes {
    ABPerson *meCard = [[ABAddressBook sharedAddressBook] me];
	
	// populate email combobox
    ABMultiValue *emailAccounts = [meCard valueForProperty:kABEmailProperty];
	if ([emailAccounts propertyType] == kABMultiStringProperty)
	{
		for (NSString *emailAccountsIdentifier in emailAccounts)
		{
			NSString *email = [emailAccounts valueForIdentifier:emailAccountsIdentifier];
			[self.O_emailComboBox addItemWithObjectValue:email];
		}
	}
}

#pragma mark - Me Card - Image

// TODO: remove : MyImagePreferenceKey, [NSImage imageNamed:@"DefaultPerson"], maybe: PCRolloverImageView

- (void)updateUserWithImage:(NSImage *)anImage {
	if (anImage) {
		NSData *pngData = [[anImage resizedImageWithSize:NSMakeSize(256.,256.)] TIFFRepresentation];
		pngData = [[NSBitmapImageRep imageRepWithData:pngData] representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
		
		TCMMMUser *me = [TCMMMUserManager me];
		[[me properties] setObject:pngData forKey:@"ImageAsPNG"];
		[me recacheImages];
		[[NSUserDefaults standardUserDefaults] setObject:pngData forKey:MyImagePreferenceKey];
		anImage = [me image];
		[anImage setFlipped:NO];
		[TCMMMUserManager didChangeMe];

	} else {
		TCMMMUser *me = [TCMMMUserManager me];
		[[me properties] removeObjectForKey:@"ImageAsPNG"];
		[me recacheImages];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:MyImagePreferenceKey];
		[TCMMMUserManager didChangeMe];
	}
}

- (IBAction)chooseImage:(id)aSender {
	[self.imagePicker beginPictureTakerWithDelegate:self didEndSelector:@selector(pictureTakerDidEnd:returnCode:contextInfo:) contextInfo:nil];
	[self.imagePicker orderOut:nil];
	[self.imagePopover showRelativeToRect:NSZeroRect ofView:self.O_avatarImageView preferredEdge:NSMinXEdge];
}

#pragma mark - IKPictureTaker

- (void)pictureTakerDidEnd:(IKPictureTaker *)aPictureTaker returnCode:(NSInteger)aReturnCode contextInfo:(void *)aContextInfo {
	[self.imagePopover close];

	NSImage *image = aPictureTaker.outputImage;
	[self updateUserWithImage:image];
	[self.O_avatarImageView setImage:image];
}

#pragma mark - IBActions - Me

- (IBAction)changeName:(id)aSender {
    TCMMMUser *me=[TCMMMUserManager me];
    NSString *newValue=[self.O_nameTextField stringValue];
    if (![[me name] isEqualTo:newValue]) {
		
        CFStringRef appID = (__bridge CFStringRef)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        // Set up the preference.
        CFPreferencesSetValue((__bridge CFStringRef)MyNamePreferenceKey, (__bridge CFStringRef)newValue, appID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
        // Write out the preference data.
        CFPreferencesSynchronize(appID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		
        [me setName:newValue];
        [TCMMMUserManager didChangeMe];
		
		self.O_avatarImageView.initials = me.initials;
    }
}

- (IBAction)changeEmail:(id)aSender {
    TCMMMUser *me=[TCMMMUserManager me];
    NSString *newValue=[self.O_emailComboBox stringValue];
    if (![[[me properties] objectForKey:@"Email"] isEqualTo:newValue]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:newValue forKey:MyEmailPreferenceKey];
        ABPerson *meCard=[[ABAddressBook sharedAddressBook] me];
        ABMultiValue *emails=[meCard valueForProperty:kABEmailProperty];
        int index=0;
        int count=[emails count];
        for (index=0;index<count;index++) {
            if ([newValue isEqualToString:[emails valueAtIndex:index]]) {
                NSString *identifier=[emails identifierAtIndex:index];
                [defaults setObject:identifier forKey:MyEmailIdentifierPreferenceKey];
                break;
            }
        }
        if (count==index) {
            [defaults removeObjectForKey:MyEmailIdentifierPreferenceKey];
        }
        [[me properties] setObject:newValue forKey:@"Email"];
        [TCMMMUserManager didChangeMe];
    }
}

- (IBAction)updateChangesColor:(id)sender {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];

    NSNumber *userHue = [defaults objectForKey:MyColorHuePreferenceKey];
    [[TCMMMUserManager me] setUserHue:userHue];
    [TCMMMUserManager didChangeMe];
	
	// check if needed?
    [defaults setObject:[defaults objectForKey:ChangesSaturationPreferenceKey] forKey:ChangesSaturationPreferenceKey];
    [defaults setObject:[defaults objectForKey:SelectionSaturationPreferenceKey] forKey:SelectionSaturationPreferenceKey];
	
	[self postGeneralViewPreferencesDidChangeNotificiation:self];
}

#pragma mark - View Update Notification
- (void)TCM_sendGeneralViewPreferencesDidChangeNotificiation {
    [[NSNotificationQueue defaultQueue]
	 enqueueNotification:[NSNotification notificationWithName:GeneralViewPreferencesDidChangeNotificiation object:self]
	 postingStyle:NSPostWhenIdle
	 coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
	 forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (IBAction)postGeneralViewPreferencesDidChangeNotificiation:(id)aSender {
    [self TCM_sendGeneralViewPreferencesDidChangeNotificiation];
}

#pragma mark - IBActions - Port Mapping
- (IBAction)changeAutomaticallyMapPorts:(id)aSender {
    BOOL shouldStart = ([self.O_automaticallyMapPortButton state]==NSOnState);
    [[NSUserDefaults standardUserDefaults] setBool:shouldStart forKey:ShouldAutomaticallyMapPort];
    if (shouldStart) {
        [[TCMPortMapper sharedInstance] start];
    } else {
        [[TCMPortMapper sharedInstance] stop];
    }
}

- (IBAction)changeDisableNetworking:(id)aSender {
	[TCMMMBEEPSessionManager sharedInstance].networkingDisabled = [self.O_disableNetworkingButton state] == NSOnState ? YES : NO;
}

- (IBAction)changeVisiblityOnNetwork:(id)aSender {
	[[TCMMMPresenceManager sharedInstance] setVisible:[self.O_invisibleOnNetowrkButton state] == NSOffState ? YES : NO];
}


#pragma mark - Localization
- (NSString *)localizedNetworkBoxLabelText {
	NSString *string = NSLocalizedStringWithDefaultValue(@"COLLAB_NETWORK_LABEL", nil, [NSBundle mainBundle],
														 @"Network",
														 @"Collaboration Preferences - Label for the network box");
	return string;
}

- (NSString *)localizedLocalPortLabelText {
	NSString *string = NSLocalizedStringWithDefaultValue(@"COLLAB_LOCAL_PORT_LABEL", nil, [NSBundle mainBundle],
														 @"Local Port:",
														 @"Collaboration Preferences - Label for the local port");
	return string;
}

- (NSString *)localizedAutomaticallyMapPortsLabelText {
	NSString *string = NSLocalizedStringWithDefaultValue(@"COLLAB_AUTOMATICALLY_MAP_PORT_LABEL", nil, [NSBundle mainBundle],
														 @"Automatically map port",
														 @"Collaboration Preferences - Label for the automatically map port toggle");
	return string;
}

- (NSString *)localizedAutomaticallyMapPortsExplanationText {
	NSString *string = NSLocalizedStringWithDefaultValue(@"COLLAB_AUTOMATICALLY_MAP_PORT_DESCRIPTION", nil, [NSBundle mainBundle],
														 @"NAT traversal uses either NAT-PMP or UPnP",
														 @"Collaboration Preferences - Label with additional description for the automatically map port toggle");
	return string;
}

- (NSString *)localizedAutomaticallyMapPortsToolTipText {
	NSString *string = NSLocalizedStringWithDefaultValue(@"COLLAB_AUTOMATICALLY_MAP_PORT_TOOL_TIP", nil, [NSBundle mainBundle],
														 @"SubEthaEdit will try to automatically map the local port to an external port if it is behind a NAT. For this to work you have to enable UPnP or NAT-PMP on your router.",
														 @"Collaboration Preferences - tool tip for the automatically map port toggle");
	return string;
}


// me card related
- (NSString *)localizedUserNameLabel {
	NSString *string = NSLocalizedStringWithDefaultValue(@"COLLAB_USER_NAME_LABEL", nil, [NSBundle mainBundle],
														 @"Name:",
														 @"Collaboration Preferences - Label for the user name text field");
	return string;
}

- (NSString *)localizedUserEmailLabel {
	NSString *string = NSLocalizedStringWithDefaultValue(@"COLLAB_USER_EMAIL_LABEL", nil, [NSBundle mainBundle],
														 @"Email:",
														 @"Collaboration Preferences - Label for the user email text field");
	return string;
}


- (NSString *)localizedImageMenuAddressBook {
	NSString *string = NSLocalizedStringWithDefaultValue(@"COLLAB_USER_IMAGE_AB", nil, [NSBundle mainBundle],
														 @"Use Address Book",
														 @"Collaboration Preferences - Image Menu - Use Image from Address Book option");
	return string;
}

- (NSString *)localizedImageMenuChoose {
	NSString *string = NSLocalizedStringWithDefaultValue(@"COLLAB_USER_IMAGE_CHOOSE", nil, [NSBundle mainBundle],
														 @"Choose Image...",
														 @"Collaboration Preferences - Image Menu - Choose Image option");
	return string;
}

- (NSString *)localizedImageMenuClear {
	NSString *string = NSLocalizedStringWithDefaultValue(@"COLLAB_USER_IMAGE_CLEAR", nil, [NSBundle mainBundle],
														 @"Clear Image",
														 @"Collaboration Preferences - Image Menu - Clear Image option");
	return string;
}

@end
