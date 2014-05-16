//
//  SEEConnection.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 08.05.07.
//	Updated by Michael Ehrmann on Fri Feb 21 2014.
//  Copyright 2007-2014 TheCodingMonkeys. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "TCMBEEP.h"
#import "TCMMillionMonkeys.h"

extern NSString * const SEEConnectionStatusDidChangeNotification;

extern NSString * const ConnectionStatusConnected;
extern NSString * const ConnectionStatusInProgress;
extern NSString * const ConnectionStatusNoConnection;


@interface SEEConnection : NSObject

@property (nonatomic, readonly) BOOL isBonjour;
@property (nonatomic, readonly) BOOL isVisible;
@property (nonatomic, readonly) BOOL isClearable;

@property (nonatomic, readonly, strong) TCMBEEPSession *BEEPSession;
@property (nonatomic, readonly) NSString *userID;
@property (nonatomic, readonly) TCMMMUser *user;

/*! the URL we connected with */
@property (nonatomic, readonly, strong) NSURL *URL;
@property (nonatomic, readonly, strong) NSString *hostStatus;
@property (nonatomic, readonly) NSString *connectionStatus;

@property (nonatomic, readonly, strong) NSArray *announcedSessions;

- (id)initWithURL:(NSURL *)anURL;
- (id)initWithBEEPSession:(TCMBEEPSession *)aSession;

- (BOOL)handleURL:(NSURL *)anURL;
- (BOOL)handleSession:(TCMBEEPSession *)aSession;
- (BOOL)handleSessionDidEnd:(TCMBEEPSession *)aSession;

- (void)connect;
- (void)reloadAnnouncedSessions;
- (void)checkDocumentRequests;
- (void)cancel;

- (NSString *)toolTipString;

@end
