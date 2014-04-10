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

#import "TCMMMBEEPSessionManager.h"
#import <TCMPortMapper/TCMPortMapper.h>

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

    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];

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
	
	// TODO

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

#pragma mark - IBAction
- (IBAction)changeAutomaticallyMapPorts:(id)aSender {
    BOOL shouldStart = ([self.O_automaticallyMapPortButton state]==NSOnState);
    [[NSUserDefaults standardUserDefaults] setBool:shouldStart forKey:ShouldAutomaticallyMapPort];
    if (shouldStart) {
        [[TCMPortMapper sharedInstance] start];
    } else {
        [[TCMPortMapper sharedInstance] stop];
    }
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

@end
