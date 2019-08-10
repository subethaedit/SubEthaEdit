//  TCMBEEPMessage.m
//  TCMBEEP
//
//  Created by Martin Ott on Wed Feb 18 2004.

#import "TCMBEEPMessage.h"
#import "TCMBEEPFrame.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@implementation TCMBEEPMessage

+ (TCMBEEPMessage *)messageWithQueue:(NSArray *)aQueue {
    return [[TCMBEEPMessage alloc] initWithQueue:aQueue];
}

- (instancetype)initWithTypeString:(NSString *)aType messageNumber:(int32_t)aMessageNumber payload:(NSData *)aPayload {
    self = [super init];
    if (self) {
        [self setMessageTypeString:aType];
        [self setMessageNumber:aMessageNumber];
        [self setPayload:aPayload];
        self.channelNumber = -1;
        self.answerNumber = -1;
    }
    return self;
}

- (instancetype)initWithQueue:(NSArray *)aQueue {
    NSParameterAssert(aQueue != nil);
    self = [super init];
    if (self) {
        if ([aQueue count] == 0) {
            self = nil;
        } else {
            TCMBEEPFrame *frame = [aQueue objectAtIndex:0];
            [self setMessageTypeString:[NSString stringWithUTF8String:[frame messageType]]];
            [self setMessageNumber:[frame messageNumber]];
            [self setAnswerNumber:[frame answerNumber]];
            _payload = [NSMutableData new];
            for (frame in aQueue) {
                [_payload appendData:[frame payload]];
            }
        }
    }
    return self;
}

- (void)setPayload:(NSData *)aData {
    _payload = [aData mutableCopy];
}

- (unsigned)payloadLength {
    return [_payload length];
}

- (BOOL)isMSG {
    return [_messageTypeString isEqualTo:@"MSG"];
}

- (BOOL)isANS {
    return [_messageTypeString isEqualTo:@"ANS"];
}

- (BOOL)isNUL {
    return [_messageTypeString isEqualTo:@"NUL"];
}

- (BOOL)isRPY {
    return [_messageTypeString isEqualTo:@"RPY"];
}

- (BOOL)isERR {
    return [_messageTypeString isEqualTo:@"ERR"];
}

@end
