//  TCMBEEPMessageXMLPayloadParser.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 14.10.13.

#import <Foundation/Foundation.h>

extern NSString * const TCMBEEPMessageXMLElementGreeting;
extern NSString * const TCMBEEPMessageXMLElementStart;
extern NSString * const TCMBEEPMessageXMLElementClose;
extern NSString * const TCMBEEPMessageXMLElementProfile;
extern NSString * const TCMBEEPMessageXMLElementOkay;
extern NSString * const TCMBEEPMessageXMLElementError;

extern NSString * const TCMBEEPMessageXMLAttributeFeatures;
extern NSString * const TCMBEEPMessageXMLAttributeLocalize;
extern NSString * const TCMBEEPMessageXMLAttributeURI;
extern NSString * const TCMBEEPMessageXMLAttributeChannelNumber;
extern NSString * const TCMBEEPMessageXMLAttributeCode;

@interface TCMBEEPMessageXMLPayloadParser : NSObject <NSXMLParserDelegate>

@property (atomic, readonly, copy) NSString *messageType;
@property (atomic, readonly, copy) NSDictionary *messageAttributeDict;
@property (atomic, readonly, copy) NSData *messageData;
@property (atomic, readonly, copy) NSArray *profileURIs;
@property (atomic, readonly, copy) NSArray *profileDataBlocks;

- (instancetype)initWithXMLData:(NSData *)data;

@end
