//
//  TCMMMState.m
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMState.h"
#import "TCMMMOperation.h"
#import "TCMMMMessage.h"
#import "TCMMMTransformator.h"


@implementation TCMMMState

- (id)initAsServer:(BOOL)isServer {
    self = [super init];
    if (self) {
        I_messageBuffer = [NSMutableArray new];
        I_isServer = isServer;
        I_numberOfClientMessages = 0;
        I_numberOfServerMessages = 0;
    }
    return self;
}

- (void)dealloc {
    I_client = nil;
    I_delegate = nil;
    [I_messageBuffer release];
    [super dealloc];
}

- (BOOL)isServer {
    return I_isServer;
}

- (void)setClient:(NSObject <TCMMMStateClientProtocol> *)aClient {
    I_client = aClient;
}

- (void)setDelegate:(id)aDelegate {
    I_delegate = aDelegate;
}

- (id)delegate {
    return I_delegate;
}

- (NSObject <TCMMMStateClientProtocol> *)client {
    return I_client;
}

- (void)handleMessage:(TCMMMMessage *)aMessage {
    // clean up buffer
    unsigned int i;
    if (I_isServer) {
        for (i = 0; i < [I_messageBuffer count];) {
            if ([[I_messageBuffer objectAtIndex:i] numberOfServerMessages]
                < [aMessage numberOfServerMessages]) {
                [I_messageBuffer removeObjectAtIndex:i];
            } else {
                i++;
            }
        }    
    } else {
        for (i = 0; i < [I_messageBuffer count];) {
            if ([[I_messageBuffer objectAtIndex:i] numberOfClientMessages]
                < [aMessage numberOfClientMessages]) {
                [I_messageBuffer removeObjectAtIndex:i];
            } else {
                i++;
            }
        }
    }

    // unwrap message
    // iterate over message buffer and transform each operation with incoming operation
    TCMMMTransformator *transformator = [TCMMMTransformator sharedInstance];
    NSEnumerator *messages = [I_messageBuffer objectEnumerator];
    TCMMMMessage *message;
    if (I_isServer) {
        while ((message = [messages nextObject])) {
            // transform now
            [transformator transformOperation:[aMessage operation] serverOperation:[message operation]];
            [message incrementNumberOfClientMessages];
        }
    } else {
        while ((message = [messages nextObject])) {
            // transform now
            [transformator transformOperation:[message operation] serverOperation:[aMessage operation]];
            [message incrementNumberOfServerMessages];
        }
    }


    // apply operation
    if ([[self delegate] respondsToSelector:@selector(state:handleOperation:)]) {
        [[self delegate] state:self handleOperation:[aMessage operation]];
    }

    // update state space
    if (I_isServer) {
        I_numberOfClientMessages++;
    } else {
        I_numberOfServerMessages++;
    }
}

- (void)handleOperation:(TCMMMOperation *)anOperation {
    
    // wrap operation in message and put it in the buffer
    TCMMMMessage *message = [[[TCMMMMessage alloc] initWithOperation:anOperation numberOfClient:I_numberOfClientMessages numberOfServer:I_numberOfServerMessages] autorelease];
    if ([self isServer]) {
        I_numberOfServerMessages++;
    } else {
        I_numberOfClientMessages++;
    }
    [I_messageBuffer addObject:message];
    [I_client state:self handleMessage:message];
}

@end
