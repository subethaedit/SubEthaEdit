//  TCMBEEPSession.h
//  TCMBEEP
//

#import <Foundation/Foundation.h>
#import "TCMBEEPProfile.h"
#import "TCMBEEPManagementProfile.h"

extern NSString * const NetworkTimeoutPreferenceKey;
extern NSString * const kTCMBEEPFrameTrailer;
extern NSString * const kTCMBEEPManagementProfile;
extern NSString * const TCMBEEPTLSProfileURI;
//extern NSString * const TCMBEEPTLSAnonProfileURI;
extern NSString * const TCMBEEPSASLProfileURIPrefix;
extern NSString * const TCMBEEPSASLANONYMOUSProfileURI;
extern NSString * const TCMBEEPSASLPLAINProfileURI;
extern NSString * const TCMBEEPSASLCRAMMD5ProfileURI;
extern NSString * const TCMBEEPSASLDIGESTMD5ProfileURI;
extern NSString * const TCMBEEPSASLGSSAPIProfileURI;
extern NSString * const TCMBEEPSessionDidReceiveGreetingNotification;

extern NSString * const TCMBEEPSessionAuthenticationInformationDidChangeNotification;


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


@class TCMBEEPChannel, TCMBEEPFrame, TCMBEEPProfile, TCMBEEPSession;

@protocol TCMBEEPAuthenticationDelegate <NSObject>
// provides an information Object representing the authenticated entitiy, if the credentials are valid. nil otherwise.
// for the PLAIN mechanism the credentials are in form "username" and "password"
- (id)authenticationInformationForCredentials:(NSDictionary *)credentials error:(NSError **)error;
@end

@protocol TCMBEEPSessionDelegate <NSObject>
- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didReceiveGreetingWithProfileURIs:(NSArray *)aProfileURIArray;
- (NSMutableDictionary *)BEEPSession:(TCMBEEPSession *)aBEEPSession willSendReply:(NSMutableDictionary *)aReply forChannelRequests:(NSArray *)aRequests;
- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didOpenChannelWithProfile:(TCMBEEPProfile *)aProfile data:(NSData *)inData;
- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didFailWithError:(NSError *)anError;
/* most likely never happening, because we usually abort sessions and don't close them, an this call is only called if it would be closed in a regular fashion */
- (void)BEEPSessionDidClose:(TCMBEEPSession *)aBEEPSession;
@end


@interface TCMBEEPSession : NSObject <TCMBEEPProfileDelegate, TCMBEEPManagementProfileDelegate>
{
    CFReadStreamRef I_readStream;
    CFWriteStreamRef I_writeStream;
    NSMutableData *I_readBuffer;
    NSMutableData *I_writeBuffer;
    int I_currentReadState;
    int I_currentReadFrameRemainingContentSize;
    
    TCMBEEPChannel *I_managementChannel;
    NSMutableDictionary *I_activeChannels;
    NSMutableArray *I_channels;
    
    int32_t I_nextChannelNumber;
    int I_maximumFrameSize;
    
    NSData *I_peerAddressData;
    
    NSMutableArray *_TLSProfileURIs;
    NSMutableArray *_saslProfileURIs;
    
    NSMutableDictionary *I_channelRequests;
    
    TCMBEEPFrame *I_currentReadFrame;
    struct {
        BOOL isInitiator;
        BOOL isProhibitingInboundInternetSessions;
        BOOL amReading;
        BOOL needsToReadAgain;
        BOOL isWaitingForTLSProceed;
        BOOL hasSentTLSProceed;
        BOOL isTLSHandshaking;
        BOOL isTLSEnabled;
    } I_flags;
    
    TCMBEEPSessionStatus I_sessionStatus;

    NSTimer *I_terminateTimer;
    NSTimeInterval I_timeout;
        
#ifndef TCM_NO_DEBUG
	BOOL isLogging;
    NSFileHandle *I_frameLogHandle;
    NSFileHandle *I_rawLogInHandle;
    NSFileHandle *I_rawLogOutHandle;
#endif
}

@property (nonatomic, assign) id <TCMBEEPSessionDelegate>delegate;
@property (nonatomic, assign) id <TCMBEEPAuthenticationDelegate>authenticationDelegate;
@property (nonatomic, retain) id authenticationInformation;
@property (nonatomic, copy) NSMutableDictionary *userInfo;
@property (nonatomic, copy) NSMutableArray *profileURIs;
@property (nonatomic, copy) NSArray *peerProfileURIs;

@property (nonatomic, copy) NSData *peerAddressData;
@property (nonatomic, copy) NSString *featuresAttribute;
@property (nonatomic, copy) NSString *peerFeaturesAttribute;
@property (nonatomic, copy) NSString *localizeAttribute;
@property (nonatomic, copy) NSString *peerLocalizeAttribute;


+ (void)prepareDiffiHellmannParameters;

/*"Initializers"*/
- (id)initWithSocket:(CFSocketNativeHandle)aSocketHandle addressData:(NSData *)aData;
- (id)initWithAddressData:(NSData *)aData;

- (void)startTerminator;
- (void)triggerTerminator;
- (void)invalidateTerminator;

/*"Accessors"*/

- (void)addProfileURIs:(NSArray *)anArray;
- (void)addTLSProfileURIs:(NSArray *)anArray;
- (void)setPeerAddressData:(NSData *)aData;
- (BOOL)isInitiator;
- (NSMutableDictionary *)activeChannels;
- (int)maximumFrameSize;
- (TCMBEEPSessionStatus)sessionStatus;
- (NSArray *)channels;
- (void)setIsProhibitingInboundInternetSessions:(BOOL)flag;
- (BOOL)isProhibitingInboundInternetSessions;
- (NSData *)addressData;
- (BOOL)isAuthenticated;
- (BOOL)isTLSEnabled;

- (NSString *)sessionID;
- (void)open;
- (void)terminate;
- (void)activateChannel:(TCMBEEPChannel *)aChannel;
- (void)channelHasFramesAvailable:(TCMBEEPChannel *)aChannel;
- (void)startChannelWithProfileURIs:(NSArray *)aProfileURIArray andData:(NSArray *)aDataArray sender:(id)aSender;
- (void)initiateChannelWithNumber:(int32_t)aChannelNumber profileURI:(NSString *)aProfileURI data:(NSData *)inData asInitiator:(BOOL)isInitiator;
- (void)closeChannelWithNumber:(int32_t)aChannelNumber code:(int)aReplyCode;
- (void)closeRequestedForChannelWithNumber:(int32_t)aChannelNumber;
- (void)acceptCloseRequestForChannelWithNumber:(int32_t)aChannelNumber;

#pragma mark Authentication
- (NSArray *)availableSASLProfileURIs;
- (void)startAuthenticationWithUserName:(NSString *)aUserName password:(NSString *)aPassword profileURI:(NSString *)aProfileURI;

@end

