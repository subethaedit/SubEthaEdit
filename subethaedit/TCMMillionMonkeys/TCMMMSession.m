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
#import "SessionProfile.h"


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
    [I_participants release];
    [I_filename release];
    [I_sessionID release];
    [I_profilesByUserID release];
    [super dealloc];
}

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
    
    // ask someone, but for now auto-accept joins
    [profile acceptJoin];
}

- (void)invitationWithProfile:(SessionProfile *)profile
{
}

#pragma mark -

// When you request a profile you have to implement BEEPSession:didOpenChannelWithProfile: to receive the profile
- (void)BEEPSession:(TCMBEEPSession *)session didOpenChannelWithProfile:(TCMBEEPProfile *)profile
{
    // check if invitiation or join is happening
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"BEEPSession:%@ didOpenChannel: %@", session, profile);
    [I_profilesByUserID setObject:profile forKey:[self hostID]];
    [profile setDelegate:self];
    [(SessionProfile *)profile sendJoinRequestForSessionID:[self sessionID]];
}

# pragma mark -

- (void)profileDidAcceptJoinRequest:(SessionProfile *)profile
{
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"profileDidAcceptJoinRequest: %@", profile);
}

@end
