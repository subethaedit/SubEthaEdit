//
//  RendezvousBrowserController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "RendezvousBrowserController.h"
#import "TCMRendezvousBrowser.h"

@implementation RendezvousBrowserController
- (id)init {
    if ((self=[super init])) {
        I_tableData=[NSMutableArray new];
        I_browser=[[TCMRendezvousBrowser alloc] initWithServiceType:@"_emac._tcp." domain:@""];
        [I_browser setDelegate:self];
        [I_browser startSearch];
    }
    return self;
}

- (void)dealloc {
    [I_tableData release];
    [super dealloc];
}

- (NSString *)windowNibName {
    return @"RendezvousBrowser";
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
    [I_tableData addObject:[NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@%@",[aNetService name],[aNetService domain]] forKey:@"serviceName"]];
    [self setTableData:[self tableData]];
}
- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didResolveService:(NSNetService *)aNetService {
    [I_tableData addObject:[NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"resolved %@%@",[aNetService name],[aNetService domain]] forKey:@"serviceName"]];
    [self setTableData:[self tableData]];
}
- (void)rendezvousBrowser:(TCMRendezvousBrowser *)aBrowser didRemoveResolved:(BOOL)wasResolved service:(NSNetService *)aNetService {
    NSLog(@"Removed Service: %@",aNetService);
}



@end
