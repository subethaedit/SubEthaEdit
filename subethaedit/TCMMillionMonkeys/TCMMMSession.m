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
#import "time.h"


#define kProcessingTime 0.5
#define kWaitingTime 0.1


NSString * const TCMMMSessionParticipantsDidChangeNotification = 
               @"TCMMMSessionParticipantsDidChangeNotification";
NSString * const TCMMMSessionPendingUsersDidChangeNotification = 
               @"TCMMMSessionPendingUsersDidChangeNotification";
NSString * const TCMMMSessionDidChangeNotification = 
               @"TCMMMSessionDidChangeNotification";
NSString * const TCMMMSessionClientStateDidChangeNotification = 
               @"TCMMMSessionClientStateDidChangeNotification";
NSString * const TCMMMSessionDidReceiveContentNotification = 
               @"TCMMMSessionDidReceiveContentNotification";


@interface TCMMMSession (TCMMMSessionPrivateAdditions)

- (NSDictionary *)TCM_sessionInformationForUserID:(NSString *)aUserID;
- (void)TCM_setSessionParticipants:(NSDictionary *)aParticipants;
- (void)triggerPerformRoundRobin;
- (void)processRoundRobinMessageProcessing;

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
           postingStyle:NSPostASAP
           coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
               forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}


+ (TCMMMSession *)sessionWithBencodedSession:(NSData *)aData
{
    NSDictionary *sessionDict=TCM_BdecodedObjectWithData(aData);
    return [self sessionWithDictionaryRepresentation:sessionDict]; 
}

+ (TCMMMSession *)sessionWithDictionaryRepresentation:(NSDictionary *)aDictionary {
    TCMMMSession *session = [[TCMMMSession alloc] initWithSessionID:[NSString stringWithUUIDData:[aDictionary objectForKey:@"sID"]] filename:[aDictionary objectForKey:@"name"]];
    [session setHostID:[NSString stringWithUUIDData:[aDictionary objectForKey:@"hID"]]];
    [session setAccessState:[[aDictionary objectForKey:@"acc"] intValue]];
    return [session autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        I_invitedUsers = [NSMutableDictionary new];
        I_groupOfInvitedUsers = [NSMutableDictionary new];
        I_stateOfInvitedUsers = [NSMutableDictionary new];
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
        I_flags.isPerformingRoundRobin = NO;
        I_flags.isPaused = NO;
        [self setIsServer:NO];
        [self setClientState:TCMMMSessionClientNoState];
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
        [self setClientState:TCMMMSessionClientNoState];
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
    [I_invitedUsers release];
    [I_groupOfInvitedUsers release];
    [I_stateOfInvitedUsers release];
    [I_sessionID release];
    [I_hostID release];
    [I_filename release];
    [[I_profilesByUserID allValues]makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
    [I_profilesByUserID release];
    [I_closingProfiles makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
    [I_closingProfiles release];
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

- (void)cleanupParticipants {
    NSString *sessionID=[self sessionID];
    NSString *userID;
    NSEnumerator *participantIDs=[[I_groupByUserID allKeys] objectEnumerator];
    TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
    while ((userID=[participantIDs nextObject])) {
        TCMMMUser *user=[userManager userForUserID:userID];
        SelectionOperation *selectionOperation=[[user propertiesForSessionID:sessionID] objectForKey:@"SelectionOperation"];
        if (selectionOperation) {
            [(PlainTextDocument *)[self document] invalidateLayoutForRange:[selectionOperation selectedRange]];
        }
        [user leaveSessionID:sessionID];
    }
    [I_participants removeAllObjects];
    [I_groupByUserID removeAllObjects];
//    [I_invitedUsers removeAllObjects];
//    [I_groupOfInvitedUsers removeAllObjects];
}

- (void)detachStateAndProfileForUserWithID:(NSString *)aUserID {
    TCMMMState *state=[I_statesByClientID objectForKey:aUserID];
    if (state) {
        [state setDelegate:nil];
        [I_closingStates addObject:state];
        [I_statesByClientID removeObjectForKey:aUserID];
    }
    SessionProfile *profile=[I_profilesByUserID objectForKey:aUserID];
    if (profile) {
        [I_closingProfiles addObject:profile];
        [I_profilesByUserID removeObjectForKey:aUserID];
    }
}

#pragma mark -
#pragma ### Accessors ###

- (NSString *)description
{
    return [NSString stringWithFormat:@"sessionID: %@, filename: %@, hostID:%@, isServer:%@", [self sessionID], [self filename],[self hostID],[self isServer]?@"YES":@"NO"];
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
    [self setIsServer:[I_hostID isEqualToString:[TCMMMUserManager myUserID]]];
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

- (void)setWasInvited:(BOOL)wasInvited {
    I_flags.wasInvited=wasInvited;
}

- (BOOL)wasInvited {
    return I_flags.wasInvited;
}

- (unsigned int)participantCount {
    return [I_groupByUserID count];
}

- (NSDictionary *)invitedUsers {
    return I_invitedUsers;
}

- (NSString *)stateOfInvitedUserById:(NSString *)aUserID {
    return [I_stateOfInvitedUsers objectForKey:aUserID];
}

- (NSDictionary *)participants {
    return I_participants;
}

- (NSArray *)pendingUsers {
    return I_pendingUsers;
}

- (void)setAccessState:(TCMMMSessionAccessState)aState {
    I_accessState=aState;
    if (aState != TCMMMSessionAccessLockedState) {
        if ([I_pendingUsers count]) {
            [self setGroup:aState==TCMMMSessionAccessReadWriteState?@"ReadWrite":@"ReadOnly"
                  forPendingUsersWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[I_pendingUsers count])]];
        }
    }
    [self TCM_sendSessionDidChangeNotification];
}

- (TCMMMSessionAccessState)accessState {
    return I_accessState;
}

- (void)setClientState:(TCMMMSessionClientState)aState {
    if (I_clientState!=aState) {
        I_clientState = aState;
        [[NSNotificationQueue defaultQueue] 
        enqueueNotification:[NSNotification notificationWithName:TCMMMSessionClientStateDidChangeNotification object:self]
               postingStyle:NSPostWhenIdle 
               coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender 
                   forModes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
    }
}

- (TCMMMSessionClientState)clientState {
    return I_clientState;
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

- (void)addContributors:(NSArray *)aContributors {
    [I_contributors addObjectsFromArray:aContributors];
}

- (NSArray *)contributors {
    return [I_contributors allObjects];
}

- (BOOL)isEditable {
    return [[I_groupByUserID objectForKey:[TCMMMUserManager myUserID]] isEqualToString:@"ReadWrite"];
}

- (void)setGroup:(NSString *)aGroup forParticipantsWithUserIDs:(NSArray *)aUserIDs {
    if ([aGroup isEqualToString:@"PoofGroup"] || [aGroup isEqualToString:@"CloseGroup"]) {
        NSEnumerator *userIDs=[aUserIDs objectEnumerator];
        NSString *userID;
        TCMMMUser *user;
        TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
        NSString *sessionID=[self sessionID];
        while ((userID=[userIDs nextObject])) {
            user = [userManager userForUserID:userID];
            NSString *group=[I_groupByUserID objectForKey:userID];
            if (group) {
                [[I_participants objectForKey:group] removeObject:user];
                [I_groupByUserID removeObjectForKey:userID];
                if ([self isServer]) {
                    [self documentDidApplyOperation:[UserChangeOperation userChangeOperationWithType:UserChangeTypeLeave userID:userID newGroup:aGroup]];
                }
                SessionProfile *profile=[I_profilesByUserID objectForKey:userID];
                [profile close];
                [self detachStateAndProfileForUserWithID:userID];
                SelectionOperation *selectionOperation=[[user propertiesForSessionID:sessionID] objectForKey:@"SelectionOperation"];
                if (selectionOperation) {
                    [(PlainTextDocument *)[self document] invalidateLayoutForRange:[selectionOperation selectedRange]];
                }
                [user leaveSessionID:sessionID];
            }
        }
        [self TCM_sendParticipantsDidChangeNotification];
    } else {
        if (![I_participants objectForKey:aGroup]) {
            [I_participants setObject:[NSMutableArray array] forKey:aGroup];
        }
        NSEnumerator *userIDs=[aUserIDs objectEnumerator];
        NSString *userID;
        TCMMMUser *user;
        TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
        NSString *sessionID=[self sessionID];
        while ((userID=[userIDs nextObject])) {
            NSString *oldGroup=[[[I_groupByUserID objectForKey:userID] retain] autorelease];
            if (![oldGroup isEqualToString:aGroup]) {
                user=[userManager userForUserID:userID];
                [I_groupByUserID setObject:aGroup forKey:userID];
                [[I_participants objectForKey:aGroup] addObject:user];
                [[I_participants objectForKey:oldGroup] removeObject:user];
                SelectionOperation *selectionOperation=[[user propertiesForSessionID:sessionID] objectForKey:@"SelectionOperation"];
                if (selectionOperation) {
                    [(PlainTextDocument *)[self document] invalidateLayoutForRange:[selectionOperation selectedRange]];
                }
                if ([self isServer]) {
                    [self documentDidApplyOperation:[UserChangeOperation userChangeOperationWithType:UserChangeTypeGroupChange userID:userID newGroup:aGroup]];
                }
                if ([oldGroup isEqualToString:@"ReadWrite"]) {
                    SessionProfile *profile=[I_profilesByUserID objectForKey:userID];
                    TCMMMState *state=[I_statesByClientID objectForKey:userID];
                    [state setClient:nil];
                    [state setDelegate:nil];
                    [I_statesByClientID removeObjectForKey:userID];
                    [profile setMMState:nil];
                    [profile sendSessionContent:[NSDictionary dictionaryWithObject:[(TextStorage *)[(PlainTextDocument *)[self document] textStorage] dictionaryRepresentation] forKey:@"TextStorage"]];
                    state = [[TCMMMState alloc] initAsServer:YES];
                    [state setDelegate:self];
                    [state setClient:profile];
                    [I_statesByClientID setObject:state forKey:userID];
                    [state release];
                }
            }
        }
        [self TCM_sendParticipantsDidChangeNotification];
    }
}

- (void)setGroup:(NSString *)aGroup forPendingUsersWithIndexes:(NSIndexSet *)aSet {
    if ([aGroup isEqualToString:@"PoofGroup"]) {
        NSMutableIndexSet *set = [aSet mutableCopy];
        unsigned index;
        while ((index = [set firstIndex]) != NSNotFound) {
            TCMMMUser *user = [I_pendingUsers objectAtIndex:index];
            SessionProfile *profile=[I_profilesByUserID objectForKey:[user userID]];
            if (profile) {
                [profile denyJoin];
                [profile close];
                [I_closingProfiles addObject:profile];
            }
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
//            [profile setMMState:state];
            [profile acceptJoin];
            [profile sendSessionInformation:[self TCM_sessionInformationForUserID:[user userID]]];
            PlainTextDocument *document=(PlainTextDocument *)[self document];
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

- (void)cancelInvitationForUserWithID:(NSString *)aUserID {
    NSString *group=[I_groupOfInvitedUsers objectForKey:aUserID];
    if (group) {
        [[I_invitedUsers objectForKey:group] removeObject:[[TCMMMUserManager sharedInstance] userForUserID:aUserID]];
        [I_stateOfInvitedUsers removeObjectForKey:aUserID];
        [I_groupOfInvitedUsers removeObjectForKey:aUserID];
        SessionProfile *profile=[I_profilesByUserID objectForKey:aUserID];
        [profile cancelInvitation];
        [profile setDelegate:nil];
        [I_profilesByUserID removeObjectForKey:aUserID];
        [self TCM_sendParticipantsDidChangeNotification];
    }
}

- (void)inviteUser:(TCMMMUser *)aUser intoGroup:(NSString *)aGroup usingBEEPSession:(TCMBEEPSession *)aBEEPSession {
    if (![I_invitedUsers objectForKey:aGroup]) {
        [I_invitedUsers setObject:[NSMutableArray array] forKey:aGroup];
    }
    NSString *userID=[aUser userID];
    if (!aBEEPSession) {
        aBEEPSession = [[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:userID];
    }
    if ([self isServer] && ![I_profilesByUserID objectForKey:userID]) {
        [I_groupOfInvitedUsers setObject:aGroup forKey:userID];
        [I_stateOfInvitedUsers setObject:@"AwaitingResponse" forKey:userID];
        [[I_invitedUsers objectForKey:@"ReadWrite"] removeObject:aUser];
        [[I_invitedUsers objectForKey:@"ReadOnly"] removeObject:aUser];
        [[I_invitedUsers objectForKey:aGroup] addObject:aUser];
    //    NSLog(@"BeepSession: %@ forUser:%@",aBEEPSession, aUser);
        [aBEEPSession startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"] andData:nil sender:self];
        [self TCM_sendParticipantsDidChangeNotification];
    } else if ([I_pendingUsers containsObject:aUser]) {
        [self setGroup:aGroup forPendingUsersWithIndexes:[NSIndexSet indexSetWithIndex:[I_pendingUsers indexOfObject:aUser]]];
    } else {
        NSBeep();
    }
}

- (void)joinUsingBEEPSession:(TCMBEEPSession *)aBEEPSession
{
    TCMMMSessionClientState state=[self clientState];
    PlainTextDocument *document=(PlainTextDocument *)[self document];
    if (state==TCMMMSessionClientNoState) {
        TCMBEEPSession *session = aBEEPSession;
        if (!session) {
            session = [[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:[self hostID]];
        }
        if (session) {
            [self setClientState:TCMMMSessionClientJoiningState];
            I_flags.shouldSendJoinRequest=YES;
            if (!document) {
                [[DocumentController sharedInstance] addProxyDocumentWithSession:self];
            } else {
                [document updateProxyWindow];
                [document showWindows];
            }
            [session startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"] andData:nil sender:self];
        }
    } else {
         [document showWindows];    
    }
}

- (void)cancelJoin {
    SessionProfile *profile = [I_profilesByUserID objectForKey:[self hostID]];
    [profile cancelJoin];
    [profile setDelegate:nil];
    [I_profilesByUserID removeObjectForKey:[self hostID]];
    I_flags.shouldSendJoinRequest = NO;
    [self setClientState:TCMMMSessionClientNoState];
}

- (void)acceptInvitation {
    SessionProfile *profile = [I_profilesByUserID objectForKey:[self hostID]];
    [profile acceptInvitation];
    [self setClientState:TCMMMSessionClientParticipantState];
}

- (void)declineInvitation {
    SessionProfile *profile = [I_profilesByUserID objectForKey:[self hostID]];
    [profile declineInvitation];
    [profile setDelegate:nil];
    [I_profilesByUserID removeObjectForKey:[self hostID]];
    [self setClientState:TCMMMSessionClientNoState];
}

- (void)leave {
    if (![self isServer]) {
        SessionProfile *profile = [I_profilesByUserID objectForKey:[self hostID]];
        if (profile) {
            UserChangeOperation *iLeftOperation=[UserChangeOperation userChangeOperationWithType:UserChangeTypeLeave userID:[TCMMMUserManager myUserID] newGroup:@""];
            [self documentDidApplyOperation:iLeftOperation]; // note that this only comes through if content was already transmitted
            [profile abortIncomingMessages];
            [profile close];
            [self detachStateAndProfileForUserWithID:[self hostID]];
            [self cleanupParticipants];
            [[TCMMMUserManager me] leaveSessionID:[self sessionID]];
        }
        [self setClientState:TCMMMSessionClientNoState];
    }
}

- (void)abandon {
    NSMutableSet *userIDs=[NSMutableSet setWithArray:[I_groupByUserID allKeys]];
    [userIDs removeObject:[TCMMMUserManager myUserID]];
    [self setGroup:@"CloseGroup" forParticipantsWithUserIDs:[userIDs allObjects]];
    [self setGroup:@"PoofGroup" forPendingUsersWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[I_pendingUsers count])]];
}

#pragma mark -

- (NSDictionary *)TCM_sessionInformationForUserID:(NSString *)userID 
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

    PlainTextDocument *document=(PlainTextDocument *)[self document];
    NSDictionary *sessionContent=[NSDictionary dictionaryWithObject:[(TextStorage *)[document textStorage] dictionaryRepresentation] forKey:@"TextStorage"];
    [I_sessionContentForUserID setObject:sessionContent forKey:userID];

    [sessionInformation setObject:[NSNumber numberWithUnsignedInt:[TCM_BencodedObject(sessionContent) length]] forKey:@"ContentLength"];

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
    if ([self isServer]) {
        // send invitation
        NSString *peerUserID = [[session userInfo] objectForKey:@"peerUserID"];
        // did we invite him?
        if ([I_groupOfInvitedUsers objectForKey:peerUserID]) {
            [profile setDelegate:self];
            [(SessionProfile *)profile sendInvitationWithSession:self];
            [I_profilesByUserID setObject:profile forKey:peerUserID];
        } else {
            NSLog(@"Invitation not sent because of fishyness");
            [profile close];
        }
    } else {
        DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"BEEPSession:%@ didOpenChannel: %@", session, profile);
        if (I_flags.shouldSendJoinRequest) {
            [I_profilesByUserID setObject:profile forKey:[self hostID]];
            [profile setDelegate:self];
            [(SessionProfile *)profile sendJoinRequestForSessionID:[self sessionID]];
            I_flags.shouldSendJoinRequest=NO;
        } else {
            [profile close];
        }
    }
}

- (void)profile:(SessionProfile *)aProfile didReceiveSessionContentFrame:(TCMBEEPFrame *)aFrame {
    I_receivedContentLength+=[aFrame length];
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMSessionDidReceiveContentNotification object:self];
}

- (double)percentOfSessionReceived {
    if (I_sessionContentLength!=0) {
        return (double)(I_receivedContentLength/(double)I_sessionContentLength)*100;
    } else {
        return 50.;
    }
}


# pragma mark -

- (void)joinRequestWithProfile:(SessionProfile *)profile
{        
    NSString *peerUserID = [[[profile session] userInfo] objectForKey:@"peerUserID"];
    
    // if user is already joined, kick the one that is in here, because he probably has lost
    // his connection anyway...
    
    NSString *participantGroup=[I_groupByUserID objectForKey:peerUserID];
    if (participantGroup) {
        [self setGroup:@"PoofGroup" forParticipantsWithUserIDs:[NSArray arrayWithObject:peerUserID]];
    }
    TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:peerUserID];
    
    if ([I_pendingUsers containsObject:user]) {
        [self setGroup:@"PoofGroup" forPendingUsersWithIndexes:[NSIndexSet indexSetWithIndex:[I_pendingUsers indexOfObject:user]]];
    }
    NSString *userState=[I_stateOfInvitedUsers objectForKey:peerUserID];
    if (userState && [userState isEqualToString:@"AwaitingResponse"]) {
        [profile denyJoin];
    } else {
        if (userState) {
            [self cancelInvitationForUserWithID:peerUserID];
        }
        [I_profilesByUserID setObject:profile forKey:peerUserID];
    
        [I_pendingUsers addObject:user];
        [profile setDelegate:self];
        // decide if autojoin depending on setting
        if ([self accessState]!=TCMMMSessionAccessLockedState) {
            [self setGroup:[self accessState]==TCMMMSessionAccessReadWriteState?@"ReadWrite":@"ReadOnly"
                  forPendingUsersWithIndexes:[NSIndexSet indexSetWithIndex:[I_pendingUsers count]-1]];
        } else {
            // if no autojoin add user to pending users and notify 
            [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMSessionPendingUsersDidChangeNotification object:self];
            [[NSSound soundNamed:@"Knock"] play];
        }
    }
}

- (void)invitationWithProfile:(SessionProfile *)profile
{
    TCMMMSessionClientState state=[self clientState];
    PlainTextDocument *document=(PlainTextDocument *)[self document];
    if (state==TCMMMSessionClientParticipantState) {
        [profile declineInvitation];
    } else if (state==TCMMMSessionClientInvitedState && document) {
        [profile declineInvitation];
        [document showWindows];
    } else {
        if (state==TCMMMSessionClientJoiningState) {
            [self cancelJoin];
        }
        
        [profile setDelegate:self];
        [I_profilesByUserID setObject:profile forKey:[self hostID]];
        [self setClientState:TCMMMSessionClientInvitedState];
        if (!document) {
            [self setWasInvited:YES];
            [[NSSound soundNamed:@"Invitation"] play];
            [[DocumentController sharedInstance] addProxyDocumentWithSession:self];
        } else {
            [document updateProxyWindow];
        }
    }
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
    [[self document] session:self didReceiveContent:aContent];
    if (![I_statesByClientID objectForKey:[self hostID]]) {
        TCMMMState *state=[[TCMMMState alloc] initAsServer:NO];
        [state setDelegate:self];
        [state setClient:[I_profilesByUserID objectForKey:[self hostID]]];
        [profile setMMState:state];
        [state setIsSendingNoOps:YES];
        [I_statesByClientID setObject:state forKey:[self hostID]];
        [state release];
    }
}

- (void)profileDidAckSessionContent:(SessionProfile *)aProfile {
    NSString *peerUserID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    TCMMMState *state=[I_statesByClientID objectForKey:peerUserID];
    [aProfile setMMState:state];
    [state setIsSendingNoOps:YES];
}

- (void)profileDidDenyJoinRequest:(SessionProfile *)aProfile
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"profileDidAcceptJoinRequest: %@", aProfile);
    NSString *peerUserID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    [[self document] sessionDidDenyJoinRequest:self];
    [I_closingProfiles addObject:aProfile];
    [I_profilesByUserID removeObjectForKey:peerUserID];
    [self setClientState:TCMMMSessionClientNoState];
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
    [self setClientState:TCMMMSessionClientParticipantState];
}

- (void)profileDidCancelInvitation:(SessionProfile *)aProfile {
    [[self document] sessionDidCancelInvitation:self];
    NSString *peerUserID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    [I_closingProfiles addObject:aProfile];
    [I_profilesByUserID removeObjectForKey:peerUserID];
    [self setClientState:TCMMMSessionClientNoState];
}


- (void)profileDidDeclineInvitation:(SessionProfile *)aProfile {
    NSString *peerUserID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    [I_stateOfInvitedUsers setObject:@"DeclinedInvitation" forKey:peerUserID];
    [aProfile setDelegate:nil];
    [I_profilesByUserID removeObjectForKey:peerUserID];
    [self TCM_sendParticipantsDidChangeNotification];
}

- (void)profileDidAcceptInvitation:(SessionProfile *)aProfile {
    NSString *peerUserID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    NSString *group=[I_groupOfInvitedUsers objectForKey:peerUserID];
    TCMMMUser *user = [[TCMMMUserManager sharedInstance] userForUserID:peerUserID];
    [[I_invitedUsers objectForKey:group] removeObject:user];
    [I_groupOfInvitedUsers removeObjectForKey:peerUserID];
    [I_stateOfInvitedUsers removeObjectForKey:peerUserID];
    
    [I_groupByUserID setObject:group forKey:peerUserID];
    if (![I_participants objectForKey:group]) {
        [I_participants setObject:[NSMutableArray array] forKey:group];
    }
    [[I_participants objectForKey:group] addObject:user];
    [I_contributors addObject:user];
    [self documentDidApplyOperation:[UserChangeOperation userChangeOperationWithType:UserChangeTypeJoin user:user newGroup:group]];
    SessionProfile *profile = [I_profilesByUserID objectForKey:[user userID]];
    TCMMMState *state = [[TCMMMState alloc] initAsServer:YES];
    [state setDelegate:self];
    [state setClient:profile];
    [I_statesByClientID setObject:state forKey:[user userID]];
    // [profile setMMState:state];
    [profile sendSessionInformation:[self TCM_sessionInformationForUserID:[user userID]]];
    PlainTextDocument *document=(PlainTextDocument *)[self document];
    [document sendInitialUserState];
    [state release];
    [user joinSessionID:[self sessionID]];
    NSMutableDictionary *properties=[user propertiesForSessionID:[self sessionID]];
    [properties setObject:[SelectionOperation selectionOperationWithRange:NSMakeRange(0,0) userID:[user userID]] forKey:@"SelectionOperation"];
    [self TCM_sendParticipantsDidChangeNotification];
}

- (NSArray *)profile:(SessionProfile *)profile userRequestsForSessionInformation:(NSDictionary *)sessionInfo
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"profile:userRequestsForSessionInformation:");
    
    NSArray *contributors=[sessionInfo objectForKey:@"Contributors"];
    NSMutableArray *result=[NSMutableArray array];
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

    I_sessionContentLength = [[sessionInfo objectForKey:@"ContentLength"] unsignedIntValue] + 6;
    I_receivedContentLength = 0;

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
    if ([[I_profilesByUserID allValues] containsObject:aProfile]) {
        // treat as error
        [self profile:aProfile didFailWithError:nil];
    }
    TCMMMState *state=[profile MMState];
    if (state) {
        [[state retain] autorelease];
        [I_closingStates removeObject:state];
        [state setClient:nil];
    }
    [profile setDelegate:nil];
    [I_closingProfiles removeObject:profile];
}

- (void)profile:(TCMBEEPProfile *)aProfile didFailWithError:(NSError *)anError {
    SessionProfile *profile=(SessionProfile *)aProfile;
    if ([self isServer]) {
        // same as leave for this user
        NSString *userID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
        TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:userID];
        NSString *group=[I_groupByUserID objectForKey:userID];
        [[I_participants objectForKey:group] removeObject:user];
        [I_groupByUserID removeObjectForKey:userID];
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMSessionPendingUsersDidChangeNotification object:self];
        [self TCM_sendParticipantsDidChangeNotification];
        [self detachStateAndProfileForUserWithID:userID];
        [self profileDidClose:profile];
        SelectionOperation *selectionOperation=[[user propertiesForSessionID:[self sessionID]] objectForKey:@"SelectionOperation"];
        if (selectionOperation) {
            [(PlainTextDocument *)[self document] invalidateLayoutForRange:[selectionOperation selectedRange]];
        }
        [user leaveSessionID:[self sessionID]];
    } else {
        if ([self clientState]==TCMMMSessionClientParticipantState) {
        // server is gone, almost the same as kick
        // i was kicked, snief
        // remove all Users
            [self cleanupParticipants];
        }
        [self detachStateAndProfileForUserWithID:[self hostID]];
        [self profileDidClose:aProfile];
        // detach document
        [[self document] sessionDidLoseConnection:self];
        [self setClientState:TCMMMSessionClientNoState];
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
        TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
        if ([userID isEqualToString:[userManager myUserID]]) {
            if ([self isServer]) {
                NSLog(@"Can't kick me out of my document, pah!");
            } else {
                // i was kicked, snief
                // remove all Users
                [self cleanupParticipants];
                [self detachStateAndProfileForUserWithID:[self hostID]];
                // detach document
                if ([[anOperation newGroup] isEqualTo:@"PoofGroup"]) {
                    [[self document] sessionDidReceiveKick:self];
                } else {
                    [[self document] sessionDidReceiveClose:self];
                }
                [self setClientState:TCMMMSessionClientNoState];
            }
        } else {
            TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:userID];
            NSString *group=[I_groupByUserID objectForKey:userID];
            [[I_participants objectForKey:group] removeObject:user];
            [I_groupByUserID removeObjectForKey:userID];
            if ([self isServer]) {
                [self detachStateAndProfileForUserWithID:userID];
            }
            SelectionOperation *selectionOperation=[[user propertiesForSessionID:[self sessionID]] objectForKey:@"SelectionOperation"];
            if (selectionOperation) {
                [(PlainTextDocument *)[self document] invalidateLayoutForRange:[selectionOperation selectedRange]];
            }
            [user leaveSessionID:[self sessionID]];
        }
        [self TCM_sendParticipantsDidChangeNotification];
    } else if ([anOperation type]==UserChangeTypeGroupChange) {
        NSString *userID=[anOperation userID];
        [self setGroup:[anOperation newGroup] forParticipantsWithUserIDs:[NSArray arrayWithObject:userID]];
        TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
        if ([userID isEqualToString:[userManager myUserID]]) {
            if ([self isServer]) {
                NSLog(@"Can't change my group in my document, pah!");
            } else {
                if ([[anOperation newGroup] isEqualTo:@"ReadOnly"]) {
                    
                    [[aState retain] autorelease];
                    [aState setDelegate:nil];
                    [aState setClient:nil];
                    [I_statesByClientID removeObjectForKey:[self hostID]];
                }
                [(PlainTextDocument *)[self document] validateEditability];
            }
        }
        
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

- (void)pauseProcessing {
    I_flags.isPaused=YES;
    //NSLog(@"paused");
}

- (void)startProcessing {
    //NSLog(@"started");
    I_flags.isPaused=NO;
    [self triggerPerformRoundRobin];
}

- (void)stateHasMessagesAvailable:(TCMMMState *)aState {
    [self triggerPerformRoundRobin];
}

- (void)triggerPerformRoundRobin {
    if (!I_flags.isPerformingRoundRobin &&
        !I_flags.isPaused &&
        [I_statesByClientID count]>0) {
        I_flags.isPerformingRoundRobin = YES;
        [self performSelector:@selector(performRoundRobinMessageProcessing) withObject:nil afterDelay:kWaitingTime];
    }
}

- (void)performRoundRobinMessageProcessing {
    int i;
    clock_t start_time = clock();
    double timeSpent=0;

    BOOL hasMessagesAvailable = YES;
    int count = [I_statesByClientID count];
    NSArray *states=[I_statesByClientID allValues];
    while (!I_flags.isPaused && hasMessagesAvailable && count && timeSpent<kProcessingTime) {
        hasMessagesAvailable = NO;
        for (i=0;i<count;i++) {
            TCMMMState *state=[states objectAtIndex:i];
            [state processMessage];
            if (!hasMessagesAvailable) {
                hasMessagesAvailable=[state hasMessagesAvailable];
            }
        }
        timeSpent=(((double)(clock()-start_time))/CLOCKS_PER_SEC);
    }
    I_flags.isPerformingRoundRobin = NO;
    if (hasMessagesAvailable && !I_flags.isPaused && count) {
        [self triggerPerformRoundRobin];
    }
}

@end


