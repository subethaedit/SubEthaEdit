//
//  TCMMMSession.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 08 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import "../TCMBEEP/TCMBEEP.h"
#import "TCMMMSession.h"
#import "TCMBencodingUtilities.h"
#import "TCMMMUserManager.h"
#import "TCMMMBEEPSessionManager.h"
#import "TCMMMUser.h"
#import "TCMMMState.h"
#import "TCMMMOperation.h"
#import "SessionProfile.h"
#import "PlainTextDocument.h"
#import "DocumentController.h"
#import "SelectionOperation.h"
#import "UserChangeOperation.h"
#import "time.h"


#define kProcessingTime 0.5
#define kWaitingTime 0.1


NSString * const TCMMMSessionParticipantsDidChangeNotification = 
               @"TCMMMSessionParticipantsDidChangeNotification";
NSString * const TCMMMSessionPendingUsersDidChangeNotification = 
               @"TCMMMSessionPendingUsersDidChangeNotification";
NSString * const TCMMMSessionPendingInvitationsDidChange =
               @"TCMMMSessionPendingInvitationsDidChange";
NSString * const TCMMMSessionDidChangeNotification = 
               @"TCMMMSessionDidChangeNotification";
NSString * const TCMMMSessionClientStateDidChangeNotification = 
               @"TCMMMSessionClientStateDidChangeNotification";
NSString * const TCMMMSessionDidReceiveContentNotification = 
               @"TCMMMSessionDidReceiveContentNotification";


@interface TCMMMSession (TCMMMSessionPrivateAdditions)

- (NSDictionary *)TCM_sessionInformationForUserID:(NSString *)aUserID;
- (NSArray *)TCM_setSessionParticipants:(NSDictionary *)aParticipants  forProfile:(SessionProfile *)profile;
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
        I_flags.shouldSendJoinRequest = NO;
        I_flags.isPerformingRoundRobin = NO;
        I_flags.pauseCount = 0;
        I_statesWithRemainingMessages=[NSMutableSet new];
        [self setIsServer:NO];
        [self setClientState:TCMMMSessionClientNoState];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChange:) name:TCMMMUserManagerUserDidChangeNotification object:nil];
    }
    return self;
}

- (id)initWithDocument:(NSDocument *)aDocument
{
    self = [self init];
    if (self) {
        [self setDocument:aDocument];
        [self setSessionID:[NSString UUIDString]];
        [self setFilename:[(PlainTextDocument *)aDocument preparedDisplayName]];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    I_document = nil;
    [I_invitedUsers release];
    [I_groupOfInvitedUsers release];
    [I_stateOfInvitedUsers release];
    [I_sessionID release];
    [I_hostID release];
    [I_filename release];
    [[I_profilesByUserID allValues] makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
    [I_profilesByUserID release];
    [I_participants release];
    [I_statesWithRemainingMessages makeObjectsPerformSelector:@selector(setClient:) withObject:nil];
    [I_statesWithRemainingMessages makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
    [I_statesWithRemainingMessages release];
    [I_sessionContentForUserID release];
    [I_contributors release];
    [I_pendingUsers release];
    [I_groupByUserID release];
    [[I_statesByClientID allValues] makeObjectsPerformSelector:@selector(setClient:) withObject:nil];
    [[I_statesByClientID allValues] makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
    [I_statesByClientID release];
    DEBUGLOG(@"MillionMonkeysLogDomain", AllLogLevel, @"MMSession deallocated");
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
    [I_invitedUsers removeAllObjects];
    [I_groupOfInvitedUsers removeAllObjects];
    [I_stateOfInvitedUsers removeAllObjects];
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
    TCMMMState *state=nil;
    while ((state = [states nextObject])) {
        [state handleOperation:anOperation];
    }
    states=[I_statesWithRemainingMessages objectEnumerator];
    while ((state=[states nextObject])) {
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
                TCMMMState *state=[I_statesByClientID objectForKey:userID];
                [state setClient:nil];
                [state setDelegate:nil];
                [I_statesByClientID removeObjectForKey:userID];
                [profile setDelegate:nil];
                [profile setMMState:nil];
                [I_profilesByUserID removeObjectForKey:userID];
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
                    [profile sendSessionContent:TCM_BencodedObject([NSDictionary dictionaryWithObject:[(PlainTextDocument *)[self document] textStorageDictionaryRepresentation] forKey:@"TextStorage"])];
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
                [profile setDelegate:nil];
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
                #warning Dependency on DocumentController
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
    if (profile) {
        [profile acceptInvitation];
        [self setClientState:TCMMMSessionClientParticipantState];
    } else {
        [self setClientState:TCMMMSessionClientNoState];
        NSBeep();
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMSessionPendingInvitationsDidChange object:self];
}

- (void)declineInvitation {
    SessionProfile *profile = [I_profilesByUserID objectForKey:[self hostID]];
    [profile declineInvitation];
    [profile setDelegate:nil];
    [I_profilesByUserID removeObjectForKey:[self hostID]];
    [self setClientState:TCMMMSessionClientNoState];
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMSessionPendingInvitationsDidChange object:self];
}

- (void)leave {
    if (![self isServer]) {
        SessionProfile *profile = [I_profilesByUserID objectForKey:[self hostID]];
        TCMMMState *state=[profile MMState];
        if (profile) {
            UserChangeOperation *iLeftOperation=[UserChangeOperation userChangeOperationWithType:UserChangeTypeLeave userID:[TCMMMUserManager myUserID] newGroup:@""];
            [self documentDidApplyOperation:iLeftOperation]; // note that this only comes through if content was already transmitted
            [profile abortIncomingMessages];
            [profile close];
            [profile setDelegate:nil];
            [profile setMMState:nil];
            [state setClient:nil];
            [state setDelegate:nil];
            [I_statesByClientID removeObjectForKey:[self hostID]];
            [I_profilesByUserID removeObjectForKey:[self hostID]];
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
    NSEnumerator *invitedUserIDs=[[I_groupOfInvitedUsers allKeys] objectEnumerator];
    NSString *userID=nil;
    while ((userID=[invitedUserIDs nextObject])) {
        [self cancelInvitationForUserWithID:userID];
    }
}

- (BOOL)isAddressedByURL:(NSURL *)aURL {
    NSString *URLPath = [aURL path];
    NSString *path = nil;
    if (URLPath != nil) {
        path = (NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)URLPath, CFSTR(""));
        [path autorelease];
    }

    if (path == nil || [path length] == 0) {
        return NO;
    }
    
    NSString *lastPathComponent = [path lastPathComponent];
    if ([lastPathComponent isEqualToString:[self sessionID]]) {
        return YES;
    }
    
    
    NSString *urlQuery = [aURL query];
    NSString *query;
    NSString *documentId = nil;
    if (urlQuery != nil) {
        query = (NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)urlQuery, CFSTR(""));
        [query autorelease];
        NSArray *components = [query componentsSeparatedByString:@"&"];
        NSEnumerator *enumerator = [components objectEnumerator];
        NSString *item;
        while ((item = [enumerator nextObject])) {
            NSArray *keyValue = [item componentsSeparatedByString:@"="];
            if ([keyValue count] == 2) {
                if ([[keyValue objectAtIndex:0] isEqualToString:@"sessionID"]) {
                    documentId = [keyValue objectAtIndex:1];
                }
                break;
            }
        }
    }
    

    if ([documentId isEqualToString:[self sessionID]]) {
        return YES;
    }
    

    if ([lastPathComponent compare:[[self filename] lastPathComponent]] == NSOrderedSame) {
        return YES;
    }
    
    return NO;
}

#pragma mark -

- (void)userDidChange:(NSNotification *)aNotification {
    TCMMMUser *user = [[aNotification userInfo] objectForKey:@"User"];
    // check if user contributed to or participates in document
    BOOL affected=([I_groupByUserID objectForKey:[user userID]]!=nil);
    if (affected) {
        [self TCM_sendParticipantsDidChangeNotification];
        if ([self isServer]) {
            // propagateChangeOfUser
            NSEnumerator *userIDs=[I_profilesByUserID keyEnumerator];
            NSString *userID=nil;
            while ((userID=[userIDs nextObject])) {
                if (![userID isEqualToString:[user userID]]) {
                    [[I_profilesByUserID objectForKey:userID] sendUserDidChangeNotification:user];
                }
            }
        }
    }
}

#pragma mark -

- (NSDictionary *)TCM_sessionInformationForUserID:(NSString *)userID 
{
    NSMutableDictionary *sessionInformation=[NSMutableDictionary dictionary];
    NSMutableArray *contributorNotifications=[NSMutableArray array];
    NSEnumerator *contributors = [I_contributors objectEnumerator];
    NSSet *userIDsOfContributors = [(PlainTextDocument *)[self document] userIDsOfContributors];
    TCMMMUser *contributor=nil;
    while ((contributor=[contributors nextObject])) {
        NSString *contributorID=[contributor userID];
        if (![contributorID isEqualToString:userID] &&
            [userIDsOfContributors containsObject:contributorID]) {
            [contributorNotifications addObject:[contributor notification]];
        }
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
    PlainTextDocument *document=(PlainTextDocument *)[self document];
    [sessionInformation setObject:[document sessionInformation] forKey:@"DocumentSessionInformation"];

    NSDictionary *sessionContent=[NSDictionary dictionaryWithObject:[document textStorageDictionaryRepresentation] forKey:@"TextStorage"];
    [I_sessionContentForUserID setObject:TCM_BencodedObject(sessionContent) forKey:userID];

    [sessionInformation setObject:[NSNumber numberWithUnsignedInt:[(NSData *)[I_sessionContentForUserID objectForKey:userID] length]] forKey:@"ContentLength"];

    return sessionInformation;
}

- (NSArray *)TCM_setSessionParticipants:(NSDictionary *)aParticipants forProfile:(SessionProfile *)profile
{
    NSMutableArray *result=[NSMutableArray array];
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
            TCMMMUser *user=[TCMMMUser userWithNotification:[userDict objectForKey:@"User"]];
            if (![[user userID] isEqualToString:[TCMMMUserManager myUserID]]) {
                if ([userManager sender:profile shouldRequestUser:user]) {
                    [result addObject:[userDict objectForKey:@"User"]];
                }
            }
            NSString *userID=[user userID];
            user=[userManager userForUserID:userID];
            NSString *sessionID=[self sessionID];
            NSMutableDictionary *properties=[user propertiesForSessionID:sessionID];
            if (!properties) {
                [user joinSessionID:sessionID];
                properties=[user propertiesForSessionID:sessionID];
            }
            [properties setObject:[SelectionOperation selectionOperationWithRange:NSMakeRange(0,0) userID:userID] forKey:@"SelectionOperation"];
            [groupArray addObject:user];
            [I_contributors addObject:user];
            [I_groupByUserID setObject:group forKey:userID];
        }
    }
    
    return result;
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
            DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Invitation not sent because of fishyness");
            [profile close];
        }
    } else {
        DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"BEEPSession:%@ didOpenChannel: %@", session, profile);
        if (I_flags.shouldSendJoinRequest) {
            if ([I_profilesByUserID objectForKey:[self hostID]]) {
                DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"WARNING! Profile already in place.");
            }
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
    
    TCMMMState *state=[I_statesByClientID objectForKey:peerUserID];
    if (state) {
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

// seed: Invitation should be denied immediately on the server
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
        if ([I_profilesByUserID objectForKey:[self hostID]]) {
            DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"invitationWithProfile but another profile is in place: %@", [I_profilesByUserID objectForKey:[self hostID]]);
        }
        [I_profilesByUserID setObject:profile forKey:[self hostID]];
        [self setClientState:TCMMMSessionClientInvitedState];
        [[NSSound soundNamed:@"Invitation"] play];
        if (!document) {
            [self setWasInvited:YES];
            #warning Dependency on DocumentController
            [[DocumentController sharedInstance] addProxyDocumentWithSession:self];
        } else {
            [document updateProxyWindow];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMSessionPendingInvitationsDidChange object:self];
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
    if (![I_statesByClientID objectForKey:[self hostID]]) {
        TCMMMState *state=[[TCMMMState alloc] initAsServer:NO];
        [state setDelegate:self];
        [state setClient:profile];
        [profile setMMState:state];
        [state setIsSendingNoOps:YES];
        [I_statesByClientID setObject:state forKey:[self hostID]];
        [state release];
    }
    [[self document] session:self didReceiveContent:aContent];
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
    [aProfile setDelegate:nil];
    if ([I_profilesByUserID objectForKey:peerUserID]==aProfile) {
        [I_profilesByUserID removeObjectForKey:peerUserID];
    } else {
        DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"profileDidDenyJoinRequest but another profile is in place: %@", [I_profilesByUserID objectForKey:peerUserID]);
    }
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
    NSString *peerUserID=[[[profile session] userInfo] objectForKey:@"peerUserID"];
    if ([I_statesByClientID objectForKey:peerUserID]) {
        DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"profileDidAcceptJoinRequest but another State is in place: %@", [I_statesByClientID objectForKey:peerUserID]);    
    }
    [I_statesByClientID setObject:state forKey:peerUserID];
    [state release];
    [self setClientState:TCMMMSessionClientParticipantState];
}

- (void)profileDidCancelInvitation:(SessionProfile *)aProfile {
    [[self document] sessionDidCancelInvitation:self];
    NSString *peerUserID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    [aProfile setDelegate:nil];
    if ([I_profilesByUserID objectForKey:peerUserID]==aProfile) {
        [I_profilesByUserID removeObjectForKey:peerUserID];
    } else {
        DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"profileDidCancelInvitation - profile and profileByuserID didn't match: %@",[I_profilesByUserID objectForKey:peerUserID]);    
    }
    [self setClientState:TCMMMSessionClientNoState];
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMSessionPendingInvitationsDidChange object:self];
}


- (void)profileDidDeclineInvitation:(SessionProfile *)aProfile {
    NSString *peerUserID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
    [I_stateOfInvitedUsers setObject:@"DeclinedInvitation" forKey:peerUserID];
    [aProfile setDelegate:nil];
    if ([I_profilesByUserID objectForKey:peerUserID]==aProfile) {
        [I_profilesByUserID removeObjectForKey:peerUserID];
    } else {
        DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"profileDidDeclineInvitation - profile and profileByuserID didn't match: %@",[I_profilesByUserID objectForKey:peerUserID]);    
    }
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
    SessionProfile *profile = aProfile; //[I_profilesByUserID objectForKey:[user userID]];
    TCMMMState *state = [[TCMMMState alloc] initAsServer:YES];
    [state setDelegate:self];
    [state setClient:profile];
    [I_statesByClientID setObject:state forKey:[user userID]];
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
        if (user) {
            if ([userManager sender:profile shouldRequestUser:user]) {
                [result addObject:userNotification];
            }
            [I_contributors addObject:[userManager userForUserID:[user userID]]];
        }
    }

    [result addObjectsFromArray:[self TCM_setSessionParticipants:[sessionInfo objectForKey:@"Participants"] forProfile:profile]];

    I_sessionContentLength = [[sessionInfo objectForKey:@"ContentLength"] unsignedIntValue] + 6;
    I_receivedContentLength = 0;

    [I_contributors addObject:[userManager me]];

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
    [aProfile sendSessionContent:[I_sessionContentForUserID objectForKey:peerUserID]];
    [I_sessionContentForUserID removeObjectForKey:peerUserID];
}

- (void)profileDidClose:(TCMBEEPProfile *)aProfile {
    //NSLog(@"profileDidClose");
    SessionProfile *profile=(SessionProfile *)aProfile;
    NSString *peerUserID = [[[profile session] userInfo] objectForKey:@"peerUserID"];
    TCMMMState *state=[I_statesByClientID objectForKey:peerUserID];
    if (state) {
        [I_statesWithRemainingMessages addObject:state];
        //NSLog(@"states: %@",[I_statesWithRemainingMessages description]);
        if (state==[I_statesByClientID objectForKey:peerUserID]) {
            [I_statesByClientID removeObjectForKey:peerUserID];
        }
        if ([(PlainTextDocument *)[self document] isReceivingContent]) {
            [[self document] sessionDidLoseConnection:self];
        }
        [state setClient:nil];
    } else if (![self isServer]) {
        if ([self clientState]==TCMMMSessionClientInvitedState) {
            [[self document] sessionDidCancelInvitation:self];
        } else if ([self clientState]==TCMMMSessionClientJoiningState) {
            [[self document] sessionDidDenyJoinRequest:self];
        } else {
            [[self document] sessionDidLoseConnection:self];
        }
        [self setClientState:TCMMMSessionClientNoState];
    }
    [profile setMMState:nil];
    [profile setDelegate:nil];
    if ([I_profilesByUserID objectForKey:peerUserID]==aProfile) {
        [I_sessionContentForUserID removeObjectForKey:peerUserID];
        [I_profilesByUserID removeObjectForKey:peerUserID];
    }
}

- (void)profile:(TCMBEEPProfile *)aProfile didFailWithError:(NSError *)anError {
    //NSLog(@"profileDidFail");
    if ([self isServer]) {
        NSString *peerUserID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
        
        TCMMMState *state=[I_statesByClientID objectForKey:peerUserID];
        if (state) {
            UserChangeOperation *heLeft=[UserChangeOperation userChangeOperationWithType:UserChangeTypeLeave userID:peerUserID newGroup:@"LostConnection"];
            [state appendOperationToIncomingMessageQueue:heLeft]; 
            [I_statesWithRemainingMessages addObject:state];
            //NSLog(@"states: %@",[I_statesWithRemainingMessages description]);
            [state setClient:nil];
            [I_statesByClientID removeObjectForKey:peerUserID];
        }
        [aProfile setDelegate:nil];
        [(SessionProfile *)aProfile setMMState:nil];
        if ([I_profilesByUserID objectForKey:peerUserID]==aProfile) {
            [I_sessionContentForUserID removeObjectForKey:peerUserID];
            [I_profilesByUserID removeObjectForKey:peerUserID];
        }
    } else { 
        if ([self clientState]==TCMMMSessionClientParticipantState) {
            NSString *peerUserID = [[[aProfile session] userInfo] objectForKey:@"peerUserID"];
            
            TCMMMState *state=[I_statesByClientID objectForKey:peerUserID];
            if (state) {
                UserChangeOperation *heLeft=[UserChangeOperation userChangeOperationWithType:UserChangeTypeLeave userID:peerUserID newGroup:@"LostConnection"];
                [state appendOperationToIncomingMessageQueue:heLeft]; 
                [I_statesWithRemainingMessages addObject:state];
        //NSLog(@"states: %@",[I_statesWithRemainingMessages description]);
                [state setClient:nil];
                [I_statesByClientID removeObjectForKey:peerUserID];
            }
            [aProfile setDelegate:nil];
            [(SessionProfile *)aProfile setMMState:nil];
            if ([I_profilesByUserID objectForKey:peerUserID]==aProfile) {
                [I_profilesByUserID removeObjectForKey:peerUserID];
            }
        } else {
            [[self document] sessionDidLoseConnection:self];
            [self setClientState:TCMMMSessionClientNoState];
        }
    }
}

#pragma mark -
#pragma ### State interaction ###

- (void)profile:(SessionProfile *)aProfile didReceiveUserChangeToReadOnly:(UserChangeOperation *)anOperation {
    //NSLog(@"pre-emtive-didRecieveUserChangeToReadOnly");
    TCMMMState *state=[I_statesByClientID objectForKey:[self hostID]];
    [state processAllUserChangeMessages];
    [self setGroup:@"ReadOnly" forParticipantsWithUserIDs:[NSArray arrayWithObject:[TCMMMUserManager myUserID]]];
    SessionProfile *profile=[I_profilesByUserID objectForKey:[self hostID]];
    [profile setMMState:nil];
    [state setDelegate:nil];
    [state setClient:nil];
    [I_statesByClientID removeObjectForKey:[self hostID]];
    [(PlainTextDocument *)[self document] validateEditability];   
}

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
        [I_contributors addObject:user];
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
                DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Can't kick me out of my document, pah!");
            } else {
                // i was kicked, snief
                // remove all Users
                [self cleanupParticipants];
                // detach document
                if ([[anOperation newGroup] isEqualTo:@"PoofGroup"]) {
                    [[self document] sessionDidReceiveKick:self];
                } else {
                    [[self document] sessionDidReceiveClose:self];
                }
                [self setClientState:TCMMMSessionClientNoState];
            }
        } else if ([userID isEqualToString:[self hostID]] && ![self isServer]) {
            if ([[anOperation newGroup] isEqualTo:@"PoofGroup"]) {
                [[self document] sessionDidLoseConnection:self];
            } else {
                [[self document] sessionDidReceiveClose:self];
            }
            [self cleanupParticipants];
            [self setClientState:TCMMMSessionClientNoState];
        } else {
            TCMMMUser *user=[[TCMMMUserManager sharedInstance] userForUserID:userID];
            NSString *group=[I_groupByUserID objectForKey:userID];
            [[I_participants objectForKey:group] removeObject:user];
            [I_groupByUserID removeObjectForKey:userID];
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
                DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Can't change my group in my document, pah!");
            } else {
                //NSLog(@"normal self change:%@",[anOperation description]);
                if ([[anOperation newGroup] isEqualTo:@"ReadOnly"]) {
                    //NSLog(@"normal self change to read only");

                    [[aState retain] autorelease];
                    SessionProfile *profile=[I_profilesByUserID objectForKey:[self hostID]];
                    [profile setMMState:nil];
                    [aState setDelegate:nil];
                    [aState setClient:nil];
                    [I_statesByClientID removeObjectForKey:[self hostID]];
                }
                [(PlainTextDocument *)[self document] validateEditability];
            }
        }
        
    } else {
        DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Got UserChangeOperation: %@",[anOperation description]);
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
    I_flags.pauseCount++;
//    NSLog(@"paused %d",I_flags.pauseCount);
}

- (void)startProcessing {
//    NSLog(@"started %d",I_flags.pauseCount);
    //NSLog(@"started");
    I_flags.pauseCount--;
    [self triggerPerformRoundRobin];
}

- (void)stateHasMessagesAvailable:(TCMMMState *)aState {
    [self triggerPerformRoundRobin];
}

- (void)triggerPerformRoundRobin {
//    NSLog(@"triggerPerformRoundRobin");
    if (!I_flags.isPerformingRoundRobin &&
        !(I_flags.pauseCount>0) &&
        ([I_statesByClientID count]>0 || [I_statesWithRemainingMessages count]>0)) {
        I_flags.isPerformingRoundRobin = YES;
        [self performSelector:@selector(performRoundRobinMessageProcessing) withObject:nil afterDelay:kWaitingTime];
    }
}

- (void)performRoundRobinMessageProcessing {
//    NSLog(@"performRoundRobinMessageProcessing");
    clock_t start_time = clock();
    double timeSpent=0;

    BOOL hasMessagesAvailable = YES;
    NSMutableArray *statesToDiscard=[NSMutableArray array];
    while (!(I_flags.pauseCount>0) && 
           hasMessagesAvailable && 
           ([I_statesByClientID count] || [I_statesWithRemainingMessages count]) && 
           timeSpent<kProcessingTime) {
        hasMessagesAvailable = NO;
        NSEnumerator *states=[I_statesByClientID objectEnumerator];
        TCMMMState *state=nil;
        while ((state=[states nextObject])) {
            [state processMessage];
            if (!hasMessagesAvailable) {
                hasMessagesAvailable=[state hasMessagesAvailable];
            }
        }

        states=[I_statesWithRemainingMessages objectEnumerator];
        while ((state=[states nextObject])) {
            [state processMessage];
            if (![state hasMessagesAvailable]) {
                [state setDelegate:nil];
                [state setClient:nil];
                [statesToDiscard addObject:state];
            } else {
                hasMessagesAvailable=YES;
            }
        }
        
        while ([statesToDiscard count]) {
            state = [statesToDiscard lastObject];
            [I_statesWithRemainingMessages removeObject:state];
            [statesToDiscard removeLastObject];
            //NSLog(@"discarding state: %@",[state description]);
        }
        
        timeSpent=(((double)(clock()-start_time))/CLOCKS_PER_SEC);
    }
    
    I_flags.isPerformingRoundRobin = NO;
    if (hasMessagesAvailable && !(I_flags.pauseCount>0) && [I_statesByClientID count]) {
        [self triggerPerformRoundRobin];
    }
}

@end


