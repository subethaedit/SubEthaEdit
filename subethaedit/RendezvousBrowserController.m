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
#import "TCMMMBEEPSessionManager.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"

@implementation RendezvousBrowserController
- (id)init {
    if ((self=[super initWithWindowNibName:@"RendezvousBrowser"])) {
        I_tableData=[NSMutableArray new];
        I_browser=[[TCMRendezvousBrowser alloc] initWithServiceType:@"_emac._tcp." domain:@""];
        [I_browser setDelegate:self];
        [I_browser startSearch];
        I_foundUserIDs=[NSMutableSet new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeVisibility:) name:TCMMMPresenceManagerUserVisibilityDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [I_foundUserIDs release];
    [I_tableData release];
    [super dealloc];
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

- (IBAction)setVisibilityByPopUpButton:(id)aSender {
    [[TCMMMPresenceManager sharedInstance] setVisible:([aSender indexOfSelectedItem]==0)];
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
        [[TCMMMBEEPSessionManager sharedInstance] connectToNetService:aNetService];
    }
}

- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didRemoveResolved:(BOOL)wasResolved service:(NSNetService *)aNetService {
    NSLog(@"Removed Service: %@",aNetService);
}

#pragma mark -
#pragma mark ### TCMMMPresenceManager Notifications ###

- (void)userDidChangeVisibility:(NSNotification *)aNotification {
    NSDictionary *userInfo=[aNotification userInfo];
    NSString *userID=[userInfo objectForKey:@"UserID"];
    TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForID:userID];
    if ([[userInfo objectForKey:@"isVisible"] boolValue]) {
        [I_tableData addObject:user];
    } else {
        [I_tableData removeObject:user];
    }
    [self setTableData:I_tableData];
}

- (void)userChangedAnnouncedDocuments:(NSNotification *)aNotification {

}

@end
