//
//  TCMBEEPBencodingProfile.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPBencodingProfile.h"
#import "TCMBEEPBencodedMessage.h"
#import "TCMBEEPMessage.h"

static NSMutableDictionary *S_routingDictionary=nil;

@implementation TCMBEEPBencodingProfile

+ (void)initialize {
	if (self == [TCMBEEPBencodingProfile class]) {
	    S_routingDictionary = [NSMutableDictionary new];
	}
}

+ (NSMutableDictionary *)myRoutingDictionary {
    id result = [S_routingDictionary objectForKey:NSStringFromClass([self class])];
    if (!result) {
        result = [NSMutableDictionary dictionary];
        [S_routingDictionary setObject:result forKey:NSStringFromClass([self class])];
        [result setObject:[NSMutableDictionary dictionary] forKey:[NSNumber numberWithInt:TCMBEEPChannelRoleInitiator]];
        [result setObject:[NSMutableDictionary dictionary] forKey:[NSNumber numberWithInt:TCMBEEPChannelRoleResponder]];
    }
    return result;
}

+ (void)registerSelector:(SEL)aSelector forMessageType:(NSString *)aMessageType messageString:(NSString *)aMessageString channelRole:(TCMBEEPChannelRole)aRole {
    NSMutableDictionary *routingDictionary = [self myRoutingDictionary];
    int i = 1;
    for (i=1;i<=2;i++) {
        if (aRole & i) {
            NSMutableDictionary *roleRoutingTable = [routingDictionary objectForKey:[NSNumber numberWithInt:i]];
            if (!aMessageType) aMessageType = @"FallBack";
            NSMutableDictionary *messageRoutingTable = [roleRoutingTable objectForKey:aMessageString];
            if (!messageRoutingTable) {
                messageRoutingTable = [NSMutableDictionary dictionary];
                [roleRoutingTable setObject:messageRoutingTable forKey:aMessageString];
            }
            [messageRoutingTable setObject:[NSValue valueWithBytes:&aSelector objCType:@encode(SEL)]
                                     forKey:aMessageType];
        }
    }
}

- (void)processBEEPMessage:(TCMBEEPMessage *)aMessage {
    TCMBEEPBencodedMessage *message = [TCMBEEPBencodedMessage bencodedMessageWithBEEPMessage:aMessage];
    if (!message) {
        [self abortIncomingMessages];
        [self close];
    } else {
        // filter the message and apply the method
        NSMutableDictionary *routingTable = [[[self class] myRoutingDictionary] objectForKey:[NSNumber numberWithInt:[[self channel] isInitiator]?TCMBEEPChannelRoleInitiator:TCMBEEPChannelRoleResponder]];
        NSDictionary *messageTable = [routingTable objectForKey:[message messageString]];
        NSValue *selectorValue = [messageTable objectForKey:[[message BEEPMessage] messageTypeString]];
        if (!selectorValue) selectorValue = [messageTable objectForKey:@"FallBack"];
        if (selectorValue) {
            SEL selector = NULL;
            [selectorValue getValue:&selector];
            [self performSelector:selector withObject:message];
        } else {
            NSLog(@"%s got unhandled message: %@",__FUNCTION__,message);
        }
    }
}

@end
