//
//  TCMBEEPSession.h
//  TCMBEEP
//
//  Created by Martin Ott on Mon Feb 16 2004.
//  Copyright (c) 2004-2007 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sasl.h"
#import "TCMBEEPProfile.h"

extern NSString * const NetworkTimeoutPreferenceKey;
extern NSString * const kTCMBEEPFrameTrailer;
extern NSString * const kTCMBEEPManagementProfile;
extern NSString * const TCMBEEPTLSProfileURI;
extern NSString * const TCMBEEPSASLProfileURIPrefix;
extern NSString * const TCMBEEPSASLANONYMOUSProfileURI;
extern NSString * const TCMBEEPSASLPLAINProfileURI;
extern NSString * const TCMBEEPSASLCRAMMD5ProfileURI;
extern NSString * const TCMBEEPSASLDIGESTMD5ProfileURI;
extern NSString * const TCMBEEPSASLGSSAPIProfileURI;
extern NSString * const TCMMMBEEPSessionDidReceiveGreetingNotification;

typedef enum {
   TCMBEEPSessionStatusNotOpen = 0,
   TCMBEEPSessionStatusOpening,
   TCMBEEPSessionStatusOpen,
   TCMBEEPSessionStatusClosing,
   TCMBEEPSessionStatusClosed,
   TCMBEEPSessionStatusError
} TCMBEEPSessionStatus;

enum {
    frameHeaderState = 1,
    frameContentState,
    frameEndState
};


@class TCMBEEPChannel, TCMBEEPFrame, TCMBEEPProfile, TCMBEEPAuthenticationClient, TCMBEEPAuthenticationServer;;


@interface TCMBEEPSession : NSObject
{
    CFReadStreamRef I_readStream;
    CFWriteStreamRef I_writeStream;
    NSMutableData *I_readBuffer;
    NSMutableData *I_writeBuffer;
    int I_currentReadState;
    int I_currentReadFrameRemainingContentSize;

    NSMutableDictionary *I_userInfo;

    TCMBEEPChannel *I_managementChannel;
    NSMutableDictionary *I_activeChannels;
    NSMutableArray *I_channels;
    
    int32_t I_nextChannelNumber;
    int I_maximumFrameSize;
    
    id I_delegate;
    
    NSData *I_peerAddressData;
    
    NSMutableArray *I_profileURIs;
    NSArray *I_peerProfileURIs;
    
    NSString *I_featuresAttribute;
    NSString *I_localizeAttribute;
    NSString *I_peerFeaturesAttribute;
    NSString *I_peerLocalizeAttribute;
    
    NSMutableDictionary *I_channelRequests;
    
    TCMBEEPFrame *I_currentReadFrame;
    struct {
        BOOL isInitiator;
        BOOL isProhibitingInboundInternetSessions;
        BOOL amReading;
        BOOL needsToReadAgain;
    } I_flags;
    
    TCMBEEPSessionStatus I_sessionStatus;

    NSTimer *I_terminateTimer;
    NSTimeInterval I_timeout;
    
    TCMBEEPAuthenticationClient *_authClient;
    TCMBEEPAuthenticationServer *_authServer;
    
#ifndef TCM_NO_DEBUG
	BOOL isLogging;
    NSFileHandle *I_frameLogHandle;
    NSFileHandle *I_rawLogInHandle;
    NSFileHandle *I_rawLogOutHandle;
#endif
}

/*"Initializers"*/
- (id)initWithSocket:(CFSocketNativeHandle)aSocketHandle addressData:(NSData *)aData;
- (id)initWithAddressData:(NSData *)aData;

- (void)startTerminator;
- (void)triggerTerminator;
- (void)invalidateTerminator;

/*"Accessors"*/
- (void)setDelegate:(id)aDelegate;
- (id)delegate;
- (void)setUserInfo:(NSMutableDictionary *)aUserInfo;
- (NSMutableDictionary *)userInfo;
- (void)addProfileURIs:(NSArray *)anArray;
- (void)setProfileURIs:(NSArray *)anArray;
- (NSArray *)profileURIs;
- (void)setPeerProfileURIs:(NSArray *)anArray;
- (NSArray *)peerProfileURIs;
- (void)setPeerAddressData:(NSData *)aData;
- (NSData *)peerAddressData;
- (void)setFeaturesAttribute:(NSString *)anAttribute;
- (NSString *)featuresAttribute;
- (void)setPeerFeaturesAttribute:(NSString *)anAttribute;
- (NSString *)peerFeaturesAttribute;
- (void)setLocalizeAttribute:(NSString *)anAttribute;
- (NSString *)localizeAttribute;
- (void)setPeerLocalizeAttribute:(NSString *)anAttribute;
- (NSString *)peerLocalizeAttribute;
- (BOOL)isInitiator;
- (NSMutableDictionary *)activeChannels;
- (int)maximumFrameSize;
- (TCMBEEPSessionStatus)sessionStatus;
- (NSArray *)channels;
- (void)setIsProhibitingInboundInternetSessions:(BOOL)flag;
- (BOOL)isProhibitingInboundInternetSessions;
- (TCMBEEPAuthenticationClient *)authenticationClient;
- (TCMBEEPAuthenticationServer *)authenticationServer;
- (NSData *)addressData;
- (BOOL)isAuthenticated;

- (void)open;
- (void)authenticate;
- (void)terminate;
- (void)activateChannel:(TCMBEEPChannel *)aChannel;
- (void)channelHasFramesAvailable:(TCMBEEPChannel *)aChannel;
- (void)startChannelWithProfileURIs:(NSArray *)aProfileURIArray andData:(NSArray *)aDataArray sender:(id)aSender;
- (void)initiateChannelWithNumber:(int32_t)aChannelNumber profileURI:(NSString *)aProfileURI data:(NSData *)inData asInitiator:(BOOL)isInitiator;
- (void)closeChannelWithNumber:(int32_t)aChannelNumber code:(int)aReplyCode;
- (void)closeRequestedForChannelWithNumber:(int32_t)aChannelNumber;
- (void)acceptCloseRequestForChannelWithNumber:(int32_t)aChannelNumber;

@end


@interface NSObject (TCMBEEPSessionDelegateAdditions)

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didReceiveGreetingWithProfileURIs:(NSArray *)aProfileURIArray;
- (NSMutableDictionary *)BEEPSession:(TCMBEEPSession *)aBEEPSession willSendReply:(NSMutableDictionary *)aReply forChannelRequests:(NSArray *)aRequests;
- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didOpenChannelWithProfile:(TCMBEEPProfile *)aProfile data:(NSData *)inData;
- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didFailWithError:(NSError *)anError;
- (void)BEEPSessionDidClose:(TCMBEEPSession *)aBEEPSession;

@end
