//  TCMBEEPFrame.m
//  TCMBEEP
//
//  Created by Martin Ott on Wed Feb 18 2004.

#import "TCMBEEPFrame.h"
#import "TCMBEEPSession.h"
#import "TCMBEEPMessage.h"


@implementation TCMBEEPFrame

+ (TCMBEEPFrame *)SEQFrameWithChannelNumber:(int32_t)channelNumber
                      acknowledgementNumber:(uint32_t)acknowledgementNumber
                                 windowSize:(int32_t)windowSize
{
    return [[[TCMBEEPFrame alloc] initWithChannelNumber:channelNumber
                                  acknowledgementNumber:acknowledgementNumber
                                             windowSize:windowSize] autorelease];

}

+ (TCMBEEPFrame *)frameWithMessage:(TCMBEEPMessage *)aMessage 
                    sequenceNumber:(uint32_t)aSequenceNumber
                     payloadLength:(uint32_t)aLength
                      intermediate:(BOOL)aFlag
{
    return [[[TCMBEEPFrame alloc] initWithMessage:aMessage 
                                   sequenceNumber:aSequenceNumber
                                    payloadLength:aLength
                                     intermediate:aFlag] autorelease];
}

- (id)initWithChannelNumber:(int32_t)channelNumber
      acknowledgementNumber:(uint32_t)acknowledgementNumber
                 windowSize:(int32_t)windowSize
{
    self = [super init];
    if (self) {
        [self setMessageTypeString:@"SEQ"];
        I_channelNumber = channelNumber;
        I_sequenceNumber = acknowledgementNumber;
        I_length = windowSize;  
    }
    return self;
}

- (id)initWithMessage:(TCMBEEPMessage *)aMessage 
       sequenceNumber:(uint32_t)aSequenceNumber
        payloadLength:(uint32_t)aLength
         intermediate:(BOOL)aFlag
{
    self = [super init];
    if (self) {
        [self setMessageTypeString:[aMessage messageTypeString]];
        I_channelNumber = [aMessage channelNumber];
        I_messageNumber = [aMessage messageNumber];
        I_answerNumber = [aMessage answerNumber];
        
        if (aFlag) {
            I_continuationIndicator[0] = '*';
        } else {
            I_continuationIndicator[0] = '.';
        }
        I_continuationIndicator[1] = 0;
        
        if ([aMessage payloadLength] < aLength) {
            DEBUGLOG(@"BEEPLogDomain", SimpleLogLevel, @"ERROR! Absurd length");
        }
        [self setPayload:[[aMessage payload] subdataWithRange:NSMakeRange(0, aLength)]];
        I_length = aLength;
        
        I_sequenceNumber = aSequenceNumber;
    }
    return self;
}

- (id)initWithHeader:(char *)aHeaderString
{
    self = [super init];
    if (self) {
        I_answerNumber = -1;
        BOOL error = NO;
        if (sscanf(aHeaderString, "%3s %d %u %d\r", I_messageType, &I_channelNumber, &I_sequenceNumber, &I_length) == 4) {
            if (strcmp(I_messageType, "SEQ") != 0) {
                error = YES;
            }
        } else if (sscanf(aHeaderString, "%3s %d %d %1s %u %d\r",
                    I_messageType, &I_channelNumber, &I_messageNumber,
                    I_continuationIndicator, &I_sequenceNumber, &I_length) == 6) {
            
        } else if (sscanf(aHeaderString, "%3s %d %d %1s %u %d %d\r",
                    I_messageType, &I_channelNumber, &I_messageNumber,
                    I_continuationIndicator, &I_sequenceNumber, &I_length, &I_answerNumber) == 7) {
            if (strcmp(I_messageType, "ANS") != 0) {
                error = YES;
            }
        } else {
            error = YES;
        }
        if (I_length < 0 || I_length > 2147483647) {
			error = YES;
		}
        if (error) {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (void)dealloc
{
    [I_payload release];
    [super dealloc];
}

- (NSString *)description
{
    if ([self isSEQ]) {
        return [NSString stringWithFormat:@"%3s %d %u %d", I_messageType, I_channelNumber, I_sequenceNumber, I_length];
    } else {
        return [NSString stringWithFormat:@"TCMBEEPFrame: %3s %d %d %1s %u %d - Payload: %@... (%lu)", I_messageType, I_channelNumber, I_messageNumber, I_continuationIndicator, I_sequenceNumber, I_length,([I_payload length]>=6?[[[NSString alloc] initWithBytes:[I_payload bytes] length:6 encoding:NSASCIIStringEncoding] autorelease]:@""),(unsigned long)[I_payload length]];
    }
}

- (NSData *)descriptionInLogFileFormatIncoming:(BOOL)aFlag
{
    NSString *prefix = aFlag ? @"> " : @"< ";
    NSMutableData *data = [NSMutableData data];
    if ([self isSEQ]) {
        NSString *header = [NSString stringWithFormat:@"%@%3s %d %u %d\r\n", prefix, I_messageType, I_channelNumber, I_sequenceNumber, I_length];
        [data appendData:[header dataUsingEncoding:NSASCIIStringEncoding]];
        return data;
    }
    
    NSString *header = [NSString stringWithFormat:@"%@%3s %d %d %1s %u %d\r\n", prefix, I_messageType, I_channelNumber, I_messageNumber, I_continuationIndicator, I_sequenceNumber, I_length];
    [data appendData:[header dataUsingEncoding:NSASCIIStringEncoding]];
    NSString *payloadString = [[[NSString alloc] initWithData:I_payload encoding:NSMacOSRomanStringEncoding] autorelease];
    NSArray *components = [payloadString componentsSeparatedByString:@"\r\n"];
    for (id loopItem in components) {
        [data appendData:[prefix dataUsingEncoding:NSASCIIStringEncoding]];
        [data appendData:[loopItem dataUsingEncoding:NSMacOSRomanStringEncoding]];
        [data appendData:[@"\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    }
    [data appendData:[[NSString stringWithFormat:@"%@END\r\n", prefix] dataUsingEncoding:NSASCIIStringEncoding]];
    
    return data;
}

#pragma mark -

- (void)setMessageTypeString:(NSString *)aString
{
    const char *UTF8String = [aString UTF8String];
    strncpy(I_messageType, UTF8String, 4);
}

- (char *)messageType
{
    return I_messageType;
}

- (int32_t)channelNumber
{
    return I_channelNumber;
}

- (int32_t)messageNumber
{
    return I_messageNumber;
}

-(char *)continuationIndicator
{
    return I_continuationIndicator;
}

-(BOOL)isIntermediate
{
    return (I_continuationIndicator[0] == '*');
}

-(uint32_t)sequenceNumber
{
    return I_sequenceNumber;
}

- (int32_t)length
{
    return I_length;
}

- (int32_t)answerNumber
{
    return I_answerNumber;
}

- (void)setPayload:(NSData *)aData
{
    [I_payload autorelease];
    I_payload = [aData copy];
}

- (NSData *)payload
{
    return I_payload;
}

- (BOOL)isMSG
{
    return (strcmp([self messageType], "MSG") == 0);
}

- (BOOL)isRPY
{
    return (strcmp([self messageType], "RPY") == 0);
}

- (BOOL)isERR
{
    return (strcmp([self messageType], "ERR") == 0);
}

- (BOOL)isANS
{
    return (strcmp([self messageType], "ANS") == 0);
}

- (BOOL)isNUL
{
    return (strcmp([self messageType], "NUL") == 0);
}

- (BOOL)isSEQ
{
    return (strcmp([self messageType], "SEQ") == 0);
}

- (void)appendToMutableData:(NSMutableData *)aData {
    NSString *headerString = nil;
    
    if ([self isSEQ]) {
        headerString = [NSString stringWithFormat:@"%s %d %u %d\r\n", I_messageType, I_channelNumber, I_sequenceNumber, I_length];    
        [aData appendData:[headerString dataUsingEncoding:NSASCIIStringEncoding]];
        return;
    }
    
    if ([self isANS]) {
        headerString = [NSString stringWithFormat:@"%s %d %d %s %u %d %d\r\n", I_messageType, I_channelNumber, I_messageNumber, I_continuationIndicator, I_sequenceNumber, I_length, I_answerNumber];    
    } else {
        headerString = [NSString stringWithFormat:@"%s %d %d %s %u %d\r\n", I_messageType, I_channelNumber, I_messageNumber, I_continuationIndicator, I_sequenceNumber, I_length];
    }
    
    [aData appendData:[headerString dataUsingEncoding:NSASCIIStringEncoding]];
    [aData appendData:[self payload]];
    [aData appendData:[kTCMBEEPFrameTrailer dataUsingEncoding:NSASCIIStringEncoding]];
}


@end
