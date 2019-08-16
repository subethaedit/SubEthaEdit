//  TCMBEEPBencodedMessage.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 25.04.07.

#import "TCMBEEPBencodedMessage.h"

@implementation TCMBEEPBencodedMessage

+ (id)bencodedMessageWithBEEPMessage:(TCMBEEPMessage *)aMessage {
    return [[TCMBEEPBencodedMessage alloc] initWithBEEPMessage:aMessage];
}

+ (id)bencodedMessageWithMessageType:(NSString *)aMessageType messageNumber:(int32_t)aMessageNumber messageString:(NSString *)aMessageString content:(id)aContent {
    TCMBEEPBencodedMessage *result = [[TCMBEEPBencodedMessage alloc] initWithMessageType:(NSString *)aMessageType messageNumber:(int32_t)aMessageNumber];
    [result setContent:aContent];
    [result setMessageString:aMessageString];
    return result;
}


- (instancetype)initWithMessageType:(NSString *)aMessageType messageNumber:(int32_t)aMessageNumber {
    if ((self=[super init])) {
        _BEEPMessage = [[TCMBEEPMessage alloc] initWithTypeString:aMessageType messageNumber:aMessageNumber payload:nil];
    }
    return self;
}

- (instancetype)initWithBEEPMessage:(TCMBEEPMessage *)aMessage {
    if ((self=[super init])) {
        if ([[aMessage payload] length]<6) {
            return nil;
        }
        [self setMessageString:[[NSString alloc] initWithBytesNoCopy:(char *)[[aMessage payload] bytes] length:6 encoding:NSASCIIStringEncoding freeWhenDone:NO]];
        if ([[aMessage payload] length] > 6) {
            id content = TCM_BdecodedObjectWithData([[aMessage payload] subdataWithRange:NSMakeRange(6, [[aMessage payload] length]-6)]);
            if (!content) {
                return nil;
            }
            [self setContent:content];
        }
        _BEEPMessage = aMessage;
    }
    return self;
}

- (void)updatePayload {
    if (_messageString) {
        NSMutableData *payload = (NSMutableData *)[_messageString dataUsingEncoding:NSASCIIStringEncoding];
        if (_content) {
            payload = [payload mutableCopy];
            [payload appendData:TCM_BencodedObject(_content)];
        }
        [_BEEPMessage setPayload:payload];
    }
}

- (void)setMessageString:(NSString *)aString {
     _messageString = [aString copy];
    if (_messageString) {
        [self updatePayload];
    }
}

- (NSString *)messageString {
    return _messageString;
}
- (void)setContent:(id)aContent {
     _content = aContent;
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
