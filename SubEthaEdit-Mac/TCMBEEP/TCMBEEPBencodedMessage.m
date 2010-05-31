//
//  TCMBEEPBencodedMessage.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.04.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import "TCMBEEPBencodedMessage.h"


@implementation TCMBEEPBencodedMessage

+ (id)bencodedMessageWithBEEPMessage:(TCMBEEPMessage *)aMessage {
    return [[[TCMBEEPBencodedMessage alloc] initWithBEEPMessage:aMessage] autorelease];
}

+ (id)bencodedMessageWithMessageType:(NSString *)aMessageType messageNumber:(int32_t)aMessageNumber messageString:(NSString *)aMessageString content:(id)aContent {
    TCMBEEPBencodedMessage *result = [[[TCMBEEPBencodedMessage alloc] initWithMessageType:(NSString *)aMessageType messageNumber:(int32_t)aMessageNumber] autorelease];
    [result setContent:aContent];
    [result setMessageString:aMessageString];
    return result;
}


- (id)initWithMessageType:(NSString *)aMessageType messageNumber:(int32_t)aMessageNumber {
    if ((self=[super init])) {
        _BEEPMessage = [[TCMBEEPMessage alloc] initWithTypeString:aMessageType messageNumber:aMessageNumber payload:nil];
    }
    return self;
}

- (id)initWithBEEPMessage:(TCMBEEPMessage *)aMessage {
    if ((self=[super init])) {
        if ([[aMessage payload] length]<6) {
            [self dealloc];
            return nil;
        }
        [self setMessageString:[[[NSString alloc] initWithBytesNoCopy:(char *)[[aMessage payload] bytes] length:6 encoding:NSASCIIStringEncoding freeWhenDone:NO] autorelease]];
        if ([[aMessage payload] length] > 6) {
            id content = TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(6, [[aMessage payload] length]-6)]);
            if (!content) {
                [self dealloc];
                return nil;
            }
            [self setContent:content];
        }
        _BEEPMessage = [aMessage retain];
    }
    return self;
}

- (void)dealloc {
    [_messageString release];
    [_content release];
    [_BEEPMessage release];
    [super dealloc];
}

- (void)updatePayload {
    if (_messageString) {
        NSMutableData *payload = (NSMutableData *)[_messageString dataUsingEncoding:NSASCIIStringEncoding];
        if (_content) {
            payload = [[payload mutableCopy] autorelease];
            [payload appendData:TCM_BencodedObject(_content)];
        }
        [_BEEPMessage setPayload:payload];
    }
}

- (void)setMessageString:(NSString *)aString {
    [_messageString autorelease];
     _messageString = [aString copy];
    if (_messageString) {
        [self updatePayload];
    }
}

- (NSString *)messageString {
    return _messageString;
}
- (void)setContent:(id)aContent {
    [_content autorelease];
     _content = [aContent retain];
    if (_messageString) {
        [self updatePayload];
    }
}
- (id)content {
    return _content;
}

- (TCMBEEPMessage *)BEEPMessage {
    return _BEEPMessage;
}

- (int32_t)messageNumber {
    return [_BEEPMessage messageNumber];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"TCMBEEPBencodedMessage: %@ %@ %@",[_BEEPMessage messageTypeString], _messageString, _content];
}


@end
