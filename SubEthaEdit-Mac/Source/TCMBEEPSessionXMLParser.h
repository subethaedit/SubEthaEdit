//  TCMBEEPSessionXMLParser.h
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 14.10.13.

#import <Foundation/Foundation.h>

extern NSString * const TCMBEEPSessionXMLElementReady;
extern NSString * const TCMBEEPSessionXMLElementProceed;
extern NSString * const TCMBEEPSessionXMLElementError;

extern NSString * const TCMBEEPSessionXMLAttributeVersion;
extern NSString * const TCMBEEPSessionXMLAttributeCode;

@interface TCMBEEPSessionXMLParser : NSObject <NSXMLParserDelegate>

@property (atomic, readonly, strong) NSString *elementName;
@property (atomic, readonly, strong) NSDictionary *attributeDict;
@property (atomic, readonly, strong) NSString *content;

- (instancetype)initWithXMLData:(NSData *)data;

@end
