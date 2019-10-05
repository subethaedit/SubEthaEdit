//  TCMMMState.m
//  SubEthaEdit
//
//  Created by Martin Ott on Fri Mar 19 2004.

#import "TCMMMState.h"
#import "TCMMMOperation.h"
#import "TCMMMNoOperation.h"
#import "TCMMMMessage.h"
#import "TCMMMTransformator.h"
#import "TCMMMUserManager.h"
#import "UserChangeOperation.h"

@implementation TCMMMState

- (instancetype)initAsServer:(BOOL)isServer {
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
    [I_timer invalidate];
    DEBUGLOG(@"MillionMonkeysLogDomain", AllLogLevel, @"MMState deallocated");
}

- (BOOL)isSendingNoOps {
    return I_isSendingNoOps;
}

- (void)setIsSendingNoOps:(BOOL)aFlag {
    if (aFlag) {
        if (!I_isSendingNoOps) {
            I_timer = [NSTimer timerWithTimeInterval:60 target:self selector:@selector(sendNoOperation:) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:I_timer forMode:NSDefaultRunLoopMode];
        }
    } else {
        if (I_isSendingNoOps) {
            [I_timer invalidate];
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
        NSUInteger i;
        if (I_isServer) {
			NSInteger numberOfServerMessages = [aMessage numberOfServerMessages];
            for (i = 0; i < [I_messageBuffer count];) {
                if ([[I_messageBuffer objectAtIndex:i] numberOfServerMessages] < numberOfServerMessages) {
                    [I_messageBuffer removeObjectAtIndex:i];
                } else {
                    i++;
                }
            }
        } else {
			NSInteger numberOfClientMessages = [aMessage numberOfClientMessages];
            for (i = 0; i < [I_messageBuffer count];) {
                if ([[I_messageBuffer objectAtIndex:i] numberOfClientMessages] < numberOfClientMessages) {
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
				DEBUGLOG(@"MillionMonkeysLogDomain", DetailedLogLevel, @"server transforming %@ with: %@", aMessage, message);
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
    TCMMMMessage *message = [[TCMMMMessage alloc] initWithOperation:anOperation numberOfClient:I_numberOfClientMessages numberOfServer:I_numberOfServerMessages];
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
    TCMMMMessage *message = [[TCMMMMessage alloc] initWithOperation:anOperation numberOfClient:I_numberOfClientMessages numberOfServer:I_numberOfServerMessages];
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
    if (!_delegate || !I_client) {
        [I_timer invalidate];
        return;
    }
    TCMMMNoOperation *operation = [[TCMMMNoOperation alloc] init];
    [operation setUserID:[TCMMMUserManager myUserID]];
    [self handleOperation:operation];
}

@end
