//
//  RendezvousBrowserController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "RendezvousBrowserController.h"
#import "TCMRendezvousBrowser.h"
#import "TCMMMPresenceManager.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"

@implementation RendezvousBrowserController
- (id)init {
    if ((self=[super init])) {
        I_tableData=[NSMutableArray new];
        I_browser=[[TCMRendezvousBrowser alloc] initWithServiceType:@"_emac._tcp." domain:@""];
        [I_browser setDelegate:self];
        [I_browser startSearch];
        I_foundUserIDs=[NSMutableSet new];
    }
    return self;
}

- (void)dealloc {
    [I_foundUserIDs release];
    [I_tableData release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"RendezvousBrowser";
}

- (void)windowDidLoad {
    [[self window] setFrameAutosaveName:@"RendezvousBrowser"];
    TCMMMUser *me=[TCMMMUserManager me];
    [I_myNameTextField setStringValue:[me name]];
    [I_imageView setImage:[[me properties] objectForKey:@"Image"]];
    [((NSPanel *)[self window]) setFloatingPanel:NO];
    [[self window] setHidesOnDeactivate:NO];
}

-(NSMutableArray *)tableData {
    return I_tableData;
}
-(void)setTableData:(NSMutableArray *)tableData {
    [I_tableData autorelease];
    I_tableData=[tableData mutableCopy];
}


#pragma mark -
#pragma mark ### TCMRendezvousBrowser Delegate ###
- (void)rendezvousBrowserWillSearch:(TCMRendezvousBrowser *)aBrowser {

}
- (void)rendezvousBrowserDidStopSearch:(TCMRendezvousBrowser *)aBrowser {

}
- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didNotSearch:(NSError *)anError {
    NSLog(@"Mist: %@",anError);
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didFindService:(NSNetService *)aNetService {
    NSLog(@"foundservice: %@",aNetService);
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didResolveService:(NSNetService *)aNetService {
//    [I_tableData addObject:[NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"resolved %@%@",[aNetService name],[aNetService domain]] forKey:@"serviceName"]];
    NSString *userID = [[aNetService TXTRecordDictionary] objectForKey:@"userid"];
    if (userID && ![userID isEqualTo:[TCMMMUserManager myID]]) {
        [I_foundUserIDs addObject:userID];
        [[TCMMMPresenceManager sharedInstance] statusConnectToNetService:aNetService userID:userID sender:self];
    }
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didRemoveResolved:(BOOL)wasResolved service:(NSNetService *)aNetService {
    NSLog(@"Removed Service: %@",aNetService);
}

#pragma mark -
#pragma mark ### TCMMMPresenceManager Notifications ###

- (void)userChangedAvailability:(NSNotification *)aNotification {

}

- (void)userChangedAnnouncedDocuments:(NSNotification *)aNotification {

}

@end
