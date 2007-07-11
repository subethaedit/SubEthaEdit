//
//  TCMMMState.m
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMState.h"
#import "TCMMMOperation.h"
#import "TCMMMNoOperation.h"
#import "TCMMMMessage.h"
#import "TCMMMTransformator.h"
#import "TCMMMUserManager.h"
#import "UserChangeOperation.h"


@implementation TCMMMState

- (id)initAsServer:(BOOL)isServer {
    self = [super init];
    if (self) {
        I_messageBuffer = [NSMutableArray new];
        I_incomingMessages = [NSMutableArray new];
        I_isServer = isServer;
        I_numberOfClientMessages = 0;
        I_numberOfServerMessages = 0;
        I_isSendingNoOps = NO;
    }
    return self;
}

- (void)dealloc {
    // DEBUGLOG(@"MillionMonkeysLogDomain", AlwaysLogLevel, @"MMState incoming messages %@",[I_incomingMessages description]);
    I_client = nil;
    I_delegate = nil;
    [I_timer invalidate];
    [I_timer release];
    [I_messageBuffer release];
    [I_incomingMessages release];
    DEBUGLOG(@"MillionMonkeysLogDomain", AllLogLevel, @"MMState deallocated");
    [super dealloc];
}

- (BOOL)isSendingNoOps {
    return I_isSendingNoOps;
}

- (void)setIsSendingNoOps:(BOOL)aFlag {
    if (aFlag) {
        if (!I_isSendingNoOps) {
            I_timer = [[NSTimer timerWithTimeInterval:60 target:self selector:@selector(sendNoOperation:) userInfo:nil repeats:YES] retain];
            [[NSRunLoop currentRunLoop] addTimer:I_timer forMode:NSDefaultRunLoopMode];
        }
    } else {
        if (I_isSendingNoOps) {
            [I_timer invalidate];
            [I_timer release];
            I_timer = nil;
        }
    }
        
    I_isSendingNoOps = aFlag;
}

- (BOOL)isServer {
    return I_isServer;
}

- (void)setClient:(NSObject <TCMMMStateClientProtocol> *)aClient {
    I_client = aClient;
    if (!I_client) {
        [self setIsSendingNoOps:NO];
    }
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

- (BOOL)hasMessagesAvailable {
    return ([I_incomingMessages count] > 0);
}

- (BOOL)processMessage {
    
    TCMMMMessage *aMessage = [I_incomingMessages lastObject];
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"process: %@", aMessage);
    BOOL result = YES;
    if (aMessage) {
        
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
                 DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"transforming with: %@", message);
                [transformator transformOperation:[message operation] serverOperation:[aMessage operation]];
                [message incrementNumberOfServerMessages];
            }
        }
    
    
        // apply operation
        if ([[self delegate] respondsToSelector:@selector(state:handleOperation:)]) {
            result = [[self delegate] state:self handleOperation:[aMessage operation]];
        }
    
        // update state space
        if (I_isServer) {
            I_numberOfClientMessages++;
        } else {
            I_numberOfServerMessages++;
        }
        
        [I_incomingMessages removeLastObject];
    }
    return result;
}

- (void)processAllUserChangeMessages {
    NSEnumerator *incomingMessages=[I_incomingMessages reverseObjectEnumerator];
    TCMMMMessage *message=nil;
    while ((message=[incomingMessages nextObject])) {
        TCMMMOperation *operation=[message operation];
        if ([operation isKindOfClass:[UserChangeOperation class]]) {
            if ([[self delegate] respondsToSelector:@selector(state:handleOperation:)]) {
                [[self delegate] state:self handleOperation:operation];
            }
        }
    }
}

- (void)appendOperationToIncomingMessageQueue:(TCMMMOperation *)anOperation {
    TCMMMMessage *message = [[[TCMMMMessage alloc] initWithOperation:anOperation numberOfClient:I_numberOfClientMessages numberOfServer:I_numberOfServerMessages] autorelease];
    [I_incomingMessages insertObject:message atIndex:0];
    [[self delegate] stateHasMessagesAvailable:self];
}

- (void)handleMessage:(TCMMMMessage *)aMessage {
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"handleMessage: %@", aMessage);
    [I_incomingMessages insertObject:aMessage atIndex:0];
    [[self delegate] stateHasMessagesAvailable:self];
}

- (void)handleOperation:(TCMMMOperation *)anOperation {
    
    // wrap operation in message and put it in the buffer
    TCMMMMessage *message = [[[TCMMMMessage alloc] initWithOperation:anOperation numberOfClient:I_numberOfClientMessages numberOfServer:I_numberOfServerMessages] autorelease];
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"buffering Message: %@", message);
    if ([self isServer]) {
        I_numberOfServerMessages++;
    } else {
        I_numberOfClientMessages++;
    }
    [I_messageBuffer addObject:message];
    [I_client state:self handleMessage:message];
}

- (id)lastIncomingMessage {
    if ([I_incomingMessages count]>0) {
        return [I_incomingMessages objectAtIndex:0];
    } else {
        return nil;
    }
}


#pragma mark -

- (void)sendNoOperation:(NSTimer *)timer {
    DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"Send nop");
    if (!I_delegate || !I_client) {
        [I_timer invalidate];
        return;
    }
    TCMMMNoOperation *operation = [[TCMMMNoOperation alloc] init];
    [operation setUserID:[TCMMMUserManager myUserID]];
    [self handleOperation:[operation autorelease]];
}

@end
