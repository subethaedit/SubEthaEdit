//  TCMBEEPBencodedMessage.h
//  SubEthaEdit
//

#import <Cocoa/Cocoa.h>

@class TCMBEEPMessage;

// BEEPBencodedMessages have this form:
// 6 Bytes ASCII Message string (e.g. USRFUL, STAINV, etc...)
// optional n-bytes bencoded content data;

@interface TCMBEEPBencodedMessage : NSObject {
    TCMBEEPMessage *_BEEPMessage;
    NSString *_messageString;
    id _content;
}
+ (id)bencodedMessageWithBEEPMessage:(TCMBEEPMessage *)aMessage;
- (instancetype)initWithBEEPMessage:(TCMBEEPMessage *)aMessage;
+ (id)bencodedMessageWithMessageType:(NSString *)aMessageType messageNumber:(int32_t)aMessageNumber messageString:(NSString *)aMessageString content:(id)aContent;
- (instancetype)initWithMessageType:(NSString *)aMessageType messageNumber:(int32_t)aMessageNumber;

- (TCMBEEPMessage *)BEEPMessage;
- (void)setMessageString:(NSString *)aString;
- (NSString *)messageString;
- (void)setContent:(id)aContent;
- (id)content;
- (int32_t)messageNumber;

@end
