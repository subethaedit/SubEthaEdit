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
#import "SessionProfile.h"
#import "PlainTextDocument.h"
#import "DocumentController.h"


NSString * const TCMMMSessionPendingUsersDidChangeNotification = 
               @"TCMMMSessionPendingUsersDidChangeNotification";


@interface TCMMMSession (TCMMMSessionPrivateAdditions)

- (NSDictionary *)TCM_sessionInformation;
- (void)TCM_setSessionParticipants:(NSDictionary *)aParticipants;

@end

#pragma mark -

@implementation TCMMMSession

+ (TCMMMSession *)sessionWithBencodedSession:(NSData *)aData
{
    NSDictionary *sessionDict=TCM_BdecodedObjectWithData(aData);
    TCMMMSession *session = [[TCMMMSession alloc] initWithSessionID:[sessionDict objectForKey:@"SessionID"] filename:[sessionDict objectForKey:@"Filename"]];
    [session setHostID:[sessionDict objectForKey:@"HostID"]];
    return [session autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        I_participants = [NSMutableDictionary new];
        I_profilesByUserID = [NSMutableDictionary new];
        I_pendingUsers = [NSMutableArray new];
        I_groupByUserID = [NSMutableDictionary new];
        I_contributors = [NSMutableSet new];
        I_statesByClientID = [NSMutableDictionary new];
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
        [I_contributors addObject:[TCMMMUserManager me]];
    }
    return self;
}

- (id)initWithSessionID:(NSString *)aSessionID filename:(NSString *)aFileName
{
    self = [self init];
    if (self) {
        [self setSessionID:aSessionID];
        [self setFilename:aFileName];
    }
    return self;
}

- (void)dealloc
{
    [I_contributors release];
    [I_participants release];
    [I_filename release];
    [I_sessionID release];
    [I_profilesByUserID release];
    [I_pendingUsers release];
    [I_groupByUserID release];
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
    I_filename = [aFilename copy];
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
            //TCMMMUser *user = [I_pendingUsers objectAtIndex:index];
            // deny
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
            SessionProfile *profile = [I_profilesByUserID objectForKey:[user userID]];
            TCMMMState *state = [[TCMMMState alloc] initAsServer:YES];
            [state setDelegate:self];
            [state setClient:profile];
            [I_statesByClientID setObject:state forKey:[user userID]];
            [profile setMMState:state];
            [profile acceptJoin];
            [profile sendSessionInformation:[self TCM_sessionInformation]];
            [state release];
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

- (NSData *)sessionBencoded
{
    NSMutableDictionary *sessionDict = [NSMutableDictionary dictionary];
    [sessionDict setObject:[self filename] forKey:@"Filename"];
    [sessionDict setObject:[self sessionID] forKey:@"SessionID"];
    [sessionDict setObject:[self hostID] forKey:@"HostID"];
    return TCM_BencodedObject(sessionDict);
}

- (void)join
{
    TCMBEEPSession *session = [[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:[self hostID]];
    [session startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"] andData:nil sender:self];
}

- (void)inviteUserWithID:(NSString *)aUserID
{
    // merk invited userID
    
    TCMBEEPSession *session = [[TCMMMBEEPSessionManager sharedInstance] sessionForUserID:[self hostID]];
    [session startChannelWithProfileURIs:[NSArray arrayWithObject:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"] andData:nil sender:self];
}

- (void)joinRequestWithProfile:(SessionProfile *)profile
{        
    NSString *peerUserID = [[[profile session] userInfo] objectForKey:@"peerUserID"];
    [I_profilesByUserID setObject:profile forKey:peerUserID];
    // decide if autojoin depending on setting
    
    // if no autojoin add user to pending users and notify 
    [I_pendingUsers addObject:[[TCMMMUserManager sharedInstance] userForUserID:peerUserID]];
    [[NSNotificationCenter defaultCenter] postNotificationName:TCMMMSessionPendingUsersDidChangeNotification object:self];
}

- (void)invitationWithProfile:(SessionProfile *)profile
{
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
            [user joinSessionID:[self sessionID]];
            [groupArray addObject:user];
            [I_groupByUserID setObject:group forKey:[user userID]];
        }
    }
}

#pragma mark -

// When you request a profile you have to implement BEEPSession:didOpenChannelWithProfile: to receive the profile
- (void)BEEPSession:(TCMBEEPSession *)session didOpenChannelWithProfile:(TCMBEEPProfile *)profile
{
    // check if invitation or join is happening
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"BEEPSession:%@ didOpenChannel: %@", session, profile);
    [I_profilesByUserID setObject:profile forKey:[self hostID]];
    [profile setDelegate:self];
    [(SessionProfile *)profile sendJoinRequestForSessionID:[self sessionID]];
}

# pragma mark -

- (void)profile:(SessionProfile *)profile didReceiveSessionContent:(id)aContent {
    NSString *string=[aContent objectForKey:@"Content"];
    NSTextStorage *textStorage=[(PlainTextDocument *)[self document] textStorage];
    [textStorage replaceCharactersInRange:NSMakeRange(0,[textStorage length]) withString:string];
}

- (void)profileDidAcceptJoinRequest:(SessionProfile *)profile
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"profileDidAcceptJoinRequest: %@", profile);
    [[DocumentController sharedInstance] addDocumentWithSession:self];
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
        [I_contributors addObject:[userManager userForUserID:[user userID]]];
    }

    [self TCM_setSessionParticipants:[sessionInfo objectForKey:@"Participants"]];

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
    [aProfile sendSessionContent:[NSDictionary dictionaryWithObject:[[(PlainTextDocument *)[self document] textStorage] string] forKey:@"Content"]];
}

#pragma mark -
#pragma ### State interaction ###

- (void)state:(TCMMMState *)aState handleOperation:(TCMMMOperation *)anOperation {

    // NSLog(@"state:%@ handleOperation:%@",aState,anOperation);

    [(PlainTextDocument *)[self document] handleOperation:anOperation];
    
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
