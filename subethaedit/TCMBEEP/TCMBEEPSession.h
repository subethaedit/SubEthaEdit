//
//  TCMBEEPSession.h
//  TCMBEEP
//
//  Created by Martin Ott on Mon Feb 16 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCMBEEPProfile.h"


extern NSString * const kTCMBEEPFrameTrailer;
extern NSString * const kTCMBEEPManagementProfile;


enum {
    frameHeaderState = 1,
    frameContentState,
    frameEndState
};


@class TCMBEEPChannel, TCMBEEPFrame, TCMBEEPProfile;


@interface TCMBEEPSession : NSObject
{
    NSInputStream *I_inputStream;
    NSOutputStream *I_outputStream;
    NSMutableData *I_readBuffer;
    NSMutableData *I_writeBuffer;
    int I_currentReadState;
    int I_currentReadFrameRemainingContentSize;

    NSMutableDictionary *I_userInfo;

    TCMBEEPChannel *I_managementChannel;
    NSMutableDictionary *I_requestedChannels;
    NSMutableDictionary *I_activeChannels;
    
    int32_t I_nextChannelNumber;
    int I_maximumFrameSize;
    
    id I_delegate;
    
    NSData *I_peerAddressData;
    
    NSArray *I_profileURIs;
    NSArray *I_peerProfileURIs;
    
    NSString *I_featuresAttribute;
    NSString *I_localizeAttribute;
    NSString *I_peerFeaturesAttribute;
    NSString *I_peerLocalizeAttribute;
    
    NSMutableDictionary *I_channelRequests;
    
    TCMBEEPFrame *I_currentReadFrame;
    struct {
        BOOL isSending;
        BOOL isInitiator;
    } I_flags;
        
#ifdef TCMBEEP_DEBUG
    NSFileHandle *I_frameLogHandle;
    NSFileHandle *I_rawLogInHandle;
    NSFileHandle *I_rawLogOutHandle;
#endif
}

/*"Initializers"*/
- (id)initWithSocket:(CFSocketNativeHandle)aSocketHandle addressData:(NSData *)aData;
- (id)initWithAddressData:(NSData *)aData;

/*"Accessors"*/
- (void)setDelegate:(id)aDelegate;
- (id)delegate;
- (void)setUserInfo:(NSMutableDictionary *)aUserInfo;
- (NSMutableDictionary *)userInfo;
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

- (void)open;
- (void)close;
- (void)terminate;
- (void)activateChannel:(TCMBEEPChannel *)aChannel;
- (void)channelHasFramesAvailable:(TCMBEEPChannel *)aChannel;
- (void)startChannelWithProfileURIs:(NSArray *)aProfileURIArray andData:(NSArray *)aDataArray sender:(id)aSender;
- (void)initiateChannelWithNumber:(int32_t)aChannelNumber profileURI:(NSString *)aProfileURI asInitiator:(BOOL)isInitiator;
- (void)closeChannelWithNumber:(int32_t)aChannelNumber code:(int)aReplyCode;

@end


@interface NSObject (TCMBEEPSessionDelegateAdditions)

- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didReceiveGreetingWithProfileURIs:(NSArray *)aProfileURIArray;
- (NSMutableDictionary *)BEEPSession:(TCMBEEPSession *)aBEEPSession willSendReply:(NSMutableDictionary *)aReply forChannelRequests:(NSArray *)aRequests;
- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didOpenChannelWithProfile:(TCMBEEPProfile *)aProfile;
- (void)BEEPSession:(TCMBEEPSession *)aBEEPSession didFailWithError:(NSError *)anError;
- (void)BEEPSessionDidClose:(TCMBEEPSession *)aBEEPSession;

@end
