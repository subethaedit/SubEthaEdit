//
//  TCMMMState.h
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@class TCMMMState, TCMMMMessage, TCMMMOperation;


@protocol TCMMMStateClientProtocol

- (void)state:(TCMMMState *)aState handleMessage:(TCMMMMessage *)aMessage;

@end


@interface TCMMMState : NSObject {
    long long I_numberOfClientMessages;
    long long I_numberOfServerMessages;
    NSMutableArray *I_messageBuffer;
    NSMutableArray *I_incomingMessages;
    BOOL I_isServer;
    BOOL I_isSendingNoOps;
    NSObject <TCMMMStateClientProtocol> *I_client;
    NSTimer *I_timer;
    id I_delegate;
}

- (id)initAsServer:(BOOL)isServer;

- (BOOL)isSendingNoOps;
- (void)setIsSendingNoOps:(BOOL)aFlag;
- (BOOL)isServer;
- (void)setClient:(NSObject <TCMMMStateClientProtocol> *)aClient;
- (NSObject <TCMMMStateClientProtocol> *)client;
- (void)setDelegate:(id)aDelegate;
- (id)delegate;

- (void)processAllUserChangeMessages;
- (void)appendOperationToIncomingMessageQueue:(TCMMMOperation *)anOperation;
- (void)handleMessage:(TCMMMMessage *)aMessage;
- (void)handleOperation:(TCMMMOperation *)anOperation;

- (BOOL)hasMessagesAvailable;
- (BOOL)processMessage;

@end


@interface NSObject (TCMMMStateDelegateAdditions)

- (BOOL)state:(TCMMMState *)aState handleOperation:(TCMMMOperation *)anOperation;
- (void)stateHasMessagesAvailable:(TCMMMState *)aState;

@end

/*
[session documentDidApplyOperation:];
[state handleOperation:];
[client state:self handleMessage:];


[state    handleMessage:]
[delegate state:self handleOperation:]
[document handleOperation:]
*/


