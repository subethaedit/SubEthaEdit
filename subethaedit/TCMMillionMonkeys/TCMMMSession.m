//
//  TCMMMSession.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "../TCMBEEP/TCMBEEP.h"
#import "TCMMMSession.h"
#import "TCMBencodingUtilities.h"
#import "TCMMMUserManager.h"
#import "TCMMMBEEPSessionManager.h"
#import "TCMMMUser.h"
#import "TCMMMState.h"
#import "TCMMMOperation.h"
#import "TextOperation.h"
#import "SessionProfile.h"
#import "PlainTextDocument.h"
#import "DocumentController.h"
#import "TextStorage.h"
#import "SelectionOperation.h"
#import "UserChangeOperation.h"


NSString * const TCMMMSessionParticipantsDidChangeNotification = 
               @"TCMMMSessionParticipantsDidChangeNotification";
NSString * const TCMMMSessionPendingUsersDidChangeNotification = 
               @"TCMMMSessionPendingUsersDidChangeNotification";
NSString * const TCMMMSessionDidChangeNotification = 
               @"TCMMMSessionDidChangeNotification";


@interface TCMMMSession (TCMMMSessionPrivateAdditions)

- (NSDictionary *)TCM_sessionInformation;
- (void)TCM_setSessionParticipants:(NSDictionary *)aParticipants;

@end

#pragma mark -

@implementation TCMMMSession

- (void)TCM_sendSessionDidChangeNotification {
    [[NSNotificationQueue defaultQueue] 
    enqueueNotification:[NSNotification notificationWithName:TCMMMSessionDidChangeNotification object:self]
           postingStyle:NSPostWhenIdle 
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (void)TCM_sendParticipantsDidChangeNotification {
    [[NSNotificationQueue defaultQueue] 
    enqueueNotification:[NSNotification notificationWithName:TCMMMSessionParticipantsDidChangeNotification object:self]
           postingStyle:NSPostWhenIdle 
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}


+ (TCMMMSession *)sessionWithBencodedSession:(NSData *)aData
{
    NSDictionary *sessionDict=TCM_BdecodedObjectWithData(aData);
    TCMMMSession *session = [[TCMMMSession alloc] initWithSessionID:[NSString stringWithUUIDData:[sessionDict objectForKey:@"sID"]] filename:[sessionDict objectForKey:@"name"]];
    [session setHostID:[NSString stringWithUUIDData:[sessionDict objectForKey:@"hID"]]];
    [session setAccessState:[[sessionDict objectForKey:@"acc"] intValue]];
    return [session autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        I_participants = [NSMutableDictionary new];
        I_sessionContentForUserID = [NSMutableDictionary new];
        I_profilesByUserID = [NSMutableDictionary new];
        I_pendingUsers = [NSMutableArray new];
        I_groupByUserID = [NSMutableDictionary new];
        I_contributors = [NSMutableSet new];
        I_statesByClientID = [NSMutableDictionary new];
        I_closingProfiles = [NSMutableArray new];
        I_closingStates   = [NSMutableArray new];
        I_flags.shouldSendJoinRequest = NO;
        I_flags.isServer = NO;
    }
    return self;
}

- (id)initWithDocument:(NSDocument *)aDocument
{
    self = [self init];
    if (self) {
        [self setDocument:aDocument];
        [self setSessionID:[NSString UUIDString]];
        [self setFilename:[aDocument displayName]];
        [self setHostID:[TCMMMUserManager myUserID]];
        TCMMMUser *me=[TCMMMUserManager me];
        [I_contributors addObject:me];
        [I_participants setObject:[NSMutableArray arrayWithObject:me] forKey:@"ReadWrite"];
        [I_groupByUserID setObject:@"ReadWrite" forKey:[me userID]];
        [self setIsServer:YES];
    }
    return self;
}

- (id)initWithSessionID:(NSString *)aSessionID filename:(NSString *)aFileName
{
    self = [self init];
    if (self) {
        [self setSessionID:aSessionID];
        [self setFilename:aFileName];
        [self setAccessState:TCMMMSessionAccessLockedState];
    }
    return self;
}

- (void)dealloc
{
    I_document = nil;
    [I_sessionID release];
    [I_hostID release];
    [I_filename release];
    [[I_profilesByUserID allValues]makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
    [I_profilesByUserID release];
    [I_closingProfiles makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
    [I_participants release];
    [I_closingStates makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
    [I_closingStates release];
    [I_sessionContentForUserID release];
    [I_contributors release];
    [I_pendingUsers release];
    [I_groupByUserID release];
    [[I_statesByClientID allValues] makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
    [I_statesByClientID release];
    [super dealloc];
}

#pragma mark -
#pragma ### Accessors ###

- (NSString *)description
{
    return [NSString stringWithFormat:@"sessionID: %@, filename: %@", [self sessionID], [self filename]];
}

- (void)setFilename:(NSString *)aFilename
{
    [I_filename autorelease];
    BOOL changed=![I_filename isEqualToString:aFilename];
    I_filename = [aFilename copy];
    if (changed) [self TCM_sendSessionDidChangeNotification];
}

- (NSString *)filename
{
    return I_filename;
}

- (void)setSessionID:(NSString *)aSessionID
{
    [I_sessionID autorelease];
    I_sessionID = [aSessionID copy];
}

- (NSString *)sessionID
{
    return I_sessionID;
}

- (void)setHostID:(NSString *)aHostID
{
    [I_hostID autorelease];
     I_hostID = [aHostID copy];
}

- (NSString *)hostID
{
    return I_hostID;
}

- (void)setDocument:(NSDocument *)aDocument
{
    I_document = aDocument;
}

- (NSDocument *)document
{
    return I_document;
}

- (void)setIsServer:(BOOL)isServer
{
    I_flags.isServer = isServer;
}

- (BOOL)isServer
{
    return I_flags.isServer;
}

- (NSDictionary *)participants {
    return I_participants;
}

- (NSArray *)pendingUsers {
    return I_pendingUsers;
}

- (void)setAccessState:(TCMMMSessionAccessState)aState {
    I_accessState=aState;
    [self TCM_sendSessionDidChangeNotification];
}

- (TCMMMSessionAccessState)accessState {
    return I_accessState;
}

#pragma mark -

- (void)documentDidApplyOperation:(TCMMMOperation *)anOperation {
    NSEnumerator *states = [I_statesByClientID objectEnumerator];
    TCMMMState *state;
    while ((state = [states nextObject])) {
        [state handleOperation:anOperation];
    }
}

#pragma mark -

- (void)setGroup:(NSString *)aGroup forPendingUsersWithIndexes:(NSIndexSet *)aSet {
    if ([aGroup isEqualToString:@"PoofGroup"]) {
        NSMutableIndexSet *set = [aSet mutableCopy];
        unsigned index;
        while ((index = [set firstIndex]) != NSNotFound) {
            TCMMMUser *user = [I_pendingUsers objectAtIndex:index];
            SessionProfile *profile=[I_profilesByUserID objectForKey:[user userID]];
            [profile denyJoin];
            [I_closingProfiles addObject:profile];
            [I_profilesByUserID removeObjectForKey:[user userID]];
            [set removeIndex:index];
        }
        [set release];
    } else {
        NSMutableIndexSet *set = [aSet mutableCopy];
        unsigned index;
        while ((index = [set firstIndex]) != NSNotFound) {
            TCMMMUser *user = [I_pendingUsers objectAtIndex:index];
            [I_groupByUserID setObject:aGroup forKey:[user userID]];
            if (![I_participants objectForKey:aGroup]) {
                [I_participants setObject:[NSMutableArray array] forKey:aGroup];
            }
            [[I_participants objectForKey:aGroup] addObject:user];
            [I_contributors addObject:user];
            [self documentDidApplyOperation:[UserChangeOperation userChangeOperationWithType:UserChangeTypeJoin user:user newGroup:aGroup]];
            SessionProfile *profile = [I_profilesByUserID objectForKey:[user userID]];
            TCMMMState *state = [[TCMMMState alloc] initAsServer:YES];
            [state setDelegate:self];
            [state setClient:profile];
            [I_statesByClientID setObject:state forKey:[user userID]];
            [profile setMMState:state];
            [profile acceptJoin];
            [profile sendSessionInformation:[self TCM_sessionInformation]];
            PlainTextDocument *document=(PlainTextDocument *)[self document];
            [I_sessionContentForUserID setObject:[NSDictionary dictionaryWithObject:[(TextStorage *)[document textStorage] dictionaryRepresentation] forKey:@"TextStorage"] forKey:[user userID]];
            [document sendInitialUserState];
            [state release];
            [user joinSessionID:[self sessionID]];
            NSMutableDictionary *properties=[user propertiesForSessionID:[self sessionID]];
            [properties setObject:[SelectionOperation selectionOperationWithRange:NSMakeRange(0,0) userID:[user userID]] forKey:@"SelectionOperation"];
            [set removeIndex:index];
        }
        [set release];
    }
    
    NSMutableIndexSet *set = [aSet mutableCopy];
    unsigned index;
    while ((index = [set lastIndex]) != NSNotFound) {
        [I_pendingUsers removeObjectAtIndex:index];
        [set removeIndex:index];
    }
    [set release];
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMSessionPendingUsersDidChangeNotification object:self];
}

/*"Data needed:
    Filename - the actual current filename of the session
    SessionID - the UUID of the session
    HostID - the userID of the Host of the session
    Access - NSNumber with TCMMMSessionAccessState
"*/

- (NSData *)sessionBencoded
{
    return TCM_BencodedObject([self dictionaryRepresentation]);
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *sessionDict = [NSMutableDictionary dictionary];
    [sessionDict setObject:[self filename] forKey:@"name"];
    [sessionDict setObject:[NSData dataWithUUIDString:[self sessionID]] forKey:@"sID"];
    [sessionDict setObject:[NSData dataWithUUIDString:[self hostID]] forKey:@"hID"];
    [sessionDict setObject:[NSNumber numberWithInt:I_accessState] forKey:@"acc"];
    return sessionDict;
}

- (void)joinUsingBEEPSession:(TCMBEEPSession *)aBEEPSession
{
    PlainTextDocument *document=(PlainTextDocument *)[self document];
    if (document) {
        [document showWindows];
    } else {
        [[DocumentController sharedInstance] addProxyDocumentWithSession:self];
        TCMBEEPSession *session = aBEEPSession;
        if (!session) {
            session = [[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:[self hostID]];
        }
        I_flags.shouldSendJoinRequest=YES;
        [session startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"] andData:nil sender:self];
    }
}

- (void)cancelJoin {
    SessionProfile *profile = [I_profilesByUserID objectForKey:[self hostID]];
    [profile cancelJoin];
    [profile setDelegate:nil];
    [I_profilesByUserID removeObjectForKey:[self hostID]];
    I_flags.shouldSendJoinRequest = NO;
}

- (void)leave {
    if (![self isServer]) {
        SessionProfile *profile = [I_profilesByUserID objectForKey:[self hostID]];
        if (profile) {
            TCMMMState *state=[I_statesByClientID objectForKey:[self hostID]];
            [I_closingProfiles addObject:profile];
            [I_closingStates addObject:state];
            [state handleOperation:[UserChangeOperation userChangeOperationWithType:UserChangeTypeLeave userID:[TCMMMUserManager myUserID] newGroup:@""]];
            [state setDelegate:nil];
            [profile close];
            [I_participants removeAllObjects];
            [I_contributors removeAllObjects];
            [I_profilesByUserID removeObjectForKey:[self hostID]];
            [I_statesByClientID removeObjectForKey:[self hostID]];
            [[TCMMMUserManager me] leaveSessionID:[self sessionID]];
        }
    }
}

- (void)inviteUserWithID:(NSString *)aUserID
{
    // merk invited userID
    
    TCMBEEPSession *session = [[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:[self hostID]];
    [session startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"] andData:nil sender:self];
}

#pragma mark -

- (NSDictionary *)TCM_sessionInformation
{
    NSMutableDictionary *sessionInformation=[NSMutableDictionary dictionary];
    NSMutableArray *contributorNotifications=[NSMutableArray array];
    NSEnumerator *contributors = [I_contributors objectEnumerator];
    TCMMMUser *contributor=nil;
    while ((contributor=[contributors nextObject])) {
        [contributorNotifications addObject:[contributor notification]];
    }
    [sessionInformation setObject:contributorNotifications forKey:@"Contributors"];
    NSMutableDictionary *participantsRepresentation=[NSMutableDictionary dictionary];
    NSEnumerator *groups=[I_participants keyEnumerator];
    NSString *group = nil;
    while ((group = [groups nextObject])) {
        NSEnumerator *users=[[I_participants objectForKey:group] objectEnumerator];
        NSMutableArray *userRepresentations=[NSMutableArray array];
        TCMMMUser *user=nil;
        while ((user=[users nextObject])) {
            [userRepresentations addObject:[NSDictionary dictionaryWithObjectsAndKeys:[user notification],@"User",[NSDictionary dictionary],@"SessionProperties",nil]];
        }
        [participantsRepresentation setObject:userRepresentations forKey:group];
    }
    [sessionInformation setObject:participantsRepresentation forKey:@"Participants"];
    [sessionInformation setObject:[[self document] sessionInformation] forKey:@"DocumentSessionInformation"];
    return sessionInformation;
}

- (void)TCM_setSessionParticipants:(NSDictionary *)aParticipants
{
    TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
    NSEnumerator *groups=[aParticipants keyEnumerator];
    NSString *group = nil;
    while ((group = [groups nextObject])) {
        NSMutableArray *groupArray=[I_participants objectForKey:group];
        if (groupArray == nil) {
            groupArray = [NSMutableArray array];
            [I_participants setObject:groupArray forKey:group];
        }
        NSEnumerator *users=[[aParticipants objectForKey:group] objectEnumerator];
        NSDictionary *userDict=nil;
        while ((userDict=[users nextObject])) {
            TCMMMUser *user=[userManager userForUserID:[[TCMMMUser userWithNotification:[userDict objectForKey:@"User"]] userID]];
            NSString *userID=[user userID];
            NSString *sessionID=[self sessionID];
            NSMutableDictionary *properties=[user propertiesForSessionID:sessionID];
            if (!properties) {
                [user joinSessionID:sessionID];
                properties=[user propertiesForSessionID:sessionID];
            }
            [properties setObject:[SelectionOperation selectionOperationWithRange:NSMakeRange(0,0) userID:userID] forKey:@"SelectionOperation"];
            [groupArray addObject:user];
            [I_groupByUserID setObject:group forKey:userID];
        }
    }
}

#pragma mark -
#pragma mark ### profile interaction ###
// When you request a profile you have to implement BEEPSession:didOpenChannelWithProfile: to receive the profile
- (void)BEEPSession:(TCMBEEPSession *)session didOpenChannelWithProfile:(TCMBEEPProfile *)profile
{
    // check if invitation or join is happening
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"BEEPSession:%@ didOpenChannel: %@", session, profile);
    if (I_flags.shouldSendJoinRequest) {
        [I_profilesByUserID setObject:profile forKey:[self hostID]];
        [profile setDelegate:self];
        [(SessionProfile *)profile sendJoinRequestForSessionID:[self sessionID]];
        I_flags.shouldSendJoinRequest=NO;
    } else {
        [[profile channel] close];
    }
}

# pragma mark -

- (void)joinRequestWithProfile:(SessionProfile *)profile
{        
    NSString *peerUserID = [[[profile session] userInfo] objectForKey:@"peerUserID"];
    [I_profilesByUserID setObject:profile forKey:peerUserID];
    // decide if autojoin depending on setting
    
    // if no autojoin add user to pending users and notify 
    [I_pendingUsers addObject:[[TCMMMUserManager sharedInstance] userForUserID:peerUserID]];
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMSessionPendingUsersDidChangeNotification object:self];
    [[NSSound soundNamed:@"Knock"] play];
}

- (void)invitationWithProfile:(SessionProfile *)profile
{
}

# pragma mark -

- (void)profileDidCancelJoinRequest:(SessionProfile *)aProfile {
    NSString *peerUserID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    [aProfile setDelegate:nil];
    [I_profilesByUserID removeObjectForKey:peerUserID];
    [I_pendingUsers removeObject:[[TCMMMUserManager sharedInstance] userForUserID:peerUserID]];
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMSessionPendingUsersDidChangeNotification object:self];
}

- (void)profile:(SessionProfile *)profile didReceiveSessionContent:(id)aContent {
    [[self document] setContentByDictionaryRepresentation:aContent];
}

- (void)profileDidDenyJoinRequest:(SessionProfile *)aProfile
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"profileDidAcceptJoinRequest: %@", aProfile);
    NSString *peerUserID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    [[self document] sessionDidDenyJoinRequest:self];
    [I_closingProfiles addObject:aProfile];
    [I_profilesByUserID removeObjectForKey:peerUserID];
}

- (void)profileDidAcceptJoinRequest:(SessionProfile *)profile
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"profileDidAcceptJoinRequest: %@", profile);
    [[self document] sessionDidAcceptJoinRequest:self];
    TCMMMState *state=[[TCMMMState alloc] initAsServer:NO];
    [state setDelegate:self];
    [state setClient:profile];
    [profile setMMState:state];
    [I_statesByClientID setObject:state forKey:[[[profile session] userInfo] objectForKey:@"peerUserID"]];
    [state release];
}

- (NSArray *)profile:(SessionProfile *)profile userRequestsForSessionInformation:(NSDictionary *)sessionInfo
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"profile:userRequestsForSessionInformation:");
    
    NSArray *contributors=[sessionInfo objectForKey:@"Contributors"];
    NSMutableArray *result=[NSArray array];
    NSEnumerator *users=[contributors objectEnumerator];
    NSDictionary *userNotification;
    TCMMMUser *user=nil;
    TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
    while ((userNotification=[users nextObject])) {
        user=[TCMMMUser userWithNotification:userNotification];
        if ([userManager sender:profile shouldRequestUser:user]) {
            [result addObject:userNotification];
        }
        [I_contributors addObject:user];
    }

    [self TCM_setSessionParticipants:[sessionInfo objectForKey:@"Participants"]];

    [[self document] session:self didReceiveSessionInformation:[sessionInfo objectForKey:@"DocumentSessionInformation"]];

    return result;
}

- (void)profile:(SessionProfile *)aProfile didReceiveUserRequests:(NSArray *)aUserRequestArray
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"profile:didReceiveUserRequests:");
    NSEnumerator *userRequests=[aUserRequestArray objectEnumerator]; 
    TCMMMUser *user=nil;
    TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
    while ((user=[userRequests nextObject])) {
        [aProfile sendUser:[userManager userForUserID:[user userID]]];
    }
    NSString *peerUserID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    [aProfile sendSessionContent:[[[I_sessionContentForUserID objectForKey:peerUserID] retain] autorelease]];
    [I_sessionContentForUserID removeObjectForKey:peerUserID];
}

- (void)profileDidClose:(TCMBEEPProfile *)aProfile {
    SessionProfile *profile=(SessionProfile *)aProfile;
    TCMMMState *state=[profile MMState];
    if (state) {
        [[state retain] autorelease];
        [I_closingStates removeObject:state];
        [state setClient:nil];
    }
    [profile setDelegate:nil];
    [I_closingProfiles removeObject:profile];
    if ([[I_profilesByUserID allValues] containsObject:aProfile]) {
        // handle well
    }
}


#pragma mark -
#pragma ### State interaction ###

- (void)handleUserChangeOperation:(UserChangeOperation *)anOperation fromState:(TCMMMState *)aState {
    if ([anOperation type]==UserChangeTypeJoin) {
        NSString *group=[anOperation newGroup];
        NSString *userID=[anOperation userID];
        TCMMMUser *userNotification=[anOperation user];
        TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
        if ([userManager sender:self shouldRequestUser:userNotification]) {
            SessionProfile *profile=(SessionProfile *)[aState client];
            [profile sendUserRequest:[userNotification notification]];
        }
        TCMMMUser *user=[userManager userForUserID:userID];
        [[I_participants objectForKey:group] addObject:user];
        [I_groupByUserID setObject:group forKey:userID];
        [user joinSessionID:[self sessionID]];
        NSMutableDictionary *properties=[user propertiesForSessionID:[self sessionID]];
        [properties setObject:[SelectionOperation selectionOperationWithRange:NSMakeRange(0,0) userID:[user userID]] forKey:@"SelectionOperation"];
        
        [self TCM_sendParticipantsDidChangeNotification];
    } else if ([anOperation type]==UserChangeTypeLeave) {
        NSString *userID=[anOperation userID];
        TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:userID];
        NSString *group=[I_groupByUserID objectForKey:userID];
        [I_groupByUserID removeObjectForKey:userID];
        [[I_participants objectForKey:group] removeObject:user];
        TCMMMState *state=[I_statesByClientID objectForKey:userID];
        [state setDelegate:nil];
        [I_closingStates addObject:state];
        [I_statesByClientID removeObjectForKey:userID];
        SessionProfile *profile=[I_profilesByUserID objectForKey:userID];
        [I_closingProfiles addObject:profile];
        [user leaveSessionID:[self sessionID]];
        [self TCM_sendParticipantsDidChangeNotification];
    } else {
        NSLog(@"Got UserChangeOperation: %@",[anOperation description]);
    }
}

- (void)state:(TCMMMState *)aState handleOperation:(TCMMMOperation *)anOperation {

    // NSLog(@"state:%@ handleOperation:%@",aState,anOperation);
    if ([[[anOperation class] operationID] isEqualToString:[UserChangeOperation operationID]]) {
        [self handleUserChangeOperation:(UserChangeOperation *)anOperation fromState:aState];
    } else {
        [(PlainTextDocument *)[self document] handleOperation:anOperation];
    }
    // distribute operation
    NSEnumerator *states = [I_statesByClientID objectEnumerator];
    TCMMMState *state;
    while ((state = [states nextObject])) {
        if (state == aState) {
            continue;
        }
        
        [state handleOperation:anOperation];
    }
}

@end
